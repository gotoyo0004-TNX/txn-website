-- =============================================
-- 管理員登入問題診斷腳本
-- 功能: 診斷 admin@txn.test 登入失敗的原因
-- =============================================

DO $$
DECLARE
    auth_user_record RECORD;
    profile_record RECORD;
    email_confirmed BOOLEAN;
    user_count INTEGER;
BEGIN
    RAISE NOTICE '=== 管理員登入問題診斷 ===';
    RAISE NOTICE '';
    
    -- 1. 檢查認證用戶詳細信息
    SELECT 
        id, email, email_confirmed_at, created_at, updated_at,
        phone_confirmed_at, confirmed_at, last_sign_in_at,
        raw_user_meta_data
    INTO auth_user_record
    FROM auth.users 
    WHERE email = 'admin@txn.test'
    LIMIT 1;
    
    IF auth_user_record.id IS NOT NULL THEN
        RAISE NOTICE '✅ 在 auth.users 中找到用戶';
        RAISE NOTICE '用戶 ID: %', auth_user_record.id;
        RAISE NOTICE '郵箱: %', auth_user_record.email;
        RAISE NOTICE '創建時間: %', auth_user_record.created_at;
        RAISE NOTICE '更新時間: %', auth_user_record.updated_at;
        RAISE NOTICE '郵箱確認時間: %', COALESCE(auth_user_record.email_confirmed_at::text, '未確認');
        RAISE NOTICE '最後登入時間: %', COALESCE(auth_user_record.last_sign_in_at::text, '從未登入');
        
        -- 檢查郵箱是否已確認
        email_confirmed := auth_user_record.email_confirmed_at IS NOT NULL;
        RAISE NOTICE '郵箱確認狀態: %', CASE WHEN email_confirmed THEN '✅ 已確認' ELSE '❌ 未確認' END;
        
    ELSE
        RAISE NOTICE '❌ 在 auth.users 中未找到用戶';
        RAISE NOTICE '需要在 Supabase Dashboard 中創建認證用戶';
        RETURN;
    END IF;
    
    RAISE NOTICE '';
    
    -- 2. 檢查用戶 profile
    SELECT *
    INTO profile_record
    FROM public.user_profiles 
    WHERE email = 'admin@txn.test'
    LIMIT 1;
    
    IF profile_record.id IS NOT NULL THEN
        RAISE NOTICE '✅ 在 user_profiles 中找到用戶';
        RAISE NOTICE 'Profile ID: %', profile_record.id;
        RAISE NOTICE '角色: %', profile_record.role;
        RAISE NOTICE '狀態: %', profile_record.status;
        RAISE NOTICE '姓名: %', COALESCE(profile_record.full_name, '未設置');
    ELSE
        RAISE NOTICE '❌ 在 user_profiles 中未找到用戶';
    END IF;
    
    RAISE NOTICE '';
    
    -- 3. 檢查 ID 是否匹配
    IF auth_user_record.id = profile_record.id THEN
        RAISE NOTICE '✅ auth.users 和 user_profiles 的 ID 匹配';
    ELSE
        RAISE NOTICE '❌ ID 不匹配！';
        RAISE NOTICE 'auth.users ID: %', auth_user_record.id;
        RAISE NOTICE 'user_profiles ID: %', profile_record.id;
    END IF;
    
    RAISE NOTICE '';
    
    -- 4. 檢查可能的問題和解決方案
    RAISE NOTICE '=== 診斷結果與建議 ===';
    
    IF NOT email_confirmed THEN
        RAISE NOTICE '🔍 問題：郵箱未確認';
        RAISE NOTICE '🔧 解決方案：在 Supabase Dashboard 中確認用戶';
        RAISE NOTICE '   - Authentication > Users > admin@txn.test';
        RAISE NOTICE '   - 點擊 "..." > Update User';
        RAISE NOTICE '   - 勾選 Email Confirm';
    END IF;
    
    -- 檢查是否有重複用戶
    SELECT COUNT(*) INTO user_count
    FROM auth.users 
    WHERE email = 'admin@txn.test';
    
    IF user_count > 1 THEN
        RAISE NOTICE '🔍 問題：發現 % 個相同郵箱的用戶', user_count;
        RAISE NOTICE '🔧 解決方案：刪除重複用戶，保留一個';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== 建議的解決步驟 ===';
    RAISE NOTICE '1. 在 Supabase Dashboard 確認用戶郵箱';
    RAISE NOTICE '2. 重置密碼為: AdminTest123!';
    RAISE NOTICE '3. 確保 Email confirmations 已關閉';
    RAISE NOTICE '4. 嘗試重新登入';
    
END $$;

-- 顯示詳細的用戶信息
SELECT 
    '=== 詳細用戶信息 ===' as 類別,
    NULL::text as 屬性,
    NULL::text as 值
UNION ALL
SELECT 
    'Auth Users',
    'Email',
    au.email
FROM auth.users au WHERE au.email = 'admin@txn.test'
UNION ALL
SELECT 
    'Auth Users',
    'Email Confirmed',
    CASE 
        WHEN au.email_confirmed_at IS NOT NULL THEN '是' 
        ELSE '否' 
    END
FROM auth.users au WHERE au.email = 'admin@txn.test'
UNION ALL
SELECT 
    'Auth Users',
    'User ID',
    au.id::text
FROM auth.users au WHERE au.email = 'admin@txn.test'
UNION ALL
SELECT 
    'User Profiles',
    'Role',
    up.role
FROM public.user_profiles up WHERE up.email = 'admin@txn.test'
UNION ALL
SELECT 
    'User Profiles',
    'Status',
    up.status
FROM public.user_profiles up WHERE up.email = 'admin@txn.test'
ORDER BY 類別, 屬性;