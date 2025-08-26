-- =============================================
-- 快速修復 Supabase 連接緩慢問題
-- 緊急優化腳本
-- =============================================

-- 🚨 緊急修復：針對連接緩慢問題的快速優化

DO $$
BEGIN
    RAISE NOTICE '🚀 開始快速修復 Supabase 連接問題...';
    RAISE NOTICE '⏰ 執行時間: %', NOW();
END $$;

-- =============================================
-- 1. 清理可能的阻塞查詢
-- =============================================

-- 檢查是否有長時間運行的查詢
SELECT 
    '🔍 檢查長時間運行的查詢' as check_type,
    pid,
    state,
    query_start,
    NOW() - query_start as duration,
    query
FROM pg_stat_activity 
WHERE state = 'active' 
  AND NOW() - query_start > INTERVAL '30 seconds'
  AND query NOT LIKE '%pg_stat_activity%';

-- =============================================
-- 2. 優化 RLS 策略（確保最簡化）
-- =============================================

-- 暫時禁用 RLS 進行優化
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- 完全清理所有策略（包括臨時策略）
DROP POLICY IF EXISTS "user_read_own_only" ON public.user_profiles;
DROP POLICY IF EXISTS "user_update_own_basic" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_user_registration_safe" ON public.user_profiles;
DROP POLICY IF EXISTS "superuser_full_access" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_users_read_all" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_users_read_own" ON public.user_profiles;
DROP POLICY IF EXISTS "users_update_own_simple" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_insert_authenticated" ON public.user_profiles;

-- 清理臨時策略
DROP POLICY IF EXISTS "temp_all_read_access" ON public.user_profiles;
DROP POLICY IF EXISTS "temp_update_own" ON public.user_profiles;
DROP POLICY IF EXISTS "temp_insert_own" ON public.user_profiles;

-- 清理其他可能存在的策略變體
DROP POLICY IF EXISTS "user_read_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_read_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "user_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_update_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_user_registration" ON public.user_profiles;

-- 確認策略清理完成
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies WHERE tablename = 'user_profiles';
    
    RAISE NOTICE '🧹 策略清理完成，剩餘策略數量: %', policy_count;
    
    IF policy_count = 0 THEN
        RAISE NOTICE '✅ 所有舊策略已清理完成';
    ELSE
        RAISE NOTICE '⚠️ 仍有策略存在，將繼續創建新策略';
    END IF;
END $$;

-- 創建最簡單、最高效的策略
-- 策略 1: 所有認證用戶可以查看所有資料（臨時解決方案）
CREATE POLICY "temp_all_read_access" ON public.user_profiles
    FOR SELECT 
    TO authenticated
    USING (true);

-- 策略 2: 認證用戶可以更新自己的資料
CREATE POLICY "temp_update_own" ON public.user_profiles
    FOR UPDATE 
    TO authenticated
    USING (auth.uid() = id);

-- 策略 3: 允許插入新資料
CREATE POLICY "temp_insert_own" ON public.user_profiles
    FOR INSERT 
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- 重新啟用 RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 3. 更新表統計信息（提升查詢性能）
-- =============================================

ANALYZE user_profiles;
ANALYZE strategies;
ANALYZE trades;
ANALYZE performance_snapshots;

-- =============================================
-- 4. 檢查並創建必要的索引
-- =============================================

-- 確保 user_profiles 有必要的索引
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_status ON user_profiles(status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_created_at ON user_profiles(created_at);

-- =============================================
-- 5. 測試修復效果
-- =============================================

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    test_count INTEGER;
BEGIN
    RAISE NOTICE '🧪 測試修復效果...';
    
    -- 測試基本查詢性能
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO test_count FROM user_profiles;
    end_time := clock_timestamp();
    duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
    
    RAISE NOTICE '📊 基本查詢性能: % ms', duration_ms;
    
    -- 測試管理員查詢
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO test_count FROM user_profiles WHERE email = 'admin@txn.test';
    end_time := clock_timestamp();
    duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
    
    RAISE NOTICE '📊 管理員查詢性能: % ms', duration_ms;
    
    IF duration_ms < 100 THEN
        RAISE NOTICE '✅ 查詢性能已優化';
    ELSIF duration_ms < 500 THEN
        RAISE NOTICE '🟡 查詢性能有改善但仍可優化';
    ELSE
        RAISE NOTICE '⚠️ 查詢仍然較慢，可能需要進一步檢查';
    END IF;
END $$;

-- =============================================
-- 6. 清理連接池（如果可能）
-- =============================================

-- 結束空閒連接（謹慎使用）
SELECT 
    '🔧 連接池狀態' as info,
    COUNT(*) as total_connections,
    COUNT(*) FILTER (WHERE state = 'idle') as idle_connections
FROM pg_stat_activity;

-- =============================================
-- 7. 完成報告
-- =============================================

SELECT 
    '✅ 快速修復完成' as status,
    NOW() as completion_time,
    '已執行基本優化，請測試前端連接' as next_action;

-- 顯示當前策略狀態
SELECT 
    '📋 當前 RLS 策略' as info,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename = 'user_profiles';

-- 完成通知
DO $$
BEGIN
    RAISE NOTICE '🎉 快速修復腳本執行完成！';
    RAISE NOTICE '📋 已簡化 RLS 策略並優化索引';
    RAISE NOTICE '⚡ 請立即測試前端連接是否改善';
    RAISE NOTICE '🔄 如果問題持續，請執行完整診斷腳本';
END $$;