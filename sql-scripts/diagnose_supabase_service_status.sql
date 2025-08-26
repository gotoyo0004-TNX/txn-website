-- =============================================
-- Supabase 服務狀態診斷腳本
-- 檢查連接緩慢和超時問題
-- =============================================

-- 💡 使用指南：
-- 1. 在 Supabase SQL 編輯器中執行此腳本
-- 2. 檢查所有輸出結果
-- 3. 根據診斷結果判斷問題原因

DO $$
BEGIN
    RAISE NOTICE '🔍 開始 Supabase 服務狀態診斷...';
    RAISE NOTICE '⏰ 診斷時間: %', NOW();
END $$;

-- =============================================
-- 1. 檢查資料庫基本健康狀態
-- =============================================

SELECT 
    '📊 資料庫基本狀態' as check_type,
    current_database() as database_name,
    current_user as current_user,
    NOW() as current_time,
    version() as postgresql_version,
    pg_database_size(current_database()) as database_size_bytes,
    pg_size_pretty(pg_database_size(current_database())) as database_size_readable;

-- =============================================
-- 2. 檢查連接和性能狀況
-- =============================================

-- 檢查當前連接數
SELECT 
    '🔗 連接狀況檢查' as check_type,
    COUNT(*) as total_connections,
    COUNT(*) FILTER (WHERE state = 'active') as active_connections,
    COUNT(*) FILTER (WHERE state = 'idle') as idle_connections,
    COUNT(*) FILTER (WHERE state IS NULL) as unknown_state
FROM pg_stat_activity;

-- 檢查連接限制
SELECT 
    '📊 連接限制檢查' as check_type,
    setting::int as max_connections,
    (SELECT COUNT(*) FROM pg_stat_activity) as current_connections,
    (setting::int - (SELECT COUNT(*) FROM pg_stat_activity)) as available_connections
FROM pg_settings 
WHERE name = 'max_connections';

-- =============================================
-- 3. 檢查表和索引狀態
-- =============================================

-- 檢查 TXN 核心表的大小和記錄數
SELECT 
    '📋 表狀態檢查' as check_type,
    'user_profiles' as table_name,
    COUNT(*) as record_count,
    pg_size_pretty(pg_total_relation_size('user_profiles')) as table_size
FROM user_profiles
UNION ALL
SELECT 
    '📋 表狀態檢查' as check_type,
    'strategies' as table_name,
    COUNT(*) as record_count,
    pg_size_pretty(pg_total_relation_size('strategies')) as table_size
FROM strategies
UNION ALL
SELECT 
    '📋 表狀態檢查' as check_type,
    'trades' as table_name,
    COUNT(*) as record_count,
    pg_size_pretty(pg_total_relation_size('trades')) as table_size
FROM trades
UNION ALL
SELECT 
    '📋 表狀態檢查' as check_type,
    'performance_snapshots' as table_name,
    COUNT(*) as record_count,
    pg_size_pretty(pg_total_relation_size('performance_snapshots')) as table_size
FROM performance_snapshots;

-- =============================================
-- 4. 檢查 RLS 策略狀態
-- =============================================

SELECT 
    '🛡️ RLS 策略狀態' as check_type,
    tablename,
    COUNT(*) as policy_count,
    array_agg(policyname) as policy_names
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- =============================================
-- 5. 測試查詢性能
-- =============================================

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    test_count INTEGER;
BEGIN
    RAISE NOTICE '⚡ 開始查詢性能測試...';
    
    -- 測試 1: 簡單計數查詢
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO test_count FROM user_profiles;
    end_time := clock_timestamp();
    duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
    
    RAISE NOTICE '📊 user_profiles 計數查詢: % ms, 結果: % 筆', duration_ms, test_count;
    
    -- 測試 2: 帶條件的查詢
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO test_count FROM user_profiles WHERE status = 'active';
    end_time := clock_timestamp();
    duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
    
    RAISE NOTICE '📊 active 用戶查詢: % ms, 結果: % 筆', duration_ms, test_count;
    
    -- 測試 3: 管理員查詢
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO test_count FROM user_profiles WHERE role IN ('admin', 'super_admin', 'moderator');
    end_time := clock_timestamp();
    duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
    
    RAISE NOTICE '📊 管理員查詢: % ms, 結果: % 筆', duration_ms, test_count;
    
    -- 測試 4: JOIN 查詢性能
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO test_count 
    FROM user_profiles up 
    JOIN auth.users au ON up.id = au.id;
    end_time := clock_timestamp();
    duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
    
    RAISE NOTICE '📊 JOIN 查詢: % ms, 結果: % 筆', duration_ms, test_count;
    
    IF duration_ms > 1000 THEN
        RAISE NOTICE '⚠️ 查詢時間超過 1 秒，可能需要優化';
    ELSE
        RAISE NOTICE '✅ 查詢性能正常';
    END IF;
