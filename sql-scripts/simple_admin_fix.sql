-- =============================================
-- 簡單直接的管理員權限修復腳本
-- 避免複雜的動態 SQL 操作
-- =============================================

-- 🚀 簡單快速的修復方案

DO $$
BEGIN
    RAISE NOTICE '🚀 開始簡單快速修復...';
    RAISE NOTICE '⏰ 執行時間: %', NOW();
END $$;

-- =============================================
-- 1. 檢查當前狀態
-- =============================================

-- 檢查 admin@txn.test 用戶
SELECT 
    '👤 檢查 admin@txn.test' as check_type,
    'auth.users' as table_name,
    COUNT(*) as found_count
FROM auth.users 
WHERE email = 'admin@txn.test';

SELECT 
    '📊 檢查 user_profiles' as check_type,
    'user_profiles' as table_name,
    COUNT(*) as found_count,
    string_agg(role || '/' || status, ', ') as role_status
FROM public.user_profiles 
WHERE email = 'admin@txn.test'
GROUP BY check_type, table_name;

-- =============================================
-- 2. 禁用所有表的 RLS
-- =============================================

ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.strategies DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.trades DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.performance_snapshots DISABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    RAISE NOTICE '🛡️ 已禁用所有表的 RLS';
END $$;

-- =============================================
-- 3. 手動清理 user_profiles 的策略
-- =============================================

-- 手動列出並刪除常見的策略名稱
DROP POLICY IF EXISTS "ultra_simple_read" ON public.user_profiles;
DROP POLICY IF EXISTS "ultra_simple_update" ON public.user_profiles;
DROP POLICY IF EXISTS "ultra_simple_insert" ON public.user_profiles;
DROP POLICY IF EXISTS "simple_read_access" ON public.user_profiles;
DROP POLICY IF EXISTS "simple_update_own" ON public.user_profiles;
DROP POLICY IF EXISTS "simple_insert_own" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_view_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_insert_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "temp_all_read_access" ON public.user_profiles;
DROP POLICY IF EXISTS "temp_update_own" ON public.user_profiles;
DROP POLICY IF EXISTS "temp_insert_own" ON public.user_profiles;
DROP POLICY IF EXISTS "safe_read_access" ON public.user_profiles;
DROP POLICY IF EXISTS "safe_update_own" ON public.user_profiles;
DROP POLICY IF EXISTS "safe_insert_own" ON public.user_profiles;
DROP POLICY IF EXISTS "safe_delete_own" ON public.user_profiles;

-- 清理可能已存在的新策略名稱
DROP POLICY IF EXISTS "allow_all_read" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_all_update" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_all_insert" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_all_delete" ON public.user_profiles;

-- 清理其他表的策略
DROP POLICY IF EXISTS "simple_all_access" ON public.strategies;
DROP POLICY IF EXISTS "simple_all_access" ON public.trades;
DROP POLICY IF EXISTS "simple_all_access" ON public.performance_snapshots;
DROP POLICY IF EXISTS "users_manage_own_strategies" ON public.strategies;
DROP POLICY IF EXISTS "users_manage_own_trades" ON public.trades;
DROP POLICY IF EXISTS "users_manage_own_performance" ON public.performance_snapshots;

-- 清理可能已存在的 allow_all 策略
DROP POLICY IF EXISTS "allow_all" ON public.strategies;
DROP POLICY IF EXISTS "allow_all" ON public.trades;
DROP POLICY IF EXISTS "allow_all" ON public.performance_snapshots;

DO $$
BEGIN
    RAISE NOTICE '🧹 已手動清理常見策略';
END $$;

-- =============================================
-- 4. 確保管理員用戶資料正確
-- =============================================

-- 強制更新管理員資料
DO $$
DECLARE
    admin_user_id UUID;
BEGIN
    -- 獲取用戶 ID
    SELECT id INTO admin_user_id 
    FROM auth.users 
    WHERE email = 'admin@txn.test';
    
    IF admin_user_id IS NOT NULL THEN
        -- 刪除舊記錄（如果存在問題）
        DELETE FROM public.user_profiles 
        WHERE email = 'admin@txn.test' 
        AND (role != 'admin' OR status != 'active');
        
        -- 插入或更新正確記錄
        INSERT INTO public.user_profiles (
            id, email, full_name, role, status, 
            approved_at, created_at, updated_at
        ) VALUES (
            admin_user_id, 'admin@txn.test', 'TXN Administrator', 
            'admin', 'active', NOW(), NOW(), NOW()
        ) ON CONFLICT (id) DO UPDATE SET
            role = 'admin',
            status = 'active',
            approved_at = COALESCE(user_profiles.approved_at, NOW()),
            updated_at = NOW();
            
        RAISE NOTICE '✅ 管理員資料已確保正確';
    ELSE
        RAISE NOTICE '❌ 找不到 admin@txn.test 認證用戶';
    END IF;
