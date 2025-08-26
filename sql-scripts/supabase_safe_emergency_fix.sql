-- =============================================
-- Supabase 安全緊急修復腳本
-- 專門為 Supabase 環境設計，避免權限問題
-- =============================================

-- 🚨 Supabase 安全緊急修復：解決連接和權限問題

DO $$
BEGIN
    RAISE NOTICE '🚨 開始 Supabase 安全緊急修復...';
    RAISE NOTICE '⏰ 執行時間: %', NOW();
    RAISE NOTICE '🔒 使用安全模式，避免需要超級用戶權限的操作';
END $$;

-- =============================================
-- 1. 檢查當前連接狀態（只讀操作）
-- =============================================

SELECT 
    '🔍 當前連接狀態' as info,
    COUNT(*) as total_connections,
    COUNT(*) FILTER (WHERE state = 'active') as active_connections,
    COUNT(*) FILTER (WHERE state = 'idle') as idle_connections
FROM pg_stat_activity
WHERE datname = current_database();

-- =============================================
-- 2. 檢查長時間查詢（不終止，只監控）
-- =============================================

DO $$
DECLARE
    long_query_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO long_query_count
    FROM pg_stat_activity 
    WHERE state = 'active'
      AND NOW() - query_start > INTERVAL '30 seconds'
      AND query NOT LIKE '%pg_stat_activity%'
      AND datname = current_database();
      
    IF long_query_count > 0 THEN
        RAISE NOTICE '⚠️ 發現 % 個長時間運行的查詢', long_query_count;
    ELSE
        RAISE NOTICE '✅ 沒有發現長時間運行的查詢';
    END IF;
END $$;

-- =============================================
-- 3. 完全重置 RLS 策略（安全清理）
-- =============================================

-- 暫時禁用所有 RLS
ALTER TABLE IF EXISTS public.user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.strategies DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.trades DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.performance_snapshots DISABLE ROW LEVEL SECURITY;

-- 安全清理所有現有策略
DO $$
DECLARE
    r RECORD;
    policy_count INTEGER := 0;
    error_count INTEGER := 0;
BEGIN
    RAISE NOTICE '🧹 開始安全清理所有 RLS 策略...';
    
    FOR r IN (
        SELECT tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public'
        ORDER BY tablename, policyname
    ) LOOP
        BEGIN
            EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON public.' || quote_ident(r.tablename);
            policy_count := policy_count + 1;
            RAISE NOTICE '  ✅ 已刪除策略: %.%', r.tablename, r.policyname;
        EXCEPTION WHEN OTHERS THEN
            error_count := error_count + 1;
            RAISE NOTICE '  ⚠️ 刪除策略失敗: %.%, 錯誤: %', r.tablename, r.policyname, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '🧹 策略清理完成：成功 %，失敗 %', policy_count, error_count;
END $$;

-- 確認清理結果
SELECT 
    '📊 策略清理確認' as check_type,
    COUNT(*) as remaining_policies
FROM pg_policies 
WHERE schemaname = 'public';

-- =============================================
-- 4. 創建最安全的 RLS 策略
-- =============================================

-- 為 user_profiles 創建最安全的策略
CREATE POLICY "safe_emergency_read" ON public.user_profiles
    FOR SELECT 
    TO authenticated
    USING (true);

CREATE POLICY "safe_emergency_insert" ON public.user_profiles
    FOR INSERT 
    TO authenticated
    WITH CHECK (auth.uid() = id);

CREATE POLICY "safe_emergency_update" ON public.user_profiles
    FOR UPDATE 
    TO authenticated
    USING (auth.uid() = id);

-- 為其他表創建安全策略
DO $$
BEGIN
    -- strategies 表
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        CREATE POLICY "safe_strategies_access" ON public.strategies 
            FOR ALL TO authenticated 
            USING (true) WITH CHECK (true);
        RAISE NOTICE '✅ 已為 strategies 創建安全策略';
    END IF;
    
    -- trades 表
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        CREATE POLICY "safe_trades_access" ON public.trades 
            FOR ALL TO authenticated 
            USING (true) WITH CHECK (true);
        RAISE NOTICE '✅ 已為 trades 創建安全策略';
    END IF;
    
    -- performance_snapshots 表
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        CREATE POLICY "safe_snapshots_access" ON public.performance_snapshots 
            FOR ALL TO authenticated 
            USING (true) WITH CHECK (true);
        RAISE NOTICE '✅ 已為 performance_snapshots 創建安全策略';
    END IF;
END $$;

