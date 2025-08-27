-- =============================================
-- TXN 系統 - 緊急回滾修復腳本
-- 版本: 1.0
-- 建立日期: 2024-12-19
-- 用途: 緊急修復所有連接問題
-- =============================================

-- 🚨 緊急修復：所有連接都失敗了

SELECT '🚨 開始緊急修復所有 Supabase 連接問題...' as status;

-- =============================================
-- 1. 立即檢查系統狀態
-- =============================================

-- 檢查資料表是否還存在
SELECT 
    '📊 資料表狀態檢查' as check_type,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- 檢查 RLS 狀態
SELECT 
    '🛡️ RLS 狀態檢查' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- =============================================
-- 2. 緊急停用所有 RLS (暫時措施)
-- =============================================

-- 暫時停用所有 RLS 以恢復基本功能
DO $$
BEGIN
    RAISE NOTICE '🔓 緊急停用所有 RLS 策略...';
    
    -- 停用所有相關表的 RLS
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') THEN
        ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ user_profiles RLS 已停用';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        ALTER TABLE public.strategies DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ strategies RLS 已停用';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        ALTER TABLE public.trades DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ trades RLS 已停用';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        ALTER TABLE public.performance_snapshots DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ performance_snapshots RLS 已停用';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'projects' AND table_schema = 'public') THEN
        ALTER TABLE public.projects DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ projects RLS 已停用';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tasks' AND table_schema = 'public') THEN
        ALTER TABLE public.tasks DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ tasks RLS 已停用';
    END IF;
END $$;

-- =============================================
-- 3. 刪除所有可能有問題的策略
-- =============================================

DO $$
DECLARE
    policy_record RECORD;
BEGIN
    RAISE NOTICE '🗑️ 刪除所有 RLS 策略...';
    
    -- 動態刪除所有策略
    FOR policy_record IN 
        SELECT schemaname, tablename, policyname
        FROM pg_policies 
        WHERE schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                policy_record.policyname, 
                policy_record.schemaname, 
                policy_record.tablename);
            RAISE NOTICE '✅ 已刪除策略: %.%', policy_record.tablename, policy_record.policyname;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️ 無法刪除策略: %.% - %', policy_record.tablename, policy_record.policyname, SQLERRM;
        END;
    END LOOP;
END $$;

-- =============================================
-- 4. 重新建立基本的安全函數
-- =============================================

-- 建立最簡單的管理員檢查函數
CREATE OR REPLACE FUNCTION public.is_admin_user_simple(user_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- 使用郵件直接檢查，避免 UUID 查詢問題
    RETURN user_email IN ('admin@txn.test', 'gotoyo0004@gmail.com');
END;
$$;

-- 建立基本的用戶角色檢查
CREATE OR REPLACE FUNCTION public.get_current_user_info()
RETURNS TABLE(
    user_id UUID,
    email TEXT,
    role TEXT,
    status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY 
    SELECT 
        up.id,
        up.email,
        up.role,
        up.status
    FROM public.user_profiles up
    JOIN auth.users au ON au.id = up.id
    WHERE au.id = auth.uid()
    LIMIT 1;
END;
$$;

-- 設定函數權限
GRANT EXECUTE ON FUNCTION public.is_admin_user_simple(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_current_user_info() TO authenticated;

-- =============================================
-- 5. 建立最基本的 RLS 策略
-- =============================================

-- 只建立最基本的策略，避免複雜邏輯
CREATE POLICY "basic_user_access" ON public.user_profiles
    FOR ALL
    TO authenticated
    USING (true)  -- 暫時允許所有認證用戶訪問
    WITH CHECK (true);

-- 重新啟用 RLS (只針對 user_profiles)
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 6. 測試基本功能
-- =============================================

-- 測試基本查詢
SELECT 
    '🧪 基本查詢測試' as test_type,
    COUNT(*) as user_count
FROM public.user_profiles;

-- 測試管理員帳戶
SELECT 
    '🧪 管理員帳戶測試' as test_type,
    email,
    role,
    status
FROM public.user_profiles 
WHERE email = 'admin@txn.test';

-- 測試新函數
SELECT 
    '🧪 函數測試' as test_type,
    public.is_admin_user_simple('admin@txn.test') as is_admin_simple;

-- 測試當前用戶資訊函數
SELECT 
    '🧪 當前用戶測試' as test_type,
    user_id,
    email,
    role,
    status
FROM public.get_current_user_info();

-- =============================================
-- 7. 檢查應用程式路由問題
-- =============================================

-- 檢查是否有其他可能影響路由的問題
SELECT 
    '🔍 系統診斷' as check_type,
    'user_profiles' as table_name,
    COUNT(*) as record_count,
    MAX(updated_at) as last_update
FROM public.user_profiles;

-- =============================================
-- 8. 完成通知
-- =============================================

SELECT '🚨 緊急修復完成！' as status;
SELECT '✅ 已停用所有問題 RLS 策略' as step_1;
SELECT '✅ 建立了簡化的管理員檢查函數' as step_2;
SELECT '✅ 建立了基本的用戶訪問策略' as step_3;
SELECT '✅ 所有認證用戶現在都可以訪問資料' as step_4;

SELECT '🔄 立即測試步驟：' as next_steps;
SELECT '1. 清除瀏覽器快取 (Ctrl+Shift+R)' as step_a;
SELECT '2. 重新登入 admin@txn.test' as step_b;
SELECT '3. 測試首頁和管理員頁面' as step_c;

SELECT '⚠️ 重要提醒：' as warning;
SELECT '此修復暫時放寬了安全策略' as warning_1;
SELECT '系統恢復正常後需要重新設定適當的 RLS' as warning_2;

-- 最終狀態確認
SELECT 
    '🎊 緊急修復狀態' as final_status,
    '所有 Supabase 連接問題應已解決' as message,
    '請立即測試應用程式' as action;
