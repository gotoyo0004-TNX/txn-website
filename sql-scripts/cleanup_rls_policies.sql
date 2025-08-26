-- =============================================
-- 清理所有 user_profiles RLS 策略
-- 解決策略重複創建的問題
-- =============================================

-- 💡 使用指南：
-- 1. 先執行此腳本清理所有舊的 RLS 策略
-- 2. 然後執行主要的修復腳本
-- 3. 這樣可以避免 "policy already exists" 錯誤

DO $$
BEGIN
    RAISE NOTICE '🧹 開始清理所有 user_profiles RLS 策略...';
END $$;

-- 清理所有可能存在的 RLS 策略
DROP POLICY IF EXISTS "user_read_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_read_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "user_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_update_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_user_registration" ON public.user_profiles;

-- 清理其他可能的命名變體
DROP POLICY IF EXISTS "users_can_view_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admins_can_view_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admins_can_update_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_user_registration" ON public.user_profiles;

-- 清理舊版本的策略名稱
DROP POLICY IF EXISTS "分級管理員可以查看所有用戶" ON public.user_profiles;
DROP POLICY IF EXISTS "活躍用戶可以查看自己資料" ON public.user_profiles;
DROP POLICY IF EXISTS "管理員可以查看所有用戶" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view their own profile." ON public.user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles." ON public.user_profiles;

-- 清理可能的其他變體
DROP POLICY IF EXISTS "allow_own_profile_read" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_admin_read_all" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_own_profile_update" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_admin_update_all" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_user_insert" ON public.user_profiles;

-- 清理更多可能的策略
DROP POLICY IF EXISTS "enable_users_read_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_admins_read_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_users_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_admins_update_all_profiles" ON public.user_profiles;

-- 檢查清理結果
SELECT 
    '📊 清理後的策略狀態' as check_type,
    COUNT(*) as remaining_policies
FROM pg_policies 
WHERE tablename = 'user_profiles';

-- 顯示剩餘的策略（如果有的話）
SELECT 
    '📋 剩餘的 RLS 策略' as info,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'user_profiles'
ORDER BY policyname;

-- 完成通知
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies WHERE tablename = 'user_profiles';
    
    RAISE NOTICE '✅ RLS 策略清理完成';
    RAISE NOTICE '📊 剩餘策略數量: %', policy_count;
    
    IF policy_count = 0 THEN
        RAISE NOTICE '🎉 所有舊策略已清理，可以安全執行修復腳本';
    ELSE
        RAISE NOTICE '⚠️ 仍有 % 個策略，請檢查是否需要手動清理', policy_count;
    END IF;
END $$;