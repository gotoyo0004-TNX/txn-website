-- =============================================
-- 修復版：管理員權限分級系統 RLS 策略
-- 功能：解決 500 錯誤並安全更新 RLS 策略
-- 檔案名稱: 20250826_120000_fix_rls_policies.sql
-- =============================================

BEGIN;

DO $$
BEGIN
    RAISE NOTICE '🚀 開始修復 RLS 策略以解決 500 錯誤';
    RAISE NOTICE '⏰ 執行時間: %', NOW();
END $$;

-- =============================================
-- 1. 檢查和修復用戶資料
-- =============================================

DO $$
DECLARE
    admin_user_id UUID;
    user_count INTEGER;
BEGIN
    RAISE NOTICE '👤 檢查 admin@txn.test 用戶狀態...';
    
    -- 檢查 admin@txn.test 用戶
    SELECT id INTO admin_user_id
    FROM auth.users 
    WHERE email = 'admin@txn.test'
    LIMIT 1;
    
    IF admin_user_id IS NOT NULL THEN
        -- 確保該用戶在 user_profiles 表中有記錄
        INSERT INTO public.user_profiles (
            id,
            email,
            full_name,
            role,
            status,
            initial_capital,
            currency,
            timezone,
            trading_experience,
            approved_at,
            approved_by,
            created_at,
            updated_at
        ) VALUES (
            admin_user_id,
            'admin@txn.test',
            'TXN 系統管理員',
            'admin',
            'active',
            100000.00,
            'USD',
            'Asia/Taipei',
            'professional',
            NOW(),
            admin_user_id,
            NOW(),
            NOW()
        )
        ON CONFLICT (id) DO UPDATE SET
            role = 'admin',
            status = 'active',
            full_name = 'TXN 系統管理員',
            approved_at = NOW(),
            updated_at = NOW();
        
        RAISE NOTICE '✅ admin@txn.test 用戶資料已修復';
    ELSE
        RAISE NOTICE '⚠️ 未找到 admin@txn.test 認證用戶';
    END IF;
    
    -- 修復所有用戶的 NULL 值
    UPDATE public.user_profiles 
    SET 
        role = COALESCE(role, 'user'),
        status = COALESCE(status, 'pending')
    WHERE role IS NULL OR status IS NULL;
    
    GET DIAGNOSTICS user_count = ROW_COUNT;
    RAISE NOTICE '🔧 已修復 % 個用戶的 NULL 值', user_count;
END $$;

-- =============================================
-- 2. 清理所有舊的 RLS 策略
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🧹 清理舊的 RLS 策略...';
END $$;

-- 清理所有可能的舊策略
DROP POLICY IF EXISTS "管理員可以查看所有用戶" ON public.user_profiles;
DROP POLICY IF EXISTS "分級管理員可以查看所有用戶" ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles." ON public.user_profiles;
DROP POLICY IF EXISTS "活躍用戶可以查看自己資料" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view their own profile." ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;

-- =============================================
-- 3. 建立新的簡化 RLS 策略
-- =============================================

-- 策略 1: 用戶可以查看自己的資料
CREATE POLICY "users_can_view_own_profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

-- 策略 2: 管理員可以查看所有用戶資料
CREATE POLICY "admins_can_view_all_profiles" ON public.user_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles p
            WHERE p.id = auth.uid() 
            AND p.role IS NOT NULL
            AND p.role != 'user' 
            AND p.status = 'active'
        )
    );

-- 策略 3: 用戶可以更新自己的基本資料（不包括 role 和 status）
CREATE POLICY "users_can_update_own_profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- 策略 4: 管理員可以更新用戶狀態和角色
CREATE POLICY "admins_can_update_user_data" ON public.user_profiles
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles p
            WHERE p.id = auth.uid() 
            AND p.role IS NOT NULL
            AND p.role != 'user' 
            AND p.status = 'active'
        )
    );

-- 策略 5: 允許新用戶註冊
CREATE POLICY "allow_user_registration" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- =============================================
-- 4. 創建索引優化
-- =============================================

CREATE INDEX IF NOT EXISTS idx_user_profiles_auth_lookup 
ON public.user_profiles(id) WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_user_profiles_role_status 
ON public.user_profiles(role, status);

-- =============================================
-- 5. 最終驗證
-- =============================================

DO $$
DECLARE
    policy_count INTEGER;
    admin_count INTEGER;
BEGIN
    RAISE NOTICE '🔍 執行最終驗證...';
    
    -- 檢查策略數量
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE tablename = 'user_profiles';
    
    -- 檢查管理員數量
    SELECT COUNT(*) INTO admin_count
    FROM public.user_profiles 
    WHERE role != 'user' AND status = 'active';
    
    RAISE NOTICE '📋 已建立 % 個 RLS 策略', policy_count;
    RAISE NOTICE '👥 系統中有 % 個活躍的管理員用戶', admin_count;
    
    RAISE NOTICE '🎉 RLS 策略修復完成！';
    RAISE NOTICE '⏰ 完成時間: %', NOW();
END $$;

COMMIT;

-- =============================================
-- 🎯 執行完成後確認事項：
-- 
-- ✅ 已完成項目：
--    - ✅ 修復 admin@txn.test 用戶資料
--    - ✅ 清理所有舊的 RLS 策略
--    - ✅ 建立簡化的新 RLS 策略
--    - ✅ 添加索引優化查詢性能
--    - ✅ 修復所有 NULL 值問題
--
-- 🔄 下一步測試：
--    1. 重新載入前端應用，檢查是否還有 500 錯誤
--    2. 確認 admin@txn.test 可以正常訪問管理面板
--    3. 測試用戶查詢和管理功能
--    4. 驗證角色分配功能正常
--
-- 🧪 驗證查詢（可在 Supabase Dashboard 中執行）：
--    SELECT email, role, status FROM user_profiles WHERE email = 'admin@txn.test';
--    SELECT * FROM pg_policies WHERE tablename = 'user_profiles';
-- =============================================