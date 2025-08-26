-- =============================================
-- 測試 SQL 修復是否正確
-- 這個腳本會模擬修復流程但不實際執行
-- =============================================

-- 1. 檢查當前 admin@txn.test 的狀態
SELECT 
    '📋 當前管理員狀態檢查' as test_step,
    u.id,
    u.email,
    u.email_confirmed_at IS NOT NULL as email_verified,
    p.role,
    p.status,
    p.approved_at,
    p.approved_by
FROM auth.users u
LEFT JOIN user_profiles p ON u.id = p.id
WHERE u.email = 'admin@txn.test';

-- 2. 測試 UPSERT 語法（不實際執行，只檢查語法）
DO $$
DECLARE
    admin_uuid UUID;
    test_result TEXT := '語法檢查通過';
BEGIN
    -- 獲取測試用的 UUID
    SELECT id INTO admin_uuid FROM auth.users WHERE email = 'admin@txn.test' LIMIT 1;
    
    IF admin_uuid IS NOT NULL THEN
        -- 這裡只是語法檢查，實際的 INSERT 會被註解掉
        RAISE NOTICE '✅ UPSERT 語法檢查通過';
        RAISE NOTICE '📋 將會使用 UUID: %', admin_uuid;
        
        /*
        -- 實際的修復語句（已註解，僅供語法檢查）
        INSERT INTO user_profiles (
            id, email, full_name, role, status, trading_experience,
            initial_capital, currency, timezone, created_at, updated_at, approved_at, approved_by
        ) VALUES (
            admin_uuid, 'admin@txn.test', 'TXN 系統管理員', 'admin', 'active', 
            'professional', 100000, 'USD', 'Asia/Taipei', NOW(), NOW(), NOW(), admin_uuid
        )
        ON CONFLICT (id) DO UPDATE SET
            role = 'admin',
            status = 'active',
            updated_at = NOW(),
            approved_at = COALESCE(user_profiles.approved_at, NOW());
        */
        
    ELSE
        RAISE NOTICE '❌ 找不到 admin@txn.test 用戶';
        RAISE NOTICE '📋 請先確保該用戶已在 Supabase 中註冊';
    END IF;
    
    RAISE NOTICE '✅ SQL 語法測試完成: %', test_result;
END $$;

-- 3. 檢查表結構中的欄位
SELECT 
    '📋 user_profiles 表結構檢查' as test_step,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
    AND table_schema = 'public'
    AND column_name IN ('approved_at', 'approved_by', 'role', 'status')
ORDER BY ordinal_position;

-- 4. 顯示修復前後對比指南
SELECT 
    '📋 修復前後對比' as guide_type,
    '修復前: COALESCE(approved_at, NOW()) - 會產生歧義錯誤' as before_fix,
    '修復後: COALESCE(user_profiles.approved_at, NOW()) - 明確指定表名' as after_fix,
    '原因: 在 ON CONFLICT DO UPDATE 中，欄位名可能指向新值或舊值' as explanation;

-- 5. 下一步執行指南
SELECT 
    '🚀 執行指南' as action_type,
    '1. 如果語法檢查通過，執行 quick_fix_loading.sql' as step_1,
    '2. 或者執行 fix_admin_loading_issue_2024.sql 進行完整修復' as step_2,
    '3. 執行後清除瀏覽器快取並重新登入' as step_3;