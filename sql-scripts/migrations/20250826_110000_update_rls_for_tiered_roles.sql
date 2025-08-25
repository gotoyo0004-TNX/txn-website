-- =============================================
-- Migration Script: Evolve RLS policies for tiered admin roles
-- 功能: 更新 RLS 策略以支援多種管理員角色 (super_admin, admin, moderator)
-- 作者: TXN Development Team
-- 建立時間: 2025-08-26 11:00:00
-- 檔案名稱: 20250826_110000_update_rls_for_tiered_roles.sql
-- =============================================

-- 這個腳本將現有的硬編碼 'admin' 角色檢查，
-- 改為更靈活的「非 'user' 角色」檢查，
-- 為未來的複雜管理員功能做準備。

BEGIN;

-- =============================================
-- 1. 更新用戶資料表的管理員查看政策
-- =============================================

-- 移除舊的管理員查看政策
DROP POLICY IF EXISTS "管理員可以查看所有用戶" ON public.user_profiles;

-- 建立新的分級管理員查看政策
-- 這個政策允許任何角色不是 'user' 的用戶查看所有用戶資料
CREATE POLICY "分級管理員可以查看所有用戶" ON public.user_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() 
            AND role != 'user' 
            AND status = 'active'
        )
    );

-- 確保用戶自己查看資料的政策仍然有效且具有優先級
DROP POLICY IF EXISTS "活躍用戶可以查看自己資料" ON public.user_profiles;
CREATE POLICY "活躍用戶可以查看自己資料" ON public.user_profiles
    FOR SELECT USING (
        auth.uid() = id AND status = 'active'
    );

-- =============================================
-- 2. 更新用戶資料表的管理員更新政策
-- =============================================

-- 移除舊的管理員更新政策
DROP POLICY IF EXISTS "管理員可以更新用戶狀態" ON public.user_profiles;

-- 建立新的分級管理員更新政策
CREATE POLICY "分級管理員可以更新用戶狀態" ON public.user_profiles
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() 
            AND role != 'user' 
            AND status = 'active'
        )
    );

-- =============================================
-- 3. 更新管理員日誌表的政策
-- =============================================

-- 移除舊的管理員日誌查看政策
DROP POLICY IF EXISTS "只有管理員可以查看管理員日誌" ON public.admin_logs;

-- 建立新的分級管理員日誌查看政策
CREATE POLICY "分級管理員可以查看管理員日誌" ON public.admin_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() 
            AND role != 'user' 
            AND status = 'active'
        )
    );

-- 移除舊的管理員日誌新增政策
DROP POLICY IF EXISTS "只有管理員可以新增管理員日誌" ON public.admin_logs;

-- 建立新的分級管理員日誌新增政策
CREATE POLICY "分級管理員可以新增管理員日誌" ON public.admin_logs
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() 
            AND role != 'user' 
            AND status = 'active'
        ) AND admin_id = auth.uid()
    );

-- =============================================
-- 4. 更新用戶狀態歷史表的政策
-- =============================================

-- 更新用戶狀態歷史查看政策
DROP POLICY IF EXISTS "用戶可以查看自己的狀態歷史" ON public.user_status_history;
CREATE POLICY "用戶和分級管理員可以查看狀態歷史" ON public.user_status_history
    FOR SELECT USING (
        user_id = auth.uid() OR 
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() 
            AND role != 'user' 
            AND status = 'active'
        )
    );

-- 更新用戶狀態歷史新增政策
DROP POLICY IF EXISTS "只有管理員可以新增狀態歷史" ON public.user_status_history;
CREATE POLICY "分級管理員可以新增狀態歷史" ON public.user_status_history
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() 
            AND role != 'user' 
            AND status = 'active'
        )
    );

-- =============================================
-- 5. 建立角色權限視圖 (可選)
-- =============================================

-- 建立一個視圖來簡化角色權限檢查
CREATE OR REPLACE VIEW admin_user_roles AS
SELECT 
    id,
    email,
    full_name,
    role,
    status,
    CASE 
        WHEN role = 'super_admin' THEN 4
        WHEN role = 'admin' THEN 3
        WHEN role = 'moderator' THEN 2
        WHEN role = 'user' THEN 1
        ELSE 0
    END as role_level,
    role != 'user' as is_admin_role
FROM public.user_profiles
WHERE status = 'active';

-- 為視圖建立索引（PostgreSQL 不直接支援視圖索引，但可以為基礎表建立）
CREATE INDEX IF NOT EXISTS idx_user_profiles_role_status_active 
ON public.user_profiles(role, status) 
WHERE status = 'active';

-- =============================================
-- 6. 更新相關的函數 (如果存在)
-- =============================================

