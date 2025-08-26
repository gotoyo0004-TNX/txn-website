-- =============================================
-- 修復 entry_date 欄位問題
-- 解決 "column entry_date does not exist" 錯誤
-- =============================================

-- 🔧 針對 admin@txn.test 權限檢查超時和欄位問題的修復

DO $$
BEGIN
    RAISE NOTICE '🔧 開始修復 entry_date 欄位問題...';
    RAISE NOTICE '⏰ 修復時間: %', NOW();
END $$;

-- =============================================
-- 1. 檢查現有表結構
-- =============================================

DO $$
DECLARE
    table_exists BOOLEAN;
    column_exists BOOLEAN;
BEGIN
    -- 檢查 trades 表是否存在
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'trades'
    ) INTO table_exists;
    
    IF table_exists THEN
        RAISE NOTICE '📋 trades 表已存在';
        
        -- 檢查 entry_date 欄位是否存在
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'trades' 
            AND column_name = 'entry_date'
        ) INTO column_exists;
        
        IF column_exists THEN
            RAISE NOTICE '✅ entry_date 欄位已存在';
        ELSE
            RAISE NOTICE '❌ entry_date 欄位不存在，需要添加';
        END IF;
    ELSE
        RAISE NOTICE '❌ trades 表不存在，需要創建';
    END IF;
END $$;

-- =============================================
-- 2. 安全地添加缺失的欄位
-- =============================================

-- 如果 trades 表存在但缺少 entry_date 欄位，則添加它
DO $$
BEGIN
    -- 添加 entry_date 欄位（如果不存在）
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'trades' 
        AND column_name = 'entry_date'
    ) THEN
        ALTER TABLE public.trades ADD COLUMN entry_date TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ 已添加 entry_date 欄位';
    END IF;
    
    -- 添加 exit_date 欄位（如果不存在）
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'trades' 
        AND column_name = 'exit_date'
    ) THEN
        ALTER TABLE public.trades ADD COLUMN exit_date TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ 已添加 exit_date 欄位';
    END IF;
    
    -- 檢查並添加其他可能缺失的欄位
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'trades' 
        AND column_name = 'side'
    ) THEN
        ALTER TABLE public.trades ADD COLUMN side VARCHAR(10) CHECK (side IN ('long', 'short'));
        RAISE NOTICE '✅ 已添加 side 欄位';
    END IF;
    
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'trades' 
        AND column_name = 'pnl'
    ) THEN
        ALTER TABLE public.trades ADD COLUMN pnl DECIMAL(15, 8);
        RAISE NOTICE '✅ 已添加 pnl 欄位';
    END IF;
    
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'trades' 
        AND column_name = 'fees'
    ) THEN
        ALTER TABLE public.trades ADD COLUMN fees DECIMAL(15, 8) DEFAULT 0;
        RAISE NOTICE '✅ 已添加 fees 欄位';
    END IF;
    
    IF NOT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'trades' 
        AND column_name = 'status'
    ) THEN
        ALTER TABLE public.trades ADD COLUMN status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'closed', 'cancelled'));
        RAISE NOTICE '✅ 已添加 status 欄位';
    END IF;
END $$;

-- =============================================
-- 3. 更新現有數據（如果需要）
-- =============================================

-- 如果 entry_date 欄位是新添加的且為空，用 created_at 填充
DO $$
BEGIN
    IF EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'trades' 
        AND column_name = 'entry_date'
    ) THEN
        -- 更新空的 entry_date
        UPDATE public.trades 
        SET entry_date = created_at 
        WHERE entry_date IS NULL AND created_at IS NOT NULL;
        
        RAISE NOTICE '✅ 已更新空的 entry_date 欄位';
    END IF;
END $$;

-- =============================================
-- 4. 創建或更新索引
-- =============================================

-- 安全地創建索引
CREATE INDEX IF NOT EXISTS idx_trades_entry_date ON public.trades(entry_date);
CREATE INDEX IF NOT EXISTS idx_trades_exit_date ON public.trades(exit_date);
CREATE INDEX IF NOT EXISTS idx_trades_status ON public.trades(status);

