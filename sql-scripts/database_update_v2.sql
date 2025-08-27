-- =============================================
-- TXN 系統 - 資料庫更新腳本 v2.0
-- 建立日期: 2024-12-19
-- 用途: 將現有資料庫升級到最新版本
-- =============================================

-- 🎯 此腳本適用於已有資料庫的系統升級
-- ⚠️  執行前請備份資料庫！

DO $$
BEGIN
    RAISE NOTICE '🔄 開始 TXN 資料庫升級到 v2.0...';
END $$;

-- =============================================
-- 1. 備份提醒和版本檢查
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '⚠️  重要提醒：';
    RAISE NOTICE '1. 請確保已備份資料庫';
    RAISE NOTICE '2. 建議在維護時間執行此腳本';
    RAISE NOTICE '3. 執行過程中可能會短暫影響服務';
    RAISE NOTICE '';
    RAISE NOTICE '🔍 檢查現有資料表...';
END $$;

-- 檢查現有資料表
SELECT 
    '📊 現有資料表' as section,
    table_name,
    CASE 
        WHEN table_name IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots') 
        THEN '✅ 核心表'
        ELSE '📋 其他表'
    END as table_type
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- =============================================
-- 2. 安全地更新資料表結構
-- =============================================

-- 暫時停用 RLS 以便進行結構更新
DO $$
BEGIN
    -- 檢查並停用 RLS
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') THEN
        ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 已暫時停用 user_profiles RLS';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        ALTER TABLE public.strategies DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 已暫時停用 strategies RLS';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        ALTER TABLE public.trades DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 已暫時停用 trades RLS';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        ALTER TABLE public.performance_snapshots DISABLE ROW LEVEL SECURITY;
        RAISE NOTICE '🔓 已暫時停用 performance_snapshots RLS';
    END IF;
END $$;

-- =============================================
-- 3. 更新 user_profiles 表結構
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '👤 更新 user_profiles 表結構...';
    
    -- 添加新欄位 (如果不存在)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'last_login_at') THEN
        ALTER TABLE public.user_profiles ADD COLUMN last_login_at TIMESTAMPTZ;
        RAISE NOTICE '✅ 添加 last_login_at 欄位';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'preferences') THEN
        ALTER TABLE public.user_profiles ADD COLUMN preferences JSONB DEFAULT '{}' NOT NULL;
        RAISE NOTICE '✅ 添加 preferences 欄位';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_profiles' AND column_name = 'metadata') THEN
        ALTER TABLE public.user_profiles ADD COLUMN metadata JSONB DEFAULT '{}' NOT NULL;
        RAISE NOTICE '✅ 添加 metadata 欄位';
    END IF;
    
    -- 更新角色約束 (如果需要)
    BEGIN
        ALTER TABLE public.user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_check;
        ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_role_check 
            CHECK (role IN ('user', 'moderator', 'admin', 'super_admin'));
        RAISE NOTICE '✅ 更新角色約束';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  角色約束更新失敗，可能已存在: %', SQLERRM;
    END;
    
    -- 更新狀態約束 (如果需要)
    BEGIN
        ALTER TABLE public.user_profiles DROP CONSTRAINT IF EXISTS user_profiles_status_check;
        ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_status_check 
            CHECK (status IN ('pending', 'active', 'suspended', 'banned'));
        RAISE NOTICE '✅ 更新狀態約束';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  狀態約束更新失敗，可能已存在: %', SQLERRM;
    END;
END $$;

-- =============================================
-- 4. 更新其他表結構
-- =============================================

-- 更新 strategies 表
DO $$
BEGIN
    RAISE NOTICE '🎯 更新 strategies 表結構...';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        -- 添加 metadata 欄位 (如果不存在)
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'strategies' AND column_name = 'metadata') THEN
            ALTER TABLE public.strategies ADD COLUMN metadata JSONB DEFAULT '{}' NOT NULL;
            RAISE NOTICE '✅ strategies 表添加 metadata 欄位';
        END IF;
    END IF;
