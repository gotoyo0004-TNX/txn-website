-- =============================================
-- 測試前端使用的函數
-- 確保 get_current_user_info 函數正常工作
-- =============================================

SELECT '🧪 測試前端權限檢查函數...' as status;

-- =============================================
-- 1. 測試 get_current_user_info 函數
-- =============================================

-- 檢查函數是否存在
SELECT 
    '🔍 函數檢查' as check_type,
    proname as function_name,
    prosrc IS NOT NULL as has_source
FROM pg_proc 
WHERE proname = 'get_current_user_info';

-- 測試函數執行 (模擬管理員用戶)
SELECT 
    '🧪 函數測試' as test_type,
    user_id,
    email,
    role,
    status
FROM public.get_current_user_info();

-- =============================================
-- 2. 測試 is_admin_user_simple 函數
-- =============================================

-- 檢查函數是否存在
SELECT 
    '🔍 簡單管理員檢查函數' as check_type,
    proname as function_name,
    prosrc IS NOT NULL as has_source
FROM pg_proc 
WHERE proname = 'is_admin_user_simple';

-- 測試管理員郵件檢查
SELECT 
    '🧪 管理員郵件測試' as test_type,
    'admin@txn.test' as email,
    public.is_admin_user_simple('admin@txn.test') as is_admin;

-- =============================================
-- 3. 檢查 RLS 策略狀態
-- =============================================

-- 檢查當前的 RLS 策略
SELECT 
    '🛡️ RLS 策略狀態' as check_type,
    schemaname,
    tablename,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'user_profiles'
ORDER BY policyname;

-- 檢查表的 RLS 啟用狀態
SELECT 
    '🔒 RLS 啟用狀態' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename = 'user_profiles';

-- =============================================
-- 4. 測試基本查詢
-- =============================================

-- 測試基本的用戶查詢
SELECT 
    '🧪 基本查詢測試' as test_type,
    COUNT(*) as total_users,
    COUNT(CASE WHEN role = 'super_admin' THEN 1 END) as super_admins,
    COUNT(CASE WHEN role = 'admin' THEN 1 END) as admins,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_users
FROM public.user_profiles;

-- 測試管理員帳戶查詢
SELECT 
    '🧪 管理員帳戶查詢' as test_type,
    id,
    email,
    role,
    status,
    created_at
FROM public.user_profiles 
WHERE email = 'admin@txn.test';

-- =============================================
-- 5. 權限測試
-- =============================================

-- 測試函數權限
SELECT 
    '🔐 函數權限測試' as test_type,
    has_function_privilege('authenticated', 'public.get_current_user_info()', 'execute') as can_execute_get_user_info,
    has_function_privilege('authenticated', 'public.is_admin_user_simple(text)', 'execute') as can_execute_is_admin;

-- =============================================
-- 6. 完成報告
-- =============================================

SELECT '✅ 前端函數測試完成！' as status;
SELECT '📋 檢查結果：' as summary;
SELECT '1. get_current_user_info 函數狀態' as check_1;
SELECT '2. is_admin_user_simple 函數狀態' as check_2;
SELECT '3. RLS 策略配置' as check_3;
SELECT '4. 基本查詢功能' as check_4;
SELECT '5. 函數執行權限' as check_5;

SELECT '🎯 如果所有測試通過，前端應該能正常工作' as conclusion;
