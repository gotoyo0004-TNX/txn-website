-- =============================================
-- 創建新測試管理員帳號
-- 功能: 創建 testadmin@txn.local 作為備用管理員
-- =============================================

-- 注意：請先在 Supabase Dashboard 創建認證用戶
-- Email: testadmin@txn.local
-- Password: TestAdmin123!
-- 勾選 Auto Confirm User

DO $$
DECLARE
    auth_user_id UUID;
BEGIN
    -- 檢查新測試管理員的認證用戶
    SELECT id INTO auth_user_id
    FROM auth.users 
    WHERE email = 'testadmin@txn.local'
    LIMIT 1;
    
    IF auth_user_id IS NOT NULL THEN
        -- 創建或更新管理員 profile
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
            auth_user_id,
            'testadmin@txn.local',
            'TXN 備用管理員',
            'admin',
            'active',
            100000.00,
            'USD',
            'Asia/Taipei',
            'professional',
            NOW(),
            auth_user_id,
            NOW(),
            NOW()
        )
        ON CONFLICT (id) DO UPDATE SET
            role = 'admin',
            status = 'active',
            full_name = 'TXN 備用管理員',
            approved_at = NOW(),
            updated_at = NOW();
        
        RAISE NOTICE '✅ 備用管理員帳號設置完成';
        RAISE NOTICE '📧 郵箱: testadmin@txn.local';
        RAISE NOTICE '🔐 密碼: TestAdmin123!';
        RAISE NOTICE '🌐 可立即前往 /auth 頁面登入';
        
    ELSE
        RAISE NOTICE '❌ 未找到 testadmin@txn.local 的認證用戶';
        RAISE NOTICE '請先在 Supabase Dashboard 創建此用戶：';
        RAISE NOTICE '1. Authentication > Users > Add User';
        RAISE NOTICE '2. Email: testadmin@txn.local';
        RAISE NOTICE '3. Password: TestAdmin123!';
        RAISE NOTICE '4. 勾選 Auto Confirm User';
        RAISE NOTICE '5. 然後重新執行此腳本';
    END IF;
END $$;