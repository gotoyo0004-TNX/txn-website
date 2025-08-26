-- =============================================
-- 修復 RLS 策略無限遞歸問題（語法正確版本）
-- 避免使用 OLD 關鍵字等問題
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🔧 開始修復 RLS 策略...';
END $$;

-- =============================================
-- 1. 暫時禁用 RLS 並清理策略
-- =============================================

-- 暫時禁用 RLS
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- 清理所有現有策略
DROP POLICY IF EXISTS "user_read_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_read_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "user_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_update_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_user_registration" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_view_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admins_can_view_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admins_can_update_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_user_registration" ON public.user_profiles;
DROP POLICY IF EXISTS "user_read_own_only" ON public.user_profiles;
DROP POLICY IF EXISTS "user_update_own_basic" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_user_registration_safe" ON public.user_profiles;
DROP POLICY IF EXISTS "superuser_full_access" ON public.user_profiles;

-- =============================================
-- 2. 創建簡單且正確的策略
-- =============================================

-- 策略 1: 認證用戶可以查看自己的資料
CREATE POLICY "authenticated_read_own" ON public.user_profiles
    FOR SELECT 
    TO authenticated
    USING (auth.uid() = id);

-- 策略 2: 認證用戶可以更新自己的資料
CREATE POLICY "authenticated_update_own" ON public.user_profiles
    FOR UPDATE 
    TO authenticated
    USING (auth.uid() = id);

-- 策略 3: 允許新用戶插入自己的資料
CREATE POLICY "authenticated_insert_own" ON public.user_profiles
    FOR INSERT 
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- 策略 4: 管理員可以查看所有資料（簡化版，避免遞歸）
-- 使用簡單的條件檢查，不查詢同一張表
CREATE POLICY "admin_read_all_simple" ON public.user_profiles
    FOR SELECT 
    TO authenticated
    USING (
        -- 檢查當前用戶 ID 是否在已知的管理員列表中
        auth.uid() IN (
            SELECT au.id 
            FROM auth.users au
            WHERE au.email IN ('admin@txn.test', 'gotoyo0004@gmail.com')
        )
        OR auth.uid() = id  -- 或者是查看自己的資料
    );

-- 策略 5: 管理員可以更新所有用戶資料
CREATE POLICY "admin_update_all_simple" ON public.user_profiles
    FOR UPDATE 
    TO authenticated
    USING (
        auth.uid() IN (
            SELECT au.id 
            FROM auth.users au
            WHERE au.email IN ('admin@txn.test', 'gotoyo0004@gmail.com')
        )
        OR auth.uid() = id  -- 或者是更新自己的資料
    );

-- =============================================
-- 3. 重新啟用 RLS
-- =============================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 4. 測試策略
-- =============================================

DO $$
DECLARE
    policy_count INTEGER;
    test_admin_uuid UUID;
BEGIN
    RAISE NOTICE '🧪 測試修復後的策略...';
    
    -- 檢查策略數量
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE tablename = 'user_profiles';
    
    RAISE NOTICE '📊 已建立 % 個 RLS 策略', policy_count;
    
    -- 檢查管理員用戶
    SELECT id INTO test_admin_uuid
    FROM auth.users 
    WHERE email = 'admin@txn.test'
    LIMIT 1;
    
    IF test_admin_uuid IS NOT NULL THEN
        RAISE NOTICE '✅ 找到管理員用戶: admin@txn.test';
    ELSE
        RAISE NOTICE '📋 未找到 admin@txn.test 用戶';
    END IF;
    
    RAISE NOTICE '✅ RLS 策略修復完成！';
END $$;

-- =============================================
-- 5. 顯示結果
-- =============================================

SELECT 
    '=== 📋 修復完成報告 ===' as report_type,
    NOW() as fix_time;

-- 顯示當前策略
SELECT 
    '🛡️ 當前 RLS 策略' as section,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'user_profiles'
ORDER BY policyname;

-- 簡單測試查詢
SELECT 
    '🧪 基本查詢測試' as section,
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE role = 'admin') as admin_count
FROM user_profiles;

-- 使用指引
SELECT 
    '📋 使用指引' as guide_type,
    '1. RLS 策略已修復，避免了無限遞歸問題' as step_1,
    '2. 使用簡單的郵件列表來識別管理員' as step_2,
    '3. 普通用戶只能訪問自己的資料' as step_3,
    '4. 管理員可以訪問所有資料' as step_4,
    '5. 清除瀏覽器快取並重新登入測試' as step_5;

-- 完成通知
DO $$
BEGIN
    RAISE NOTICE '🎉 RLS 策略修復完成，應該不會再有遞歸問題！';
    RAISE NOTICE '⚡ 請立即重新整理頁面測試訪問';
END $$;