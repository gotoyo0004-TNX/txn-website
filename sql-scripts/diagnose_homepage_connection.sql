-- =============================================
-- 首頁 Supabase 連接問題診斷腳本
-- 檢查為什麼管理面板修復後首頁連接失敗
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🔍 開始診斷首頁 Supabase 連接問題...';
    RAISE NOTICE '⏰ 診斷時間: %', NOW();
END $$;

-- =============================================
-- 1. 檢查當前 RLS 策略狀態
-- =============================================

SELECT 
    '🛡️ 當前 RLS 策略檢查' as check_type,
    tablename,
    COUNT(*) as policy_count,
    array_agg(policyname) as policy_names
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- =============================================
-- 2. 測試基本資料庫連接
-- =============================================

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    test_count INTEGER;
BEGIN
    RAISE NOTICE '⚡ 測試基本資料庫查詢...';
    
    -- 測試 1: 最簡單的查詢
    start_time := clock_timestamp();
    BEGIN
        SELECT COUNT(*) INTO test_count FROM user_profiles LIMIT 1;
        end_time := clock_timestamp();
        duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
        RAISE NOTICE '✅ 基本查詢成功: % ms, 結果: % 筆', duration_ms, test_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ 基本查詢失敗: %', SQLERRM;
    END;
    
    -- 測試 2: 測試首頁可能的查詢
    start_time := clock_timestamp();
    BEGIN
        SELECT COUNT(*) INTO test_count FROM user_profiles WHERE status = 'active';
        end_time := clock_timestamp();
        duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
        RAISE NOTICE '✅ 狀態查詢成功: % ms, 結果: % 筆', duration_ms, test_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ 狀態查詢失敗: %', SQLERRM;
    END;
    
    -- 測試 3: 測試認證相關查詢
    start_time := clock_timestamp();
    BEGIN
        SELECT COUNT(*) INTO test_count FROM auth.users LIMIT 1;
        end_time := clock_timestamp();
        duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
        RAISE NOTICE '✅ 認證查詢成功: % ms, 結果: % 筆', duration_ms, test_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ 認證查詢失敗: %', SQLERRM;
    END;
END $$;

-- =============================================
-- 3. 檢查 RLS 策略是否過於寬鬆
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🔒 檢查 RLS 策略安全性...';
    
    -- 檢查是否有過於寬鬆的策略
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_profiles' 
        AND qual = 'true'
    ) THEN
        RAISE NOTICE '⚠️ 發現寬鬆策略: 所有認證用戶都可以存取';
        RAISE NOTICE '💡 這可能解釋為什麼管理面板可以運作';
    ELSE
        RAISE NOTICE '✅ 沒有發現過於寬鬆的策略';
    END IF;
END $$;

-- =============================================
-- 4. 檢查表存在和權限
-- =============================================

SELECT 
    '📋 表存在檢查' as check_type,
    schemaname,
    tablename,
    tableowner,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY tablename;

-- =============================================
-- 5. 檢查可能的權限問題
-- =============================================

-- 檢查 anon 用戶權限
SELECT 
    '👤 anon 用戶權限' as check_type,
    schemaname,
    tablename,
    privilege_type
FROM information_schema.table_privileges 
WHERE grantee = 'anon' 
AND schemaname = 'public'
ORDER BY tablename, privilege_type;

-- 檢查 authenticated 用戶權限
SELECT 
    '🔐 authenticated 用戶權限' as check_type,
    schemaname,
    tablename,
    privilege_type
FROM information_schema.table_privileges 
WHERE grantee = 'authenticated' 
AND schemaname = 'public'
ORDER BY tablename, privilege_type;

-- =============================================
-- 6. 測試 SupabaseTest 組件可能的查詢
-- =============================================

DO $$
DECLARE
    test_result TEXT;
BEGIN
    RAISE NOTICE '🧪 測試 SupabaseTest 組件查詢...';
    
    -- 測試各表的基本查詢（模擬 SupabaseTest 組件）
    BEGIN
        PERFORM * FROM user_profiles LIMIT 1;
        RAISE NOTICE '✅ user_profiles 表查詢成功';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ user_profiles 表查詢失敗: %', SQLERRM;
    END;
    
    BEGIN
        PERFORM * FROM strategies LIMIT 1;
        RAISE NOTICE '✅ strategies 表查詢成功';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ strategies 表查詢失敗: %', SQLERRM;
    END;
    
    BEGIN
        PERFORM * FROM trades LIMIT 1;
        RAISE NOTICE '✅ trades 表查詢成功';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ trades 表查詢失敗: %', SQLERRM;
    END;
    
    BEGIN
        PERFORM * FROM performance_snapshots LIMIT 1;
        RAISE NOTICE '✅ performance_snapshots 表查詢成功';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ performance_snapshots 表查詢失敗: %', SQLERRM;
    END;
END $$;

-- =============================================
-- 7. 檢查連接池和活動連接
-- =============================================

SELECT 
    '🔗 連接狀況' as check_type,
    COUNT(*) as total_connections,
    COUNT(*) FILTER (WHERE state = 'active') as active_connections,
    COUNT(*) FILTER (WHERE state = 'idle') as idle_connections,
    COUNT(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction
FROM pg_stat_activity;

-- =============================================
-- 8. 提供修復建議
-- =============================================

DO $$
DECLARE
    policy_count INTEGER;
    unsafe_policies INTEGER;
BEGIN
    RAISE NOTICE '=== 📋 診斷結果和建議 ===';
    
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies WHERE tablename = 'user_profiles';
    
    SELECT COUNT(*) INTO unsafe_policies
    FROM pg_policies 
    WHERE tablename = 'user_profiles' AND qual = 'true';
    
    RAISE NOTICE '📊 user_profiles 策略數量: %', policy_count;
    RAISE NOTICE '⚠️ 寬鬆策略數量: %', unsafe_policies;
    
    IF unsafe_policies > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '🔧 建議修復步驟:';
        RAISE NOTICE '1. 當前使用寬鬆策略 (USING true) 可能影響安全性';
        RAISE NOTICE '2. 建議重新設計更安全的 RLS 策略';
        RAISE NOTICE '3. 如果首頁仍然連接失敗，可能是前端快取問題';
        RAISE NOTICE '4. 建議清除瀏覽器快取並重新整理';
    ELSE
        RAISE NOTICE '✅ RLS 策略設定合理';
        RAISE NOTICE '💡 如果首頁連接失敗，檢查網路或前端快取';
    END IF;
END $$;

-- 完成通知
SELECT 
    '=== 🎉 診斷完成 ===' as status,
    NOW() as completion_time,
    '請檢查上述診斷結果' as next_steps;