END $$;

-- 更新 trades 表
DO $$
BEGIN
    RAISE NOTICE '💰 更新 trades 表結構...';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        -- 添加 tags 欄位 (如果不存在)
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'trades' AND column_name = 'tags') THEN
            ALTER TABLE public.trades ADD COLUMN tags TEXT[] DEFAULT '{}';
            RAISE NOTICE '✅ trades 表添加 tags 欄位';
        END IF;
        
        -- 添加 metadata 欄位 (如果不存在)
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'trades' AND column_name = 'metadata') THEN
            ALTER TABLE public.trades ADD COLUMN metadata JSONB DEFAULT '{}' NOT NULL;
            RAISE NOTICE '✅ trades 表添加 metadata 欄位';
        END IF;
    END IF;
END $$;

-- =============================================
-- 5. 更新或建立索引
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '📇 更新資料庫索引...';
    
    -- 建立索引 (如果不存在)
    BEGIN
        CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
        CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);
        CREATE INDEX IF NOT EXISTS idx_user_profiles_status ON public.user_profiles(status);
        RAISE NOTICE '✅ user_profiles 索引已更新';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '⚠️  user_profiles 索引更新失敗: %', SQLERRM;
    END;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        BEGIN
            CREATE INDEX IF NOT EXISTS idx_strategies_user_id ON public.strategies(user_id);
            CREATE INDEX IF NOT EXISTS idx_strategies_is_active ON public.strategies(is_active);
            RAISE NOTICE '✅ strategies 索引已更新';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️  strategies 索引更新失敗: %', SQLERRM;
        END;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        BEGIN
            CREATE INDEX IF NOT EXISTS idx_trades_user_id ON public.trades(user_id);
            CREATE INDEX IF NOT EXISTS idx_trades_symbol ON public.trades(symbol);
            CREATE INDEX IF NOT EXISTS idx_trades_status ON public.trades(status);
            CREATE INDEX IF NOT EXISTS idx_trades_entry_date ON public.trades(entry_date);
            RAISE NOTICE '✅ trades 索引已更新';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️  trades 索引更新失敗: %', SQLERRM;
        END;
    END IF;
END $$;

-- =============================================
-- 6. 更新觸發器和函數
-- =============================================

-- 更新時間戳函數
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 重新建立觸發器
DO $$
BEGIN
    RAISE NOTICE '⚡ 更新觸發器...';
    
    -- user_profiles 觸發器
    DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
    CREATE TRIGGER update_user_profiles_updated_at
        BEFORE UPDATE ON public.user_profiles
        FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
    
    -- strategies 觸發器 (如果表存在)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        DROP TRIGGER IF EXISTS update_strategies_updated_at ON public.strategies;
        CREATE TRIGGER update_strategies_updated_at
            BEFORE UPDATE ON public.strategies
            FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
    
    -- trades 觸發器 (如果表存在)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        DROP TRIGGER IF EXISTS update_trades_updated_at ON public.trades;
        CREATE TRIGGER update_trades_updated_at
            BEFORE UPDATE ON public.trades
            FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
    
    RAISE NOTICE '✅ 觸發器更新完成';
END $$;

-- =============================================
-- 7. 清理舊的 RLS 策略並建立新的
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🛡️ 更新 RLS 安全策略...';
    
    -- 清理舊策略
    DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
    DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
    DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.user_profiles;
    DROP POLICY IF EXISTS "authenticated_read_own" ON public.user_profiles;
    DROP POLICY IF EXISTS "authenticated_update_own" ON public.user_profiles;
    DROP POLICY IF EXISTS "authenticated_insert_own" ON public.user_profiles;
    DROP POLICY IF EXISTS "admin_read_all_simple" ON public.user_profiles;
    DROP POLICY IF EXISTS "admin_update_all_simple" ON public.user_profiles;
    
    -- 建立或更新安全函數
    CREATE OR REPLACE FUNCTION public.is_admin_user_safe(user_id UUID)
    RETURNS BOOLEAN AS $$
    DECLARE
        user_role TEXT;
        user_status TEXT;
    BEGIN
        SELECT role, status INTO user_role, user_status
        FROM public.user_profiles 
        WHERE id = user_id;
        
        IF user_role IS NULL THEN
            RETURN FALSE;
        END IF;
        
        RETURN (user_role IN ('admin', 'super_admin', 'moderator') AND user_status = 'active');
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER STABLE;
    
    RAISE NOTICE '✅ 安全函數已更新';