-- 更新 approve_user 函數的權限檢查 (如果存在)
CREATE OR REPLACE FUNCTION public.approve_user(target_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_user_role TEXT;
    target_user_exists BOOLEAN;
BEGIN
    -- 檢查當前用戶是否有管理員權限 (不是 'user' 角色)
    SELECT role INTO current_user_role
    FROM public.user_profiles
    WHERE id = auth.uid() AND status = 'active';
    
    IF current_user_role IS NULL OR current_user_role = 'user' THEN
        RAISE EXCEPTION 'Insufficient permissions: Only admin-level users can approve users';
    END IF;
    
    -- 檢查目標用戶是否存在
    SELECT EXISTS (
        SELECT 1 FROM public.user_profiles 
        WHERE id = target_user_id
    ) INTO target_user_exists;
    
    IF NOT target_user_exists THEN
        RAISE EXCEPTION 'Target user does not exist';
    END IF;
    
    -- 執行用戶批准
    UPDATE public.user_profiles SET
        status = 'active',
        approved_at = NOW(),
        approved_by = auth.uid(),
        updated_at = NOW()
    WHERE id = target_user_id;
    
    -- 記錄管理員操作
    INSERT INTO public.admin_logs (
        admin_id,
        action,
        target_user_id,
        details,
        created_at
    ) VALUES (
        auth.uid(),
        'APPROVE_USER',
        target_user_id,
        jsonb_build_object(
            'action', 'User approved',
            'approved_by_role', current_user_role
        ),
        NOW()
    );
    
    RETURN TRUE;
END;
$$;

-- 更新 deactivate_user 函數的權限檢查 (如果存在)
CREATE OR REPLACE FUNCTION public.deactivate_user(target_user_id UUID, reason TEXT DEFAULT NULL)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_user_role TEXT;
    target_user_exists BOOLEAN;
BEGIN
    -- 檢查當前用戶是否有管理員權限 (不是 'user' 角色)
    SELECT role INTO current_user_role
    FROM public.user_profiles
    WHERE id = auth.uid() AND status = 'active';
    
    IF current_user_role IS NULL OR current_user_role = 'user' THEN
        RAISE EXCEPTION 'Insufficient permissions: Only admin-level users can deactivate users';
    END IF;
    
    -- 檢查目標用戶是否存在
    SELECT EXISTS (
        SELECT 1 FROM public.user_profiles 
        WHERE id = target_user_id
    ) INTO target_user_exists;
    
    IF NOT target_user_exists THEN
        RAISE EXCEPTION 'Target user does not exist';
    END IF;
    
    -- 執行用戶停用
    UPDATE public.user_profiles SET
        status = 'inactive',
        updated_at = NOW()
    WHERE id = target_user_id;
    
    -- 記錄狀態變更歷史
    INSERT INTO public.user_status_history (
        user_id,
        old_status,
        new_status,
        changed_by,
        reason,
        created_at
    ) SELECT 
        target_user_id,
        'active',
        'inactive',
        auth.uid(),
        COALESCE(reason, 'Deactivated by admin'),
        NOW();
    
    -- 記錄管理員操作
    INSERT INTO public.admin_logs (
        admin_id,
        action,
        target_user_id,
        details,
        created_at
    ) VALUES (
        auth.uid(),
        'DEACTIVATE_USER',
        target_user_id,
        jsonb_build_object(
            'action', 'User deactivated',
            'reason', COALESCE(reason, 'No reason provided'),
            'deactivated_by_role', current_user_role
        ),
        NOW()
    );
    
    RETURN TRUE;
END;
$$;

-- =============================================
-- 7. 驗證和測試
-- =============================================

-- 檢查政策是否正確建立
SELECT 
    'RLS Policies Updated' as status,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename IN ('user_profiles', 'admin_logs', 'user_status_history')
AND policyname LIKE '%分級管理員%';

-- 檢查視圖是否建立成功
SELECT 
    'Admin Roles View' as status,
    COUNT(*) as view_exists
FROM information_schema.views 
WHERE table_name = 'admin_user_roles';

COMMIT;

-- =============================================
-- 執行完成後確認事項：
-- 
-- ✅ 已完成項目：
--    - 移除硬編碼的 'admin' 角色檢查
--    - 建立靈活的「非 'user' 角色」權限系統
--    - 更新所有相關的 RLS 策略
--    - 建立角色權限視圖
--    - 更新管理員功能函數
--
-- 🔄 下一步：
--    - 在前端定義角色常數
--    - 建立分級管理員界面
--    - 實作角色管理功能
--
-- 🧪 測試建議：
--    - 確認現有管理員仍可正常訪問
--    - 測試不同角色的權限範圍
--    - 驗證 RLS 策略正常運作
-- =============================================