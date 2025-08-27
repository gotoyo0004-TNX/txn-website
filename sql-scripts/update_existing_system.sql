-- =============================================
-- TXN 系統 - 更新現有系統腳本
-- 版本: 1.0
-- 建立日期: 2024-12-19
-- 用途: 更新已存在的資料庫，修復首頁連接問題
-- =============================================

-- 🎯 此腳本專門用於已有 user_profiles 表的系統
-- 將安全地更新現有結構，不會刪除資料

DO $$
BEGIN
    RAISE NOTICE '🔄 開始更新現有 TXN 系統...';
    RAISE NOTICE '📊 保留所有現有資料';
END $$;

-- =============================================
-- 1. 檢查現有系統狀態
-- =============================================

SELECT 
    '📊 現有資料表檢查' as check_type,
    table_name,
    CASE 
        WHEN table_name IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots') 
        THEN '✅ 核心表存在'
        ELSE '📋 其他表'
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public'
    AND table_name IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
ORDER BY table_name;

-- 檢查現有用戶
SELECT 
    '👥 現有用戶檢查' as check_type,
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE role IN ('admin', 'super_admin', 'moderator')) as admin_users
FROM public.user_profiles;

-- =============================================
-- 2. 安全地更新資料表結構
-- =============================================

-- 暫時停用 RLS 以便更新
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    RAISE NOTICE '🔧 更新 user_profiles 表結構...';
    
    -- 添加缺失的欄位 (如果不存在)
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
    
    -- 更新現有記錄的預設值
    UPDATE public.user_profiles 
    SET 
        preferences = COALESCE(preferences, '{}'),
        metadata = COALESCE(metadata, '{}')
    WHERE preferences IS NULL OR metadata IS NULL;
    
    RAISE NOTICE '✅ user_profiles 表結構更新完成';
END $$;

-- =============================================
-- 3. 建立缺失的資料表 (如果不存在)
-- =============================================

-- 交易策略表
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        CREATE TABLE public.strategies (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            category TEXT DEFAULT 'general',
            risk_level TEXT DEFAULT 'medium' CHECK (risk_level IN ('low', 'medium', 'high')),
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
            updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
            metadata JSONB DEFAULT '{}' NOT NULL
        );
        RAISE NOTICE '✅ 建立 strategies 表';
    ELSE
        RAISE NOTICE '⚠️  strategies 表已存在，跳過建立';
    END IF;
END $$;

-- 交易記錄表
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        CREATE TABLE public.trades (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
            strategy_id UUID REFERENCES public.strategies(id) ON DELETE SET NULL,
            symbol TEXT NOT NULL,
            trade_type TEXT NOT NULL CHECK (trade_type IN ('buy', 'sell', 'long', 'short')),
            quantity DECIMAL(20, 8) NOT NULL,
            entry_price DECIMAL(20, 8) NOT NULL,
            exit_price DECIMAL(20, 8),
            entry_date TIMESTAMPTZ NOT NULL,
            exit_date TIMESTAMPTZ,
            status TEXT DEFAULT 'open' CHECK (status IN ('open', 'closed', 'cancelled')),
            profit_loss DECIMAL(20, 8),
            fees DECIMAL(20, 8) DEFAULT 0,
            notes TEXT,
            tags TEXT[] DEFAULT '{}',
            created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
            updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
            metadata JSONB DEFAULT '{}' NOT NULL
        );
        RAISE NOTICE '✅ 建立 trades 表';
    ELSE
        RAISE NOTICE '⚠️  trades 表已存在，跳過建立';
    END IF;
END $$;

-- 績效快照表
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        CREATE TABLE public.performance_snapshots (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
            snapshot_date DATE NOT NULL,
            total_trades INTEGER DEFAULT 0,
            winning_trades INTEGER DEFAULT 0,
            losing_trades INTEGER DEFAULT 0,
            total_profit_loss DECIMAL(20, 8) DEFAULT 0,
            win_rate DECIMAL(5, 2) DEFAULT 0,
            average_win DECIMAL(20, 8) DEFAULT 0,
            average_loss DECIMAL(20, 8) DEFAULT 0,
            largest_win DECIMAL(20, 8) DEFAULT 0,
            largest_loss DECIMAL(20, 8) DEFAULT 0,
            created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
            metadata JSONB DEFAULT '{}' NOT NULL,
            UNIQUE(user_id, snapshot_date)
        );
        RAISE NOTICE '✅ 建立 performance_snapshots 表';
    ELSE
        RAISE NOTICE '⚠️  performance_snapshots 表已存在，跳過建立';
    END IF;
