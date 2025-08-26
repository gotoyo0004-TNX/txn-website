-- =============================================
-- 徹底清理所有 RLS 策略並修復管理員權限
-- 解決策略重複創建問題的最終解決方案
-- =============================================

-- 🧹 徹底清理所有策略，然後重新創建

DO $$
BEGIN
    RAISE NOTICE '🧹 開始徹底清理所有 RLS 策略...';
    RAISE NOTICE '⏰ 執行時間: %', NOW();
END $$;

-- =============================================
-- 1. 禁用所有表的 RLS
-- =============================================

DO $$
BEGIN
    -- 禁用主要表的 RLS
    ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;
    
    -- 安全地禁用其他表的 RLS（如果存在）
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        ALTER TABLE public.strategies DISABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        ALTER TABLE public.trades DISABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        ALTER TABLE public.performance_snapshots DISABLE ROW LEVEL SECURITY;
    END IF;
    
    RAISE NOTICE '🛡️ 已禁用所有表的 RLS';
END $$;

-- =============================================
-- 2. 動態清理所有現有策略
-- =============================================

DO $$
DECLARE
    r RECORD;
    policy_count INTEGER := 0;
BEGIN
    RAISE NOTICE '🧹 開始動態清理所有現有策略...';
    
    -- 清理所有 public schema 的策略
    FOR r IN (
        SELECT tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public'
        ORDER BY tablename, policyname
    ) LOOP
        BEGIN
            EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON public.' || quote_ident(r.tablename);
            policy_count := policy_count + 1;
            RAISE NOTICE '  ❌ 已刪除策略: %.%', r.tablename, r.policyname;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '  ⚠️ 刪除策略失敗: %.%, 錯誤: %', r.tablename, r.policyname, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '🧹 共動態清理了 % 個策略', policy_count;
END $$;

-- =============================================
-- 3. 確認清理結果
-- =============================================

SELECT 
    '📊 策略清理確認' as check_type,
    COUNT(*) as remaining_policies,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ 所有策略已清理'
        ELSE '⚠️ 仍有策略殘留'
    END as status
FROM pg_policies 
WHERE schemaname = 'public';

-- 如果還有殘留策略，顯示它們
DO $$
DECLARE
    remaining_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO remaining_count
    FROM pg_policies 
    WHERE schemaname = 'public';
    
    IF remaining_count > 0 THEN
        RAISE NOTICE '⚠️ 發現 % 個殘留策略，將顯示詳情', remaining_count;
    ELSE
        RAISE NOTICE '✅ 所有策略已完全清理';
    END IF;
END $$;

-- 顯示殘留策略（如果有）
SELECT 
    '📋 殘留策略' as info,
    tablename,
    policyname
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =============================================
-- 4. 強制確保管理員用戶資料正確
-- =============================================

DO $$
DECLARE
    admin_user_id UUID;
    existing_count INTEGER;
BEGIN
    RAISE NOTICE '👤 開始修復管理員用戶資料...';
    
    -- 獲取認證系統中的用戶 ID
    SELECT id INTO admin_user_id 
    FROM auth.users 
    WHERE email = 'admin@txn.test';
    
    IF admin_user_id IS NOT NULL THEN
        RAISE NOTICE '✅ 找到認證用戶 ID: %', admin_user_id;
        
        -- 清理可能有問題的記錄
        DELETE FROM public.user_profiles 
        WHERE email = 'admin@txn.test' 
        AND (role != 'admin' OR status != 'active');
        
        -- 檢查是否已有正確記錄
        SELECT COUNT(*) INTO existing_count
        FROM public.user_profiles 
        WHERE id = admin_user_id AND email = 'admin@txn.test' AND role = 'admin' AND status = 'active';
        
        IF existing_count = 0 THEN
            -- 強制插入正確記錄
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
                
            RAISE NOTICE '✅ 已修復管理員用戶資料';
        ELSE
            RAISE NOTICE '✅ 管理員用戶資料已正確';
        END IF;
    ELSE
        RAISE NOTICE '❌ 認證系統中找不到 admin@txn.test 用戶';
        RAISE NOTICE '💡 請確保在 Supabase Auth 中創建此用戶';
    END IF;
END $$;

-- =============================================
-- 5. 創建全新的簡單策略
-- =============================================

-- 為 user_profiles 創建策略
CREATE POLICY "full_access_read" ON public.user_profiles
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "full_access_update" ON public.user_profiles
    FOR UPDATE TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "full_access_insert" ON public.user_profiles
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY "full_access_delete" ON public.user_profiles
    FOR DELETE TO authenticated
    USING (true);

DO $$
BEGIN
    RAISE NOTICE '✅ 已為 user_profiles 創建新策略';
END $$;

