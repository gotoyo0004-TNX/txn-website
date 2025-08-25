-- =============================================
-- TXN 數據庫結構優化 - 添加郵箱唯一約束
-- 日期: 2025-08-25
-- 功能: 為 user_profiles 表的 email 欄位添加唯一約束
-- 版本: v3.1 (結構優化)
-- =============================================

-- 說明：
-- 此腳本為 user_profiles 表的 email 欄位添加唯一約束
-- 這將允許在未來的插入操作中使用 ON CONFLICT (email) 語法
-- 執行前會檢查並處理可能存在的重複郵箱記錄

-- 1. 檢查並處理重複的郵箱記錄
DO $$
DECLARE
    duplicate_count INTEGER;
    rec RECORD;
BEGIN
    -- 檢查是否有重複的郵箱
    SELECT COUNT(*) INTO duplicate_count
    FROM (
        SELECT email, COUNT(*) as count
        FROM public.user_profiles
        WHERE email IS NOT NULL AND email != ''
        GROUP BY email
        HAVING COUNT(*) > 1
    ) duplicates;
    
    IF duplicate_count > 0 THEN
        RAISE NOTICE '發現 % 個重複的郵箱記錄，開始處理...', duplicate_count;
        
        -- 對每個重複的郵箱，保留最早創建的記錄，其他的加上時間戳後綴
        FOR rec IN (
            SELECT email, COUNT(*) as count
            FROM public.user_profiles
            WHERE email IS NOT NULL AND email != ''
            GROUP BY email
            HAVING COUNT(*) > 1
        ) LOOP
            RAISE NOTICE '處理重複郵箱: %', rec.email;
            
            -- 為重複記錄添加時間戳後綴（除了最早的記錄）
            UPDATE public.user_profiles 
            SET email = email || '_' || EXTRACT(EPOCH FROM created_at)::text
            WHERE email = rec.email 
            AND id NOT IN (
                SELECT id 
                FROM public.user_profiles 
                WHERE email = rec.email 
                ORDER BY created_at ASC 
                LIMIT 1
            );
        END LOOP;
        
        RAISE NOTICE '重複郵箱記錄處理完成';
    ELSE
        RAISE NOTICE '未發現重複的郵箱記錄';
    END IF;
END $$;

-- 2. 添加郵箱唯一約束
DO $$
BEGIN
    -- 檢查約束是否已存在
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE table_name = 'user_profiles' 
        AND constraint_type = 'UNIQUE' 
        AND constraint_name = 'user_profiles_email_unique'
    ) THEN
        -- 添加唯一約束
        ALTER TABLE public.user_profiles 
        ADD CONSTRAINT user_profiles_email_unique UNIQUE (email);
        
        RAISE NOTICE '✅ 郵箱唯一約束添加成功';
    ELSE
        RAISE NOTICE 'ℹ️  郵箱唯一約束已存在，跳過創建';
    END IF;
EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION '添加唯一約束失敗：仍存在重複的郵箱記錄。請檢查數據並手動處理重複項。';
    WHEN OTHERS THEN
        RAISE EXCEPTION '添加唯一約束時發生錯誤: %', SQLERRM;
END $$;

-- 3. 添加相關索引優化（如果不存在）
DO $$
BEGIN
    -- 檢查索引是否已存在
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_indexes 
        WHERE tablename = 'user_profiles' 
        AND indexname = 'idx_user_profiles_email_unique'
    ) THEN
        -- 由於添加了唯一約束，PostgreSQL 會自動創建索引
        -- 但我們可以確保索引名稱符合我們的命名規範
        RAISE NOTICE 'ℹ️  唯一約束會自動創建索引';
    ELSE
        RAISE NOTICE 'ℹ️  郵箱索引已存在';
    END IF;
END $$;

-- 4. 驗證約束是否正確添加
DO $$
DECLARE
    constraint_exists BOOLEAN;
    unique_emails_count INTEGER;
    total_emails_count INTEGER;
BEGIN
    -- 檢查約束是否存在
    SELECT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE table_name = 'user_profiles' 
        AND constraint_type = 'UNIQUE' 
        AND constraint_name = 'user_profiles_email_unique'
    ) INTO constraint_exists;
    
    -- 檢查郵箱的唯一性
    SELECT COUNT(DISTINCT email) INTO unique_emails_count
    FROM public.user_profiles 
    WHERE email IS NOT NULL AND email != '';
    
    SELECT COUNT(*) INTO total_emails_count
    FROM public.user_profiles 
    WHERE email IS NOT NULL AND email != '';
    
    RAISE NOTICE '';
    RAISE NOTICE '=== 驗證結果 ===';
    RAISE NOTICE '唯一約束存在: %', CASE WHEN constraint_exists THEN '✅ 是' ELSE '❌ 否' END;
    RAISE NOTICE '唯一郵箱數量: %', unique_emails_count;
    RAISE NOTICE '總郵箱記錄數: %', total_emails_count;
    
    IF constraint_exists AND unique_emails_count = total_emails_count THEN
        RAISE NOTICE '✅ 郵箱唯一約束設置成功！';
        RAISE NOTICE 'ℹ️  現在可以在插入語句中使用 ON CONFLICT (email) 語法';
    ELSE
        RAISE NOTICE '⚠️  設置過程中可能出現問題，請檢查';
    END IF;
END $$;

-- 5. 使用示例
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== 使用示例 ===';
    RAISE NOTICE '現在可以使用以下語法：';
    RAISE NOTICE '';
    RAISE NOTICE 'INSERT INTO public.user_profiles (id, email, full_name, ...)';
    RAISE NOTICE 'VALUES (uuid_value, ''user@example.com'', ''用戶名'', ...)';
    RAISE NOTICE 'ON CONFLICT (email) DO UPDATE SET';
    RAISE NOTICE '    full_name = EXCLUDED.full_name,';
    RAISE NOTICE '    updated_at = NOW();';
    RAISE NOTICE '';
END $$;

-- =============================================
-- 執行完成
-- =============================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 數據庫結構優化完成！';
    RAISE NOTICE '📧 郵箱唯一約束已添加';
    RAISE NOTICE '🔧 現在可以安全使用測試管理員腳本了';
END $$;