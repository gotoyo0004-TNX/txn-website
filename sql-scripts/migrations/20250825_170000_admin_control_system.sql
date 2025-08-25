-- =============================================
-- TXN 管理員控制系統資料庫遷移
-- 日期: 2025-08-25
-- 功能: 新增用戶角色和狀態管理系統
-- 版本: v3.0 (管理員控制)
-- =============================================

-- 1. 擴展 user_profiles 資料表，增加角色和狀態欄位
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('admin', 'user')),
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('active', 'inactive', 'pending')),
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES public.user_profiles(id);

-- 2. 建立管理員操作日誌表
CREATE TABLE IF NOT EXISTS public.admin_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    action VARCHAR(50) NOT NULL, -- approve_user, deactivate_user, promote_admin, etc.
    target_user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    details JSONB, -- 操作詳細資訊
    ip_address INET, -- 操作 IP 地址
    user_agent TEXT, -- 瀏覽器資訊
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 建立用戶狀態變更歷史表
CREATE TABLE IF NOT EXISTS public.user_status_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    changed_by UUID REFERENCES public.user_profiles(id),
    reason TEXT, -- 變更原因
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 更新現有用戶為管理員（第一個註冊的用戶）
-- 注意：這個腳本會將最早註冊的用戶設為管理員
UPDATE public.user_profiles 
SET 
    role = 'admin',
    status = 'active',
    approved_at = NOW()
WHERE id = (
    SELECT id 
    FROM public.user_profiles 
    ORDER BY created_at ASC 
    LIMIT 1
) AND role = 'user';

-- 5. 為管理員日誌表啟用 RLS
ALTER TABLE public.admin_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_status_history ENABLE ROW LEVEL SECURITY;

-- 6. 管理員日誌 RLS 政策
CREATE POLICY "只有管理員可以查看管理員日誌" ON public.admin_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() AND role = 'admin' AND status = 'active'
        )
    );

CREATE POLICY "只有管理員可以新增管理員日誌" ON public.admin_logs
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() AND role = 'admin' AND status = 'active'
        ) AND admin_id = auth.uid()
    );

-- 7. 用戶狀態歷史 RLS 政策
CREATE POLICY "用戶可以查看自己的狀態歷史" ON public.user_status_history
    FOR SELECT USING (
        user_id = auth.uid() OR 
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() AND role = 'admin' AND status = 'active'
        )
    );

CREATE POLICY "只有管理員可以新增狀態歷史" ON public.user_status_history
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() AND role = 'admin' AND status = 'active'
        )
    );

-- 8. 更新用戶資料表 RLS 政策 - 只有活躍用戶可以查看資料
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;

-- 重新建立更嚴格的政策
CREATE POLICY "活躍用戶可以查看自己資料" ON public.user_profiles
    FOR SELECT USING (
        auth.uid() = id AND status = 'active'
    );

CREATE POLICY "活躍用戶可以更新自己資料" ON public.user_profiles
    FOR UPDATE USING (
        auth.uid() = id AND status = 'active'
    );

CREATE POLICY "可以新增用戶資料" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 管理員可以查看所有用戶
CREATE POLICY "管理員可以查看所有用戶" ON public.user_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() AND role = 'admin' AND status = 'active'
        )
    );

-- 管理員可以更新用戶狀態和角色
CREATE POLICY "管理員可以更新用戶狀態" ON public.user_profiles
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() AND role = 'admin' AND status = 'active'
        )
    );

-- 9. 更新策略表 RLS 政策 - 只有活躍用戶可以管理策略
DROP POLICY IF EXISTS "Users can manage own strategies" ON public.strategies;

CREATE POLICY "活躍用戶可以管理自己的策略" ON public.strategies
    FOR ALL USING (
        auth.uid() = user_id AND 
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() AND status = 'active'
        )
    );

-- 10. 更新交易表 RLS 政策 - 只有活躍用戶可以管理交易
DROP POLICY IF EXISTS "Users can manage own trades" ON public.trades;

CREATE POLICY "活躍用戶可以管理自己的交易" ON public.trades
    FOR ALL USING (
        auth.uid() = user_id AND 
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() AND status = 'active'
        )
    );

-- 11. 更新績效快照 RLS 政策
DROP POLICY IF EXISTS "Users can view own performance" ON public.performance_snapshots;

CREATE POLICY "活躍用戶可以查看自己的績效" ON public.performance_snapshots
    FOR SELECT USING (
        auth.uid() = user_id AND 
        EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth.uid() AND status = 'active'
        )
    );

