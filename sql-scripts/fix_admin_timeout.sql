-- =============================================
-- 修復管理員權限檢查超時問題
-- 版本: 1.0
-- 建立日期: 2024-12-19
-- =============================================

-- 🎯 專門修復 "管理員權限檢查超時" 錯誤

SELECT '🔧 開始修復管理員權限檢查超時問題...' as status;

-- =============================================
-- 1. 建立優化的管理員檢查函數
-- =============================================

-- 建立快速的管理員檢查函數
CREATE OR REPLACE FUNCTION public.is_admin_user_safe(user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    user_role TEXT;
    user_status TEXT;
BEGIN
    -- 使用簡單快速的查詢
    SELECT role, status INTO user_role, user_status
    FROM public.user_profiles 
    WHERE id = user_id
    LIMIT 1;
    
    -- 如果找不到用戶，返回 false
    IF user_role IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- 檢查是否為活躍的管理員
    RETURN (user_role IN ('admin', 'super_admin', 'moderator') AND user_status = 'active');
END;
$$;

-- =============================================
-- 2. 建立快速用戶角色檢查函數
-- =============================================

-- 建立專門用於快速角色檢查的函數
CREATE OR REPLACE FUNCTION public.get_user_role(user_id UUID)
RETURNS TABLE(
    role TEXT,
    status TEXT,
    email TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY 
    SELECT 
        up.role,
        up.status,
        up.email
    FROM public.user_profiles up
    WHERE up.id = user_id
    LIMIT 1;
END;
$$;

-- 設定權限
GRANT EXECUTE ON FUNCTION public.get_user_role(UUID) TO authenticated;

-- =============================================
-- 3. 測試管理員檢查函數
-- =============================================

-- 測試當前登入用戶的權限 (假設是 admin@txn.test)
SELECT 
    '🧪 管理員權限測試' as test_type,
    email,
    role,
    status,
    public.is_admin_user_safe(id) as is_admin
FROM public.user_profiles 
WHERE email = 'admin@txn.test';

-- =============================================
-- 4. 檢查並修復可能的 RLS 問題
-- =============================================

-- 檢查當前的 RLS 策略
SELECT 
    '🛡️ 當前 RLS 策略' as check_type,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'user_profiles' 
    AND schemaname = 'public'
ORDER BY policyname;

-- =============================================
-- 5. 建立簡化的管理員檢查策略
-- =============================================

-- 如果需要，建立一個簡化的管理員檢查策略
DO $$
BEGIN
    -- 檢查是否存在問題策略並移除
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_profiles' 
            AND policyname = 'admin_timeout_fix'
    ) THEN
        DROP POLICY admin_timeout_fix ON public.user_profiles;
    END IF;
    
    -- 建立新的快速管理員檢查策略
    CREATE POLICY admin_timeout_fix ON public.user_profiles
        FOR SELECT
        TO authenticated
        USING (
            -- 允許用戶查看自己的資料
            auth.uid() = id
            OR
            -- 或者使用簡單的管理員郵件檢查 (避免遞歸)
            auth.uid() IN (
                SELECT au.id 
                FROM auth.users au
                WHERE au.email IN ('admin@txn.test', 'gotoyo0004@gmail.com')
            )
        );
END $$;

-- =============================================
-- 6. 確保管理員帳戶資料正確
-- =============================================

-- 更新管理員帳戶，確保資料完整
UPDATE public.user_profiles 
SET 
    role = 'super_admin',
    status = 'active',
    full_name = COALESCE(full_name, 'TXN 系統管理員'),
    updated_at = NOW()
WHERE email = 'admin@txn.test';

-- 顯示更新後的管理員資料
SELECT 
    '👤 管理員帳戶狀態' as info_type,
    id,
    email,
    full_name,
    role,
    status,
    created_at,
    updated_at
FROM public.user_profiles 
WHERE email = 'admin@txn.test';

-- =============================================
-- 7. 測試修復結果
-- =============================================

-- 測試新的角色檢查函數
SELECT 
    '🧪 角色檢查測試' as test_type,
    role,
    status,
    email
FROM public.get_user_role(
    (SELECT id FROM public.user_profiles WHERE email = 'admin@txn.test')
);

-- 測試管理員權限函數
SELECT 
    '🧪 管理員權限函數測試' as test_type,
    public.is_admin_user_safe(
        (SELECT id FROM public.user_profiles WHERE email = 'admin@txn.test')
    ) as is_admin_result;

-- =============================================
-- 8. 完成通知
-- =============================================

SELECT '🎉 管理員權限超時問題修復完成！' as status;
SELECT '✅ 建立了優化的管理員檢查函數' as step_1;
SELECT '✅ 建立了快速角色檢查函數' as step_2;
SELECT '✅ 更新了 RLS 策略避免遞歸' as step_3;
SELECT '✅ 確認了管理員帳戶資料' as step_4;

SELECT '🔄 請執行以下步驟：' as next_steps;
SELECT '1. 重新整理管理員頁面' as step_a;
SELECT '2. 清除瀏覽器快取 (Ctrl+Shift+R)' as step_b;
SELECT '3. 重新登入 admin@txn.test' as step_c;

SELECT '🎯 預期結果：' as expected;
SELECT '管理員頁面應該不再出現超時錯誤' as result_1;
SELECT '權限檢查應該在 1-2 秒內完成' as result_2;
