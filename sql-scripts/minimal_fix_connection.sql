-- =============================================
-- TXN 系統 - 最小化連接修復腳本
-- 版本: 1.0
-- 建立日期: 2024-12-19
-- 用途: 最簡單的方式修復首頁連接問題
-- =============================================

-- 🎯 此腳本只做必要的修復，避免語法錯誤

-- 顯示開始訊息
SELECT '🔧 開始最小化修復首頁連接問題...' as status;

-- =============================================
-- 1. 檢查當前狀態
-- =============================================

-- 檢查現有資料表
SELECT 
    '📊 現有資料表' as check_type,
    table_name
FROM information_schema.tables 
WHERE table_schema = 'public'
    AND table_name IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
ORDER BY table_name;

-- =============================================
-- 2. 建立系統健康檢查函數 (關鍵修復)
-- =============================================

-- 刪除舊版本 (如果存在)
DROP FUNCTION IF EXISTS public.check_system_health();

-- 建立新的系統健康檢查函數
CREATE FUNCTION public.check_system_health()
RETURNS TABLE(
    component TEXT,
    status TEXT,
    message TEXT
) 
LANGUAGE plpgsql 
SECURITY DEFINER
AS $$
BEGIN
    -- 基本連接測試
    RETURN QUERY SELECT 
        'database'::TEXT,
        'connected'::TEXT,
        'Database connection is working'::TEXT;
    
    -- 檢查 user_profiles 表
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') THEN
        RETURN QUERY SELECT 'user_profiles'::TEXT, 'exists'::TEXT, 'Table exists'::TEXT;
    ELSE
        RETURN QUERY SELECT 'user_profiles'::TEXT, 'missing'::TEXT, 'Table missing'::TEXT;
    END IF;
    
    -- 檢查 strategies 表
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        RETURN QUERY SELECT 'strategies'::TEXT, 'exists'::TEXT, 'Table exists'::TEXT;
    ELSE
        RETURN QUERY SELECT 'strategies'::TEXT, 'missing'::TEXT, 'Table missing'::TEXT;
    END IF;
    
    -- 檢查 trades 表
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        RETURN QUERY SELECT 'trades'::TEXT, 'exists'::TEXT, 'Table exists'::TEXT;
    ELSE
        RETURN QUERY SELECT 'trades'::TEXT, 'missing'::TEXT, 'Table missing'::TEXT;
    END IF;
    
    -- 檢查 performance_snapshots 表
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        RETURN QUERY SELECT 'performance_snapshots'::TEXT, 'exists'::TEXT, 'Table exists'::TEXT;
    ELSE
        RETURN QUERY SELECT 'performance_snapshots'::TEXT, 'missing'::TEXT, 'Table missing'::TEXT;
    END IF;
    
    RETURN;
END;
$$;

-- =============================================
-- 3. 設定函數權限 (關鍵步驟)
-- =============================================

-- 允許匿名用戶執行此函數
GRANT EXECUTE ON FUNCTION public.check_system_health() TO anon;
GRANT EXECUTE ON FUNCTION public.check_system_health() TO authenticated;

-- =============================================
-- 4. 建立版本檢查函數
-- =============================================

-- 刪除舊版本 (如果存在)
DROP FUNCTION IF EXISTS public.get_system_version();

-- 建立版本檢查函數
CREATE FUNCTION public.get_system_version()
RETURNS TABLE(
    version TEXT,
    build_date TEXT,
    status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY SELECT 
        '2.0'::TEXT,
        '2024-12-19'::TEXT,
        'operational'::TEXT;
END;
$$;

-- 設定版本函數權限
GRANT EXECUTE ON FUNCTION public.get_system_version() TO anon;
GRANT EXECUTE ON FUNCTION public.get_system_version() TO authenticated;

-- =============================================
-- 5. 測試新函數
-- =============================================

-- 測試系統健康檢查
SELECT 
    '🧪 健康檢查測試' as test_type,
    component,
    status,
    message
FROM public.check_system_health();

-- 測試版本檢查
SELECT 
    '🧪 版本檢查測試' as test_type,
    version,
    build_date,
    status
FROM public.get_system_version();

-- =============================================
-- 6. 檢查管理員帳戶 (如果存在)
-- =============================================

-- 顯示現有管理員
SELECT 
    '👥 管理員帳戶' as info_type,
    email,
    role,
    status
FROM public.user_profiles 
WHERE role IN ('super_admin', 'admin', 'moderator')
ORDER BY email;

-- =============================================
-- 7. 完成通知
-- =============================================

SELECT '🎉 最小化修復完成！' as status;
SELECT '✅ 已建立公開的系統健康檢查函數' as step_1;
SELECT '✅ 已設定匿名用戶執行權限' as step_2;
SELECT '✅ 保留所有現有資料和設定' as step_3;

SELECT '🔄 下一步操作：' as next_steps;
SELECT '1. 重新啟動應用程式 (npm run dev)' as step_a;
SELECT '2. 清除瀏覽器快取 (Ctrl+Shift+R)' as step_b;
SELECT '3. 測試首頁連接' as step_c;

SELECT '🎯 預期結果：' as expected;
SELECT '首頁應該顯示 "Supabase 基本連接成功"' as result_1;
SELECT '管理員頁面應該繼續正常工作' as result_2;

-- =============================================
-- 8. 最終驗證
-- =============================================

-- 確認函數已建立
SELECT 
    '🔍 函數建立確認' as check_type,
    proname as function_name,
    'EXISTS' as status
FROM pg_proc 
WHERE proname IN ('check_system_health', 'get_system_version')
    AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 最終狀態
SELECT 
    '🎊 修復狀態' as final_status,
    '首頁連接問題修復完成' as message,
    '請測試應用程式' as action;
