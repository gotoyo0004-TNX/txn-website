-- =============================================
-- TXN 管理面板載入問題終極修復腳本 v2024.8.26
-- 功能: 修復 admin@txn.test 載入緩慢和權限問題
-- =============================================

-- 💡 使用指南：
-- 1. 在 Supabase SQL 編輯器中執行此腳本
-- 2. 執行完成後清除瀏覽器快取並重新登入
-- 3. 如果仍有問題，請檢查瀏覽器控制台錯誤

-- =============================================
-- 0. 完整診斷報告
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🔍 開始系統診斷...';
    RAISE NOTICE '執行時間: %', NOW();
END $$;

-- 檢查 auth.users 表
SELECT 
    '📋 Auth Users 檢查' as step,
    email,
    id as user_uuid,
    email_confirmed_at IS NOT NULL as email_confirmed,
    created_at,
    last_sign_in_at,
    CASE 
        WHEN email_confirmed_at IS NULL THEN '❌ Email 未驗證'
        ELSE '✅ Email 已驗證'
    END as email_status
FROM auth.users 
WHERE email = 'admin@txn.test'
ORDER BY created_at DESC;

-- 檢查 user_profiles 表
SELECT 
    '📋 User Profiles 檢查' as step,
    id,
    email,
    role,
    status,
    full_name,
    created_at,
    updated_at,
    approved_at,
    CASE 
        WHEN role IN ('admin', 'super_admin', 'moderator') AND status = 'active' THEN '✅ 權限正常'
        WHEN role NOT IN ('admin', 'super_admin', 'moderator') THEN '❌ 角色錯誤'
        WHEN status != 'active' THEN '❌ 狀態錯誤'
        ELSE '❌ 權限異常'
    END as permission_status
FROM user_profiles 
WHERE email = 'admin@txn.test'
ORDER BY created_at DESC;

-- 檢查 RLS 策略
SELECT 
    '🛡️ RLS 策略檢查' as step,
    schemaname,
    tablename,
    policyname,
    cmd,
    permissive,
    CASE 
        WHEN qual IS NOT NULL THEN '有條件限制'
        ELSE '無限制'
    END as policy_type
FROM pg_policies 
WHERE tablename = 'user_profiles'
ORDER BY policyname;

-- =============================================
-- 1. 強制修復管理員帳戶
-- =============================================

DO $$
DECLARE
    admin_uuid UUID;
    profile_exists BOOLEAN;
    current_role TEXT;
    current_status TEXT;
BEGIN
    RAISE NOTICE '🔧 開始修復管理員帳戶...';
    
    -- 獲取 admin@txn.test 的 UUID
    SELECT id INTO admin_uuid 
    FROM auth.users 
    WHERE email = 'admin@txn.test'
    ORDER BY created_at DESC 
    LIMIT 1;
    
    IF admin_uuid IS NULL THEN
        RAISE NOTICE '❌ 致命錯誤: admin@txn.test 不存在於 auth.users 表';
        RAISE NOTICE '📋 解決方案: 請先註冊此帳戶，然後重新執行腳本';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ 找到用戶: admin@txn.test (UUID: %)', admin_uuid;
    
    -- 檢查 profile 是否存在
    SELECT EXISTS(SELECT 1 FROM user_profiles WHERE id = admin_uuid) INTO profile_exists;
    
    IF profile_exists THEN
        -- 獲取當前狀態
        SELECT role, status INTO current_role, current_status 
        FROM user_profiles WHERE id = admin_uuid;
        
        RAISE NOTICE '📋 當前狀態: role=%, status=%', current_role, current_status;
        
        -- 強制更新為管理員
        UPDATE user_profiles 
        SET 
            role = 'admin',
            status = 'active',
            full_name = COALESCE(full_name, 'TXN 系統管理員'),
            trading_experience = COALESCE(trading_experience, 'professional'),
            initial_capital = COALESCE(initial_capital, 100000),
            currency = COALESCE(currency, 'USD'),
            timezone = COALESCE(timezone, 'Asia/Taipei'),
            updated_at = NOW(),
            approved_at = COALESCE(user_profiles.approved_at, NOW()),
            approved_by = COALESCE(user_profiles.approved_by, admin_uuid)
        WHERE id = admin_uuid;
        
        RAISE NOTICE '✅ 已更新管理員權限';
    ELSE
        -- 創建新的管理員 profile
        INSERT INTO user_profiles (
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
            100000,
            'USD',
            'Asia/Taipei',
            NOW(),
            NOW(),
            NOW(),
            admin_uuid
        );
        
        RAISE NOTICE '✅ 已創建管理員資料';
    END IF;
END $$;

-- =============================================
-- 2. 優化 RLS 策略
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '🛡️ 優化 RLS 策略...';
END $$;

-- 清理舊策略（確保完全清理）
DROP POLICY IF EXISTS "user_read_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_read_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "user_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_update_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_user_registration" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_view_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admins_can_view_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admins_can_update_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_user_registration" ON public.user_profiles;

