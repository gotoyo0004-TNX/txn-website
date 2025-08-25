-- =============================================
-- TXN 測試管理員帳號創建腳本
-- 日期: 2025-08-25
-- 功能: 創建測試用管理員帳號
-- 版本: v1.0 (測試環境)
-- =============================================

-- 1. 檢查是否已有測試管理員帳號
DO $$
DECLARE
    test_admin_exists BOOLEAN;
BEGIN
    -- 檢查是否已存在測試管理員
    SELECT EXISTS (
        SELECT 1 FROM public.user_profiles 
        WHERE email = 'admin@txn.test' AND role = 'admin'
    ) INTO test_admin_exists;
    
    IF test_admin_exists THEN
        RAISE NOTICE '測試管理員帳號已存在，跳過創建';
    ELSE
        RAISE NOTICE '開始創建測試管理員帳號...';
    END IF;
END $$;

-- 2. 創建測試管理員用戶資料
-- 注意：這個腳本假設您已經在 Supabase Auth 中手動創建了用戶
-- 用戶資訊：
-- Email: admin@txn.test
-- Password: AdminTest123!
-- 
-- 如果尚未創建 Auth 用戶，請先在 Supabase Dashboard 的 Authentication > Users 中創建
-- 然後將下面的 USER_ID 替換為實際的用戶 ID

-- 方法一：如果您已經知道用戶 ID，請替換下面的 'YOUR_USER_ID_HERE'
-- INSERT INTO public.user_profiles (
--     id,
--     email,
--     full_name,
--     role,
--     status,
--     initial_capital,
--     currency,
--     timezone,
--     trading_experience,
--     approved_at,
--     approved_by,
--     created_at,
--     updated_at
-- ) VALUES (
--     'YOUR_USER_ID_HERE'::uuid,
--     'admin@txn.test',
--     'TXN 測試管理員',
--     'admin',
--     'active',
--     100000.00,
--     'USD',
--     'Asia/Taipei',
--     'professional',
--     NOW(),
--     'YOUR_USER_ID_HERE'::uuid,
--     NOW(),
--     NOW()
-- )
-- ON CONFLICT (id) DO UPDATE SET
--     role = 'admin',
--     status = 'active',
--     full_name = 'TXN 測試管理員',
--     approved_at = NOW(),
--     updated_at = NOW();

-- 方法二：創建完整的測試環境（推薦）
-- 這個方法會創建一個假的用戶 ID 用於測試
-- 注意：這只適用於測試環境，不應在生產環境使用

