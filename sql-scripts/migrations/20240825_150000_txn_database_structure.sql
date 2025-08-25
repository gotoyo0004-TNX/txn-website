-- =============================================
-- TXN 交易日誌專案資料庫結構
-- 日期: 2024-08-25
-- 功能: 建立專用於交易日誌的資料表結構
-- 版本: v2.0 (TXN 專用)
-- =============================================

-- 1. 用戶資料表擴展 (User Profiles)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    avatar_url TEXT,
    
    -- TXN 專用欄位
    initial_capital DECIMAL(15,2) DEFAULT 10000.00, -- 初始資金
    currency VARCHAR(3) DEFAULT 'USD', -- 幣別
    timezone VARCHAR(50) DEFAULT 'UTC',
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
    color VARCHAR(7) DEFAULT '#FBBF24', -- 標籤顏色 (HEX)
    
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

-- 3. 交易記錄資料表 (核心)
CREATE TABLE IF NOT EXISTS public.trades (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    strategy_id UUID REFERENCES public.strategies(id) ON DELETE SET NULL,
    
    -- 基本交易資訊
    symbol VARCHAR(20) NOT NULL, -- 交易商品代號 (如: EURUSD, BTCUSD)
    direction VARCHAR(5) NOT NULL CHECK (direction IN ('LONG', 'SHORT')), -- 交易方向
    
    -- 價格資訊
    entry_price DECIMAL(15,8) NOT NULL, -- 入場價格 (支援加密貨幣精度)
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
    risk_reward_ratio DECIMAL(8,4), -- 風險回報比
    
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

-- 4. 交易績效快照表 (用於儀表板優化)
CREATE TABLE IF NOT EXISTS public.performance_snapshots (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- 快照日期
    snapshot_date DATE NOT NULL,
    
    -- 累計績效指標
    total_trades INTEGER DEFAULT 0,
    winning_trades INTEGER DEFAULT 0,
    losing_trades INTEGER DEFAULT 0,
    win_rate DECIMAL(5,2) DEFAULT 0.00,
    
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

-- 用戶資料表政策
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

-- =============================================
-- 觸發器函數：自動計算交易損益
-- =============================================

CREATE OR REPLACE FUNCTION calculate_trade_metrics()
RETURNS TRIGGER AS $$
BEGIN
    -- 只在交易關閉時計算
    IF NEW.status = 'closed' AND NEW.exit_price IS NOT NULL THEN
        -- 計算損益金額
        IF NEW.direction = 'LONG' THEN
            NEW.profit_loss = (NEW.exit_price - NEW.entry_price) * NEW.position_size;
        ELSE -- SHORT
            NEW.profit_loss = (NEW.entry_price - NEW.exit_price) * NEW.position_size;
        END IF;
        
        -- 計算損益百分比 (基於風險金額)
        IF NEW.risk_amount > 0 THEN
            NEW.profit_loss_percentage = (NEW.profit_loss / NEW.risk_amount) * 100;
        END IF;
        
        -- 計算風險回報比
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

-- 建立觸發器
CREATE TRIGGER calculate_trade_metrics_trigger
    BEFORE UPDATE ON public.trades
    FOR EACH ROW EXECUTE FUNCTION calculate_trade_metrics();

-- =============================================
-- 觸發器函數：更新策略統計
-- =============================================

CREATE OR REPLACE FUNCTION update_strategy_stats()
RETURNS TRIGGER AS $$
DECLARE
    strategy_record RECORD;
BEGIN
    -- 如果有關聯策略，更新統計
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
CREATE TRIGGER update_strategy_stats_trigger
    AFTER INSERT OR UPDATE OR DELETE ON public.trades
    FOR EACH ROW EXECUTE FUNCTION update_strategy_stats();

-- =============================================
-- 索引優化 (提升查詢效能)
-- =============================================

-- 用戶相關索引
CREATE INDEX IF NOT EXISTS idx_trades_user_id ON public.trades(user_id);
CREATE INDEX IF NOT EXISTS idx_trades_user_entry_time ON public.trades(user_id, entry_time DESC);
CREATE INDEX IF NOT EXISTS idx_trades_user_status ON public.trades(user_id, status);

-- 策略相關索引
CREATE INDEX IF NOT EXISTS idx_trades_strategy_id ON public.trades(strategy_id);
CREATE INDEX IF NOT EXISTS idx_strategies_user_id ON public.strategies(user_id);

-- 績效快照索引
CREATE INDEX IF NOT EXISTS idx_performance_user_date ON public.performance_snapshots(user_id, snapshot_date DESC);

-- 交易查詢優化索引
CREATE INDEX IF NOT EXISTS idx_trades_symbol ON public.trades(symbol);
CREATE INDEX IF NOT EXISTS idx_trades_direction ON public.trades(direction);
CREATE INDEX IF NOT EXISTS idx_trades_entry_time ON public.trades(entry_time DESC);

-- =============================================
-- 初始預設策略
-- =============================================

-- 建立一個觸發器，當新用戶註冊時自動建立預設策略
CREATE OR REPLACE FUNCTION create_default_strategies()
RETURNS TRIGGER AS $$
BEGIN
    -- 建立預設策略
    INSERT INTO public.strategies (user_id, name, description, color) VALUES
    (NEW.id, '趨勢跟隨', '跟隨市場主要趨勢的交易策略', '#22C55E'),
    (NEW.id, '突破交易', '基於關鍵支撐阻力位突破的策略', '#3B82F6'),
    (NEW.id, '反轉交易', '在超買超賣區域尋找反轉機會', '#EF4444');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER create_default_strategies_trigger
    AFTER INSERT ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION create_default_strategies();

-- =============================================
-- 執行完成後請確認：
-- 1. 所有資料表正確建立
-- 2. RLS 政策正常生效  
-- 3. 觸發器功能測試
-- 4. 索引建立成功
-- 5. 預設策略自動建立機制
-- 
-- 下一步：
-- 1. 在前端實作用戶認證系統
-- 2. 建立交易表單和列表功能
-- 3. 實作儀表板 KPI 計算
-- =============================================