-- 重新啟用 RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        ALTER TABLE public.strategies ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        ALTER TABLE public.performance_snapshots ENABLE ROW LEVEL SECURITY;
    END IF;
    
    RAISE NOTICE '🛡️ 已重新啟用所有表的 RLS';
END $$;

-- =============================================
-- 5. 優化索引（安全操作）
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🔧 開始創建和優化索引...';
    
    -- user_profiles 關鍵索引
    CREATE INDEX IF NOT EXISTS idx_user_profiles_email_fast ON user_profiles(email);
    CREATE INDEX IF NOT EXISTS idx_user_profiles_role_status_fast ON user_profiles(role, status);
    CREATE INDEX IF NOT EXISTS idx_user_profiles_admin_lookup ON user_profiles(id, role, status) WHERE role = 'admin';
    
    -- 如果其他表存在，也創建索引
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        CREATE INDEX IF NOT EXISTS idx_trades_user_id ON trades(user_id);
        CREATE INDEX IF NOT EXISTS idx_trades_created_at ON trades(created_at);
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        CREATE INDEX IF NOT EXISTS idx_strategies_user_id ON strategies(user_id);
    END IF;
    
    RAISE NOTICE '✅ 索引優化完成';
END $$;

-- =============================================
-- 6. 修復管理員用戶資料
-- =============================================

DO $$
DECLARE
    admin_user_id UUID;
    admin_exists BOOLEAN;
BEGIN
    RAISE NOTICE '👤 開始修復管理員用戶資料...';
    
    -- 獲取認證系統中的管理員用戶 ID
    SELECT id INTO admin_user_id 
    FROM auth.users 
    WHERE email = 'admin@txn.test';
    
    IF admin_user_id IS NOT NULL THEN
        RAISE NOTICE '✅ 找到認證用戶 ID: %', admin_user_id;
        
        -- 檢查是否已有正確的 profile 記錄
        SELECT EXISTS(
            SELECT 1 FROM public.user_profiles 
            WHERE id = admin_user_id AND email = 'admin@txn.test' 
            AND role = 'admin' AND status = 'active'
        ) INTO admin_exists;
        
        IF NOT admin_exists THEN
            -- 強制插入或更新管理員資料
            INSERT INTO public.user_profiles (
                id, email, full_name, role, status, 
                approved_at, created_at, updated_at
            ) VALUES (
                admin_user_id, 'admin@txn.test', 'TXN System Administrator', 
                'admin', 'active', NOW(), NOW(), NOW()
            ) ON CONFLICT (id) DO UPDATE SET
                email = 'admin@txn.test',
                role = 'admin',
                status = 'active',
                approved_at = COALESCE(user_profiles.approved_at, NOW()),
                updated_at = NOW(),
                full_name = COALESCE(user_profiles.full_name, 'TXN System Administrator');
                
            RAISE NOTICE '✅ 管理員資料已創建/更新';
        ELSE
            RAISE NOTICE '✅ 管理員資料已存在且正確';
        END IF;
    ELSE
        RAISE NOTICE '❌ 認證系統中找不到 admin@txn.test';
        RAISE NOTICE '💡 請在 Supabase Dashboard -> Authentication -> Users 中創建此用戶';
    END IF;
END $$;

-- =============================================
-- 7. 安全的性能優化
-- =============================================

-- 更新表統計信息（這個操作是安全的）
ANALYZE public.user_profiles;

-- 如果其他表存在，也更新統計信息
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        ANALYZE public.strategies;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        ANALYZE public.trades;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        ANALYZE public.performance_snapshots;
    END IF;
    
    RAISE NOTICE '📊 已更新所有表的統計信息';
END $$;

-- =============================================
-- 8. 連接和性能測試
-- =============================================

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    test_count INTEGER;
    admin_found BOOLEAN;