INSERT INTO public.user_profiles (
    id,
    email,
    full_name,
    role,
    status,
    initial_capital,
    currency,
    timezone,
    trading_experience,
    approved_at,
    approved_by,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000001'::uuid,  -- 測試用固定 UUID
    'admin@txn.test',
    'TXN 測試管理員',
    'admin',
    'active',
    100000.00,
    'USD',
    'Asia/Taipei',
    'professional',
    NOW(),
    '00000000-0000-0000-0000-000000000001'::uuid,
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    role = 'admin',
    status = 'active',
    full_name = 'TXN 測試管理員',
    approved_at = NOW(),
    updated_at = NOW();

-- 3. 創建一些測試用的待審核用戶
INSERT INTO public.user_profiles (
    id,
    email,
    full_name,
    role,
    status,
    initial_capital,
    currency,
    timezone,
    trading_experience,
    created_at,
    updated_at
) VALUES 
(
    '00000000-0000-0000-0000-000000000002'::uuid,
    'user1@test.com',
    '測試用戶一',
    'user',
    'pending',
    10000.00,
    'USD',
    'Asia/Taipei',
    'beginner',
    NOW() - INTERVAL '2 hours',
    NOW() - INTERVAL '2 hours'
),
(
    '00000000-0000-0000-0000-000000000003'::uuid,
    'user2@test.com',
    '測試用戶二',
    'user',
    'pending',
    25000.00,
    'USD',
    'Asia/Taipei',
    'intermediate',
    NOW() - INTERVAL '1 hour',
    NOW() - INTERVAL '1 hour'
),
(
    '00000000-0000-0000-0000-000000000004'::uuid,
    'user3@test.com',
    '測試用戶三',
    'user',
    'pending',
    50000.00,
    'EUR',
    'Europe/London',
    'advanced',
    NOW() - INTERVAL '30 minutes',
    NOW() - INTERVAL '30 minutes'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    status = 'pending',
    updated_at = NOW();

-- 4. 創建一個已批准的測試用戶
INSERT INTO public.user_profiles (
    id,
    email,
    full_name,
    role,
    status,
    initial_capital,
    currency,
    timezone,
    trading_experience,
    approved_at,
    approved_by,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000005'::uuid,
    'activeuser@test.com',
    '活躍測試用戶',
    'user',
    'active',
    15000.00,
    'USD',
    'Asia/Taipei',
    'intermediate',
    NOW() - INTERVAL '1 day',
    '00000000-0000-0000-0000-000000000001'::uuid,
    NOW() - INTERVAL '2 days',
    NOW() - INTERVAL '1 day'
)
ON CONFLICT (id) DO UPDATE SET
    status = 'active',
    approved_at = NOW() - INTERVAL '1 day',
    approved_by = '00000000-0000-0000-0000-000000000001'::uuid,
    updated_at = NOW();

-- 5. 創建一個已停用的測試用戶
INSERT INTO public.user_profiles (
    id,
    email,
    full_name,
    role,
    status,
    initial_capital,
    currency,
    timezone,
    trading_experience,
    created_at,
    updated_at
) VALUES (
    '00000000-0000-0000-0000-000000000006'::uuid,
    'inactiveuser@test.com',
    '已停用測試用戶',
    'user',
    'inactive',
    5000.00,
    'USD',
    'Asia/Taipei',
    'beginner',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '1 day'
)
ON CONFLICT (id) DO UPDATE SET
    status = 'inactive',
    updated_at = NOW();

-- 6. 為測試管理員創建預設策略
INSERT INTO public.strategies (user_id, name, description, color) VALUES
('00000000-0000-0000-0000-000000000001'::uuid, '管理員測試策略', '用於測試的管理員策略', '#22C55E'),
('00000000-0000-0000-0000-000000000005'::uuid, '活躍用戶策略', '活躍用戶的測試策略', '#3B82F6')
ON CONFLICT (user_id, name) DO NOTHING;

-- 7. 創建一些測試用的管理員操作日誌
INSERT INTO public.admin_logs (admin_id, action, target_user_id, details) VALUES
('00000000-0000-0000-0000-000000000001'::uuid, 'approve_user', '00000000-0000-0000-0000-000000000005'::uuid, 
 jsonb_build_object('timestamp', NOW() - INTERVAL '1 day', 'reason', '測試批准')),
('00000000-0000-0000-0000-000000000001'::uuid, 'deactivate_user', '00000000-0000-0000-0000-000000000006'::uuid, 
 jsonb_build_object('timestamp', NOW() - INTERVAL '1 day', 'reason', '測試停用'))
ON CONFLICT DO NOTHING;

-- 8. 顯示創建結果
DO $$
BEGIN
    RAISE NOTICE '=== 測試帳號創建完成 ===';
    RAISE NOTICE '管理員帳號：admin@txn.test';
    RAISE NOTICE '密碼：AdminTest123!';
    RAISE NOTICE '狀態：active (已啟用)';
    RAISE NOTICE '角色：admin (管理員)';
    RAISE NOTICE '';
    RAISE NOTICE '同時創建了以下測試用戶：';
    RAISE NOTICE '- user1@test.com (待審核)';
    RAISE NOTICE '- user2@test.com (待審核)';
    RAISE NOTICE '- user3@test.com (待審核)';
    RAISE NOTICE '- activeuser@test.com (已批准)';
    RAISE NOTICE '- inactiveuser@test.com (已停用)';
    RAISE NOTICE '';
    RAISE NOTICE '注意：如要在前端登入，請先在 Supabase Auth 中創建對應的認證用戶';
END $$;

-- =============================================
-- 執行說明：
-- 1. 在 Supabase Dashboard > SQL Editor 中執行此腳本
-- 2. 執行後會創建測試用的管理員帳號和其他測試用戶
-- 3. 如需要真正登入，請在 Authentication > Users 中手動創建：
--    Email: admin@txn.test
--    Password: AdminTest123!
--    然後將 User ID 更新到上面的腳本中
-- 
-- 清理測試數據（如需要）：
-- DELETE FROM public.admin_logs WHERE admin_id::text LIKE '00000000-0000-0000-0000-%';
-- DELETE FROM public.strategies WHERE user_id::text LIKE '00000000-0000-0000-0000-%';
-- DELETE FROM public.user_profiles WHERE id::text LIKE '00000000-0000-0000-0000-%';
-- =============================================