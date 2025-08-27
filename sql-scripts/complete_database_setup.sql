-- =============================================
-- TXN 交易日誌系統 - 完整資料庫設定腳本
-- 版本: 2.0
-- 建立日期: 2024-12-19
-- =============================================

-- 🎯 此腳本將完成以下設定：
-- 1. 建立所有必要的資料表
-- 2. 設定 RLS (Row Level Security) 安全策略
-- 3. 建立必要的函數和觸發器
-- 4. 插入初始資料
-- 5. 建立管理員帳戶

DO $$
BEGIN
    RAISE NOTICE '🚀 開始 TXN 資料庫完整設定...';
END $$;

-- =============================================
-- 1. 檢查前置條件
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🔍 檢查系統狀態...';

    -- 檢查是否已有資料表存在
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_profiles' AND table_schema = 'public') THEN
        RAISE NOTICE '⚠️  發現現有的 user_profiles 表';
        RAISE NOTICE '💡 建議：如需清理現有結構，請先執行 safe_cleanup_before_setup.sql';
    ELSE
        RAISE NOTICE '✅ 未發現現有資料表，可以安全建立';
    END IF;
END $$;

-- =============================================
-- 2. 建立資料表結構
-- =============================================

-- 用戶資料表
CREATE TABLE public.user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'moderator', 'admin', 'super_admin')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'suspended', 'banned')),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    last_login_at TIMESTAMPTZ,
    preferences JSONB DEFAULT '{}' NOT NULL,
    metadata JSONB DEFAULT '{}' NOT NULL
);

-- 交易策略表
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

-- 交易記錄表
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

-- 績效快照表
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

-- =============================================
-- 3. 建立索引以提升效能
-- =============================================

CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX idx_user_profiles_status ON public.user_profiles(status);

CREATE INDEX idx_strategies_user_id ON public.strategies(user_id);
CREATE INDEX idx_strategies_is_active ON public.strategies(is_active);

CREATE INDEX idx_trades_user_id ON public.trades(user_id);
CREATE INDEX idx_trades_strategy_id ON public.trades(strategy_id);
CREATE INDEX idx_trades_symbol ON public.trades(symbol);
CREATE INDEX idx_trades_status ON public.trades(status);
CREATE INDEX idx_trades_entry_date ON public.trades(entry_date);

CREATE INDEX idx_performance_snapshots_user_id ON public.performance_snapshots(user_id);
CREATE INDEX idx_performance_snapshots_date ON public.performance_snapshots(snapshot_date);

-- =============================================
-- 4. 建立觸發器以自動更新時間戳
-- =============================================

-- 更新時間戳函數
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 為各表建立觸發器
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_strategies_updated_at
    BEFORE UPDATE ON public.strategies
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_trades_updated_at
    BEFORE UPDATE ON public.trades
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- =============================================
-- 5. 建立 RLS 安全策略
-- =============================================

-- 啟用 RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.strategies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_snapshots ENABLE ROW LEVEL SECURITY;

-- 建立安全的管理員檢查函數
CREATE OR REPLACE FUNCTION public.is_admin_user_safe(user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    user_role TEXT;
    user_status TEXT;
BEGIN
    -- 使用 security definer 權限直接查詢，避免 RLS 遞歸
    SELECT role, status INTO user_role, user_status
    FROM public.user_profiles 
    WHERE id = user_id;
    
    -- 如果找不到用戶，返回 false
    IF user_role IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- 檢查是否為活躍的管理員
    RETURN (user_role IN ('admin', 'super_admin', 'moderator') AND user_status = 'active');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 用戶資料表策略
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

-- 策略表策略
CREATE POLICY "strategies_user_access" ON public.strategies
    FOR ALL 
    TO authenticated
    USING (user_id = auth.uid() OR is_admin_user_safe(auth.uid()))
    WITH CHECK (user_id = auth.uid() OR is_admin_user_safe(auth.uid()));

-- 交易記錄表策略
CREATE POLICY "trades_user_access" ON public.trades
    FOR ALL 
    TO authenticated
    USING (user_id = auth.uid() OR is_admin_user_safe(auth.uid()))
    WITH CHECK (user_id = auth.uid() OR is_admin_user_safe(auth.uid()));

-- 績效快照表策略
CREATE POLICY "performance_user_access" ON public.performance_snapshots
    FOR ALL 
    TO authenticated
    USING (user_id = auth.uid() OR is_admin_user_safe(auth.uid()))
    WITH CHECK (user_id = auth.uid() OR is_admin_user_safe(auth.uid()));

-- =============================================
-- 6. 建立自動處理新用戶的函數
-- =============================================

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
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 建立觸發器，當新用戶註冊時自動建立 profile
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- 7. 插入初始資料
-- =============================================

-- 插入範例策略類別 (可選)
-- 這些將在用戶建立策略時作為選項

-- =============================================
-- 8. 完成通知
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '✅ TXN 資料庫設定完成！';
    RAISE NOTICE '📊 已建立資料表：user_profiles, strategies, trades, performance_snapshots';
    RAISE NOTICE '🛡️ RLS 安全策略已啟用';
    RAISE NOTICE '⚡ 觸發器和函數已建立';
    RAISE NOTICE '🔄 下一步：執行 create_admin_user.sql 建立管理員帳戶';
END $$;

-- 顯示建立的資料表
SELECT 
    '📋 已建立的資料表' as section,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
    AND table_name IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
ORDER BY table_name;

-- 顯示 RLS 策略
SELECT 
    '🛡️ RLS 策略' as section,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
