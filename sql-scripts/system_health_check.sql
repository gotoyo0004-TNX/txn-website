-- =============================================
-- TXN 系統健康檢查腳本
-- 版本: 2.0
-- 建立日期: 2024-12-19
-- 用途: 快速診斷系統狀態和常見問題
-- =============================================

-- 🎯 此腳本將檢查：
-- 1. 資料表結構完整性
-- 2. RLS 策略狀態
-- 3. 索引效能
-- 4. 用戶帳戶狀態
-- 5. 常見問題診斷

DO $$
BEGIN
    RAISE NOTICE '🏥 開始 TXN 系統健康檢查...';
    RAISE NOTICE '執行時間: %', NOW();
END $$;

-- =============================================
-- 1. 資料表結構檢查
-- =============================================

SELECT 
    '📊 資料表結構檢查' as check_type,
    'table_existence' as check_name,
    CASE 
        WHEN COUNT(*) = 4 THEN '✅ 通過'
        ELSE '❌ 失敗'
    END as status,
    COUNT(*) as found_tables,
    '4' as expected_tables,
    STRING_AGG(table_name, ', ') as table_list
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots');

-- 檢查必要欄位
SELECT 
    '📊 必要欄位檢查' as check_type,
    table_name,
    CASE 
        WHEN table_name = 'user_profiles' AND COUNT(*) >= 10 THEN '✅ 通過'
        WHEN table_name = 'strategies' AND COUNT(*) >= 8 THEN '✅ 通過'
        WHEN table_name = 'trades' AND COUNT(*) >= 15 THEN '✅ 通過'
        WHEN table_name = 'performance_snapshots' AND COUNT(*) >= 12 THEN '✅ 通過'
        ELSE '⚠️ 欄位可能不完整'
    END as status,
    COUNT(*) as column_count
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
GROUP BY table_name
ORDER BY table_name;

-- =============================================
-- 2. RLS 策略檢查
-- =============================================

SELECT 
    '🛡️ RLS 策略檢查' as check_type,
    tablename,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ 已啟用'
        ELSE '❌ 未設定'
    END as rls_status,
    COUNT(*) as policy_count,
    STRING_AGG(policyname, ', ') as policies
FROM pg_policies 
WHERE schemaname = 'public'
    AND tablename IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
GROUP BY tablename
ORDER BY tablename;

-- 檢查 RLS 是否啟用
SELECT 
    '🛡️ RLS 啟用狀態' as check_type,
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ 已啟用'
        ELSE '❌ 未啟用'
    END as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
    AND tablename IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
ORDER BY tablename;

-- =============================================
-- 3. 索引效能檢查
-- =============================================

SELECT 
    '📇 索引檢查' as check_type,
    schemaname,
    tablename,
    indexname,
    CASE 
        WHEN indexname LIKE 'idx_%' THEN '✅ 自定義索引'
        WHEN indexname LIKE '%_pkey' THEN '🔑 主鍵索引'
        ELSE '📋 其他索引'
    END as index_type
FROM pg_indexes 
WHERE schemaname = 'public'
    AND tablename IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
ORDER BY tablename, indexname;

-- =============================================
-- 4. 用戶帳戶狀態檢查
-- =============================================

-- 檢查管理員帳戶
SELECT 
    '👥 管理員帳戶檢查' as check_type,
    COUNT(*) as admin_count,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ 存在管理員'
        ELSE '❌ 無管理員帳戶'
    END as status
FROM public.user_profiles 
WHERE role IN ('super_admin', 'admin', 'moderator')
    AND status = 'active';

-- 用戶統計
SELECT 
    '📊 用戶統計' as check_type,
    role,
    status,
    COUNT(*) as user_count
FROM public.user_profiles 
GROUP BY role, status
ORDER BY role, status;

-- 檢查測試帳戶
SELECT 
    '🧪 測試帳戶檢查' as check_type,
    email,
    role,
    status,
    CASE 
        WHEN email = 'admin@txn.test' AND role = 'super_admin' AND status = 'active' 
        THEN '✅ 測試管理員正常'
        WHEN email = 'admin@txn.test' 
        THEN '⚠️ 測試管理員狀態異常'
        ELSE '📋 其他帳戶'
    END as account_status
FROM public.user_profiles 
WHERE email LIKE '%@txn.test'
ORDER BY email;

-- =============================================
-- 5. 函數和觸發器檢查
-- =============================================

-- 檢查重要函數
SELECT 
    '⚡ 函數檢查' as check_type,
    proname as function_name,
    CASE 
        WHEN proname = 'is_admin_user_safe' THEN '✅ 管理員檢查函數'
        WHEN proname = 'update_updated_at_column' THEN '✅ 時間戳更新函數'
        WHEN proname = 'handle_new_user' THEN '✅ 新用戶處理函數'
        ELSE '📋 其他函數'
    END as function_type