END $$;

-- =============================================
-- 5. 創建最簡單的策略
-- =============================================

-- 為 user_profiles 創建最寬鬆的策略
CREATE POLICY "allow_all_read" ON public.user_profiles
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "allow_all_update" ON public.user_profiles
    FOR UPDATE TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "allow_all_insert" ON public.user_profiles
    FOR INSERT TO authenticated
    WITH CHECK (true);

-- 為其他表創建簡單策略（如果表存在）
DO $$
BEGIN
    -- strategies 表
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        CREATE POLICY "allow_all" ON public.strategies FOR ALL TO authenticated USING (true) WITH CHECK (true);
        RAISE NOTICE '✅ strategies 表策略已創建';
    END IF;
    
    -- trades 表
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        CREATE POLICY "allow_all" ON public.trades FOR ALL TO authenticated USING (true) WITH CHECK (true);
        RAISE NOTICE '✅ trades 表策略已創建';
    END IF;
    
    -- performance_snapshots 表
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        CREATE POLICY "allow_all" ON public.performance_snapshots FOR ALL TO authenticated USING (true) WITH CHECK (true);
        RAISE NOTICE '✅ performance_snapshots 表策略已創建';
    END IF;
END $$;

-- =============================================
-- 6. 重新啟用 RLS
-- =============================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    -- 其他表（如果存在）
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        ALTER TABLE public.strategies ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        ALTER TABLE public.performance_snapshots ENABLE ROW LEVEL SECURITY;
    END IF;
    
    RAISE NOTICE '🛡️ 已重新啟用 RLS';
END $$;

-- =============================================
-- 7. 測試查詢性能
-- =============================================

DO $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    duration_ms NUMERIC;
    test_count INTEGER;
    admin_found BOOLEAN;
BEGIN
    RAISE NOTICE '🧪 測試修復效果...';
    
    -- 測試基本查詢
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO test_count FROM public.user_profiles;
    end_time := clock_timestamp();
    duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
    RAISE NOTICE '📊 基本查詢: % ms, 結果: %', duration_ms, test_count;
    
    -- 測試管理員查詢
    start_time := clock_timestamp();
    SELECT EXISTS(
        SELECT 1 FROM public.user_profiles 
        WHERE email = 'admin@txn.test' AND role = 'admin' AND status = 'active'
    ) INTO admin_found;
    end_time := clock_timestamp();
    duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
    RAISE NOTICE '📊 管理員查詢: % ms, 找到: %', duration_ms, admin_found;
    
    IF duration_ms > 2000 THEN
        RAISE NOTICE '⚠️ 查詢仍然較慢';
    ELSE
        RAISE NOTICE '✅ 查詢速度正常';
    END IF;
END $$;

-- =============================================
-- 8. 最終驗證
-- =============================================

-- 顯示最終結果
SELECT 
    '🎯 最終管理員狀態' as section,
    up.id,
    up.email,
    up.role,
    up.status,
    up.approved_at IS NOT NULL as approved,
    au.email_confirmed_at IS NOT NULL as email_confirmed
FROM public.user_profiles up
JOIN auth.users au ON up.id = au.id
WHERE up.email = 'admin@txn.test';

-- 顯示策略數量
SELECT 
    '📋 當前策略數量' as section,
    tablename,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- =============================================
-- 9. 完成報告
-- =============================================

SELECT 
    '=== 🎉 簡單修復完成 ===' as status,
    NOW() as completion_time,
    '已使用最寬鬆的策略設置' as message;

DO $$
BEGIN
    RAISE NOTICE '🎉 簡單修復腳本執行完成！';
    RAISE NOTICE '📋 建議立即測試：';
    RAISE NOTICE '1. 清除瀏覽器快取 (Ctrl+Shift+Delete)';
    RAISE NOTICE '2. 重新整理首頁';
    RAISE NOTICE '3. 嘗試訪問管理面板 /admin';
END $$;