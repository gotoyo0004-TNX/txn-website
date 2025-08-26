-- =============================================
-- TXN 專案 Supabase 完整更新腳本
-- 版本：2.0
-- 日期：2025-08-26
-- =============================================

-- 💡 使用指南：
-- 1. 在 Supabase SQL 編輯器中執行此腳本
-- 2. 確保依序執行，不要跳過步驟
-- 3. 執行完成後測試前端連接

DO $$
BEGIN
    RAISE NOTICE '🚀 開始 TXN 專案 Supabase 完整更新...';
    RAISE NOTICE '⏰ 更新時間: %', NOW();
END $$;

-- =============================================
-- 1. 確保基本資料表存在
-- =============================================

-- 用戶資料表
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('user', 'admin', 'super_admin', 'moderator')),
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'suspended', 'deleted')),
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE,
    last_login_at TIMESTAMP WITH TIME ZONE
);

-- 交易策略表
CREATE TABLE IF NOT EXISTS public.strategies (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'high')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- 交易記錄表
CREATE TABLE IF NOT EXISTS public.trades (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    strategy_id UUID REFERENCES public.strategies(id) ON DELETE SET NULL,
    symbol VARCHAR(50) NOT NULL,
    side VARCHAR(10) CHECK (side IN ('long', 'short')) NOT NULL,
    entry_price DECIMAL(15, 8) NOT NULL,
    exit_price DECIMAL(15, 8),
    quantity DECIMAL(15, 8) NOT NULL,
    entry_date TIMESTAMP WITH TIME ZONE NOT NULL,
    exit_date TIMESTAMP WITH TIME ZONE,
    pnl DECIMAL(15, 8),
    fees DECIMAL(15, 8) DEFAULT 0,
    notes TEXT,
    screenshot_url TEXT,
    status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'closed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 績效快照表
CREATE TABLE IF NOT EXISTS public.performance_snapshots (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    snapshot_date DATE NOT NULL,
    total_trades INTEGER DEFAULT 0,
    winning_trades INTEGER DEFAULT 0,
    losing_trades INTEGER DEFAULT 0,
    total_pnl DECIMAL(15, 8) DEFAULT 0,
    win_rate DECIMAL(5, 4) DEFAULT 0,
    profit_factor DECIMAL(10, 4) DEFAULT 0,
    max_drawdown DECIMAL(10, 4) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, snapshot_date)
);

DO $$
BEGIN
    RAISE NOTICE '✅ 資料表結構檢查完成';
END $$;

-- =============================================
-- 2. 創建索引以提升性能
-- =============================================

-- 用戶資料表索引
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_status ON public.user_profiles(status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_created_at ON public.user_profiles(created_at);

-- 策略表索引
CREATE INDEX IF NOT EXISTS idx_strategies_user_id ON public.strategies(user_id);
CREATE INDEX IF NOT EXISTS idx_strategies_is_active ON public.strategies(is_active);

-- 交易記錄表索引
CREATE INDEX IF NOT EXISTS idx_trades_user_id ON public.trades(user_id);
CREATE INDEX IF NOT EXISTS idx_trades_strategy_id ON public.trades(strategy_id);
CREATE INDEX IF NOT EXISTS idx_trades_symbol ON public.trades(symbol);
CREATE INDEX IF NOT EXISTS idx_trades_entry_date ON public.trades(entry_date);
CREATE INDEX IF NOT EXISTS idx_trades_status ON public.trades(status);

-- 績效快照表索引
CREATE INDEX IF NOT EXISTS idx_performance_snapshots_user_id ON public.performance_snapshots(user_id);
CREATE INDEX IF NOT EXISTS idx_performance_snapshots_date ON public.performance_snapshots(snapshot_date);

DO $$
BEGIN
    RAISE NOTICE '✅ 索引創建完成';
END $$;

-- =============================================
-- 3. 清理並重建 RLS 策略
-- =============================================

-- 暫時禁用所有表的 RLS
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.strategies DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.trades DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_snapshots DISABLE ROW LEVEL SECURITY;

-- 清理所有現有策略
DO $$
DECLARE
    r RECORD;
BEGIN
    -- 清理 user_profiles 的所有策略
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'user_profiles') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON public.user_profiles';
    END LOOP;
    
    -- 清理 strategies 的所有策略
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'strategies') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON public.strategies';
    END LOOP;
    
    -- 清理 trades 的所有策略
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'trades') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON public.trades';
    END LOOP;
    
    -- 清理 performance_snapshots 的所有策略
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'performance_snapshots') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON public.performance_snapshots';
    END LOOP;
    
    RAISE NOTICE '🧹 所有舊的 RLS 策略已清理';
