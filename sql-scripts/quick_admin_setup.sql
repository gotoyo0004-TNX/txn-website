-- =============================================
-- 快速設置現有用戶為管理員
-- 功能: 將任何現有的認證用戶設為管理員
-- =============================================

DO $$
DECLARE
    auth_user_record RECORD;
    admin_count INTEGER;
BEGIN
    -- 檢查是否已有管理員
    SELECT COUNT(*) INTO admin_count
    FROM public.user_profiles 
    WHERE role = 'admin' AND status = 'active';
    
    IF admin_count > 0 THEN
        RAISE NOTICE '✅ 已存在 % 個活躍管理員', admin_count;
        
        -- 顯示現有管理員
        FOR auth_user_record IN (
            SELECT up.email, up.full_name, up.created_at
            FROM public.user_profiles up
            WHERE up.role = 'admin' AND up.status = 'active'
        ) LOOP
            RAISE NOTICE '管理員: % (%) - 創建時間: %', 
                auth_user_record.full_name, 
                auth_user_record.email, 
                auth_user_record.created_at;
        END LOOP;
        
        RETURN;
    END IF;
    
    -- 找到第一個認證用戶並設為管理員
    SELECT au.id, au.email, au.created_at 
    INTO auth_user_record
    FROM auth.users au
    WHERE au.email IS NOT NULL 
    ORDER BY au.created_at ASC 
    LIMIT 1;
    
    IF auth_user_record.id IS NOT NULL THEN
        -- 插入或更新為管理員
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
            auth_user_record.id,
            auth_user_record.email,
            'TXN 管理員',
            'admin',
            'active',
            100000.00,
            'USD',
            'Asia/Taipei',
            'professional',
            NOW(),
            auth_user_record.id,
            NOW(),
            NOW()
        )
        ON CONFLICT (id) DO UPDATE SET
            role = 'admin',
            status = 'active',
            full_name = 'TXN 管理員',
            approved_at = NOW(),
            updated_at = NOW();
        
        RAISE NOTICE '✅ 已將用戶 % 設置為管理員', auth_user_record.email;
        RAISE NOTICE '🔑 您現在可以使用此帳號登入管理面板: %', auth_user_record.email;
        RAISE NOTICE '📱 前往 /auth 頁面使用此帳號登入';
    ELSE
        RAISE NOTICE '❌ 未找到任何認證用戶';
        RAISE NOTICE '請先在 Supabase Dashboard > Authentication > Users 中創建用戶';
        RAISE NOTICE '或在網站上註冊一個新帳號';
    END IF;
END $$;

-- 顯示當前用戶狀態
DO $$
DECLARE
    auth_users_count INTEGER;
    profiles_count INTEGER;
    admin_count INTEGER;
BEGIN
    -- 獲取各種統計數據
    SELECT COUNT(*) INTO auth_users_count FROM auth.users;
    SELECT COUNT(*) INTO profiles_count FROM public.user_profiles;
    SELECT COUNT(*) INTO admin_count FROM public.user_profiles WHERE role = 'admin' AND status = 'active';
    
    RAISE NOTICE '';
    RAISE NOTICE '=== 用戶狀態統計 ===';
    RAISE NOTICE '認證用戶數量: %', auth_users_count;
    RAISE NOTICE 'Profile 記錄數: %', profiles_count;
    RAISE NOTICE '管理員數量: %', admin_count;
    RAISE NOTICE '';
    RAISE NOTICE '=== 所有用戶列表 ===';
END $$;

-- 顯示所有用戶詳細資訊
SELECT 
    COALESCE(up.full_name, 'N/A') as 姓名,
    up.email as 郵箱,
    up.role as 角色,
    up.status as 狀態,
    up.created_at as 創建時間
FROM public.user_profiles up
ORDER BY up.created_at;