END $$;

-- =============================================
-- 6. 檢查 admin@txn.test 用戶具體狀態
-- =============================================

-- 檢查認證用戶狀態
SELECT 
    '👤 admin@txn.test 認證狀態' as check_type,
    id,
    email,
    email_confirmed_at IS NOT NULL as email_confirmed,
    created_at,
    last_sign_in_at,
    CASE 
        WHEN last_sign_in_at > NOW() - INTERVAL '1 hour' THEN '🟢 最近活躍'
        WHEN last_sign_in_at > NOW() - INTERVAL '1 day' THEN '🟡 今日登入'
        ELSE '🔴 較久未登入'
    END as activity_status
FROM auth.users 
WHERE email = 'admin@txn.test';

-- 檢查用戶資料狀態
SELECT 
    '👤 admin@txn.test 資料狀態' as check_type,
    id,
    email,
    role,
    status,
    created_at,
    updated_at,
    approved_at,
    CASE 
        WHEN role = 'admin' AND status = 'active' THEN '✅ 權限正常'
        WHEN role != 'admin' THEN '❌ 角色異常'
        WHEN status != 'active' THEN '❌ 狀態異常'
        ELSE '❌ 未知問題'
    END as permission_status
FROM user_profiles 
WHERE email = 'admin@txn.test';

-- =============================================
-- 7. 檢查系統資源使用情況
-- =============================================

-- 檢查緩存命中率
SELECT 
    '💾 緩存性能' as check_type,
    'buffer_hit_ratio' as metric,
    ROUND(
        100.0 * sum(blks_hit) / (sum(blks_hit) + sum(blks_read)), 2
    ) as hit_ratio_percent
FROM pg_stat_database
WHERE datname = current_database();

-- 檢查表統計信息更新時間
SELECT 
    '📊 統計信息狀態' as check_type,
    schemaname,
    tablename,
    last_analyze,
    last_autoanalyze,
    CASE 
        WHEN last_analyze IS NULL AND last_autoanalyze IS NULL THEN '❌ 從未分析'
        WHEN GREATEST(last_analyze, last_autoanalyze) < NOW() - INTERVAL '1 day' THEN '⚠️ 統計過期'
        ELSE '✅ 統計正常'
    END as stats_status
FROM pg_stat_user_tables
WHERE schemaname = 'public';

-- =============================================
-- 8. 提供診斷建議
-- =============================================

DO $$
DECLARE
    total_connections INTEGER;
    max_connections INTEGER;
    connection_ratio NUMERIC;
BEGIN
    -- 獲取連接數據
    SELECT COUNT(*) INTO total_connections FROM pg_stat_activity;
    SELECT setting::int INTO max_connections FROM pg_settings WHERE name = 'max_connections';
    connection_ratio := (total_connections::NUMERIC / max_connections::NUMERIC) * 100;
    
    RAISE NOTICE '=== 🔧 診斷建議 ===';
    
    IF connection_ratio > 80 THEN
        RAISE NOTICE '⚠️ 連接數過高 (%.1f%%)，可能影響性能', connection_ratio;
        RAISE NOTICE '建議: 檢查是否有未關閉的連接或考慮增加連接限制';
    ELSE
        RAISE NOTICE '✅ 連接數正常 (%.1f%%)', connection_ratio;
    END IF;
    
    RAISE NOTICE '📋 如果前端連接緩慢，請檢查:';
    RAISE NOTICE '1. 網路連線穩定性';
    RAISE NOTICE '2. Supabase 專案配額是否已達上限';
    RAISE NOTICE '3. API 金鑰是否正確且有效';
    RAISE NOTICE '4. 瀏覽器是否有快取或代理問題';
    RAISE NOTICE '5. 防火牆或安全軟體是否阻擋連接';
END $$;

-- =============================================
-- 9. 顯示完整診斷摘要
-- =============================================

SELECT 
    '=== 📋 診斷完成 ===' as summary,
    NOW() as completed_at,
    '請檢查上述所有輸出結果以判斷問題原因' as next_steps;