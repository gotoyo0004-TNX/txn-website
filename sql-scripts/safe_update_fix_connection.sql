-- =============================================
-- TXN 系統 - 安全更新修復連接問題
-- 版本: 1.0
-- 建立日期: 2024-12-19
-- 用途: 安全地修復首頁 Supabase 連接問題
-- =============================================

-- 🎯 此腳本專門解決首頁連接失敗問題
-- 不會刪除現有資料，只更新必要的設定

DO $$
BEGIN
    RAISE NOTICE '🔧 開始安全修復首頁連接問題...';
    RAISE NOTICE '📊 保留所有現有資料和設定';
END $$;

-- =============================================
-- 1. 檢查當前系統狀態
-- =============================================

-- 檢查現有資料表
SELECT 
    '📊 系統狀態檢查' as check_type,
    table_name,
    '✅ 存在' as status
FROM information_schema.tables 
WHERE table_schema = 'public'
    AND table_name IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
ORDER BY table_name;

-- 檢查現有策略
SELECT 
    '🛡️ 現有 RLS 策略' as check_type,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
    AND tablename = 'user_profiles'
ORDER BY policyname;

-- =============================================
-- 2. 建立系統健康檢查函數 (關鍵修復)
-- =============================================

-- 這個函數允許未登入用戶檢查系統狀態
CREATE OR REPLACE FUNCTION public.check_system_health()
RETURNS TABLE(
    component TEXT,
    status TEXT,
    message TEXT
) AS $$
BEGIN
    -- 基本連接測試
    RETURN QUERY SELECT 
        'database'::TEXT as component,
        'connected'::TEXT as status,
        'Database connection is working'::TEXT as message;
    
    -- 檢查各資料表存在性 (不查詢實際資料)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') THEN
        RETURN QUERY SELECT 'user_profiles'::TEXT, 'exists'::TEXT, 'Table exists and accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'user_profiles'::TEXT, 'missing'::TEXT, 'Table does not exist'::TEXT;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        RETURN QUERY SELECT 'strategies'::TEXT, 'exists'::TEXT, 'Table exists and accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'strategies'::TEXT, 'missing'::TEXT, 'Table does not exist'::TEXT;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        RETURN QUERY SELECT 'trades'::TEXT, 'exists'::TEXT, 'Table exists and accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'trades'::TEXT, 'missing'::TEXT, 'Table does not exist'::TEXT;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        RETURN QUERY SELECT 'performance_snapshots'::TEXT, 'exists'::TEXT, 'Table exists and accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'performance_snapshots'::TEXT, 'missing'::TEXT, 'Table does not exist'::TEXT;
    END IF;
    
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 🔑 關鍵：設定函數權限，允許匿名用戶執行
GRANT EXECUTE ON FUNCTION public.check_system_health() TO anon;
GRANT EXECUTE ON FUNCTION public.check_system_health() TO authenticated;

-- =============================================
-- 3. 建立版本檢查函數
-- =============================================

CREATE OR REPLACE FUNCTION public.get_system_version()
RETURNS TABLE(
    version TEXT,
    build_date TEXT,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY SELECT 
        '2.0'::TEXT as version,
        '2024-12-19'::TEXT as build_date,
        'operational'::TEXT as status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 設定版本檢查函數權限
GRANT EXECUTE ON FUNCTION public.get_system_version() TO anon;
GRANT EXECUTE ON FUNCTION public.get_system_version() TO authenticated;

-- =============================================
-- 4. 確保管理員帳戶正確 (如果存在)
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '👤 檢查管理員帳戶...';
    
    -- 檢查並更新測試管理員
    IF EXISTS (SELECT 1 FROM public.user_profiles WHERE email = 'admin@txn.test') THEN
        UPDATE public.user_profiles 
        SET 
            role = 'super_admin',
            status = 'active',
            updated_at = NOW()
        WHERE email = 'admin@txn.test';
        
        RAISE NOTICE '✅ 管理員帳戶權限已確認';
    ELSE
        RAISE NOTICE '⚠️  未找到 admin@txn.test 帳戶';
        RAISE NOTICE '💡 請在 Supabase Auth 中建立此用戶，或執行 create_admin_user.sql';
    END IF;
END $$;

-- =============================================
-- 5. 測試新功能
-- =============================================

-- 測試系統健康檢查函數
SELECT 
    '🧪 系統健康檢查測試' as test_type,
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
-- 6. 顯示當前管理員列表
-- =============================================

SELECT 
    '👥 管理員帳戶列表' as info_type,
    email,
    role,
    status,
    created_at,
    last_login_at
FROM public.user_profiles 
WHERE role IN ('super_admin', 'admin', 'moderator')
ORDER BY role, email;

-- =============================================
-- 7. 完成通知和指引
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 安全修復完成！';
    RAISE NOTICE '';
    RAISE NOTICE '✅ 修復內容：';
    RAISE NOTICE '1. 建立了公開的系統健康檢查函數';
    RAISE NOTICE '2. 允許未登入用戶進行基本連接測試';
    RAISE NOTICE '3. 確認了管理員帳戶權限';
    RAISE NOTICE '4. 保留了所有現有資料和設定';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 應用程式端需要的修改：';
    RAISE NOTICE '1. SupabaseTest 元件已更新使用新的檢查函數';
    RAISE NOTICE '2. 區分登入和未登入狀態的測試方式';
    RAISE NOTICE '';
    RAISE NOTICE '📋 測試步驟：';
    RAISE NOTICE '1. 重新啟動開發伺服器 (如果在本地)';
    RAISE NOTICE '2. 清除瀏覽器快取 (Ctrl+Shift+R)';
    RAISE NOTICE '3. 訪問首頁 - 應該顯示連接成功';
    RAISE NOTICE '4. 訪問 /admin - 應該正常工作';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 預期結果：';
    RAISE NOTICE '- 首頁：Supabase 基本連接成功';
    RAISE NOTICE '- 管理頁：admin@txn.test 正常登入';
END $$;

-- =============================================
-- 8. 最終驗證
-- =============================================

-- 確認函數權限設定
SELECT 
    '🔐 函數權限檢查' as check_type,
    proname as function_name,
    proacl as permissions,
    CASE 
        WHEN 'anon=X' = ANY(string_to_array(proacl::text, ',')) THEN '✅ 允許匿名用戶'
        WHEN proacl IS NULL THEN '✅ 公開函數'
        ELSE '⚠️ 權限受限'
    END as access_status
FROM pg_proc 
WHERE proname IN ('check_system_health', 'get_system_version')
    AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 最終成功確認
SELECT 
    '🎊 修復完成確認' as final_status,
    '首頁連接問題應已解決' as message,
    '請重新啟動應用程式並測試' as next_action;
