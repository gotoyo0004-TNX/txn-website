-- =============================================
-- 🚀 TXN 資料庫快速執行指引
-- 執行此腳本以完成用戶認證系統的資料庫配置
-- =============================================

-- ⚠️ 重要：請在 Supabase SQL Editor 中執行以下腳本

-- 1️⃣ 如果這是全新安裝，請執行以下兩個腳本（按順序）：

/*
   第一步：執行基礎結構腳本
   檔案：sql-scripts/migrations/20240825_150000_txn_database_structure.sql
   
   第二步：執行認證系統更新腳本  
   檔案：sql-scripts/migrations/20250825_160000_auth_system_database_update.sql
*/

-- 2️⃣ 如果您已經有舊版本的資料庫，只需執行：

/*
   檔案：sql-scripts/migrations/20250825_160000_auth_system_database_update.sql
*/

-- 3️⃣ 執行後驗證（複製以下查詢並執行）：

-- 檢查資料表是否正確建立
SELECT * FROM validate_txn_database();

-- 檢查 RLS 政策
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public' 
ORDER BY tablename, policyname;

-- 檢查觸發器
SELECT trigger_name, event_object_table, action_timing
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND event_object_table IN ('user_profiles', 'strategies', 'trades')
ORDER BY event_object_table;

-- ✅ 成功指標：
-- 1. validate_txn_database() 顯示所有表格 exists = true
-- 2. 每個表格都有相應的 RLS 政策
-- 3. 觸發器正確建立

-- 🎉 完成後，您的 TXN 用戶認證系統就可以正常運作了！
-- 下一步：測試前端註冊/登入功能，確認 user_profiles 自動建立