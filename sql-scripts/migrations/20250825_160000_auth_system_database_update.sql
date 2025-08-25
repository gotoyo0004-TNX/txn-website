-- =============================================
-- TXN 用戶認證系統 - 資料庫更新腳本
-- 日期: 2025-08-25
-- 功能: 配合已完成的用戶認證系統，確保資料庫結構完整
-- 版本: v3.0 (Auth System Compatible)
-- 執行順序: 在 20240825_150000_txn_database_structure.sql 之後執行
-- =============================================

-- 檢查並確保必要的資料表存在
-- 如果之前的腳本未執行，則建立完整結構

-- 1. 用戶資料表 (User Profiles) - 與 AuthContext 完全匹配
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    avatar_url TEXT,
    
    -- TXN 專用欄位 - 與 AuthContext.tsx 中的預設值一致
    initial_capital DECIMAL(15,2) DEFAULT 10000.00, -- 初始資金
    currency VARCHAR(3) DEFAULT 'USD', -- 幣別
    timezone VARCHAR(50) DEFAULT 'UTC', -- 時區
    trading_experience VARCHAR(20) DEFAULT 'beginner' CHECK (trading_experience IN ('beginner', 'intermediate', 'advanced', 'professional')),
    
    -- 系統欄位
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 交易策略資料表
CREATE TABLE IF NOT EXISTS public.strategies (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    
    name VARCHAR(100) NOT NULL, -- 策略名稱
    description TEXT, -- 策略描述
    color VARCHAR(7) DEFAULT '#FBBF24', -- 標籤顏色 (TXN 品牌色)
    
    -- 統計欄位 (由觸發器自動計算)
    total_trades INTEGER DEFAULT 0,
    win_rate DECIMAL(5,2) DEFAULT 0.00, -- 勝率 %
    avg_profit_loss DECIMAL(15,2) DEFAULT 0.00, -- 平均損益
    
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 確保用戶策略名稱唯一
    UNIQUE(user_id, name)
);

