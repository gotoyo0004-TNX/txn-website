-- =============================================
-- 立即執行修復腳本 - TXN 管理員權限問題
-- 執行時間: 2025-08-26
-- 目標: 解決 admin@txn.test 500 錯誤和權限問題
-- =============================================

BEGIN;

DO $$
BEGIN
    RAISE NOTICE '🚀 開始立即修復流程...';
    RAISE NOTICE '⏰ 執行時間: %', NOW();
END $$;

-- =============================================
-- 1. 檢查當前系統狀態
-- =============================================

DO $$
DECLARE
    admin_exists BOOLEAN;
    admin_uuid UUID;
    admin_role TEXT;
    admin_status TEXT;
BEGIN
    RAISE NOTICE '=== 🔍 系統狀態檢查 ===';
    
    -- 檢查 admin@txn.test 是否存在
    SELECT EXISTS(
        SELECT 1 FROM auth.users WHERE email = 'admin@txn.test'
    ) INTO admin_exists;
    
    RAISE NOTICE '📋 Admin 用戶存在: %', admin_exists;
    
    IF admin_exists THEN
        SELECT id INTO admin_uuid FROM auth.users WHERE email = 'admin@txn.test';
        RAISE NOTICE '📋 Admin UUID: %', admin_uuid;
        
        -- 檢查 user_profiles 中的狀態
        SELECT role, status INTO admin_role, admin_status
        FROM public.user_profiles WHERE id = admin_uuid;
        
        RAISE NOTICE '📋 當前角色: %, 狀態: %', admin_role, admin_status;
    END IF;
END $$;

-- =============================================
-- 2. 強制修復管理員帳戶
-- =============================================

DO $$
DECLARE
    admin_uuid UUID;
BEGIN
    RAISE NOTICE '=== 🔧 修復管理員帳戶 ===';
    
    -- 獲取 admin@txn.test 的 UUID
    SELECT id INTO admin_uuid FROM auth.users WHERE email = 'admin@txn.test';
    
    IF admin_uuid IS NULL THEN
        RAISE NOTICE '❌ 錯誤: admin@txn.test 用戶不存在';
        RAISE NOTICE '📋 請先在前端註冊此帳戶，然後重新執行腳本';
        RETURN;
    END IF;
    
    -- 強制更新/創建管理員資料
    INSERT INTO public.user_profiles (
        id,
        email,
        full_name,
        role,
        status,
        trading_experience,
        initial_capital,
        currency,
        timezone,
        created_at,
        updated_at,
        approved_at,
        approved_by
    ) VALUES (
        admin_uuid,
        'admin@txn.test',
        'TXN 系統管理員',
        'admin',
        'active',
        'professional',
        100000.00,
        'USD',
        'Asia/Taipei',
        NOW(),
        NOW(),
        NOW(),
        admin_uuid
    )
    ON CONFLICT (id) DO UPDATE SET
        role = 'admin',
        status = 'active',
        full_name = COALESCE(user_profiles.full_name, 'TXN 系統管理員'),
        updated_at = NOW(),
        approved_at = NOW();
    
    RAISE NOTICE '✅ 管理員帳戶已修復';
END $$;

-- =============================================
-- 3. 清理和重建 RLS 策略
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '=== 🛡️ 重建 RLS 策略 ===';
END $$;

-- 清理所有舊策略
DROP POLICY IF EXISTS "user_read_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_read_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "user_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_update_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "user_insert_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_view_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admins_can_view_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admins_can_update_user_data" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_user_registration" ON public.user_profiles;

-- 建立新的優化策略
-- 策略 1: 用戶查看自己的資料
CREATE POLICY "enable_users_read_own_profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

-- 策略 2: 管理員查看所有資料
CREATE POLICY "enable_admins_read_all_profiles" ON public.user_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles p
            WHERE p.id = auth.uid() 
            AND p.role IN ('admin', 'super_admin', 'moderator')
            AND p.status = 'active'
        )
    );

