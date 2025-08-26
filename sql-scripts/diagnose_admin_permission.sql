-- 診斷管理員帳號權限問題
-- 檢查 admin@txn.test 帳號的詳細信息

-- 1. 檢查用戶是否存在及其基本信息
SELECT 
    id,
    email,
    role,
    status,
    created_at,
    updated_at,
    approved_at,
    approved_by
FROM user_profiles 
WHERE email = 'admin@txn.test';

-- 2. 檢查所有管理員帳號
SELECT 
    email,
    role,
    status,
    created_at
FROM user_profiles 
WHERE role IN ('admin', 'super_admin', 'moderator')
ORDER BY created_at DESC;

-- 3. 檢查 RLS 策略是否正確
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'user_profiles';

-- 4. 檢查用戶認證記錄
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    last_sign_in_at
FROM auth.users 
WHERE email = 'admin@txn.test';