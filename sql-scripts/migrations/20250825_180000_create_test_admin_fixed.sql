-- =============================================
-- TXN 測試管理員帳號創建腳本 (修復版)
-- 日期: 2025-08-25
-- 功能: 創建測試用管理員帳號 - 解決外鍵約束問題
-- 版本: v1.2 (修復外鍵約束錯誤和郵箱約束錯誤)
-- =============================================

-- 重要說明：
-- 1. 此腳本解決了外鍵約束錯誤。user_profiles.id 必須對應 auth.users 表中的真實用戶 ID。
-- 2. 建議先執行 20250825_185000_add_email_unique_constraint.sql 為郵箱欄位添加唯一約束
-- 3. 提供三種方法來創建測試管理員帳號：

-- =============================================
-- 方法一：手動設置 (推薦用於生產環境測試)
-- =============================================
-- 步驟：
-- 1. 在 Supabase Dashboard > Authentication > Users 中創建新用戶
-- 2. Email: admin@txn.test
-- 3. Password: AdminTest123!
-- 4. 複製生成的 User ID
-- 5. 將下面的 'YOUR_ACTUAL_USER_ID_HERE' 替換為真實的 User ID
-- 6. 取消註釋並執行以下代碼

/*
-- 替換 'YOUR_ACTUAL_USER_ID_HERE' 為從 Supabase Auth 獲得的真實用戶 ID
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
    'YOUR_ACTUAL_USER_ID_HERE'::uuid,  -- 替換為真實的用戶 ID
    'admin@txn.test',
    'TXN 測試管理員',
    'admin',
    'active',
    100000.00,
    'USD',
    'Asia/Taipei',
    'professional',
    NOW(),
    'YOUR_ACTUAL_USER_ID_HERE'::uuid,  -- 替換為真實的用戶 ID
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    role = 'admin',
    status = 'active',
    full_name = 'TXN 測試管理員',
    approved_at = NOW(),
    updated_at = NOW();

RAISE NOTICE '方法一：手動設置完成 - 管理員帳號已創建';
*/

-- =============================================
-- 方法二：動態設置 (自動檢測現有用戶)
-- =============================================
-- 此方法會檢查是否有匹配的認證用戶，如果有則設置為管理員

DO $$
DECLARE
    auth_user_id UUID;
    profile_exists BOOLEAN;
BEGIN
    -- 檢查是否有 admin@txn.test 的認證用戶
    SELECT au.id INTO auth_user_id
    FROM auth.users au 
    WHERE au.email = 'admin@txn.test' 
    LIMIT 1;
    
    IF auth_user_id IS NOT NULL THEN
        -- 檢查是否已有 user_profile
        SELECT EXISTS (
            SELECT 1 FROM public.user_profiles 
            WHERE id = auth_user_id
        ) INTO profile_exists;
        
        IF profile_exists THEN
            -- 更新現有資料
            UPDATE public.user_profiles SET
                role = 'admin',
                status = 'active',
                full_name = 'TXN 測試管理員',
                approved_at = NOW(),
                approved_by = auth_user_id,
                updated_at = NOW()
            WHERE id = auth_user_id;
            
            RAISE NOTICE '方法二：已更新現有用戶為管理員 - 用戶ID: %', auth_user_id;
        ELSE
            -- 創建新的 profile
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
            
            RAISE NOTICE '方法二：已創建管理員用戶資料 - 用戶ID: %', auth_user_id;
        END IF;
    ELSE
        RAISE NOTICE '方法二：未找到 admin@txn.test 的認證用戶，請先在 Supabase Auth 中創建';
        RAISE NOTICE '請前往 Supabase Dashboard > Authentication > Users 創建用戶';
        RAISE NOTICE 'Email: admin@txn.test, Password: AdminTest123!';
    END IF;
END $$;

-- =============================================
-- 方法三：測試環境設置 (使用臨時外鍵約束禁用)
-- =============================================
-- 此方法為純測試環境創建假用戶數據，臨時禁用外鍵約束
-- 注意：這僅適用於開發/測試環境，不應在生產環境使用

DO $$
DECLARE
    test_admin_id UUID;
    test_user_id_1 UUID;
    test_user_id_2 UUID;
    test_user_id_3 UUID;
    test_user_id_4 UUID;
    test_user_id_5 UUID;
    constraint_exists BOOLEAN;