-- 3. 交易記錄資料表 (核心功能 - 準備第二階段開發)
CREATE TABLE IF NOT EXISTS public.trades (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    strategy_id UUID REFERENCES public.strategies(id) ON DELETE SET NULL,
    
    -- 基本交易資訊
    symbol VARCHAR(20) NOT NULL, -- 交易商品代號
    direction VARCHAR(5) NOT NULL CHECK (direction IN ('LONG', 'SHORT')), -- 交易方向
    
    -- 價格資訊 (支援加密貨幣精度)
    entry_price DECIMAL(15,8) NOT NULL, -- 入場價格
    exit_price DECIMAL(15,8), -- 出場價格
    stop_loss DECIMAL(15,8), -- 停損價格
    take_profit DECIMAL(15,8), -- 停利價格
    
    -- 交易量與資金管理
    position_size DECIMAL(15,4) NOT NULL, -- 交易量
    risk_amount DECIMAL(15,2), -- 風險金額
    
    -- 時間資訊
    entry_time TIMESTAMP WITH TIME ZONE NOT NULL,
    exit_time TIMESTAMP WITH TIME ZONE,
    
    -- 損益計算 (自動計算)
    profit_loss DECIMAL(15,2), -- 損益金額
    profit_loss_percentage DECIMAL(8,4), -- 損益百分比
    risk_reward_ratio DECIMAL(8,4), -- 風險回報比 (R/R Ratio)
    
    -- 交易狀態
    status VARCHAR(15) DEFAULT 'open' CHECK (status IN ('open', 'closed', 'cancelled')),
    
    -- 附加資訊
    notes TEXT, -- 交易筆記
    tags TEXT[], -- 標籤陣列
    screenshot_url TEXT, -- 交易截圖 URL
    
    -- 系統欄位
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 交易績效快照表 (儀表板數據優化)
CREATE TABLE IF NOT EXISTS public.performance_snapshots (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- 快照日期
    snapshot_date DATE NOT NULL,
    
    -- 累計績效指標
    total_trades INTEGER DEFAULT 0,
    winning_trades INTEGER DEFAULT 0,
    losing_trades INTEGER DEFAULT 0,
    win_rate DECIMAL(5,2) DEFAULT 0.00, -- 勝率 %
    
    -- 損益統計
    total_profit_loss DECIMAL(15,2) DEFAULT 0.00,
    gross_profit DECIMAL(15,2) DEFAULT 0.00,
    gross_loss DECIMAL(15,2) DEFAULT 0.00,
    profit_factor DECIMAL(8,4) DEFAULT 0.00, -- 獲利因子
    
    -- 風險指標
    max_drawdown DECIMAL(15,2) DEFAULT 0.00, -- 最大回檔
    avg_win DECIMAL(15,2) DEFAULT 0.00, -- 平均獲利
    avg_loss DECIMAL(15,2) DEFAULT 0.00, -- 平均虧損
    risk_reward_ratio DECIMAL(8,4) DEFAULT 0.00, -- 平均風險回報比
    
    -- 權益曲線數據
    account_balance DECIMAL(15,2) NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 確保每個用戶每天只有一筆快照
    UNIQUE(user_id, snapshot_date)
);

-- =============================================
-- RLS (Row Level Security) 安全政策
-- =============================================

-- 啟用 RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.strategies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_snapshots ENABLE ROW LEVEL SECURITY;

-- 清除可能存在的舊政策
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can manage own strategies" ON public.strategies;
DROP POLICY IF EXISTS "Users can manage own trades" ON public.trades;
DROP POLICY IF EXISTS "Users can view own performance" ON public.performance_snapshots;

-- 用戶資料表政策 (與 AuthContext 操作匹配)
CREATE POLICY "Users can view own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 策略資料表政策
CREATE POLICY "Users can manage own strategies" ON public.strategies
    FOR ALL USING (auth.uid() = user_id);

-- 交易記錄政策
CREATE POLICY "Users can manage own trades" ON public.trades
    FOR ALL USING (auth.uid() = user_id);

-- 績效快照政策
CREATE POLICY "Users can view own performance" ON public.performance_snapshots
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert performance snapshots" ON public.performance_snapshots
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- =============================================
-- 觸發器：自動更新 updated_at 欄位
-- =============================================

-- 建立或替換更新函數
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 為用戶資料表建立觸發器
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 為策略資料表建立觸發器
DROP TRIGGER IF EXISTS update_strategies_updated_at ON public.strategies;
CREATE TRIGGER update_strategies_updated_at
    BEFORE UPDATE ON public.strategies
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 為交易記錄建立觸發器
DROP TRIGGER IF EXISTS update_trades_updated_at ON public.trades;
CREATE TRIGGER update_trades_updated_at
    BEFORE UPDATE ON public.trades
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- =============================================
-- 觸發器：自動計算交易損益 (準備第二階段功能)
-- =============================================

CREATE OR REPLACE FUNCTION calculate_trade_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- 只在交易關閉時計算損益
    IF NEW.status = 'closed' AND NEW.exit_price IS NOT NULL THEN
        -- 計算損益金額 (依方向)
        IF NEW.direction = 'LONG' THEN
            NEW.profit_loss = (NEW.exit_price - NEW.entry_price) * NEW.position_size;
        ELSE -- SHORT
            NEW.profit_loss = (NEW.entry_price - NEW.exit_price) * NEW.position_size;
        END IF;
        
        -- 計算損益百分比 (基於風險金額)
        IF NEW.risk_amount IS NOT NULL AND NEW.risk_amount > 0 THEN
            NEW.profit_loss_percentage = (NEW.profit_loss / NEW.risk_amount) * 100;
        END IF;
        
        -- 計算風險回報比 (R/R Ratio)
        IF NEW.stop_loss IS NOT NULL AND NEW.take_profit IS NOT NULL THEN
            DECLARE
                risk_points DECIMAL;
                reward_points DECIMAL;
            BEGIN
                IF NEW.direction = 'LONG' THEN
                    risk_points = NEW.entry_price - NEW.stop_loss;
                    reward_points = NEW.take_profit - NEW.entry_price;
                ELSE -- SHORT
                    risk_points = NEW.stop_loss - NEW.entry_price;
                    reward_points = NEW.entry_price - NEW.take_profit;
                END IF;
                
                IF risk_points > 0 THEN
                    NEW.risk_reward_ratio = reward_points / risk_points;
                END IF;
            END;
        END IF;
    END IF;
    
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 建立交易計算觸發器
DROP TRIGGER IF EXISTS calculate_trade_metrics_trigger ON public.trades;
CREATE TRIGGER calculate_trade_metrics_trigger
    BEFORE INSERT OR UPDATE ON public.trades
    FOR EACH ROW EXECUTE FUNCTION calculate_trade_metrics();

-- =============================================
-- 觸發器：自動更新策略統計
-- =============================================

CREATE OR REPLACE FUNCTION update_strategy_stats()
RETURNS TRIGGER AS $$
DECLARE
    strategy_record RECORD;
BEGIN
    -- 更新相關策略的統計數據
    IF COALESCE(NEW.strategy_id, OLD.strategy_id) IS NOT NULL THEN
        SELECT 
            COUNT(*) as total,
            COUNT(*) FILTER (WHERE profit_loss > 0) as wins,
            AVG(profit_loss) as avg_pl
        INTO strategy_record
        FROM public.trades 
        WHERE strategy_id = COALESCE(NEW.strategy_id, OLD.strategy_id)
        AND status = 'closed';
        
        UPDATE public.strategies SET
            total_trades = strategy_record.total,
            win_rate = CASE 
                WHEN strategy_record.total > 0 
                THEN (strategy_record.wins::DECIMAL / strategy_record.total * 100)
                ELSE 0 
            END,
            avg_profit_loss = COALESCE(strategy_record.avg_pl, 0),
            updated_at = NOW()
        WHERE id = COALESCE(NEW.strategy_id, OLD.strategy_id);
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 建立策略統計更新觸發器
DROP TRIGGER IF EXISTS update_strategy_stats_trigger ON public.trades;
CREATE TRIGGER update_strategy_stats_trigger
    AFTER INSERT OR UPDATE OR DELETE ON public.trades
    FOR EACH ROW EXECUTE FUNCTION update_strategy_stats();

-- =============================================
-- 新用戶預設策略自動建立
-- =============================================

CREATE OR REPLACE FUNCTION create_default_strategies()
RETURNS TRIGGER AS $$
BEGIN
    -- 為新用戶建立預設交易策略 (符合 TXN 品牌色彩)
    INSERT INTO public.strategies (user_id, name, description, color) VALUES
    (NEW.id, '趨勢跟隨', '跟隨市場主要趨勢的交易策略，適合新手入門', '#228B22'), -- 沉穩森林綠
    (NEW.id, '突破交易', '基於關鍵支撐阻力位突破的短線策略', '#FBBF24'), -- 活力金 (主要強調色)
    (NEW.id, '反轉交易', '在超買超賣區域尋找反轉機會的逆勢策略', '#DC143C'); -- 冷靜緋紅
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 建立新用戶策略自動建立觸發器
DROP TRIGGER IF EXISTS create_default_strategies_trigger ON public.user_profiles;
CREATE TRIGGER create_default_strategies_trigger
    AFTER INSERT ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION create_default_strategies();

-- =============================================
-- 索引優化 (提升查詢效能)
-- =============================================

-- 用戶相關索引
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_trades_user_id ON public.trades(user_id);
CREATE INDEX IF NOT EXISTS idx_trades_user_entry_time ON public.trades(user_id, entry_time DESC);
CREATE INDEX IF NOT EXISTS idx_trades_user_status ON public.trades(user_id, status);

-- 策略相關索引
CREATE INDEX IF NOT EXISTS idx_trades_strategy_id ON public.trades(strategy_id);
CREATE INDEX IF NOT EXISTS idx_strategies_user_id ON public.strategies(user_id);
CREATE INDEX IF NOT EXISTS idx_strategies_user_active ON public.strategies(user_id, is_active);

-- 績效快照索引
CREATE INDEX IF NOT EXISTS idx_performance_user_date ON public.performance_snapshots(user_id, snapshot_date DESC);

-- 交易查詢優化索引
CREATE INDEX IF NOT EXISTS idx_trades_symbol ON public.trades(symbol);
CREATE INDEX IF NOT EXISTS idx_trades_direction ON public.trades(direction);
CREATE INDEX IF NOT EXISTS idx_trades_entry_time ON public.trades(entry_time DESC);
CREATE INDEX IF NOT EXISTS idx_trades_status ON public.trades(status);

-- 複合索引 (常用查詢組合)
CREATE INDEX IF NOT EXISTS idx_trades_user_symbol_time ON public.trades(user_id, symbol, entry_time DESC);
CREATE INDEX IF NOT EXISTS idx_trades_user_strategy_time ON public.trades(user_id, strategy_id, entry_time DESC);

-- =============================================
-- 測試資料驗證函數
-- =============================================

-- 建立驗證函數，檢查資料庫結構是否正確
CREATE OR REPLACE FUNCTION validate_txn_database()
RETURNS TABLE(
    table_name TEXT,
    exists BOOLEAN,
    policies_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.table_name::TEXT,
        true as exists,
        (SELECT COUNT(*) FROM pg_policies WHERE tablename = t.table_name) as policies_count
    FROM information_schema.tables t
    WHERE t.table_schema = 'public'
    AND t.table_name IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
    ORDER BY t.table_name;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 執行後驗證
-- =============================================

-- 檢查資料表和政策
SELECT * FROM validate_txn_database();

-- 檢查觸發器
SELECT 
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND event_object_table IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
ORDER BY event_object_table, trigger_name;

-- =============================================
-- 完成！下一步操作指引：
-- 
-- 1. 已完成項目：
--    ✅ 用戶認證系統 (AuthContext + Supabase Auth)
--    ✅ 用戶資料表自動建立和更新
--    ✅ RLS 安全政策
--    ✅ 預設策略自動建立
-- 
-- 2. 準備開始第二階段：
--    🚀 實作新增/編輯交易功能 (Modal 視窗)
--    🚀 建立交易表單組件 (含風險回報比計算)
--    🚀 實作交易歷史頁面 (CRUD 功能)
--    🚀 建立篩選器和排序功能
-- 
-- 3. 測試建議：
--    - 註冊新用戶測試 user_profiles 自動建立
--    - 確認預設策略自動產生
--    - 驗證 RLS 政策正常運作
-- =============================================