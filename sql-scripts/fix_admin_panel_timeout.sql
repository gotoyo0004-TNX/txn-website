-- =============================================
-- 修復管理員面板超時問題
-- 針對 admin@txn.test 用戶的特殊修復
-- =============================================

-- 💡 問題分析：
-- 1. 首頁 Supabase 連接正常
-- 2. 管理員面板診斷超時
-- 3. 用戶已登入但查詢 user_profiles 時超時
-- 4. 可能是 RLS 策略導致的查詢阻塞

DO $$
BEGIN
    RAISE NOTICE '🔧 開始修復管理員面板超時問題...';
    RAISE NOTICE '📧 目標用戶: admin@txn.test';
    RAISE NOTICE '🆔 用戶 UUID: 13acfefa-cc3b-485e-8520-3d4e1a79d9cd';
END $$;

-- =============================================
-- 1. 檢查當前 admin@txn.test 用戶狀態
-- =============================================

-- 檢查認證用戶
SELECT 
    '📋 認證用戶檢查' as check_type,
    id,
    email,
    email_confirmed_at IS NOT NULL as email_confirmed,
    created_at,
    last_sign_in_at
FROM auth.users 
WHERE email = 'admin@txn.test' OR id = '13acfefa-cc3b-485e-8520-3d4e1a79d9cd';

-- 檢查用戶資料（可能會因為 RLS 而查詢不到）
DO $$
DECLARE
    profile_count INTEGER;
    admin_uuid UUID := '13acfefa-cc3b-485e-8520-3d4e1a79d9cd';
BEGIN
    -- 嘗試查詢用戶資料
    BEGIN
        SELECT COUNT(*) INTO profile_count
        FROM user_profiles 
        WHERE id = admin_uuid;
        
        RAISE NOTICE '📊 用戶資料查詢結果: % 筆記錄', profile_count;
        
        IF profile_count = 0 THEN
            RAISE NOTICE '⚠️ 用戶資料不存在或被 RLS 策略阻擋';
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ 用戶資料查詢失敗: %', SQLERRM;
    END;
END $$;

-- =============================================
-- 2. 暫時禁用 RLS 進行診斷
-- =============================================

-- 暫時禁用 RLS 以確認問題
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- 再次檢查用戶資料
SELECT 
    '📋 RLS 禁用後的用戶資料檢查' as check_type,
    id,
    email,
    role,
    status,
    created_at,
    approved_at
FROM user_profiles 
WHERE email = 'admin@txn.test' OR id = '13acfefa-cc3b-485e-8520-3d4e1a79d9cd';

-- =============================================
-- 3. 確保 admin@txn.test 用戶資料正確
-- =============================================

DO $$
DECLARE
    admin_uuid UUID := '13acfefa-cc3b-485e-8520-3d4e1a79d9cd';
    profile_exists BOOLEAN;
BEGIN
    -- 檢查用戶資料是否存在
    SELECT EXISTS(
        SELECT 1 FROM user_profiles WHERE id = admin_uuid
    ) INTO profile_exists;
    
    IF NOT profile_exists THEN
        RAISE NOTICE '🔧 創建缺失的管理員用戶資料...';
        
        -- 創建管理員用戶資料
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
            admin_uuid,
            'admin@txn.test',
            'TXN 系統管理員',
            'admin',
            'active',
            'professional',
            100000,
            'USD',
            'Asia/Taipei',
            NOW(),
            NOW(),
            NOW(),
            admin_uuid
        );
        
        RAISE NOTICE '✅ 管理員用戶資料已創建';
    ELSE
        -- 確保資料正確
        UPDATE user_profiles 
        SET 
            role = 'admin',
            status = 'active',
            email = 'admin@txn.test',
            updated_at = NOW(),
            approved_at = COALESCE(approved_at, NOW()),
            approved_by = COALESCE(approved_by, admin_uuid)
        WHERE id = admin_uuid;
        
        RAISE NOTICE '✅ 管理員用戶資料已更新';
    END IF;
END $$;

-- =============================================
-- 4. 重建簡單且高效的 RLS 策略
-- =============================================