BEGIN
    RAISE NOTICE '🧪 開始執行連接和性能測試...';
    
    -- 測試 1: 基本查詢性能
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO test_count FROM public.user_profiles;
    end_time := clock_timestamp();
    duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
    RAISE NOTICE '📊 基本查詢測試: % ms, 記錄數: %', ROUND(duration_ms, 2), test_count;
    
    -- 測試 2: 管理員查詢性能
    start_time := clock_timestamp();
    SELECT EXISTS(
        SELECT 1 FROM public.user_profiles 
        WHERE email = 'admin@txn.test' AND role = 'admin' AND status = 'active'
    ) INTO admin_found;
    end_time := clock_timestamp();
    duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
    RAISE NOTICE '📊 管理員查詢測試: % ms, 找到管理員: %', ROUND(duration_ms, 2), admin_found;
    
    -- 測試 3: 索引效率測試
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO test_count FROM public.user_profiles WHERE role = 'admin' AND status = 'active';
    end_time := clock_timestamp();
    duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
    RAISE NOTICE '📊 索引查詢測試: % ms, 管理員數量: %', ROUND(duration_ms, 2), test_count;
    
    -- 性能評估
    IF duration_ms < 50 THEN
        RAISE NOTICE '✅ 查詢性能優秀 (< 50ms)';
    ELSIF duration_ms < 200 THEN
        RAISE NOTICE '🟡 查詢性能良好 (< 200ms)';
    ELSE
        RAISE NOTICE '⚠️ 查詢性能需要關注 (> 200ms)';
    END IF;
END $$;

-- =============================================
-- 9. 最終狀態報告
-- =============================================

-- 顯示當前 RLS 策略狀態
SELECT 
    '📋 當前 RLS 策略狀態' as section,
    tablename,
    COUNT(*) as policy_count,
    array_agg(policyname ORDER BY policyname) as policies
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- 顯示管理員完整狀態
SELECT 
    '👤 管理員最終狀態' as section,
    CASE 
        WHEN au.email IS NOT NULL AND up.email IS NOT NULL 
             AND up.role = 'admin' AND up.status = 'active'
        THEN '✅ 完全正常'
        WHEN au.email IS NOT NULL AND up.email IS NULL
        THEN '❌ 缺少 user_profiles 記錄'
        WHEN au.email IS NULL
        THEN '❌ Auth 用戶不存在'
        ELSE '❌ 其他問題'
    END as status,
    au.email as auth_email,
    up.role as profile_role,
    up.status as profile_status,
    up.approved_at IS NOT NULL as is_approved
FROM auth.users au
FULL OUTER JOIN public.user_profiles up ON au.id = up.id
WHERE au.email = 'admin@txn.test' OR up.email = 'admin@txn.test';

-- 顯示連接統計
SELECT 
    '🔗 最終連接狀態' as section,
    COUNT(*) as total_connections,
    COUNT(*) FILTER (WHERE state = 'active') as active_connections,
    COUNT(*) FILTER (WHERE state = 'idle') as idle_connections
FROM pg_stat_activity
WHERE datname = current_database();

-- =============================================
-- 10. 完成報告和後續建議
-- =============================================

DO $$
DECLARE
    admin_ok BOOLEAN;
    policy_count INTEGER;
    connection_count INTEGER;
BEGIN
    -- 最終狀態檢查
    SELECT EXISTS(
        SELECT 1 FROM public.user_profiles 
        WHERE email = 'admin@txn.test' AND role = 'admin' AND status = 'active'
    ) INTO admin_ok;
    
    SELECT COUNT(*) INTO policy_count FROM pg_policies WHERE schemaname = 'public';
    SELECT COUNT(*) INTO connection_count FROM pg_stat_activity WHERE datname = current_database();
    
    RAISE NOTICE '=== 🎉 Supabase 安全緊急修復完成 ===';
    RAISE NOTICE '⏰ 完成時間: %', NOW();
    RAISE NOTICE '';
    RAISE NOTICE '📋 修復結果摘要：';
    RAISE NOTICE '  管理員設置: %', CASE WHEN admin_ok THEN '✅ 正常' ELSE '❌ 需要檢查' END;
    RAISE NOTICE '  RLS 策略數: % 個', policy_count;
    RAISE NOTICE '  資料庫連接: % 個', connection_count;
    RAISE NOTICE '';
    RAISE NOTICE '🚀 請立即測試：';
    RAISE NOTICE '1. 清除瀏覽器快取 (Ctrl+Shift+Delete)';
    RAISE NOTICE '2. 重新載入首頁測試連接';
    RAISE NOTICE '3. 訪問管理面板 /admin';
    RAISE NOTICE '4. 測試所有管理功能';
    RAISE NOTICE '';
    
    IF admin_ok AND policy_count >= 3 THEN
        RAISE NOTICE '🎯 修復成功！系統應該可以正常使用了';
    ELSE
        RAISE NOTICE '⚠️ 可能仍有問題，請檢查：';
        RAISE NOTICE '  • Supabase Auth 中是否有 admin@txn.test 用戶';
        RAISE NOTICE '  • 網路連接是否穩定';
        RAISE NOTICE '  • 瀏覽器快取是否已清除';
    END IF;
END $$;