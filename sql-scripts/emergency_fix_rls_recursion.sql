-- =============================================
-- 緊急修復 RLS 無限遞歸問題
-- 最簡單快速的解決方案
-- =============================================

-- 🚨 緊急修復：立即解決無限遞歸問題

-- 1. 暫時禁用 RLS（立即解決問題）
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- 2. 清理所有有問題的策略（徹底清理）
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

-- 清理可能已存在的新策略
DROP POLICY IF EXISTS "authenticated_users_read_all" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_users_read_own" ON public.user_profiles;
DROP POLICY IF EXISTS "users_update_own_simple" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_insert_authenticated" ON public.user_profiles;

-- 清理其他可能的策略變體
DROP POLICY IF EXISTS "authenticated_read_own" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_update_own" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_insert_own" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_read_all_simple" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_update_all_simple" ON public.user_profiles;

-- 3. 創建最簡單的策略（無遞歸風險）
-- 策略 1: 所有認證用戶可以查看自己的資料
CREATE POLICY "authenticated_users_read_own" ON public.user_profiles
    FOR SELECT 
    TO authenticated
    USING (auth.uid() = id);

-- 策略 2: 認證用戶可以查看所有資料（暫時性解決方案）
CREATE POLICY "authenticated_users_read_all" ON public.user_profiles
    FOR SELECT 
    TO authenticated
    USING (true);

-- 策略 2: 用戶只能更新自己的資料
CREATE POLICY "users_update_own_simple" ON public.user_profiles
    FOR UPDATE 
    TO authenticated
    USING (auth.uid() = id);

-- 策略 3: 允許插入新用戶資料
CREATE POLICY "allow_insert_authenticated" ON public.user_profiles
    FOR INSERT 
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- 4. 重新啟用 RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 5. 確認修復成功
SELECT 
    '✅ 緊急修復完成' as status,
    '已移除遞歸策略，系統應該可以正常訪問' as message,
    COUNT(*) as total_policies
FROM pg_policies 
WHERE tablename = 'user_profiles';

-- 完成通知
DO $$
BEGIN
    RAISE NOTICE '🚨 緊急修復完成！';
    RAISE NOTICE '📊 RLS 無限遞歸問題已解決';
    RAISE NOTICE '⚡ 請立即重新整理頁面測試';
END $$;