-- =============================================
-- TXN 系統 - 建立管理員帳戶腳本
-- 版本: 2.0
-- 建立日期: 2024-12-19
-- =============================================

-- 🎯 此腳本將建立初始管理員帳戶
-- ⚠️  請在執行 complete_database_setup.sql 之後執行此腳本

DO $$
BEGIN
    RAISE NOTICE '👤 開始建立 TXN 系統管理員帳戶...';
END $$;

-- =============================================
-- 1. 檢查前置條件
-- =============================================

-- 檢查 user_profiles 表是否存在
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'user_profiles'
    ) THEN
        RAISE EXCEPTION '❌ user_profiles 表不存在！請先執行 complete_database_setup.sql';
    END IF;
    
    RAISE NOTICE '✅ 資料表檢查通過';
END $$;

-- =============================================
-- 2. 建立管理員帳戶
-- =============================================

-- 注意：這個腳本假設您已經在 Supabase Auth 中建立了對應的用戶
-- 如果還沒有，請先在 Supabase Dashboard 的 Authentication > Users 中建立用戶

-- 方法一：如果您已經有 auth.users 中的用戶，更新其 profile
-- 請將 'your-admin-user-id' 替換為實際的用戶 UUID

/*
-- 範例：更新現有用戶為管理員
UPDATE public.user_profiles 
SET 
    role = 'super_admin',
    status = 'active',
    full_name = 'TXN 系統管理員',
    updated_at = NOW()
WHERE email = 'admin@txn.test';
*/

-- 方法二：如果需要建立測試管理員資料 (僅用於開發環境)
-- ⚠️ 生產環境請勿使用此方法

-- 檢查是否已存在測試管理員
DO $$
DECLARE
    admin_exists BOOLEAN := FALSE;
    test_admin_id UUID;
BEGIN
    -- 檢查是否已存在測試管理員
    SELECT EXISTS(
        SELECT 1 FROM public.user_profiles 
        WHERE email = 'admin@txn.test'
    ) INTO admin_exists;
    
    IF admin_exists THEN
        RAISE NOTICE '⚠️  測試管理員帳戶已存在，更新權限...';
        
        -- 更新現有管理員權限
        UPDATE public.user_profiles 
        SET 
            role = 'super_admin',
            status = 'active',
            full_name = 'TXN 系統管理員',
            updated_at = NOW()
        WHERE email = 'admin@txn.test';
        
        RAISE NOTICE '✅ 測試管理員權限已更新';
    ELSE
        RAISE NOTICE '📝 建立新的測試管理員帳戶...';
        
        -- 生成測試用的 UUID
        test_admin_id := gen_random_uuid();
        
        -- 插入測試管理員資料
        -- 注意：這只會在 user_profiles 表中建立記錄
        -- 實際的認證仍需要在 Supabase Auth 中設定
        INSERT INTO public.user_profiles (
            id,
            email,
            full_name,
            role,
            status,
            created_at,
            updated_at,
            preferences,
            metadata
        ) VALUES (
            test_admin_id,
            'admin@txn.test',
            'TXN 系統管理員',
            'super_admin',
            'active',
            NOW(),
            NOW(),
            '{"theme": "light", "language": "zh-TW"}',
            '{"created_by": "setup_script", "is_test_account": true}'
        );
        
        RAISE NOTICE '✅ 測試管理員資料已建立';
        RAISE NOTICE '📧 Email: admin@txn.test';
        RAISE NOTICE '🆔 ID: %', test_admin_id;
        RAISE NOTICE '⚠️  請在 Supabase Dashboard 中建立對應的認證用戶';
    END IF;
END $$;

-- =============================================
-- 3. 建立其他管理員帳戶 (可選)
-- =============================================

-- 如果需要建立多個管理員，可以複製以下模板

