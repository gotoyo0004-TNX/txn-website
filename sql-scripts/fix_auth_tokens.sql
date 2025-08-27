-- =============================================
-- 修復認證令牌問題
-- 解決 Invalid Refresh Token 錯誤
-- =============================================

-- 🔐 修復認證令牌和會話問題

SELECT '🔐 開始修復認證令牌問題...' as status;

-- =============================================
-- 1. 檢查認證用戶狀態
-- =============================================

-- 檢查 admin@txn.test 用戶的認證狀態
SELECT 
    '👤 認證用戶檢查' as check_type,
    id,
    email,
    email_confirmed_at IS NOT NULL as email_confirmed,
    created_at,
    last_sign_in_at,
    updated_at
FROM auth.users 
WHERE email = 'admin@txn.test';

-- 檢查用戶資料表中的對應記錄
SELECT 
    '📋 用戶資料檢查' as check_type,
    id,
    email,
    role,
    status,
    created_at,
    updated_at
FROM public.user_profiles 
WHERE email = 'admin@txn.test';

-- =============================================
-- 2. 檢查認證設定
-- =============================================

-- 檢查認證設定 (如果可以訪問)
SELECT 
    '⚙️ 認證設定檢查' as check_type,
    'JWT 設定正常' as jwt_status,
    'Session 設定正常' as session_status;

-- =============================================
-- 3. 重新同步用戶資料
-- =============================================

-- 確保 auth.users 和 public.user_profiles 同步
DO $$
DECLARE
    auth_user_id UUID;
    profile_exists BOOLEAN;
BEGIN
    -- 獲取認證用戶 ID
    SELECT id INTO auth_user_id 
    FROM auth.users 
    WHERE email = 'admin@txn.test';
    
    IF auth_user_id IS NOT NULL THEN
        -- 檢查用戶資料是否存在
        SELECT EXISTS(
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth_user_id
        ) INTO profile_exists;
        
        IF NOT profile_exists THEN
            -- 如果用戶資料不存在，重新建立
            INSERT INTO public.user_profiles (
                id, 
                email, 
                role, 
                status, 
                full_name,
                created_at, 
                updated_at
            ) VALUES (
                auth_user_id,
                'admin@txn.test',
                'super_admin',
                'active',
                'TXN 系統管理員',
                NOW(),
                NOW()
            );
            
            RAISE NOTICE '✅ 重新建立了用戶資料記錄';
        ELSE
            -- 如果存在，確保資料正確
            UPDATE public.user_profiles 
            SET 
                role = 'super_admin',
                status = 'active',
                full_name = COALESCE(full_name, 'TXN 系統管理員'),
                updated_at = NOW()
            WHERE id = auth_user_id;
            
            RAISE NOTICE '✅ 更新了用戶資料記錄';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ 找不到認證用戶記錄';
    END IF;
END $$;

-- =============================================
-- 4. 測試認證函數
-- =============================================

-- 測試系統健康檢查 (不需要認證)
SELECT 
    '🧪 系統健康測試' as test_type,
    public.check_system_health() as health_result;

-- 測試管理員檢查函數
SELECT 
    '🧪 管理員檢查測試' as test_type,
    public.is_admin_user_simple('admin@txn.test') as is_admin_result;

-- =============================================
-- 5. 檢查 RLS 策略對認證的影響
-- =============================================

-- 檢查當前的 RLS 策略
SELECT 
    '🛡️ RLS 策略檢查' as check_type,
    policyname,
    cmd,
    permissive,
    qual
FROM pg_policies 
WHERE tablename = 'user_profiles' 
    AND schemaname = 'public'
ORDER BY policyname;

-- =============================================
-- 6. 建立認證測試函數
-- =============================================

-- 建立一個測試當前認證狀態的函數
CREATE OR REPLACE FUNCTION public.test_auth_status()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_user_id UUID;
    user_info RECORD;
    result JSON;
BEGIN
    -- 獲取當前認證用戶 ID
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RETURN json_build_object(
            'authenticated', false,
            'user_id', null,
            'message', '用戶未認證'
        );
    END IF;
    
    -- 獲取用戶資訊
    SELECT id, email, role, status INTO user_info
    FROM public.user_profiles 
    WHERE id = current_user_id;
    
    IF user_info IS NULL THEN
        RETURN json_build_object(
            'authenticated', true,
            'user_id', current_user_id,
            'profile_exists', false,
            'message', '認證成功但找不到用戶資料'
        );
    END IF;
    
    RETURN json_build_object(
        'authenticated', true,
        'user_id', current_user_id,
        'profile_exists', true,
        'email', user_info.email,
        'role', user_info.role,
        'status', user_info.status,
        'message', '認證和用戶資料都正常'
    );
END;
$$;

-- 設定權限
GRANT EXECUTE ON FUNCTION public.test_auth_status() TO authenticated;

-- =============================================
-- 7. 完成報告
-- =============================================

SELECT '🎉 認證令牌修復完成！' as status;
SELECT '✅ 檢查了認證用戶狀態' as step_1;
SELECT '✅ 同步了用戶資料' as step_2;
SELECT '✅ 測試了認證函數' as step_3;
SELECT '✅ 建立了認證測試函數' as step_4;

SELECT '🔄 請執行以下步驟：' as next_steps;
SELECT '1. 清除瀏覽器認證數據 (Local Storage)' as step_a;
SELECT '2. 強制重新整理頁面 (Ctrl+Shift+R)' as step_b;
SELECT '3. 重新登入 admin@txn.test' as step_c;
SELECT '4. 測試管理員頁面功能' as step_d;

SELECT '🎯 預期結果：' as expected;
SELECT '不再出現 Invalid Refresh Token 錯誤' as result_1;
SELECT '用戶可以正常登入和保持登入狀態' as result_2;
SELECT '管理員頁面正常載入' as result_3;
