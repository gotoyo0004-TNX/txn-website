-- =============================================
-- 確認現有管理員狀態
-- 功能: 確認 gotoyo0004@gmail.com 管理員狀態
-- =============================================

DO $$
DECLARE
    admin_exists BOOLEAN;
    admin_id UUID;
BEGIN
    -- 檢查現有管理員
    SELECT EXISTS (
        SELECT 1 FROM public.user_profiles 
        WHERE email = 'gotoyo0004@gmail.com' 
        AND role = 'admin' 
        AND status = 'active'
    ) INTO admin_exists;
    
    SELECT id INTO admin_id
    FROM public.user_profiles 
    WHERE email = 'gotoyo0004@gmail.com'
    LIMIT 1;
    
    RAISE NOTICE '=== 現有管理員狀態確認 ===';
    
    IF admin_exists THEN
        RAISE NOTICE '✅ gotoyo0004@gmail.com 是活躍的管理員';
        RAISE NOTICE '管理員 ID: %', admin_id;
        RAISE NOTICE '';
        RAISE NOTICE '🔧 解決登入問題：';
        RAISE NOTICE '1. 前往 Supabase Dashboard';
        RAISE NOTICE '2. Authentication > Users';
        RAISE NOTICE '3. 找到 gotoyo0004@gmail.com';
        RAISE NOTICE '4. 點擊 "..." > Reset Password';
        RAISE NOTICE '5. 設置新密碼: AdminTest123!';
        RAISE NOTICE '6. 立即使用此帳號登入';
        RAISE NOTICE '';
        RAISE NOTICE '📧 管理員郵箱: gotoyo0004@gmail.com';
        RAISE NOTICE '🔐 建議新密碼: AdminTest123!';
        RAISE NOTICE '🌐 登入頁面: /auth';
    ELSE
        RAISE NOTICE '❌ gotoyo0004@gmail.com 不是活躍管理員';
        RAISE NOTICE '需要設置管理員權限';
    END IF;
END $$;

-- 顯示所有管理員
SELECT 
    '當前所有管理員' as 類型,
    email as 郵箱,
    full_name as 姓名,
    status as 狀態,
    created_at as 創建時間
FROM public.user_profiles 
WHERE role = 'admin'
ORDER BY created_at;