DO $$
BEGIN
    RAISE NOTICE '✅ 索引創建完成';
END $$;

-- =============================================
-- 5. 修復 admin@txn.test 權限問題
-- =============================================

-- 確保管理員用戶資料正確
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
    COALESCE(au.raw_user_meta_data->>'full_name', 'TXN Admin'),
    'admin',
    'active',
    NOW(),
    NOW(),
    NOW()
FROM auth.users au
WHERE au.email = 'admin@txn.test'
  AND au.id IS NOT NULL
ON CONFLICT (id) DO UPDATE SET
    role = 'admin',
    status = 'active',
    approved_at = COALESCE(user_profiles.approved_at, NOW()),
    updated_at = NOW();

-- 同時確保 email 唯一性
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
    COALESCE(au.raw_user_meta_data->>'full_name', 'TXN Admin'),
    'admin',
    'active',
    NOW(),
    NOW(),
    NOW()
FROM auth.users au
WHERE au.email = 'admin@txn.test'
  AND au.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.user_profiles up WHERE up.email = au.email
  );

-- =============================================
-- 6. 清理並重建簡單的 RLS 策略
-- =============================================

-- 暫時禁用 RLS
ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

-- 清理所有策略
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'user_profiles') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON public.user_profiles';
    END LOOP;
    RAISE NOTICE '🧹 user_profiles 策略已清理';
END $$;

-- 創建最簡單的策略
CREATE POLICY "simple_read_access" ON public.user_profiles
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "simple_update_own" ON public.user_profiles
    FOR UPDATE TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "simple_insert_own" ON public.user_profiles
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = id);

-- 重新啟用 RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    RAISE NOTICE '🛡️ 簡化的 RLS 策略已重建';
END $$;

-- =============================================
-- 7. 測試修復結果
-- =============================================

DO $$
DECLARE
    admin_count INTEGER;
    admin_data RECORD;
    column_count INTEGER;
BEGIN
    RAISE NOTICE '🧪 測試修復結果...';
    
    -- 檢查管理員用戶
    SELECT COUNT(*) INTO admin_count
    FROM public.user_profiles 
    WHERE email = 'admin@txn.test' AND role = 'admin' AND status = 'active';
    
    IF admin_count > 0 THEN
        RAISE NOTICE '✅ admin@txn.test 用戶設置正確';
        
        -- 顯示管理員詳細信息
        SELECT * INTO admin_data
        FROM public.user_profiles 
        WHERE email = 'admin@txn.test' 
        LIMIT 1;
        
        RAISE NOTICE '📊 管理員詳情: ID=%, Role=%, Status=%', 
            admin_data.id, admin_data.role, admin_data.status;
    ELSE
        RAISE NOTICE '❌ admin@txn.test 用戶設置有問題';
    END IF;
    
    -- 檢查 trades 表結構
    SELECT COUNT(*) INTO column_count
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'trades'
    AND column_name IN ('entry_date', 'exit_date', 'side', 'pnl', 'status');
    
    RAISE NOTICE '📋 trades 表重要欄位數量: % (預期: 5)', column_count;
    
    IF column_count = 5 THEN
        RAISE NOTICE '✅ trades 表結構完整';
    ELSE
        RAISE NOTICE '⚠️ trades 表結構可能不完整';
    END IF;
END $$;

-- =============================================
-- 8. 完成報告
-- =============================================

SELECT 
    '=== 🎉 修復完成 ===' as status,
    NOW() as completion_time,
    'entry_date 問題已修復，admin@txn.test 權限已設置' as message;

-- 顯示當前 admin 用戶狀態
SELECT 
    '👤 admin@txn.test 最終狀態' as section,
    up.id,
    up.email,
    up.role,
    up.status,
    up.approved_at IS NOT NULL as approved,
    au.email_confirmed_at IS NOT NULL as email_confirmed
FROM public.user_profiles up
JOIN auth.users au ON up.id = au.id
WHERE up.email = 'admin@txn.test';

-- 顯示 trades 表結構
SELECT 
    '📋 trades 表欄位檢查' as section,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'trades'
ORDER BY ordinal_position;