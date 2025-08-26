-- 修復管理員帳號權限問題 - 終極修復版本
-- 檢查並強制修復 admin@txn.test 帳號

-- 💡 使用指南：
-- 1. 在 Supabase SQL 編輯器中執行此腳本
-- 2. 執行完成後重新登入 admin@txn.test
-- 3. 如果仍有問題，檢查 Supabase 項目設置和 RLS 策略

-- 📋 檢查 user_profiles 表結構
SELECT 
    '📋 User Profiles 表結構檢查' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 0. 詳細診斷當前狀態
SELECT 
    '=== 診斷報告 ===' as info;

-- 檢查 auth.users 表
SELECT 
    '📋 Auth Users 檢查' as step,
    email,
    id as user_uuid,
    email_confirmed_at IS NOT NULL as email_confirmed,
    created_at,
    CASE 
        WHEN email_confirmed_at IS NULL THEN '❌ Email 未驗證'
        ELSE '✅ Email 已驗證'
    END as email_status
FROM auth.users 
WHERE email = 'admin@txn.test';

-- 檢查 user_profiles 表
SELECT 
    '📋 User Profiles 檢查' as step,
    email,
    role,
    status,
    full_name,
    created_at,
    CASE 
        WHEN role IN ('admin', 'super_admin', 'moderator') AND status = 'active' THEN '✅ 權限正常'
        WHEN role NOT IN ('admin', 'super_admin', 'moderator') THEN '❌ 角色錯誤'
        WHEN status != 'active' THEN '❌ 狀態錯誤'
        ELSE '❌ 權限異常'
    END as permission_status
FROM user_profiles 
WHERE email = 'admin@txn.test';

-- 1. 強制修復 - 確保管理員帳號正確設置
DO $$
DECLARE
    user_exists BOOLEAN;
    user_uuid UUID;
    profile_exists BOOLEAN;
    current_role TEXT;
    current_status TEXT;
BEGIN
    RAISE NOTICE '🚀 開始強制修復流程...';
    
    -- 檢查用戶是否存在於 auth.users
    SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = 'admin@txn.test') INTO user_exists;
    
    IF NOT user_exists THEN
        RAISE NOTICE '❌ 致命錯誤: 用戶 admin@txn.test 不存在於 auth.users 表中';
        RAISE NOTICE '📋 解決方案: 請先在前端註冊 admin@txn.test 帳號，然後重新執行此腳本';
        RETURN;
    ELSE
        -- 獲取用戶 UUID
        SELECT id INTO user_uuid FROM auth.users WHERE email = 'admin@txn.test';
        RAISE NOTICE '✅ 找到認證用戶 admin@txn.test，UUID: %', user_uuid;
        
        -- 檢查是否存在於 user_profiles 表
        SELECT EXISTS(SELECT 1 FROM user_profiles WHERE id = user_uuid) INTO profile_exists;
        
        IF NOT profile_exists THEN
            RAISE NOTICE '🔧 用戶資料不存在，強制創建管理員資料...';
            
            -- 強制創建用戶資料
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
                updated_at,
                approved_at,
                approved_by
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
                NOW(),
                NOW(),
                user_uuid  -- 使用自己的 UUID 作為審批者
            )
            ON CONFLICT (id) DO UPDATE SET
                role = 'admin',
                status = 'active',
                full_name = 'System Administrator',
                trading_experience = 'professional',
                updated_at = NOW(),
                approved_at = NOW(),
                approved_by = user_uuid;  -- 使用自己的 UUID
            
            RAISE NOTICE '✅ 已強制創建/更新管理員用戶資料';
        ELSE
            -- 檢查目前權限
            SELECT role, status INTO current_role, current_status 
            FROM user_profiles WHERE id = user_uuid;
            
            RAISE NOTICE '📋 目前資料: role=%, status=%', current_role, current_status;
            
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
                updated_at = NOW(),
                approved_at = COALESCE(approved_at, NOW()),
                approved_by = COALESCE(approved_by, user_uuid)  -- 使用自己的 UUID 或保持原值
            WHERE id = user_uuid;
            
            RAISE NOTICE '✅ 已強制更新管理員權限和資料';
        END IF;
        
        -- 額外確認更新成功
        SELECT role, status INTO current_role, current_status 
        FROM user_profiles WHERE id = user_uuid;
        
        IF current_role = 'admin' AND current_status = 'active' THEN
            RAISE NOTICE '🎉 修復成功! 最終狀態: role=%, status=%', current_role, current_status;
        ELSE
            RAISE NOTICE '⚠️  修復可能失敗! 最終狀態: role=%, status=%', current_role, current_status;
        END IF;
    END IF;
END $$;

-- 2. 顯示完整修復結果
SELECT 
    '=== 修復結果報告 ===' as info;

SELECT 
    '📊 最終用戶狀態' as report_section,
    u.id as user_uuid,
    u.email,
    u.email_confirmed_at IS NOT NULL as email_verified,
    u.created_at as auth_created_at,
    p.role,
    p.status,
    p.full_name,
    p.approved_at,
    p.approved_by,
    p.created_at as profile_created_at,
    p.updated_at as profile_updated_at
FROM auth.users u
LEFT JOIN user_profiles p ON u.id = p.id
WHERE u.email = 'admin@txn.test';

-- 3. 權限檢查邏輯驗證
SELECT 
    '🔐 權限檢查結果' as report_section,
    'admin@txn.test' as email,
    role,
    status,
    CASE 
        WHEN role IN ('moderator', 'admin', 'super_admin') AND status = 'active' 
        THEN '✅ 可以訪問管理面板'
        WHEN role NOT IN ('moderator', 'admin', 'super_admin')
        THEN '❌ 角色權限不足 (需要: admin/moderator/super_admin)'
        WHEN status != 'active'
        THEN '❌ 帳號狀態異常 (需要: active)'
        ELSE '❌ 未知錯誤'
    END as access_status,
    CASE 
        WHEN role = 'admin' THEN '管理員'
        WHEN role = 'super_admin' THEN '超級管理員'
        WHEN role = 'moderator' THEN '版主'
        ELSE '一般用戶'
    END as role_display
FROM user_profiles 
WHERE email = 'admin@txn.test';

-- 4. 提供下一步指導
SELECT 
    '📋 下一步操作指導' as guide,
    '1. 清除瀏覽器 localStorage 和 cookies' as step_1,
    '2. 重新登入 admin@txn.test' as step_2,
    '3. 如果仍有載入問題，檢查瀏覽器開發者工具的 Console 和 Network 頁籤' as step_3,
    '4. 確認 Supabase 項目的 RLS 策略允許管理員訪問 user_profiles 表' as step_4;

-- 5. RLS 策略檢查 (如果可能)
SELECT 
    '🛡️ RLS 策略檢查' as security_check,
    schemaname,
    tablename,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'user_profiles'
ORDER BY policyname;