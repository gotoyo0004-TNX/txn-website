-- =============================================
-- 緊急修復：解決管理員 500 錯誤
-- 針對 admin@txn.test 用戶的 500 錯誤問題
-- 用戶 UUID: 13acfefa-cc3b-485e-8520-3d4e1a79d9cd
-- =============================================

BEGIN;

DO $$
BEGIN
    RAISE NOTICE '🚨 開始緊急修復管理員 500 錯誤';
    RAISE NOTICE '⏰ 執行時間: %', NOW();
    RAISE NOTICE '🎯 目標用戶: admin@txn.test';
    RAISE NOTICE '🔍 用戶 UUID: 13acfefa-cc3b-485e-8520-3d4e1a79d9cd';
END $$;

-- =============================================
-- 1. 詳細診斷當前狀態
-- =============================================

DO $$
DECLARE
    auth_user_exists BOOLEAN;
    profile_exists BOOLEAN;
    current_role TEXT;
    current_status TEXT;
    target_uuid UUID := '13acfefa-cc3b-485e-8520-3d4e1a79d9cd';
BEGIN
    RAISE NOTICE '=== 🔍 開始詳細診斷 ===';
    
    -- 檢查 auth.users 表
    SELECT EXISTS(SELECT 1 FROM auth.users WHERE id = target_uuid) INTO auth_user_exists;
    RAISE NOTICE '📋 Auth 用戶存在: %', auth_user_exists;
    
    -- 檢查 user_profiles 表
    SELECT EXISTS(SELECT 1 FROM public.user_profiles WHERE id = target_uuid) INTO profile_exists;
    RAISE NOTICE '📋 Profile 存在: %', profile_exists;
    
    IF profile_exists THEN
        SELECT role, status INTO current_role, current_status 
        FROM public.user_profiles WHERE id = target_uuid;
        RAISE NOTICE '📋 當前角色: %, 狀態: %', current_role, current_status;
    END IF;
END $$;

-- =============================================
-- 2. 強制修復用戶資料
-- =============================================

DO $$
DECLARE
    target_uuid UUID := '13acfefa-cc3b-485e-8520-3d4e1a79d9cd';
    auth_email TEXT;
BEGIN
    RAISE NOTICE '=== 🔧 開始強制修復 ===';
    
    -- 獲取認證用戶的郵箱
    SELECT email INTO auth_email FROM auth.users WHERE id = target_uuid;
    
    IF auth_email IS NULL THEN
        RAISE NOTICE '❌ 致命錯誤：認證用戶不存在！';
        RAISE NOTICE '📋 解決方案：請確認該用戶已正確註冊';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ 找到認證用戶：%', auth_email;
    
    -- 強制插入/更新用戶資料
    INSERT INTO public.user_profiles (
        id,
        email,
        full_name,
        role,
        status,
        trading_experience,
        initial_capital,
        currency,
        timezone,
        created_at,
        updated_at,
        approved_at,
        approved_by
    ) VALUES (
        target_uuid,
        auth_email,
        'TXN 系統管理員',
        'admin',
        'active',
        'professional',
        100000.00,
        'USD',
        'Asia/Taipei',
        NOW(),
        NOW(),
        NOW(),
        target_uuid
    )
    ON CONFLICT (id) DO UPDATE SET
        role = 'admin',
        status = 'active',
        full_name = COALESCE(user_profiles.full_name, 'TXN 系統管理員'),
        trading_experience = COALESCE(user_profiles.trading_experience, 'professional'),
        initial_capital = COALESCE(user_profiles.initial_capital, 100000.00),
        currency = COALESCE(user_profiles.currency, 'USD'),
        timezone = COALESCE(user_profiles.timezone, 'Asia/Taipei'),
        updated_at = NOW(),
        approved_at = NOW(),
        approved_by = target_uuid;
    
    RAISE NOTICE '✅ 用戶資料已強制修復';
END $$;

-- =============================================
-- 3. 清理並重建 RLS 策略
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '=== 🛡️ 修復 RLS 策略 ===';
END $$;

-- 清理所有舊策略
DROP POLICY IF EXISTS "users_can_view_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admins_can_view_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admins_can_update_user_data" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_user_registration" ON public.user_profiles;
DROP POLICY IF EXISTS "分級管理員可以查看所有用戶" ON public.user_profiles;
DROP POLICY IF EXISTS "活躍用戶可以查看自己資料" ON public.user_profiles;

