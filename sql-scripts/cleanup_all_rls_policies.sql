-- =============================================
-- 徹底清理所有 user_profiles RLS 策略
-- 根據 RLS 策略創建規範，清理所有可能的策略變體
-- =============================================

-- 💡 使用指南：
-- 1. 先執行此腳本清理所有策略
-- 2. 然後執行主要的修復腳本
-- 3. 這樣可以避免 "policy already exists" 錯誤

DO $$
BEGIN
    RAISE NOTICE '🧹 開始徹底清理所有 user_profiles RLS 策略...';
END $$;

-- =============================================
-- 1. 暫時禁用 RLS 以避免清理過程中的問題
-- =============================================

ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- =============================================
-- 2. 清理所有可能的策略名稱（按字母順序）
-- =============================================

-- A 開頭的策略
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

-- E 開頭的策略
DROP POLICY IF EXISTS "enable_admins_read_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_admins_update_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_user_registration" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_users_read_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_users_update_own_profile" ON public.user_profiles;

-- S 開頭的策略
DROP POLICY IF EXISTS "superuser_full_access" ON public.user_profiles;

-- U 開頭的策略
DROP POLICY IF EXISTS "user_read_own_only" ON public.user_profiles;
DROP POLICY IF EXISTS "user_read_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "user_update_own_basic" ON public.user_profiles;
DROP POLICY IF EXISTS "user_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_view_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "users_update_own_simple" ON public.user_profiles;

-- 中文命名的策略
DROP POLICY IF EXISTS "分級管理員可以查看所有用戶" ON public.user_profiles;
DROP POLICY IF EXISTS "活躍用戶可以查看自己資料" ON public.user_profiles;
DROP POLICY IF EXISTS "管理員可以查看所有用戶" ON public.user_profiles;

-- 英文全名的策略
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view their own profile." ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles." ON public.user_profiles;

-- =============================================
-- 3. 檢查清理結果
-- =============================================

DO $$
DECLARE
    remaining_policies INTEGER;
BEGIN
    SELECT COUNT(*) INTO remaining_policies
    FROM pg_policies 
    WHERE tablename = 'user_profiles';
    
    RAISE NOTICE '📊 清理後剩餘策略數量: %', remaining_policies;
    
    IF remaining_policies = 0 THEN
        RAISE NOTICE '✅ 所有策略已清理完成';
    ELSE
        RAISE NOTICE '⚠️ 仍有策略未清理，請檢查';
    END IF;
END $$;

-- 顯示剩餘的策略（如果有的話）
SELECT 
    '📋 剩餘的策略' as info,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'user_profiles'
ORDER BY policyname;

-- =============================================
-- 4. 重新啟用 RLS（準備接受新策略）
-- =============================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 完成通知
DO $$
BEGIN
    RAISE NOTICE '🎉 策略清理完成！';
    RAISE NOTICE '📋 現在可以安全地執行主要修復腳本';
    RAISE NOTICE '⚡ 建議執行：emergency_fix_rls_recursion.sql 或 fix_rls_simple_correct.sql';
END $$;