FROM pg_proc 
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    AND proname IN ('is_admin_user_safe', 'update_updated_at_column', 'handle_new_user')
ORDER BY proname;

-- 檢查觸發器
SELECT 
    '⚡ 觸發器檢查' as check_type,
    event_object_table as table_name,
    trigger_name,
    event_manipulation as trigger_event,
    CASE 
        WHEN trigger_name LIKE '%updated_at%' THEN '✅ 時間戳觸發器'
        WHEN trigger_name LIKE '%new_user%' THEN '✅ 新用戶觸發器'
        ELSE '📋 其他觸發器'
    END as trigger_type
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
    AND event_object_table IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
ORDER BY event_object_table, trigger_name;

-- =============================================
-- 6. 資料完整性檢查
-- =============================================

-- 檢查外鍵約束
SELECT 
    '🔗 外鍵約束檢查' as check_type,
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    '✅ 正常' as status
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_schema = 'public'
    AND tc.table_name IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
ORDER BY tc.table_name, tc.constraint_name;

-- =============================================
-- 7. 效能指標檢查
-- =============================================

-- 資料表大小
SELECT 
    '📏 資料表大小' as check_type,
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as table_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as data_size
FROM pg_tables 
WHERE schemaname = 'public'
    AND tablename IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- =============================================
-- 8. 常見問題診斷
-- =============================================

-- 檢查是否有孤立記錄
DO $$
DECLARE
    orphan_count INTEGER;
BEGIN
    -- 檢查 strategies 表中的孤立記錄
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        SELECT COUNT(*) INTO orphan_count
        FROM public.strategies s
        LEFT JOIN public.user_profiles up ON s.user_id = up.id
        WHERE up.id IS NULL;
        
        RAISE NOTICE '🔍 孤立記錄檢查 - strategies: % 筆孤立記錄', orphan_count;
    END IF;
    
    -- 檢查 trades 表中的孤立記錄
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        SELECT COUNT(*) INTO orphan_count
        FROM public.trades t
        LEFT JOIN public.user_profiles up ON t.user_id = up.id
        WHERE up.id IS NULL;
        
        RAISE NOTICE '🔍 孤立記錄檢查 - trades: % 筆孤立記錄', orphan_count;
    END IF;
END $$;

-- =============================================
-- 9. 系統建議
-- =============================================

DO $$
DECLARE
    total_users INTEGER;
    admin_users INTEGER;
    table_count INTEGER;
    policy_count INTEGER;
BEGIN
    -- 統計資料
    SELECT COUNT(*) INTO total_users FROM public.user_profiles;
    SELECT COUNT(*) INTO admin_users FROM public.user_profiles WHERE role IN ('super_admin', 'admin', 'moderator');
    SELECT COUNT(*) INTO table_count FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots');
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE schemaname = 'public';
    
    RAISE NOTICE '';
    RAISE NOTICE '📋 系統健康檢查摘要：';
    RAISE NOTICE '- 核心資料表: %/4', table_count;
    RAISE NOTICE '- RLS 策略: % 個', policy_count;
    RAISE NOTICE '- 總用戶數: %', total_users;
    RAISE NOTICE '- 管理員數: %', admin_users;
    RAISE NOTICE '';
    
    -- 提供建議
    IF table_count < 4 THEN
        RAISE NOTICE '⚠️  建議: 執行 complete_database_setup.sql 建立缺失的資料表';
    END IF;
    
    IF policy_count = 0 THEN
        RAISE NOTICE '⚠️  建議: RLS 策略未設定，請執行資料庫設定腳本';
    END IF;
    
    IF admin_users = 0 THEN
        RAISE NOTICE '⚠️  建議: 執行 create_admin_user.sql 建立管理員帳戶';
    END IF;
    
    IF table_count = 4 AND policy_count > 0 AND admin_users > 0 THEN
        RAISE NOTICE '✅ 系統狀態良好！';
    END IF;
END $$;

-- =============================================
-- 10. 完成通知
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 TXN 系統健康檢查完成！';
    RAISE NOTICE '📊 請查看上方的檢查結果';
    RAISE NOTICE '⚠️  如發現問題，請執行相應的修復腳本';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 可用的修復腳本：';
    RAISE NOTICE '- complete_database_setup.sql (完整設定)';
    RAISE NOTICE '- database_update_v2.sql (升級現有系統)';
    RAISE NOTICE '- create_admin_user.sql (建立管理員)';
    RAISE NOTICE '- fix_rls_simple_correct.sql (修復 RLS 問題)';
END $$;
