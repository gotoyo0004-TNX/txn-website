-- 修復管理員帳號權限問題 - 緊急修復版本
-- 檢查並修復 admin@txn.test 帳號

-- 0. 快速檢查當前狀態
SELECT 
    'auth.users 檢查' as check_type,
    email,
    email_confirmed_at IS NOT NULL as email_confirmed,
    created_at
FROM auth.users 
WHERE email = 'admin@txn.test'
UNION ALL
SELECT 
    'user_profiles 檢查' as check_type,
    email,
    CASE WHEN status = 'active' THEN true ELSE false END as status_active,
    created_at
FROM user_profiles 
WHERE email = 'admin@txn.test';

-- 1. 緊急修復 - 確保管理員帳號正確設置
DO $$
DECLARE
    user_exists BOOLEAN;
    user_uuid UUID;
    profile_exists BOOLEAN;
BEGIN
    -- 檢查用戶是否存在於 auth.users
    SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = 'admin@txn.test') INTO user_exists;
    
    IF NOT user_exists THEN
        RAISE NOTICE '❌ 用戶 admin@txn.test 不存在於 auth.users 表中 - 請先註冊此帳號';
    ELSE
        -- 獲取用戶 UUID
        SELECT id INTO user_uuid FROM auth.users WHERE email = 'admin@txn.test';
        RAISE NOTICE '✅ 找到用戶 admin@txn.test，UUID: %', user_uuid;
        
        -- 檢查是否存在於 user_profiles 表
        SELECT EXISTS(SELECT 1 FROM user_profiles WHERE id = user_uuid) INTO profile_exists;
        
        IF NOT profile_exists THEN
            RAISE NOTICE '🔧 用戶不存在於 user_profiles 表中，正在創建...';
            
            -- 創建用戶資料
            INSERT INTO user_profiles (
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
                updated_at
            ) VALUES (
                user_uuid,
                'admin@txn.test',
                'System Administrator',
                'admin',
                'active',
                'professional',
                10000,
                'USD',
                'Asia/Taipei',
                NOW(),
                NOW()
            );
            
            RAISE NOTICE '✅ 已創建管理員用戶資料';
        ELSE
            RAISE NOTICE '🔧 用戶存在於 user_profiles 表中，正在檢查和修復權限...';
            
            -- 強制更新為正確的管理員設置
            UPDATE user_profiles 
            SET 
                role = 'admin',
                status = 'active',
                full_name = COALESCE(full_name, 'System Administrator'),
                trading_experience = COALESCE(trading_experience, 'professional'),
                initial_capital = COALESCE(initial_capital, 10000),
                currency = COALESCE(currency, 'USD'),
                timezone = COALESCE(timezone, 'Asia/Taipei'),
                updated_at = NOW()
            WHERE id = user_uuid;
            
            RAISE NOTICE '✅ 已更新管理員權限和資料';
        END IF;
    END IF;
END $$;

-- 2. 顯示最終結果
SELECT 
    u.id,
    u.email,
    u.email_confirmed_at,
    u.created_at as auth_created_at,
    p.role,
    p.status,
    p.full_name,
    p.created_at as profile_created_at
FROM auth.users u
LEFT JOIN user_profiles p ON u.id = p.id
WHERE u.email = 'admin@txn.test';

-- 3. 測試權限檢查邏輯
SELECT 
    'admin@txn.test' as email,
    role,
    status,
    CASE 
        WHEN role IN ('moderator', 'admin', 'super_admin') AND status = 'active' 
        THEN '✅ 可以訪問管理面板'
        ELSE '❌ 無法訪問管理面板'
    END as access_status
FROM user_profiles 
WHERE email = 'admin@txn.test';