END $$;

-- =============================================
-- 4. 創建安全的 RLS 策略
-- =============================================

-- user_profiles 表策略
CREATE POLICY "users_can_view_all_profiles" ON public.user_profiles
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "users_can_update_own_profile" ON public.user_profiles
    FOR UPDATE TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "users_can_insert_own_profile" ON public.user_profiles
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = id);

-- strategies 表策略
CREATE POLICY "users_manage_own_strategies" ON public.strategies
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- trades 表策略
CREATE POLICY "users_manage_own_trades" ON public.trades
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- performance_snapshots 表策略
CREATE POLICY "users_manage_own_performance" ON public.performance_snapshots
    FOR ALL TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 重新啟用 RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.strategies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_snapshots ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    RAISE NOTICE '🛡️ RLS 策略重建完成';
END $$;

-- =============================================
-- 5. 創建或更新觸發器
-- =============================================

-- 更新 updated_at 的觸發器函數
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 為各表添加更新時間觸發器
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_strategies_updated_at ON public.strategies;
CREATE TRIGGER update_strategies_updated_at
    BEFORE UPDATE ON public.strategies
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_trades_updated_at ON public.trades;
CREATE TRIGGER update_trades_updated_at
    BEFORE UPDATE ON public.trades
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 計算交易損益的觸發器
CREATE OR REPLACE FUNCTION public.calculate_trade_pnl()
RETURNS TRIGGER AS $$
BEGIN
    -- 只有在交易關閉時才計算 PnL
    IF NEW.status = 'closed' AND NEW.exit_price IS NOT NULL THEN
        IF NEW.side = 'long' THEN
            NEW.pnl = (NEW.exit_price - NEW.entry_price) * NEW.quantity - COALESCE(NEW.fees, 0);
        ELSE -- short
            NEW.pnl = (NEW.entry_price - NEW.exit_price) * NEW.quantity - COALESCE(NEW.fees, 0);
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS calculate_pnl_trigger ON public.trades;
CREATE TRIGGER calculate_pnl_trigger
    BEFORE INSERT OR UPDATE ON public.trades
    FOR EACH ROW EXECUTE FUNCTION public.calculate_trade_pnl();

DO $$
BEGIN
    RAISE NOTICE '⚙️ 觸發器設置完成';
END $$;

-- =============================================
-- 6. 確保管理員用戶存在
-- =============================================

-- 檢查並創建管理員用戶資料
INSERT INTO public.user_profiles (
    id, 
    email, 
    full_name, 
    role, 
    status, 
    approved_at,
    created_at,
    updated_at
)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'full_name', 'System Admin'),
    'admin',
    'active',
    NOW(),
    NOW(),
    NOW()
FROM auth.users au
WHERE au.email = 'admin@txn.test'
ON CONFLICT (id) DO UPDATE SET
    role = 'admin',
    status = 'active',
    approved_at = COALESCE(user_profiles.approved_at, NOW()),
    updated_at = NOW();

DO $$
DECLARE
    admin_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO admin_count
    FROM public.user_profiles 
    WHERE email = 'admin@txn.test' AND role = 'admin' AND status = 'active';
    
    IF admin_count > 0 THEN
        RAISE NOTICE '✅ 管理員用戶設置完成';
    ELSE
        RAISE NOTICE '⚠️ 管理員用戶需要手動在認證系統中創建';
    END IF;
END $$;

-- =============================================
-- 7. 創建有用的視圖
-- =============================================