BEGIN
    -- 檢查是否為測試環境（通過檢查是否有真實用戶來判斷）
    IF (SELECT COUNT(*) FROM auth.users) > 0 THEN
        RAISE NOTICE '檢測到真實用戶，跳過方法三（避免在生產環境執行）';
        RAISE NOTICE '如需測試，請使用方法一或方法二';
        RETURN;
    END IF;
    
    -- 生成測試用的 UUID
    test_admin_id := gen_random_uuid();
    test_user_id_1 := gen_random_uuid();
    test_user_id_2 := gen_random_uuid();
    test_user_id_3 := gen_random_uuid();
    test_user_id_4 := gen_random_uuid();
    test_user_id_5 := gen_random_uuid();
    
    RAISE NOTICE '方法三：測試環境設置開始（純開發測試）...';
    RAISE NOTICE '生成的測試管理員 ID: %', test_admin_id;
    
    -- 檢查外鍵約束是否存在
    SELECT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'user_profiles' 
        AND constraint_type = 'FOREIGN KEY' 
        AND constraint_name = 'user_profiles_id_fkey'
    ) INTO constraint_exists;
    
    IF constraint_exists THEN
        -- 臨時禁用外鍵約束（僅用於測試環境）
        RAISE NOTICE '臨時禁用外鍵約束以創建測試數據...';
        ALTER TABLE public.user_profiles DROP CONSTRAINT IF EXISTS user_profiles_id_fkey;
    END IF;
    
    -- 創建測試管理員
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
        test_admin_id,
        'test.admin@txn.local',
        'TXN 測試管理員 (測試環境)',
        'admin',
        'active',
        100000.00,
        'USD',
        'Asia/Taipei',
        'professional',
        NOW(),
        test_admin_id,
        NOW(),
        NOW()
    );
    
    -- 創建測試用的待審核用戶
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
        created_at,
        updated_at
    ) VALUES 
    (
        test_user_id_1,
        'pending.user1@test.local',
        '待審核測試用戶一',
        'user',
        'pending',
        10000.00,
        'USD',
        'Asia/Taipei',
        'beginner',
        NOW() - INTERVAL '2 hours',
        NOW() - INTERVAL '2 hours'
    ),
    (
        test_user_id_2,
        'pending.user2@test.local',
        '待審核測試用戶二',
        'user',
        'pending',
        25000.00,
        'USD',
        'Asia/Taipei',
        'intermediate',
        NOW() - INTERVAL '1 hour',
        NOW() - INTERVAL '1 hour'
    ),
    (
        test_user_id_3,
        'pending.user3@test.local',
        '待審核測試用戶三',
        'user',
        'pending',
        50000.00,
        'EUR',
        'Europe/London',
        'advanced',
        NOW() - INTERVAL '30 minutes',
        NOW() - INTERVAL '30 minutes'
    ),
    (
        test_user_id_4,
        'active.user@test.local',
        '活躍測試用戶',
        'user',
        'active',
        15000.00,
        'USD',
        'Asia/Taipei',
        'intermediate',
        NOW() - INTERVAL '1 day',
        test_admin_id,
        NOW() - INTERVAL '2 days',
        NOW() - INTERVAL '1 day'
    ),
    (
        test_user_id_5,
        'inactive.user@test.local',
        '已停用測試用戶',
        'user',
        'inactive',
        5000.00,
        'USD',
        'Asia/Taipei',
        'beginner',
        NOW() - INTERVAL '3 days',
        NOW() - INTERVAL '1 day'
    );
    
    -- 創建預設策略
    INSERT INTO public.strategies (user_id, name, description, color) VALUES
    (test_admin_id, '管理員測試策略', '用於測試的管理員策略', '#22C55E'),
    (test_user_id_4, '活躍用戶策略', '活躍用戶的測試策略', '#3B82F6')
    ON CONFLICT (user_id, name) DO NOTHING;
    
    -- 創建管理員操作日誌
    INSERT INTO public.admin_logs (admin_id, action, target_user_id, details) VALUES
    (test_admin_id, 'approve_user', test_user_id_4, 
     jsonb_build_object('timestamp', NOW() - INTERVAL '1 day', 'reason', '測試批准')),
    (test_admin_id, 'deactivate_user', test_user_id_5, 
     jsonb_build_object('timestamp', NOW() - INTERVAL '1 day', 'reason', '測試停用'))
    ON CONFLICT DO NOTHING;
    
    -- 重新啟用外鍵約束（如果之前存在）
    IF constraint_exists THEN
        RAISE NOTICE '重新啟用外鍵約束...';
        ALTER TABLE public.user_profiles 
        ADD CONSTRAINT user_profiles_id_fkey 
        FOREIGN KEY (id) REFERENCES auth.users(id);
        
        RAISE NOTICE '⚠️  注意：外鍵約束已重新啟用';
        RAISE NOTICE '⚠️  測試數據創建時臨時禁用了約束，現已恢復';
    END IF;
    
    RAISE NOTICE '方法三：測試環境設置完成';
    RAISE NOTICE '注意：方法三創建的用戶無法登入，僅用於測試管理面板顯示';
    RAISE NOTICE '如需要登入測試，請使用方法一或方法二';
    