END $$;

-- 建立新的 RLS 策略
CREATE POLICY "users_read_own" ON public.user_profiles
    FOR SELECT 
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "users_update_own" ON public.user_profiles
    FOR UPDATE 
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "users_insert_own" ON public.user_profiles
    FOR INSERT 
    TO authenticated
    WITH CHECK (auth.uid() = id);

CREATE POLICY "admin_full_access_users" ON public.user_profiles
    FOR ALL 
    TO authenticated
    USING (is_admin_user_safe(auth.uid()))
    WITH CHECK (is_admin_user_safe(auth.uid()));

-- 為其他表建立策略 (如果存在)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        DROP POLICY IF EXISTS "strategies_user_access" ON public.strategies;
        CREATE POLICY "strategies_user_access" ON public.strategies
            FOR ALL 
            TO authenticated
            USING (user_id = auth.uid() OR is_admin_user_safe(auth.uid()))
            WITH CHECK (user_id = auth.uid() OR is_admin_user_safe(auth.uid()));
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        DROP POLICY IF EXISTS "trades_user_access" ON public.trades;
        CREATE POLICY "trades_user_access" ON public.trades
            FOR ALL 
            TO authenticated
            USING (user_id = auth.uid() OR is_admin_user_safe(auth.uid()))
            WITH CHECK (user_id = auth.uid() OR is_admin_user_safe(auth.uid()));
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        DROP POLICY IF EXISTS "performance_user_access" ON public.performance_snapshots;
        CREATE POLICY "performance_user_access" ON public.performance_snapshots
            FOR ALL 
            TO authenticated
            USING (user_id = auth.uid() OR is_admin_user_safe(auth.uid()))
            WITH CHECK (user_id = auth.uid() OR is_admin_user_safe(auth.uid()));
    END IF;
END $$;

-- =============================================
-- 8. 重新啟用 RLS
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🔒 重新啟用 RLS 安全策略...';
    
    ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        ALTER TABLE public.strategies ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        ALTER TABLE public.performance_snapshots ENABLE ROW LEVEL SECURITY;
    END IF;
    
    RAISE NOTICE '✅ RLS 已重新啟用';
END $$;

-- =============================================
-- 9. 更新完成驗證
-- =============================================

-- 顯示更新後的資料表結構
SELECT 
    '📊 更新後的資料表' as section,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
ORDER BY table_name, ordinal_position;

-- 顯示 RLS 策略
SELECT 
    '🛡️ 更新後的 RLS 策略' as section,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- =============================================
-- 10. 完成通知
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🎉 TXN 資料庫升級到 v2.0 完成！';
    RAISE NOTICE '';
    RAISE NOTICE '✅ 完成的更新：';
    RAISE NOTICE '- 資料表結構已更新';
    RAISE NOTICE '- 索引已優化';
    RAISE NOTICE '- RLS 安全策略已更新';
    RAISE NOTICE '- 觸發器和函數已更新';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 建議的後續步驟：';
    RAISE NOTICE '1. 重新啟動應用程式';
    RAISE NOTICE '2. 清除瀏覽器快取';
    RAISE NOTICE '3. 測試所有功能';
    RAISE NOTICE '4. 監控系統效能';
    RAISE NOTICE '';
    RAISE NOTICE '📞 如有問題，請檢查應用程式日誌';
END $$;
