-- =============================================
-- Supabase 連接診斷腳本
-- 用於排查連接測試卡住的問題
-- =============================================

-- 💡 使用指南：
-- 1. 在 Supabase SQL 編輯器中執行此腳本
-- 2. 檢查輸出結果，確認資料庫狀態
-- 3. 根據結果對比前端連接測試

-- 1. 檢查資料庫基本狀態
SELECT 
    '📊 資料庫基本狀態' as check_type,
    current_database() as database_name,
    current_user as current_user,
    NOW() as current_time,
    version() as postgresql_version;

-- 2. 檢查所有現有表格
SELECT 
    '📋 現有表格檢查' as check_type,
    schemaname,
    tablename,
    tableowner,
    hasindexes,
    hasrules,
    hastriggers
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- 3. 檢查 TXN 核心表格是否存在
SELECT 
    '🔍 TXN 核心表格狀態' as check_type,
    'user_profiles' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public')
        THEN '✅ 存在'
        ELSE '❌ 不存在'
    END as status
UNION ALL
SELECT 
    '🔍 TXN 核心表格狀態' as check_type,
    'strategies' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public')
        THEN '✅ 存在'
        ELSE '❌ 不存在'
    END as status
UNION ALL
SELECT 
    '🔍 TXN 核心表格狀態' as check_type,
    'trades' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public')
        THEN '✅ 存在'
        ELSE '❌ 不存在'
    END as status
UNION ALL
SELECT 
    '🔍 TXN 核心表格狀態' as check_type,
    'performance_snapshots' as table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public')
        THEN '✅ 存在'
        ELSE '❌ 不存在'
    END as status;

-- 4. 檢查資料庫連接限制
SELECT 
    '🔗 連接狀態檢查' as check_type,
    max_conn,
    used,
    res_for_super,
    max_conn-used-res_for_super as res_for_normal 
FROM 
    (SELECT count(*) used FROM pg_stat_activity) t1,
    (SELECT setting::int res_for_super FROM pg_settings WHERE name=$$superuser_reserved_connections$$) t2,
    (SELECT setting::int max_conn FROM pg_settings WHERE name=$$max_connections$$) t3;

-- 5. 檢查當前活動連接
SELECT 
    '🌐 當前活動連接' as check_type,
    state,
    count(*) as connection_count
FROM pg_stat_activity 
WHERE state IS NOT NULL
GROUP BY state
ORDER BY connection_count DESC;

-- 6. 檢查 RLS 策略狀態
SELECT 
    '🛡️ RLS 策略狀態' as check_type,
    tablename,
    COUNT(*) as policy_count,
    string_agg(policyname, ', ') as policy_names
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- 7. 模擬前端查詢測試
DO $$
DECLARE
    test_result TEXT;
    error_detail TEXT;
BEGIN
    RAISE NOTICE '🧪 模擬前端查詢測試...';
    
    -- 測試 user_profiles 表查詢
    BEGIN
        PERFORM id FROM user_profiles LIMIT 1;
        RAISE NOTICE '✅ user_profiles 查詢成功';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS error_detail = MESSAGE_TEXT;
        RAISE NOTICE '❌ user_profiles 查詢失敗: %', error_detail;
    END;
    
    -- 測試 strategies 表查詢
    BEGIN
        PERFORM id FROM strategies LIMIT 1;
        RAISE NOTICE '✅ strategies 查詢成功';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS error_detail = MESSAGE_TEXT;
        RAISE NOTICE '❌ strategies 查詢失敗: %', error_detail;
    END;
    
    -- 測試 trades 表查詢
    BEGIN
        PERFORM id FROM trades LIMIT 1;
        RAISE NOTICE '✅ trades 查詢成功';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS error_detail = MESSAGE_TEXT;
        RAISE NOTICE '❌ trades 查詢失敗: %', error_detail;
    END;
    
    -- 測試 performance_snapshots 表查詢
    BEGIN
        PERFORM id FROM performance_snapshots LIMIT 1;
        RAISE NOTICE '✅ performance_snapshots 查詢成功';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS error_detail = MESSAGE_TEXT;
        RAISE NOTICE '❌ performance_snapshots 查詢失敗: %', error_detail;
    END;
END $$;

-- 8. 診斷建議
SELECT 
    '💡 診斷建議' as suggestion_type,
    '如果所有表格都不存在，請執行資料庫初始化腳本' as step_1,
    '如果查詢失敗，請檢查 RLS 策略設定' as step_2,
    '如果連接數過多，可能需要等待或重新啟動 Supabase 專案' as step_3,
    '前端連接測試卡住通常是網路問題或 CORS 設定問題' as step_4;