/*
-- 範例：建立版主帳戶
INSERT INTO public.user_profiles (
    id,
    email,
    full_name,
    role,
    status,
    created_at,
    updated_at,
    preferences,
    metadata
) VALUES (
    gen_random_uuid(),
    'moderator@txn.test',
    'TXN 版主',
    'moderator',
    'active',
    NOW(),
    NOW(),
    '{"theme": "light", "language": "zh-TW"}',
    '{"created_by": "setup_script", "is_test_account": true}'
) ON CONFLICT (email) DO UPDATE SET
    role = EXCLUDED.role,
    status = EXCLUDED.status,
    updated_at = NOW();
*/

-- =============================================
-- 4. 驗證管理員帳戶
-- =============================================

-- 顯示所有管理員帳戶
SELECT 
    '👥 管理員帳戶列表' as section,
    id,
    email,
    full_name,
    role,
    status,
    created_at
FROM public.user_profiles 
WHERE role IN ('super_admin', 'admin', 'moderator')
ORDER BY role, email;

-- 檢查 RLS 策略是否正常工作
SELECT 
    '🛡️ RLS 策略檢查' as section,
    COUNT(*) as total_policies
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'user_profiles';

-- =============================================
-- 5. 設定指引
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🎉 管理員帳戶設定完成！';
    RAISE NOTICE '';
    RAISE NOTICE '📋 下一步操作：';
    RAISE NOTICE '1. 在 Supabase Dashboard > Authentication > Users 中建立對應的認證用戶';
    RAISE NOTICE '2. 確保用戶的 UUID 與 user_profiles 表中的 id 匹配';
    RAISE NOTICE '3. 設定用戶密碼 (建議: admin123456)';
    RAISE NOTICE '4. 在應用程式中使用 admin@txn.test 登入測試';
    RAISE NOTICE '';
    RAISE NOTICE '🔐 測試登入資訊：';
    RAISE NOTICE 'Email: admin@txn.test';
    RAISE NOTICE 'Password: (請在 Supabase Auth 中設定)';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  安全提醒：';
    RAISE NOTICE '- 生產環境請使用強密碼';
    RAISE NOTICE '- 定期更換管理員密碼';
    RAISE NOTICE '- 啟用雙因素認證 (如果可用)';
END $$;

-- =============================================
-- 6. 建立範例資料 (可選)
-- =============================================

-- 如果需要一些測試資料，可以取消註解以下部分

/*
-- 建立範例交易策略
INSERT INTO public.strategies (
    user_id,
    name,
    description,
    category,
    risk_level,
    is_active,
    metadata
) 
SELECT 
    id as user_id,
    '趨勢跟隨策略',
    '基於移動平均線的趨勢跟隨策略',
    'trend_following',
    'medium',
    true,
    '{"created_by": "setup_script", "is_example": true}'
FROM public.user_profiles 
WHERE email = 'admin@txn.test'
ON CONFLICT DO NOTHING;

-- 建立範例交易記錄
INSERT INTO public.trades (
    user_id,
    strategy_id,
    symbol,
    trade_type,
    quantity,
    entry_price,
    exit_price,
    entry_date,
    exit_date,
    status,
    profit_loss,
    fees,
    notes,
    tags,
    metadata
)
SELECT 
    up.id as user_id,
    s.id as strategy_id,
    'BTCUSDT',
    'long',
    0.1,
    45000.00,
    47000.00,
    NOW() - INTERVAL '7 days',
    NOW() - INTERVAL '5 days',
    'closed',
    200.00,
    5.00,
    '範例交易記錄',
    ARRAY['bitcoin', 'crypto', 'example'],
    '{"created_by": "setup_script", "is_example": true}'
FROM public.user_profiles up
JOIN public.strategies s ON s.user_id = up.id
WHERE up.email = 'admin@txn.test'
    AND s.name = '趨勢跟隨策略'
ON CONFLICT DO NOTHING;
*/

-- 完成通知
SELECT 
    '🎊 設定完成' as status,
    '管理員帳戶已準備就緒' as message,
    'admin@txn.test' as test_email,
    '請在 Supabase Auth 中設定對應的認證用戶' as next_step;