-- =============================================
-- 觸發器函數：記錄用戶狀態變更
-- =============================================

CREATE OR REPLACE FUNCTION log_user_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- 如果狀態有變更，記錄到歷史表
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO public.user_status_history (
            user_id,
            old_status,
            new_status,
            changed_by,
            reason
        ) VALUES (
            NEW.id,
            OLD.status,
            NEW.status,
            auth.uid(),
            '管理員變更用戶狀態'
        );
    END IF;
    
    -- 如果用戶被批准，記錄批准時間
    IF OLD.status = 'pending' AND NEW.status = 'active' THEN
        NEW.approved_at = NOW();
        NEW.approved_by = auth.uid();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 建立狀態變更觸發器
CREATE TRIGGER log_user_status_change_trigger
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION log_user_status_change();

-- =============================================
-- 管理員輔助函數
-- =============================================

-- 檢查用戶是否為管理員
CREATE OR REPLACE FUNCTION is_admin(user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_profiles 
        WHERE id = user_id AND role = 'admin' AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 獲取待審核用戶列表
CREATE OR REPLACE FUNCTION get_pending_users()
RETURNS TABLE (
    id UUID,
    email VARCHAR,
    full_name VARCHAR,
    trading_experience VARCHAR,
    initial_capital DECIMAL,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    -- 只有管理員可以呼叫
    IF NOT is_admin() THEN
        RAISE EXCEPTION '只有管理員可以查看待審核用戶';
    END IF;
    
    RETURN QUERY
    SELECT 
        up.id,
        up.email,
        up.full_name,
        up.trading_experience,
        up.initial_capital,
        up.created_at
    FROM public.user_profiles up
    WHERE up.status = 'pending'
    ORDER BY up.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 批准用戶函數
CREATE OR REPLACE FUNCTION approve_user(target_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- 只有管理員可以批准
    IF NOT is_admin() THEN
        RAISE EXCEPTION '只有管理員可以批准用戶';
    END IF;
    
    -- 更新用戶狀態
    UPDATE public.user_profiles 
    SET 
        status = 'active',
        approved_at = NOW(),
        approved_by = auth.uid()
    WHERE id = target_user_id AND status = 'pending';
    
    -- 記錄管理員操作
    INSERT INTO public.admin_logs (admin_id, action, target_user_id, details)
    VALUES (
        auth.uid(),
        'approve_user',
        target_user_id,
        jsonb_build_object('timestamp', NOW())
    );
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 停用用戶函數
CREATE OR REPLACE FUNCTION deactivate_user(target_user_id UUID, reason TEXT DEFAULT '管理員停用')
RETURNS BOOLEAN AS $$
BEGIN
    -- 只有管理員可以停用
    IF NOT is_admin() THEN
        RAISE EXCEPTION '只有管理員可以停用用戶';
    END IF;
    
    -- 不能停用自己
    IF target_user_id = auth.uid() THEN
        RAISE EXCEPTION '不能停用自己的帳戶';
    END IF;
    
    -- 更新用戶狀態
    UPDATE public.user_profiles 
    SET status = 'inactive'
    WHERE id = target_user_id AND status = 'active';
    
    -- 記錄管理員操作
    INSERT INTO public.admin_logs (admin_id, action, target_user_id, details)
    VALUES (
        auth.uid(),
        'deactivate_user',
        target_user_id,
        jsonb_build_object('reason', reason, 'timestamp', NOW())
    );
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 索引優化
-- =============================================

-- 管理員相關索引
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_status ON public.user_profiles(status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role_status ON public.user_profiles(role, status);

-- 管理員日誌索引
CREATE INDEX IF NOT EXISTS idx_admin_logs_admin_id ON public.admin_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_logs_created_at ON public.admin_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_logs_action ON public.admin_logs(action);

-- 狀態歷史索引
CREATE INDEX IF NOT EXISTS idx_user_status_history_user_id ON public.user_status_history(user_id);
CREATE INDEX IF NOT EXISTS idx_user_status_history_created_at ON public.user_status_history(created_at DESC);

-- =============================================
-- 執行完成後請確認：
-- 1. 用戶角色和狀態欄位正確新增
-- 2. 管理員日誌和狀態歷史表建立成功
-- 3. RLS 政策更新正確
-- 4. 觸發器和函數正常運作
-- 5. 第一個用戶已設為管理員
-- 
-- 下一步：
-- 1. 在 Supabase 設定中關閉郵件確認
-- 2. 實作前端管理員控制面板
-- 3. 測試完整的用戶審核流程
-- =============================================