-- 新增優化後的策略
-- 策略 1: 用戶查看自己的資料 (高性能)
CREATE POLICY "user_read_own_profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

-- 策略 2: 管理員查看所有資料 (優化查詢)
CREATE POLICY "admin_read_all_profiles" ON public.user_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles admin_profile
            WHERE admin_profile.id = auth.uid() 
            AND admin_profile.role IN ('admin', 'super_admin', 'moderator')
            AND admin_profile.status = 'active'
        )
    );

-- 策略 3: 用戶更新自己的資料
CREATE POLICY "user_update_own_profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- 策略 4: 管理員更新用戶資料
CREATE POLICY "admin_update_all_profiles" ON public.user_profiles
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles admin_profile
            WHERE admin_profile.id = auth.uid() 
            AND admin_profile.role IN ('admin', 'super_admin', 'moderator')
            AND admin_profile.status = 'active'
        )
    );

-- 策略 5: 允許用戶註冊
CREATE POLICY "allow_user_registration" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- =============================================
-- 3. 性能優化索引
-- =============================================

-- 為管理員權限查詢優化索引
DROP INDEX IF EXISTS idx_user_profiles_auth_lookup;
DROP INDEX IF EXISTS idx_user_profiles_admin_check;

CREATE INDEX IF NOT EXISTS idx_user_profiles_auth_lookup 
ON public.user_profiles(id, role, status) 
WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_user_profiles_admin_check 
ON public.user_profiles(role, status) 
WHERE role IN ('admin', 'super_admin', 'moderator');

-- =============================================
-- 4. 權限測試
-- =============================================

DO $$
DECLARE
    admin_uuid UUID;
    test_result RECORD;
    policy_count INTEGER;
BEGIN
    RAISE NOTICE '🧪 執行權限測試...';
    
    -- 獲取管理員 UUID
    SELECT id INTO admin_uuid FROM auth.users WHERE email = 'admin@txn.test';
    
    IF admin_uuid IS NOT NULL THEN
        -- 測試管理員權限
        SELECT role, status INTO test_result
        FROM user_profiles 
        WHERE id = admin_uuid;
        
        IF test_result.role = 'admin' AND test_result.status = 'active' THEN
            RAISE NOTICE '✅ 權限測試通過: 管理員可以正常訪問';
        ELSE
            RAISE NOTICE '❌ 權限測試失敗: role=%, status=%', test_result.role, test_result.status;
        END IF;
    END IF;
    
    -- 檢查策略數量
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies WHERE tablename = 'user_profiles';
    
    RAISE NOTICE '📊 已建立 % 個 RLS 策略', policy_count;
END $$;

-- =============================================
-- 5. 最終狀態報告
-- =============================================

SELECT 
    '=== 📋 修復完成報告 ===' as report_type,
    NOW() as fix_time;

-- 顯示管理員最終狀態
SELECT 
    '📊 管理員最終狀態' as section,
    u.id as user_uuid,
    u.email,
    u.email_confirmed_at IS NOT NULL as email_verified,
    u.last_sign_in_at,
    p.role,
    p.status,
    p.full_name,
    p.approved_at,
    p.created_at as profile_created,
    p.updated_at as profile_updated,
    CASE 
        WHEN p.role IN ('admin', 'super_admin', 'moderator') AND p.status = 'active' 
        THEN '✅ 可以訪問管理面板'
        ELSE '❌ 無法訪問管理面板'
    END as access_status
FROM auth.users u
LEFT JOIN user_profiles p ON u.id = p.id
WHERE u.email = 'admin@txn.test'
ORDER BY u.created_at DESC;

-- 顯示所有活躍的管理員
SELECT 
    '👥 所有活躍管理員' as section,
    up.email,
    up.role,
    up.full_name,
    up.created_at,
    au.last_sign_in_at
FROM user_profiles up
JOIN auth.users au ON up.id = au.id
WHERE up.role IN ('admin', 'super_admin', 'moderator') 
AND up.status = 'active'
ORDER BY up.created_at;

-- =============================================
-- 6. 後續操作指引
-- =============================================

SELECT 
    '📋 後續操作指引' as guide_type,
    '1. 清除瀏覽器所有 TXN 相關的 localStorage 和 cookies' as step_1,
    '2. 重新登入 admin@txn.test' as step_2,
    '3. 如果仍有載入問題，按 F12 檢查瀏覽器控制台錯誤' as step_3,
    '4. 確認網路連線穩定，Supabase 服務正常' as step_4,
    '5. 如果問題持續，請檢查 Supabase 專案的配額和狀態' as step_5;

-- 完成通知
DO $$
BEGIN
    RAISE NOTICE '🎉 修復腳本執行完成！';
    RAISE NOTICE '📧 測試帳戶: admin@txn.test';
    RAISE NOTICE '🌐 登入頁面: /auth';
    RAISE NOTICE '⚡ 建議: 清除瀏覽器快取後重新登入';
END $$;