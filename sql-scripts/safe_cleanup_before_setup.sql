-- =============================================
-- TXN 系統 - 安全清理腳本
-- 版本: 1.0
-- 建立日期: 2024-12-19
-- 用途: 在執行 complete_database_setup.sql 之前安全清理現有結構
-- =============================================

-- 🎯 此腳本將安全地清理現有的資料庫結構
-- ⚠️  執行前請備份資料庫！

DO $$
BEGIN
    RAISE NOTICE '🧹 開始安全清理 TXN 資料庫結構...';
    RAISE NOTICE '⚠️  這將刪除所有現有的 TXN 相關資料！';
END $$;

-- =============================================
-- 1. 停用所有 RLS 策略
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🔓 停用 RLS 策略...';
    
    -- 停用 RLS (如果表存在)
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
END $$;

-- =============================================
-- 2. 刪除所有 RLS 策略
-- =============================================

DO $$
DECLARE
    policy_record RECORD;
BEGIN
    RAISE NOTICE '🗑️ 刪除所有 RLS 策略...';
    
    -- 動態刪除所有相關的 RLS 策略
    FOR policy_record IN 
        SELECT schemaname, tablename, policyname
        FROM pg_policies 
        WHERE schemaname = 'public'
            AND tablename IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
            policy_record.policyname, 
            policy_record.schemaname, 
            policy_record.tablename);
        RAISE NOTICE '✅ 已刪除策略: %.%', policy_record.tablename, policy_record.policyname;
    END LOOP;
END $$;

-- =============================================
-- 3. 刪除觸發器 (按正確順序)
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '⚡ 刪除觸發器...';
    
    -- 刪除 auth.users 上的觸發器
    DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
    RAISE NOTICE '✅ 已刪除 auth.users 觸發器';
    
    -- 刪除 public 表上的觸發器
    DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
    DROP TRIGGER IF EXISTS update_strategies_updated_at ON public.strategies;
    DROP TRIGGER IF EXISTS update_trades_updated_at ON public.trades;
    DROP TRIGGER IF EXISTS update_performance_snapshots_updated_at ON public.performance_snapshots;
    
    RAISE NOTICE '✅ 已刪除所有 public 表觸發器';
END $$;

-- =============================================
-- 4. 刪除函數
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🔧 刪除函數...';
    
    -- 刪除自定義函數
    DROP FUNCTION IF EXISTS public.is_admin_user_safe(UUID);
    DROP FUNCTION IF EXISTS public.handle_new_user();
    DROP FUNCTION IF EXISTS public.update_updated_at_column();
    
    -- 刪除可能存在的其他版本
    DROP FUNCTION IF EXISTS public.is_admin_user(UUID);
    DROP FUNCTION IF EXISTS public.check_admin_permission(UUID);
    
    RAISE NOTICE '✅ 已刪除所有自定義函數';
END $$;

-- =============================================
-- 5. 刪除資料表 (按依賴順序)
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🗑️ 刪除資料表...';
    
    -- 按依賴關係順序刪除表
    DROP TABLE IF EXISTS public.performance_snapshots CASCADE;
    RAISE NOTICE '✅ 已刪除 performance_snapshots 表';
    
    DROP TABLE IF EXISTS public.trades CASCADE;
    RAISE NOTICE '✅ 已刪除 trades 表';
    
    DROP TABLE IF EXISTS public.strategies CASCADE;
    RAISE NOTICE '✅ 已刪除 strategies 表';
    
    DROP TABLE IF EXISTS public.user_profiles CASCADE;
    RAISE NOTICE '✅ 已刪除 user_profiles 表';
    
    -- 刪除可能存在的其他相關表
    DROP TABLE IF EXISTS public.projects CASCADE;
    DROP TABLE IF EXISTS public.tasks CASCADE;
    DROP TABLE IF EXISTS public.activity_logs CASCADE;
    DROP TABLE IF EXISTS public.users CASCADE;
    
    RAISE NOTICE '✅ 已刪除所有相關資料表';
END $$;

-- =============================================
-- 6. 清理序列 (Sequences)
-- =============================================

DO $$
DECLARE
    seq_record RECORD;
BEGIN
    RAISE NOTICE '🔢 清理序列...';
    
    -- 查找並刪除相關的序列
    FOR seq_record IN 
        SELECT schemaname, sequencename
        FROM pg_sequences 
        WHERE schemaname = 'public'
            AND (sequencename LIKE '%user_profiles%' 
                OR sequencename LIKE '%strategies%' 
                OR sequencename LIKE '%trades%' 
                OR sequencename LIKE '%performance%')
    LOOP
        EXECUTE format('DROP SEQUENCE IF EXISTS %I.%I CASCADE', 
            seq_record.schemaname, 
            seq_record.sequencename);
        RAISE NOTICE '✅ 已刪除序列: %', seq_record.sequencename;
    END LOOP;
END $$;

-- =============================================
-- 7. 清理索引
-- =============================================

DO $$
DECLARE
    idx_record RECORD;
BEGIN
    RAISE NOTICE '📇 清理索引...';
    
    -- 查找並刪除自定義索引
    FOR idx_record IN 
        SELECT schemaname, tablename, indexname
        FROM pg_indexes 
        WHERE schemaname = 'public'
            AND indexname LIKE 'idx_%'
            AND tablename IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
    LOOP
        EXECUTE format('DROP INDEX IF EXISTS %I.%I', 
            idx_record.schemaname, 
            idx_record.indexname);
        RAISE NOTICE '✅ 已刪除索引: %', idx_record.indexname;
    END LOOP;
END $$;

-- =============================================
-- 8. 清理類型定義 (如果有)
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '📝 清理自定義類型...';
    
    -- 刪除可能存在的自定義類型
    DROP TYPE IF EXISTS public.user_role_type CASCADE;
    DROP TYPE IF EXISTS public.user_status_type CASCADE;
    DROP TYPE IF EXISTS public.trade_type_enum CASCADE;
    DROP TYPE IF EXISTS public.trade_status_enum CASCADE;
    
    RAISE NOTICE '✅ 已清理自定義類型';
END $$;

-- =============================================
-- 9. 驗證清理結果
-- =============================================

-- 檢查剩餘的相關物件
SELECT 
    '🔍 清理驗證 - 剩餘資料表' as check_type,
    COUNT(*) as remaining_tables
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots');

SELECT 
    '🔍 清理驗證 - 剩餘策略' as check_type,
    COUNT(*) as remaining_policies
FROM pg_policies 
WHERE schemaname = 'public'
    AND tablename IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots');

SELECT 
    '🔍 清理驗證 - 剩餘函數' as check_type,
    COUNT(*) as remaining_functions
FROM pg_proc 
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    AND proname IN ('is_admin_user_safe', 'update_updated_at_column', 'handle_new_user');

-- =============================================
-- 10. 完成通知
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 安全清理完成！';
    RAISE NOTICE '';
    RAISE NOTICE '✅ 已清理的項目：';
    RAISE NOTICE '- 所有 RLS 策略';
    RAISE NOTICE '- 所有觸發器';
    RAISE NOTICE '- 所有自定義函數';
    RAISE NOTICE '- 所有相關資料表';
    RAISE NOTICE '- 所有自定義索引';
    RAISE NOTICE '- 所有自定義類型';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 下一步：';
    RAISE NOTICE '1. 執行 complete_database_setup.sql 重新建立結構';
    RAISE NOTICE '2. 執行 create_admin_user.sql 建立管理員';
    RAISE NOTICE '3. 執行 system_health_check.sql 驗證設定';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  重要：請確保應用程式已停止，避免連接錯誤';
END $$;
