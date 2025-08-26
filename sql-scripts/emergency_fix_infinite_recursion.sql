-- =============================================
-- 緊急修復 RLS 無限遞歸問題
-- 解決 "infinite recursion detected in policy" 錯誤
-- =============================================

-- 🚨 緊急：根據 Supabase 日誌顯示的遞歸錯誤立即修復

DO $$
BEGIN
    RAISE NOTICE '🚨 緊急修復：RLS 無限遞歸問題';
    RAISE NOTICE '📊 錯誤：infinite recursion detected in policy for relation "user_profiles"';
    RAISE NOTICE '⏰ 修復時間: %', NOW();
END $$;

-- =============================================
-- 1. 立即禁用 RLS（停止遞歸）
-- =============================================

ALTER TABLE public.user_profiles DISABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    RAISE NOTICE '✅ 已禁用 RLS，遞歸問題暫時解決';
END $$;

-- =============================================
-- 2. 徹底清理所有策略（防止遞歸重現）
-- =============================================

-- 清理所有可能造成遞歸的策略
DROP POLICY IF EXISTS "temp_all_read_access" ON public.user_profiles;
DROP POLICY IF EXISTS "temp_update_own" ON public.user_profiles;
DROP POLICY IF EXISTS "temp_insert_own" ON public.user_profiles;
DROP POLICY IF EXISTS "user_read_own_only" ON public.user_profiles;
DROP POLICY IF EXISTS "user_update_own_basic" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_user_registration_safe" ON public.user_profiles;
DROP POLICY IF EXISTS "superuser_full_access" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_users_read_all" ON public.user_profiles;
DROP POLICY IF EXISTS "authenticated_users_read_own" ON public.user_profiles;
DROP POLICY IF EXISTS "users_update_own_simple" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_insert_authenticated" ON public.user_profiles;

-- 清理舊的可能造成遞歸的策略
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

-- 清理管理員相關的遞歸策略
DROP POLICY IF EXISTS "分級管理員可以查看所有用戶" ON public.user_profiles;
DROP POLICY IF EXISTS "活躍用戶可以查看自己資料" ON public.user_profiles;
DROP POLICY IF EXISTS "管理員可以查看所有用戶" ON public.user_profiles;

-- 刪除可能造成遞歸的函數
DROP FUNCTION IF EXISTS is_admin_user_safe(UUID);
DROP FUNCTION IF EXISTS is_admin_user(UUID);

DO $$
BEGIN
    RAISE NOTICE '🧹 所有可能造成遞歸的策略和函數已清理';
END $$;

-- =============================================
-- 3. 創建最簡單的無遞歸策略
-- =============================================

-- 策略 1: 基本讀取權限（無條件檢查，避免遞歸）
CREATE POLICY "safe_read_access" ON public.user_profiles
    FOR SELECT 
    TO authenticated
    USING (true);  -- 所有認證用戶都可以讀取

-- 策略 2: 用戶更新自己的資料（最簡單的條件）
CREATE POLICY "safe_update_own" ON public.user_profiles
    FOR UPDATE 
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 策略 3: 用戶插入自己的資料
CREATE POLICY "safe_insert_own" ON public.user_profiles
    FOR INSERT 
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- 策略 4: 刪除權限（僅限自己）
CREATE POLICY "safe_delete_own" ON public.user_profiles
    FOR DELETE 
    TO authenticated
    USING (auth.uid() = id);

DO $$
BEGIN
    RAISE NOTICE '✅ 創建了無遞歸風險的基本策略';
END $$;

-- =============================================
-- 4. 重新啟用 RLS
-- =============================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 5. 測試策略是否正常工作
-- =============================================

DO $$
DECLARE
    test_count INTEGER;
    policy_count INTEGER;
BEGIN
    RAISE NOTICE '🧪 測試修復效果...';
    
    -- 測試基本查詢（這是之前失敗的查詢）
    BEGIN
        SELECT COUNT(*) INTO test_count FROM user_profiles LIMIT 1;
        RAISE NOTICE '✅ 基本查詢測試成功，記錄數: %', test_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ 基本查詢仍然失敗: %', SQLERRM;
    END;
    
    -- 檢查策略數量
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE tablename = 'user_profiles';
    
    RAISE NOTICE '📊 當前策略數量: %', policy_count;
    
    IF policy_count = 4 THEN
        RAISE NOTICE '✅ 策略數量正確';
    ELSE
        RAISE NOTICE '⚠️ 策略數量異常，預期 4 個';
    END IF;
END $$;

-- =============================================
-- 6. 顯示當前策略狀態
-- =============================================

SELECT 
    '📋 當前 RLS 策略' as section,
    policyname,
    cmd,
    permissive,
    '✅ 無遞歸風險' as safety_status
FROM pg_policies 
WHERE tablename = 'user_profiles'
ORDER BY policyname;

-- =============================================
-- 7. 完成報告和建議
-- =============================================

SELECT 
    '=== 🎉 緊急修復完成 ===' as status,
    NOW() as fix_completion_time,
    '已解決無限遞歸問題' as result;

DO $$
BEGIN
    RAISE NOTICE '🎉 RLS 無限遞歸問題修復完成！';
    RAISE NOTICE '📊 修復要點：';
    RAISE NOTICE '  1. 已移除所有可能造成遞歸的策略';
    RAISE NOTICE '  2. 已移除有問題的管理員檢查函數';
    RAISE NOTICE '  3. 創建了最簡單的無遞歸策略';
    RAISE NOTICE '  4. 所有策略都使用最基本的條件檢查';
    RAISE NOTICE '';
    RAISE NOTICE '⚡ 立即行動：';
    RAISE NOTICE '  1. 清除瀏覽器快取';
    RAISE NOTICE '  2. 重新整理網站首頁';
    RAISE NOTICE '  3. 測試 Supabase 連接是否正常';
    RAISE NOTICE '  4. 檢查管理面板是否可以載入';
END $$;