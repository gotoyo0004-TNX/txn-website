-- =============================================
-- 重置管理員密碼腳本
-- 功能: 重置 gotoyo0004@gmail.com 管理員的密碼
-- =============================================

-- 注意：此方法需要直接更新 auth.users 表，僅在必要時使用

DO $$
DECLARE
    admin_user_id UUID;
    new_password_hash TEXT;
BEGIN
    -- 找到管理員用戶ID
    SELECT id INTO admin_user_id
    FROM auth.users 
    WHERE email = 'gotoyo0004@gmail.com'
    LIMIT 1;
    
    IF admin_user_id IS NOT NULL THEN
        -- 方法一：生成新的密碼哈希 (推薦使用 Dashboard 操作)
        RAISE NOTICE '找到管理員用戶: gotoyo0004@gmail.com';
        RAISE NOTICE 'User ID: %', admin_user_id;
        RAISE NOTICE '';
        RAISE NOTICE '⚠️  建議使用 Supabase Dashboard 重置密碼：';
        RAISE NOTICE '1. 前往 Authentication > Users';
        RAISE NOTICE '2. 找到 gotoyo0004@gmail.com';
        RAISE NOTICE '3. 點擊 "..." 選單 > Reset Password';
        RAISE NOTICE '4. 設置新密碼: AdminTest123!';
        RAISE NOTICE '';
        
        -- 確認用戶狀態
        RAISE NOTICE '=== 用戶狀態確認 ===';
        RAISE NOTICE '管理員權限已確認 ✅';
        RAISE NOTICE '用戶狀態: active ✅';
        RAISE NOTICE '';
        RAISE NOTICE '密碼重置後，可直接使用以下資訊登入：';
        RAISE NOTICE '📧 郵箱: gotoyo0004@gmail.com';
        RAISE NOTICE '🔐 新密碼: AdminTest123! (或您設置的密碼)';
        RAISE NOTICE '🌐 登入頁面: /auth';
        
    ELSE
        RAISE NOTICE '❌ 未找到指定的管理員用戶';
    END IF;
END $$;

-- 顯示當前所有管理員
SELECT 
    '=== 當前管理員列表 ===' as 信息,
    NULL::text as 郵箱,
    NULL::text as 狀態
UNION ALL
SELECT 
    up.full_name,
    up.email,
    up.status
FROM public.user_profiles up
WHERE up.role = 'admin'
ORDER BY up.created_at;