-- =============================================
-- TXN 管理面板性能優化腳本
-- 專門解決載入慢和查詢性能問題
-- =============================================

-- 1. 分析當前表的性能狀況
SELECT 
    '📊 user_profiles 表統計' as info,
    COUNT(*) as total_users,
    COUNT(*) FILTER (WHERE status = 'active') as active_users,
    COUNT(*) FILTER (WHERE role IN ('admin', 'super_admin', 'moderator')) as admin_users,
    pg_size_pretty(pg_total_relation_size('user_profiles')) as table_size;

-- 2. 檢查現有索引
SELECT 
    '📋 現有索引' as info,
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'user_profiles' 
ORDER BY indexname;

-- 3. 建立高效能索引（如果不存在）
-- 為管理員權限檢查優化
DROP INDEX IF EXISTS idx_user_profiles_admin_fast;
CREATE INDEX idx_user_profiles_admin_fast 
ON public.user_profiles(id, role, status) 
WHERE status = 'active' AND role IN ('admin', 'super_admin', 'moderator');

-- 為一般權限檢查優化
DROP INDEX IF EXISTS idx_user_profiles_auth_fast;
CREATE INDEX idx_user_profiles_auth_fast 
ON public.user_profiles(id) 
WHERE status = 'active';

-- 為角色查詢優化
DROP INDEX IF EXISTS idx_user_profiles_role_status;
CREATE INDEX idx_user_profiles_role_status 
ON public.user_profiles(role, status);

-- 4. 優化 RLS 策略查詢性能
-- 創建專門的函數來檢查管理員權限
CREATE OR REPLACE FUNCTION is_admin_user(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.user_profiles 
        WHERE id = user_id 
        AND role IN ('admin', 'super_admin', 'moderator')
        AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 5. 重建優化的 RLS 策略
DROP POLICY IF EXISTS "admin_read_all_profiles" ON public.user_profiles;
CREATE POLICY "admin_read_all_profiles" ON public.user_profiles
    FOR SELECT USING (is_admin_user(auth.uid()));

DROP POLICY IF EXISTS "admin_update_all_profiles" ON public.user_profiles;
CREATE POLICY "admin_update_all_profiles" ON public.user_profiles
    FOR UPDATE USING (is_admin_user(auth.uid()));

-- 6. 分析查詢計劃（僅供參考）
-- 這些查詢展示了優化後的性能
EXPLAIN (ANALYZE, BUFFERS) 
SELECT role, status FROM user_profiles WHERE id = (
    SELECT id FROM auth.users WHERE email = 'admin@txn.test' LIMIT 1
);

-- 7. 清理無用資料和優化表結構
-- 重新計算表統計信息
ANALYZE public.user_profiles;

-- 8. 檢查 RLS 策略性能
SELECT 
    '🛡️ RLS 策略檢查' as info,
    schemaname,
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN policyname LIKE '%admin%' THEN '管理員相關策略'
        WHEN policyname LIKE '%user%' THEN '用戶相關策略'
        ELSE '其他策略'
    END as policy_type
FROM pg_policies 
WHERE tablename = 'user_profiles'
ORDER BY policy_type, policyname;

-- 9. 顯示優化結果
SELECT 
    '✅ 性能優化完成' as status,
    '已建立高效能索引和函數' as optimization,
    '建議清除瀏覽器快取並重新登入' as next_step;