-- 策略 3: 用戶更新自己的資料
CREATE POLICY "enable_users_update_own_profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- 策略 4: 管理員更新用戶資料
CREATE POLICY "enable_admins_update_all_profiles" ON public.user_profiles
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles p
            WHERE p.id = auth.uid() 
            AND p.role IN ('admin', 'super_admin', 'moderator')
            AND p.status = 'active'
        )
    );

-- 策略 5: 允許用戶註冊
CREATE POLICY "enable_user_registration" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- =============================================
-- 4. 建立索引優化
-- =============================================

-- 為權限查詢優化索引
CREATE INDEX IF NOT EXISTS idx_user_profiles_auth_lookup 
ON public.user_profiles(id, role, status) 
WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_user_profiles_role_filter 
ON public.user_profiles(role, status);

-- =============================================
-- 5. 最終驗證
-- =============================================

DO $$
DECLARE
    admin_uuid UUID;
    final_role TEXT;
    final_status TEXT;
    policy_count INTEGER;
    index_count INTEGER;
BEGIN
    RAISE NOTICE '=== ✅ 最終驗證 ===';
    
    -- 驗證管理員狀態
    SELECT id INTO admin_uuid FROM auth.users WHERE email = 'admin@txn.test';
    
    IF admin_uuid IS NOT NULL THEN
        SELECT role, status INTO final_role, final_status 
        FROM public.user_profiles WHERE id = admin_uuid;
        
        RAISE NOTICE '📊 管理員最終狀態: 角色=%, 狀態=%', final_role, final_status;
        
        IF final_role = 'admin' AND final_status = 'active' THEN
            RAISE NOTICE '🎉 管理員帳戶修復成功！';
        ELSE
            RAISE NOTICE '⚠️ 管理員帳戶可能仍有問題';
        END IF;
    END IF;
    
    -- 檢查策略數量
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies WHERE tablename = 'user_profiles';
    
    RAISE NOTICE '🛡️ 已建立 % 個 RLS 策略', policy_count;
    
    -- 檢查索引
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes 
    WHERE tablename = 'user_profiles' 
    AND indexname LIKE 'idx_user_profiles_%';
    
    RAISE NOTICE '⚡ 已建立 % 個優化索引', index_count;
END $$;

-- =============================================
-- 6. 顯示修復報告
-- =============================================

SELECT 
    '=== 📋 修復完成報告 ===' as "修復報告",
    NOW() as "完成時間";

-- 顯示管理員用戶最終狀態
SELECT 
    '🎯 管理員狀態' as "報告項目",
    u.email as "郵箱",
    p.role as "角色", 
    p.status as "狀態",
    p.full_name as "姓名",
    CASE 
        WHEN p.role IN ('admin', 'super_admin', 'moderator') AND p.status = 'active'
        THEN '✅ 權限正常'
        ELSE '❌ 權限異常'
    END as "權限狀態"
FROM auth.users u
LEFT JOIN public.user_profiles p ON u.id = p.id
WHERE u.email = 'admin@txn.test';

-- 顯示 RLS 策略狀態
SELECT 
    '🛡️ RLS 策略' as "報告項目",
    policyname as "策略名稱",
    cmd as "操作類型"
FROM pg_policies 
WHERE tablename = 'user_profiles'
ORDER BY policyname;

COMMIT;

-- =============================================
-- 🎯 執行完成後的立即測試步驟:
-- 
-- 1. 重新載入前端應用
-- 2. 清除瀏覽器快取 (Ctrl+Shift+R)
-- 3. 清除 localStorage: 
--    - 開啟開發者工具 (F12)
--    - Application > Local Storage > 清除所有項目
-- 4. 重新登入 admin@txn.test
-- 5. 檢查管理面板是否可以正常訪問
-- 
-- 如果仍有問題，請檢查:
-- - 瀏覽器控制台是否有錯誤訊息
-- - Supabase Dashboard 的 Logs 頁面
-- - 確認環境變數配置正確
-- =============================================