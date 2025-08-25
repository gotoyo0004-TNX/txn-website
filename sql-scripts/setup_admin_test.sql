-- =============================================
-- 設置新測試管理員腳本
-- 功能: 為新創建的 admin@txn.test 用戶設置管理員權限
-- =============================================

-- 第一步：在 Supabase Dashboard > Authentication > Users 中創建用戶
-- Email: admin@txn.test
-- Password: AdminTest123!
-- 勾選 Auto Confirm User

-- 第二步：執行以下腳本（替換 YOUR_USER_ID 為實際的用戶 ID）

DO $$
DECLARE
    auth_user_id UUID;
    existing_admin_test BOOLEAN;
BEGIN
    -- 檢查是否有 admin@txn.test 的認證用戶
    SELECT id INTO auth_user_id
    FROM auth.users 
    WHERE email = 'admin@txn.test'
    LIMIT 1;
    
    IF auth_user_id IS NOT NULL THEN
        -- 檢查是否已有 profile
        SELECT EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth_user_id
        ) INTO existing_admin_test;
        
        IF existing_admin_test THEN
            -- 更新現有資料為管理員
            UPDATE public.user_profiles SET
                role = 'admin',
                status = 'active',
                full_name = 'TXN 測試管理員',
                approved_at = NOW(),
                approved_by = auth_user_id,
                updated_at = NOW()
            WHERE id = auth_user_id;
            
            RAISE NOTICE '✅ 已更新 admin@txn.test 為管理員';
        ELSE
            -- 創建新的管理員 profile
            INSERT INTO public.user_profiles (
                id,
                email,
                full_name,
                role,
                status,
                initial_capital,
                currency,
                timezone,
                trading_experience,
                approved_at,
                approved_by,
                created_at,
                updated_at
            ) VALUES (
                auth_user_id,
                'admin@txn.test',
                'TXN 測試管理員',
                'admin',
                'active',
                100000.00,
                'USD',
                'Asia/Taipei',
                'professional',
                NOW(),
                auth_user_id,
                NOW(),
                NOW()
            );
            
            RAISE NOTICE '✅ 已創建 admin@txn.test 管理員 profile';
        END IF;
        
        RAISE NOTICE '🔑 測試管理員帳號已設置完成';
        RAISE NOTICE '📧 郵箱: admin@txn.test';
        RAISE NOTICE '🔐 密碼: AdminTest123!';
        RAISE NOTICE '🌐 前往 /auth 頁面登入';
        
    ELSE
        RAISE NOTICE '❌ 未找到 admin@txn.test 的認證用戶';
        RAISE NOTICE '請先在 Supabase Dashboard > Authentication > Users 中創建此用戶';
        RAISE NOTICE '郵箱: admin@txn.test';
        RAISE NOTICE '密碼: AdminTest123!';
        RAISE NOTICE '記得勾選 Auto Confirm User';
    END IF;
END $$;

-- 驗證設置結果
SELECT 
    'admin@txn.test 設置驗證' as 驗證項目,
    CASE 
        WHEN EXISTS (SELECT 1 FROM auth.users WHERE email = 'admin@txn.test') 
        THEN '✅ 認證用戶已存在' 
        ELSE '❌ 認證用戶不存在' 
    END as 認證狀態,
    CASE 
        WHEN EXISTS (SELECT 1 FROM public.user_profiles WHERE email = 'admin@txn.test' AND role = 'admin' AND status = 'active') 
        THEN '✅ 管理員權限已設置' 
        ELSE '❌ 管理員權限未設置' 
    END as 權限狀態;