-- 建立新的簡化策略
-- 策略 1: 用戶可以查看自己的資料
CREATE POLICY "allow_own_profile_read" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

-- 策略 2: 管理員可以查看所有資料
CREATE POLICY "allow_admin_read_all" ON public.user_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles admin_check
            WHERE admin_check.id = auth.uid() 
            AND admin_check.role IN ('admin', 'super_admin', 'moderator')
            AND admin_check.status = 'active'
        )
    );

-- 策略 3: 用戶可以更新自己的資料
CREATE POLICY "allow_own_profile_update" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- 策略 4: 管理員可以更新所有用戶資料
CREATE POLICY "allow_admin_update_all" ON public.user_profiles
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles admin_check
            WHERE admin_check.id = auth.uid() 
            AND admin_check.role IN ('admin', 'super_admin', 'moderator')
            AND admin_check.status = 'active'
        )
    );

-- 策略 5: 允許新用戶註冊
CREATE POLICY "allow_user_insert" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- =============================================
-- 4. 建立索引優化查詢性能
-- =============================================

-- 為認證查詢創建專用索引
CREATE INDEX IF NOT EXISTS idx_user_profiles_auth_active 
ON public.user_profiles(id, role, status) 
WHERE status = 'active';

-- 為管理員查詢創建索引
CREATE INDEX IF NOT EXISTS idx_user_profiles_admin_roles 
ON public.user_profiles(role, status) 
WHERE role IN ('admin', 'super_admin', 'moderator');

-- =============================================
-- 5. 最終驗證和測試
-- =============================================

DO $$
DECLARE
    target_uuid UUID := '13acfefa-cc3b-485e-8520-3d4e1a79d9cd';
    final_role TEXT;
    final_status TEXT;
    policy_count INTEGER;
BEGIN
    RAISE NOTICE '=== ✅ 最終驗證 ===';
    
    -- 檢查修復結果
    SELECT role, status INTO final_role, final_status 
    FROM public.user_profiles WHERE id = target_uuid;
    
    RAISE NOTICE '📊 最終狀態 - 角色: %, 狀態: %', final_role, final_status;
    
    -- 檢查 RLS 策略數量
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies WHERE tablename = 'user_profiles';
    
    RAISE NOTICE '🛡️ 已建立 % 個 RLS 策略', policy_count;
    
    -- 驗證管理員權限
    IF final_role IN ('admin', 'super_admin', 'moderator') AND final_status = 'active' THEN
        RAISE NOTICE '🎉 修復成功！管理員權限已正常';
    ELSE
        RAISE NOTICE '⚠️ 修復可能存在問題，請檢查';
    END IF;
END $$;

-- =============================================
-- 6. 顯示完整的修復報告
-- =============================================

SELECT 
    '=== 📋 修復完成報告 ===' as info,
    NOW() as 修復時間;

-- 顯示目標用戶的完整資訊
SELECT 
    '📊 目標用戶最終狀態' as 報告類型,
    u.id as 用戶UUID,
    u.email as 郵箱,
    u.email_confirmed_at IS NOT NULL as 郵箱已驗證,
    p.role as 角色,
    p.status as 狀態,
    p.full_name as 姓名,
    p.created_at as 創建時間,
    p.updated_at as 更新時間,
    p.approved_at as 審核時間
FROM auth.users u
LEFT JOIN public.user_profiles p ON u.id = p.id
WHERE u.id = '13acfefa-cc3b-485e-8520-3d4e1a79d9cd';

-- 顯示所有 RLS 策略
SELECT 
    '🛡️ RLS 策略狀態' as 報告類型,
    policyname as 策略名稱,
    cmd as 操作類型,
    permissive as 允許性策略
FROM pg_policies 
WHERE tablename = 'user_profiles'
ORDER BY policyname;

COMMIT;

-- =============================================
-- 🎯 執行完成後的下一步：
-- 
-- ✅ 立即測試：
--    1. 重新載入前端應用
--    2. 清除瀏覽器快取和 localStorage
--    3. 重新登入 admin@txn.test
--    4. 檢查是否還有 500 錯誤
--
-- 🔍 如果問題仍然存在：
--    1. 檢查瀏覽器開發者工具的 Network 頁籤
--    2. 查看 Supabase Dashboard 的 Logs
--    3. 確認前端環境變數設定正確
-- =============================================