-- 用戶統計視圖
CREATE OR REPLACE VIEW public.user_stats AS
SELECT
    up.id,
    up.email,
    up.full_name,
    up.role,
    up.status,
    COUNT(DISTINCT s.id) as strategy_count,
    COUNT(DISTINCT t.id) as total_trades,
    COUNT(DISTINCT CASE WHEN t.pnl > 0 THEN t.id END) as winning_trades,
    COALESCE(SUM(t.pnl), 0) as total_pnl,
    up.created_at,
    up.last_login_at
FROM public.user_profiles up
LEFT JOIN public.strategies s ON up.id = s.user_id
LEFT JOIN public.trades t ON up.id = t.user_id AND t.status = 'closed'
GROUP BY up.id, up.email, up.full_name, up.role, up.status, up.created_at, up.last_login_at;

-- 交易績效視圖
CREATE OR REPLACE VIEW public.trading_performance AS
SELECT
    t.user_id,
    COUNT(*) as total_trades,
    COUNT(CASE WHEN t.pnl > 0 THEN 1 END) as winning_trades,
    COUNT(CASE WHEN t.pnl < 0 THEN 1 END) as losing_trades,
    COALESCE(SUM(t.pnl), 0) as total_pnl,
    CASE 
        WHEN COUNT(*) > 0 THEN 
            ROUND((COUNT(CASE WHEN t.pnl > 0 THEN 1 END) * 100.0 / COUNT(*)), 2)
        ELSE 0 
    END as win_rate,
    COALESCE(AVG(CASE WHEN t.pnl > 0 THEN t.pnl END), 0) as avg_win,
    COALESCE(AVG(CASE WHEN t.pnl < 0 THEN ABS(t.pnl) END), 0) as avg_loss
FROM public.trades t
WHERE t.status = 'closed'
GROUP BY t.user_id;

DO $$
BEGIN
    RAISE NOTICE '📊 視圖創建完成';
END $$;

-- =============================================
-- 8. 設置權限
-- =============================================

-- 確保 authenticated 用戶可以存取所有表
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.strategies TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.trades TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.performance_snapshots TO authenticated;

-- 允許存取視圖
GRANT SELECT ON public.user_stats TO authenticated;
GRANT SELECT ON public.trading_performance TO authenticated;

-- 允許使用序列
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

DO $$
BEGIN
    RAISE NOTICE '🔐 權限設置完成';
END $$;

-- =============================================
-- 9. 最終測試和驗證
-- =============================================

DO $$
DECLARE
    table_count INTEGER;
    policy_count INTEGER;
    admin_exists BOOLEAN;
BEGIN
    RAISE NOTICE '🧪 開始最終驗證...';
    
    -- 檢查表數量
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots');
    
    -- 檢查 RLS 策略數量
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE schemaname = 'public';
    
    -- 檢查管理員是否存在
    SELECT EXISTS(
        SELECT 1 FROM public.user_profiles 
        WHERE email = 'admin@txn.test' AND role = 'admin' AND status = 'active'
    ) INTO admin_exists;
    
    RAISE NOTICE '📊 驗證結果:';
    RAISE NOTICE '  - 核心資料表: % 個 (預期: 4)', table_count;
    RAISE NOTICE '  - RLS 策略: % 個', policy_count;
    RAISE NOTICE '  - 管理員用戶: %', CASE WHEN admin_exists THEN '✅ 存在' ELSE '❌ 不存在' END;
    
    IF table_count = 4 AND policy_count > 0 THEN
        RAISE NOTICE '🎉 資料庫更新成功完成！';
    ELSE
        RAISE NOTICE '⚠️ 可能存在問題，請檢查上述結果';
    END IF;
END $$;

-- =============================================
-- 10. 完成報告
-- =============================================

SELECT 
    '=== 🎯 TXN 專案 Supabase 更新完成 ===' as status,
    NOW() as completion_time,
    '資料庫已準備就緒，可以開始使用' as message;

-- 顯示當前狀態摘要
SELECT 
    '📋 系統狀態摘要' as section,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
ORDER BY tablename;

-- 顯示 RLS 策略摘要
SELECT 
    '🛡️ RLS 策略摘要' as section,
    tablename,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;