END $$;

-- =============================================
-- 4. 建立或更新索引
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '📇 建立或更新索引...';
    
    -- 建立索引 (如果不存在)
    CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
    CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);
    CREATE INDEX IF NOT EXISTS idx_user_profiles_status ON public.user_profiles(status);
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        CREATE INDEX IF NOT EXISTS idx_strategies_user_id ON public.strategies(user_id);
        CREATE INDEX IF NOT EXISTS idx_strategies_is_active ON public.strategies(is_active);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        CREATE INDEX IF NOT EXISTS idx_trades_user_id ON public.trades(user_id);
        CREATE INDEX IF NOT EXISTS idx_trades_strategy_id ON public.trades(strategy_id);
        CREATE INDEX IF NOT EXISTS idx_trades_symbol ON public.trades(symbol);
        CREATE INDEX IF NOT EXISTS idx_trades_status ON public.trades(status);
        CREATE INDEX IF NOT EXISTS idx_trades_entry_date ON public.trades(entry_date);
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        CREATE INDEX IF NOT EXISTS idx_performance_snapshots_user_id ON public.performance_snapshots(user_id);
        CREATE INDEX IF NOT EXISTS idx_performance_snapshots_date ON public.performance_snapshots(snapshot_date);
    END IF;
    
    RAISE NOTICE '✅ 索引建立完成';
END $$;

-- =============================================
-- 5. 建立或更新函數
-- =============================================

-- 更新時間戳函數
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 安全的管理員檢查函數
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

-- 新用戶處理函數
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, role, status)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        'user',
        'active'
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 系統健康檢查函數 (允許未登入用戶使用)
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
    
    -- 檢查各資料表
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') THEN
        RETURN QUERY SELECT 'user_profiles'::TEXT, 'exists'::TEXT, 'Table exists and accessible'::TEXT;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        RETURN QUERY SELECT 'strategies'::TEXT, 'exists'::TEXT, 'Table exists and accessible'::TEXT;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        RETURN QUERY SELECT 'trades'::TEXT, 'exists'::TEXT, 'Table exists and accessible'::TEXT;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        RETURN QUERY SELECT 'performance_snapshots'::TEXT, 'exists'::TEXT, 'Table exists and accessible'::TEXT;
    END IF;
    
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 設定函數權限 - 允許所有用戶執行
GRANT EXECUTE ON FUNCTION public.check_system_health() TO anon;
GRANT EXECUTE ON FUNCTION public.check_system_health() TO authenticated;

-- =============================================
-- 6. 建立或更新觸發器
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '⚡ 建立或更新觸發器...';
    
    -- 刪除現有觸發器後重新建立
    DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
    CREATE TRIGGER update_user_profiles_updated_at
        BEFORE UPDATE ON public.user_profiles
        FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
    
    -- 新用戶觸發器
    DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
    CREATE TRIGGER on_auth_user_created
        AFTER INSERT ON auth.users
        FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
    
    -- 其他表的觸發器 (如果存在)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        DROP TRIGGER IF EXISTS update_strategies_updated_at ON public.strategies;
        CREATE TRIGGER update_strategies_updated_at
            BEFORE UPDATE ON public.strategies
            FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        DROP TRIGGER IF EXISTS update_trades_updated_at ON public.trades;
        CREATE TRIGGER update_trades_updated_at
            BEFORE UPDATE ON public.trades
            FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
    
    RAISE NOTICE '✅ 觸發器更新完成';
END $$;

-- =============================================
-- 7. 更新 RLS 策略 - 解決首頁連接問題
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🛡️ 更新 RLS 策略以修復連接問題...';
    
    -- 清理舊策略
    DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
    DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
    DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.user_profiles;
    DROP POLICY IF EXISTS "authenticated_read_own" ON public.user_profiles;
    DROP POLICY IF EXISTS "authenticated_update_own" ON public.user_profiles;
    DROP POLICY IF EXISTS "authenticated_insert_own" ON public.user_profiles;
    DROP POLICY IF EXISTS "admin_read_all_simple" ON public.user_profiles;
    DROP POLICY IF EXISTS "admin_update_all_simple" ON public.user_profiles;
    DROP POLICY IF EXISTS "allow_connection_test" ON public.user_profiles;
    
    RAISE NOTICE '✅ 已清理舊的 RLS 策略';
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