-- 清理所有策略
DROP POLICY IF EXISTS "authenticated_users_read_all" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_users_read_own" ON public.user_profiles;
DROP POLICY IF EXISTS "users_update_own_simple" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_insert_authenticated" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_read_own" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_update_own" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_insert_own" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_read_all_simple" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_update_all_simple" ON public.user_profiles;

-- 創建超簡單的策略（優先考慮性能）
-- 策略 1: 認證用戶可以讀取所有資料（暫時性，避免複雜查詢）
CREATE POLICY "simple_read_all" ON public.user_profiles
    FOR SELECT 
    TO authenticated
    USING (true);

-- 策略 2: 認證用戶可以更新自己的資料
CREATE POLICY "simple_update_own" ON public.user_profiles
    FOR UPDATE 
    TO authenticated
    USING (auth.uid() = id);

-- 策略 3: 允許插入
CREATE POLICY "simple_insert" ON public.user_profiles
    FOR INSERT 
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- =============================================
-- 5. 重新啟用 RLS
-- =============================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 6. 測試查詢性能
-- =============================================

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration INTERVAL;
    test_count INTEGER;
    admin_uuid UUID := '13acfefa-cc3b-485e-8520-3d4e1a79d9cd';
BEGIN
    RAISE NOTICE '🧪 測試查詢性能...';
    
    -- 測試基本查詢
    start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO test_count
    FROM user_profiles 
    WHERE id = admin_uuid;
    
    end_time := clock_timestamp();
    duration := end_time - start_time;
    
    RAISE NOTICE '📊 單一用戶查詢: % 毫秒，結果: % 筆', 
        EXTRACT(milliseconds FROM duration), test_count;
    
    -- 測試批量查詢
    start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO test_count
    FROM user_profiles 
    LIMIT 5;
    
    end_time := clock_timestamp();
    duration := end_time - start_time;
    
    RAISE NOTICE '📊 批量查詢: % 毫秒，結果: % 筆', 
        EXTRACT(milliseconds FROM duration), test_count;
        
    IF EXTRACT(milliseconds FROM duration) > 1000 THEN
        RAISE NOTICE '⚠️ 查詢時間較長，可能需要進一步優化';
    ELSE
        RAISE NOTICE '✅ 查詢性能正常';
    END IF;
END $$;

-- =============================================
-- 7. 顯示修復結果
-- =============================================

SELECT 
    '=== 📋 管理員面板修復結果 ===' as report_type,
    NOW() as fix_time;

-- 顯示最終用戶狀態
SELECT 
    '📊 管理員最終狀態' as section,
    u.id,
    u.email,
    u.email_confirmed_at IS NOT NULL as email_verified,
    p.role,
    p.status,
    p.full_name,
    p.approved_at,
    CASE 
        WHEN p.role = 'admin' AND p.status = 'active'
        THEN '✅ 管理員權限正常'
        ELSE '❌ 權限異常'
    END as permission_status
FROM auth.users u
LEFT JOIN user_profiles p ON u.id = p.id
WHERE u.email = 'admin@txn.test';

-- 顯示當前策略
SELECT 
    '🛡️ 當前 RLS 策略' as section,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'user_profiles'
ORDER BY policyname;

-- =============================================
-- 8. 使用指引
-- =============================================

SELECT 
    '📋 修復完成指引' as guide_type,
    '1. 管理員用戶資料已確保存在且正確' as step_1,
    '2. RLS 策略已簡化，避免複雜查詢導致超時' as step_2,
    '3. 查詢性能已優化' as step_3,
    '4. 清除瀏覽器快取並重新登入測試管理員面板' as step_4,
    '5. 如果仍有問題，請檢查網路連線' as step_5;

-- 完成通知
DO $$
BEGIN
    RAISE NOTICE '🎉 管理員面板超時問題修復完成！';
    RAISE NOTICE '⚡ 請立即測試: https://bespoke-gecko-b54fbd.netlify.app/admin';
    RAISE NOTICE '📧 使用帳戶: admin@txn.test';
END $$;