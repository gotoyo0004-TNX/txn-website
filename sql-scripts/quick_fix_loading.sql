-- =============================================
-- 快速修復管理面板載入問題
-- 專門解決 Supabase 連接緩慢和權限檢查問題
-- =============================================

-- 🚀 這是精簡版腳本，專注解決載入問題

-- 1. 直接修復管理員帳戶 (無診斷輸出)
DO $$
DECLARE
    admin_uuid UUID;
BEGIN
    -- 獲取用戶 UUID
    SELECT id INTO admin_uuid FROM auth.users WHERE email = 'admin@txn.test' LIMIT 1;
    
    IF admin_uuid IS NOT NULL THEN
        -- 強制更新/插入管理員資料
        INSERT INTO user_profiles (
            id, email, full_name, role, status, trading_experience,
            initial_capital, currency, timezone, created_at, updated_at, approved_at, approved_by
        ) VALUES (
            admin_uuid, 'admin@txn.test', 'TXN 系統管理員', 'admin', 'active', 
            'professional', 100000, 'USD', 'Asia/Taipei', NOW(), NOW(), NOW(), admin_uuid
        )
        ON CONFLICT (id) DO UPDATE SET
            role = 'admin',
            status = 'active',
            updated_at = NOW(),
            approved_at = COALESCE(user_profiles.approved_at, NOW());
    END IF;
END $$;

-- 2. 重建高效能 RLS 策略（完全清理舊策略）
DROP POLICY IF EXISTS "user_read_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_read_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "user_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admin_update_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_view_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admins_can_view_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "users_can_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "admins_can_update_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "enable_user_registration" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_user_registration" ON public.user_profiles;

CREATE POLICY "user_read_own_profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "admin_read_all_profiles" ON public.user_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles p
            WHERE p.id = auth.uid() 
            AND p.role IN ('admin', 'super_admin', 'moderator')
            AND p.status = 'active'
        )
    );

CREATE POLICY "user_update_own_profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "admin_update_all_profiles" ON public.user_profiles
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles p
            WHERE p.id = auth.uid() 
            AND p.role IN ('admin', 'super_admin', 'moderator')
            AND p.status = 'active'
        )
    );

-- 3. 性能優化索引
CREATE INDEX IF NOT EXISTS idx_profiles_fast_auth 
ON public.user_profiles(id, role, status) 
WHERE status = 'active';

-- 完成
SELECT 
    '✅ 快速修復完成' as status,
    '請清除瀏覽器快取並重新登入' as next_step;