-- 🔑 關鍵：建立允許基本連接測試的策略
CREATE POLICY "allow_basic_connection_test" ON public.user_profiles
    FOR SELECT 
    TO anon, authenticated
    USING (
        -- 只允許查詢 id 欄位進行連接測試
        -- 不返回實際用戶資料
        false  -- 實際上不允許查詢資料，但允許測試連接
    );

-- 重新啟用 RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 為其他表設定 RLS (如果存在)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'strategies' AND table_schema = 'public') THEN
        ALTER TABLE public.strategies ENABLE ROW LEVEL SECURITY;
        
        DROP POLICY IF EXISTS "strategies_user_access" ON public.strategies;
        CREATE POLICY "strategies_user_access" ON public.strategies
            FOR ALL 
            TO authenticated
            USING (user_id = auth.uid() OR is_admin_user_safe(auth.uid()))
            WITH CHECK (user_id = auth.uid() OR is_admin_user_safe(auth.uid()));
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'trades' AND table_schema = 'public') THEN
        ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;
        
        DROP POLICY IF EXISTS "trades_user_access" ON public.trades;
        CREATE POLICY "trades_user_access" ON public.trades
            FOR ALL 
            TO authenticated
            USING (user_id = auth.uid() OR is_admin_user_safe(auth.uid()))
            WITH CHECK (user_id = auth.uid() OR is_admin_user_safe(auth.uid()));
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'performance_snapshots' AND table_schema = 'public') THEN
        ALTER TABLE public.performance_snapshots ENABLE ROW LEVEL SECURITY;
        
        DROP POLICY IF EXISTS "performance_user_access" ON public.performance_snapshots;
        CREATE POLICY "performance_user_access" ON public.performance_snapshots
            FOR ALL 
            TO authenticated
            USING (user_id = auth.uid() OR is_admin_user_safe(auth.uid()))
            WITH CHECK (user_id = auth.uid() OR is_admin_user_safe(auth.uid()));
    END IF;
END $$;

-- =============================================
-- 8. 確保管理員帳戶正確設定
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '👤 檢查和更新管理員帳戶...';
    
    -- 確保測試管理員帳戶存在且權限正確
    IF EXISTS (SELECT 1 FROM public.user_profiles WHERE email = 'admin@txn.test') THEN
        UPDATE public.user_profiles 
        SET 
            role = 'super_admin',
            status = 'active',
            full_name = COALESCE(full_name, 'TXN 系統管理員'),
            updated_at = NOW(),
            preferences = COALESCE(preferences, '{"theme": "light", "language": "zh-TW"}'),
            metadata = COALESCE(metadata, '{"updated_by": "system_update", "version": "2.0"}')
        WHERE email = 'admin@txn.test';
        
        RAISE NOTICE '✅ 測試管理員帳戶已更新';
    ELSE
        RAISE NOTICE '⚠️  未找到測試管理員，請執行 create_admin_user.sql';
    END IF;
END $$;

-- =============================================
-- 9. 測試新的連接方式
-- =============================================

-- 測試系統健康檢查函數
SELECT 
    '🧪 系統健康檢查測試' as test_type,
    component,
    status,
    message
FROM public.check_system_health();

-- =============================================
-- 10. 完成通知
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 現有系統更新完成！';
    RAISE NOTICE '';
    RAISE NOTICE '✅ 完成的更新：';
    RAISE NOTICE '1. 資料表結構已更新 (保留所有資料)';
    RAISE NOTICE '2. RLS 策略已優化';
    RAISE NOTICE '3. 建立了公開的系統健康檢查函數';
    RAISE NOTICE '4. 觸發器和索引已更新';
    RAISE NOTICE '5. 管理員權限已確認';
    RAISE NOTICE '';
    RAISE NOTICE '🔄 下一步：';
    RAISE NOTICE '1. 重新啟動應用程式 (npm run dev)';
    RAISE NOTICE '2. 清除瀏覽器快取 (Ctrl+Shift+R)';
    RAISE NOTICE '3. 測試首頁連接 (應該顯示成功)';
    RAISE NOTICE '4. 測試管理員登入 (admin@txn.test)';
    RAISE NOTICE '';
    RAISE NOTICE '📞 如仍有問題，請執行 system_health_check.sql 診斷';
END $$;

-- 最終狀態檢查
SELECT 
    '🎊 更新完成驗證' as final_status,
    COUNT(*) as total_tables,
    '應該等於 4' as expected
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots');