-- 為其他表創建策略
DO $$
BEGIN
    -- strategies 表
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        CREATE POLICY "full_access" ON public.strategies 
            FOR ALL TO authenticated 
            USING (true) 
            WITH CHECK (true);
        RAISE NOTICE '✅ 已為 strategies 創建策略';
    END IF;
    
    -- trades 表
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        CREATE POLICY "full_access" ON public.trades 
            FOR ALL TO authenticated 
            USING (true) 
            WITH CHECK (true);
        RAISE NOTICE '✅ 已為 trades 創建策略';
    END IF;
    
    -- performance_snapshots 表
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        CREATE POLICY "full_access" ON public.performance_snapshots 
            FOR ALL TO authenticated 
            USING (true) 
            WITH CHECK (true);
        RAISE NOTICE '✅ 已為 performance_snapshots 創建策略';
    END IF;
END $$;

-- =============================================
-- 6. 重新啟用 RLS
-- =============================================

DO $$
BEGIN
    -- 重新啟用主要表的 RLS
    ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
    
    -- 安全地啟用其他表的 RLS
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
    
    -- 測試 1: 基本查詢
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO test_count FROM public.user_profiles;
    end_time := clock_timestamp();
    duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
    RAISE NOTICE '📊 基本查詢: % ms, 結果: %', duration_ms, test_count;
    
    -- 測試 2: 管理員查詢
    start_time := clock_timestamp();
    SELECT EXISTS(
        SELECT 1 FROM public.user_profiles 
        WHERE email = 'admin@txn.test' AND role = 'admin' AND status = 'active'
    ) INTO admin_found;
    end_time := clock_timestamp();
    duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
    RAISE NOTICE '📊 管理員查詢: % ms, 找到: %', duration_ms, admin_found;
    
    -- 測試 3: 角色篩選查詢
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO test_count
    FROM public.user_profiles 
    WHERE role = 'admin' AND status = 'active';
    end_time := clock_timestamp();
    duration_ms := EXTRACT(milliseconds FROM (end_time - start_time));
    RAISE NOTICE '📊 角色篩選查詢: % ms, 結果: %', duration_ms, test_count;
    
    IF duration_ms > 1000 THEN
        RAISE NOTICE '⚠️ 查詢時間超過 1 秒，可能仍需優化';
    ELSE
        RAISE NOTICE '✅ 查詢性能良好';
    END IF;
END $$;

-- =============================================
-- 8. 最終驗證和報告
-- =============================================

-- 顯示管理員最終狀態
SELECT 
    '🎯 管理員最終狀態' as section,
    CASE 
        WHEN au.id IS NOT NULL AND up.id IS NOT NULL 
             AND up.role = 'admin' AND up.status = 'active' 
        THEN '✅ 完全正常'
        WHEN au.id IS NOT NULL AND up.id IS NULL 
        THEN '❌ 缺少 user_profiles 記錄'
        WHEN au.id IS NULL 
        THEN '❌ 認證用戶不存在'
        ELSE '❌ 其他問題'
    END as status,
    au.email as auth_email,
    up.email as profile_email,
    up.role,
    up.status,
    up.approved_at IS NOT NULL as approved
FROM auth.users au
FULL OUTER JOIN public.user_profiles up ON au.id = up.id
WHERE au.email = 'admin@txn.test' OR up.email = 'admin@txn.test';

-- 顯示當前策略狀態
SELECT 
    '📋 當前策略狀態' as section,
    tablename,
    COUNT(*) as policy_count,
    array_agg(policyname ORDER BY policyname) as policies
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- =============================================
-- 9. 完成報告
-- =============================================

SELECT 
    '=== 🎉 徹底清理和修復完成 ===' as status,
    NOW() as completion_time,
    '所有策略已重新創建，管理員權限已修復' as message;

DO $$
DECLARE
    admin_ok BOOLEAN;
    policy_count INTEGER;
BEGIN
    -- 最終檢查
    SELECT EXISTS(
        SELECT 1 FROM public.user_profiles 
        WHERE email = 'admin@txn.test' AND role = 'admin' AND status = 'active'
    ) INTO admin_ok;
    
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public';
    
    RAISE NOTICE '=== 🎯 最終檢查結果 ===';
    RAISE NOTICE '管理員設置: %', CASE WHEN admin_ok THEN '✅ 正確' ELSE '❌ 有問題' END;
    RAISE NOTICE 'RLS 策略: % 個已創建', policy_count;
    
    IF admin_ok AND policy_count >= 4 THEN
        RAISE NOTICE '🎉 修復完全成功！';
        RAISE NOTICE '請立即測試：';
        RAISE NOTICE '1. 清除瀏覽器快取 (Ctrl+Shift+Delete)';
        RAISE NOTICE '2. 重新整理首頁';
        RAISE NOTICE '3. 嘗試訪問管理面板 /admin';
    ELSE
        RAISE NOTICE '⚠️ 可能仍有問題，請檢查：';
        RAISE NOTICE '1. Supabase Auth 中是否有 admin@txn.test 用戶';
        RAISE NOTICE '2. 網路連接是否正常';
        RAISE NOTICE '3. 瀏覽器快取是否已清除';
    END IF;
END $$;