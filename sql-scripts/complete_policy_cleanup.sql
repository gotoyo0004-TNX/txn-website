-- =============================================
-- 徹底清理所有 RLS 策略
-- 解決策略重複創建問題的專用腳本
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🧹 開始徹底清理所有 user_profiles RLS 策略...';
END $$;

-- 暫時禁用 RLS
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- 清理所有可能存在的策略（按字母順序）
DROP POLICY IF EXISTS "admin_read_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_read_all_simple" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_update_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_update_all_simple" ON public.user_profiles;
DROP POLICY IF EXISTS "admins_can_view_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "admins_can_update_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_admin_read_all" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_admin_update_all" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_insert_authenticated" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_own_profile_read" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_own_profile_update" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_user_insert" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_user_registration" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_user_registration_safe" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_insert_own" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_read_own" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_update_own" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_users_read_all" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_users_read_own" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_admins_read_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_admins_update_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_user_registration" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_users_read_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_users_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "superuser_full_access" ON public.user_profiles;
DROP POLICY IF EXISTS "temp_all_read_access" ON public.user_profiles;
DROP POLICY IF EXISTS "temp_update_own" ON public.user_profiles;
DROP POLICY IF EXISTS "temp_insert_own" ON public.user_profiles;
DROP POLICY IF EXISTS "user_read_own_only" ON public.user_profiles;
DROP POLICY IF EXISTS "user_read_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "user_update_own_basic" ON public.user_profiles;
DROP POLICY IF EXISTS "user_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_view_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "users_update_own_simple" ON public.user_profiles;

-- 清理中文命名的策略
DROP POLICY IF EXISTS "分級管理員可以查看所有用戶" ON public.user_profiles;
DROP POLICY IF EXISTS "活躍用戶可以查看自己資料" ON public.user_profiles;
DROP POLICY IF EXISTS "管理員可以查看所有用戶" ON public.user_profiles;

-- 清理英文全名的策略
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view their own profile." ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles." ON public.user_profiles;

-- 重新啟用 RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 檢查清理結果
SELECT 
    '📊 策略清理結果' as status,
    COUNT(*) as remaining_policies
FROM pg_policies 
WHERE tablename = 'user_profiles';

-- 顯示剩餘策略（如果有）
SELECT 
    '📋 剩餘策略' as info,
    policyname
FROM pg_policies 
WHERE tablename = 'user_profiles'
ORDER BY policyname;

DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies WHERE tablename = 'user_profiles';
    
    RAISE NOTICE '✅ 策略清理完成！';
    RAISE NOTICE '📊 剩餘策略數量: %', policy_count;
    
    IF policy_count = 0 THEN
        RAISE NOTICE '🎉 所有策略已完全清理';
    ELSE
        RAISE NOTICE '⚠️ 仍有策略存在，請檢查';
    END IF;
END $$;