EXCEPTION
    WHEN OTHERS THEN
        -- 如果出錯，確保恢復外鍵約束
        IF constraint_exists THEN
            BEGIN
                ALTER TABLE public.user_profiles 
                ADD CONSTRAINT user_profiles_id_fkey 
                FOREIGN KEY (id) REFERENCES auth.users(id);
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE '警告：無法恢復外鍵約束，請手動檢查';
            END;
        END IF;
        
        RAISE EXCEPTION '方法三執行失敗: %', SQLERRM;
END $$;

-- =============================================
-- 顯示設置狀態
-- =============================================
DO $$
DECLARE
    admin_count INTEGER;
    pending_count INTEGER;
    total_count INTEGER;
BEGIN
    -- 統計管理員數量
    SELECT COUNT(*) INTO admin_count
    FROM public.user_profiles 
    WHERE role = 'admin' AND status = 'active';
    
    -- 統計待審核用戶數量
    SELECT COUNT(*) INTO pending_count
    FROM public.user_profiles 
    WHERE status = 'pending';
    
    -- 統計總用戶數量
    SELECT COUNT(*) INTO total_count
    FROM public.user_profiles;
    
    RAISE NOTICE '=== 設置狀態報告 ===';
    RAISE NOTICE '活躍管理員數量: %', admin_count;
    RAISE NOTICE '待審核用戶數量: %', pending_count;
    RAISE NOTICE '總用戶數量: %', total_count;
    RAISE NOTICE '';
    
    IF admin_count > 0 THEN
        RAISE NOTICE '✅ 管理員帳號設置完成';
        RAISE NOTICE '您現在可以訪問 /admin 頁面測試管理功能';
    ELSE
        RAISE NOTICE '⚠️  未檢測到活躍管理員帳號';
        RAISE NOTICE '請使用方法一或方法二創建管理員帳號';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== 使用說明 ===';
    RAISE NOTICE '• 方法一：適用於需要真正登入的測試';
    RAISE NOTICE '• 方法二：自動檢測現有認證用戶並設置為管理員';
    RAISE NOTICE '• 方法三：純數據測試，無法登入但可測試面板顯示';
END $$;

-- =============================================
-- 清理腳本 (如需要)
-- =============================================
-- 如果需要清理測試數據，請執行以下腳本：

/*
-- 清理測試數據
DELETE FROM public.admin_logs 
WHERE admin_id IN (
    SELECT id FROM public.user_profiles 
    WHERE email LIKE '%.local' OR email LIKE '%@test.%'
);

DELETE FROM public.strategies 
WHERE user_id IN (
    SELECT id FROM public.user_profiles 
    WHERE email LIKE '%.local' OR email LIKE '%@test.%'
);

DELETE FROM public.user_profiles 
WHERE email LIKE '%.local' OR email LIKE '%@test.%';

RAISE NOTICE '測試數據已清理完成';
*/

-- =============================================
-- 執行完成
-- =============================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 腳本執行完成！';
    RAISE NOTICE '請檢查上方的設置狀態報告';
    RAISE NOTICE '如有問題，請參考 TEST_ADMIN_SETUP.md 文件';
END $$;