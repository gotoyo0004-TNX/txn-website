# 🚀 TXN 系統 SQL 腳本執行順序指南

## 📋 您當前的情況

根據您的描述：
- ✅ 管理員頁面 (`/admin`) - Supabase 連接成功
- ❌ 首頁 (`/`) - Supabase 連接失敗
- 🔐 已登入帳戶：`admin@txn.test`

**問題原因：** RLS (Row Level Security) 策略阻止未登入用戶查詢資料表

## 🎯 立即修復方案

### 方案一：快速修復 (推薦)
```sql
-- 在 Supabase Dashboard 的 SQL Editor 中執行
sql-scripts/quick_fix_current_issue.sql
```

**此腳本將：**
- ✅ 建立允許連接測試的 RLS 策略
- ✅ 建立公開的系統健康檢查函數
- ✅ 修復首頁連接問題
- ✅ 保留現有資料和設定

### 方案二：完整重建 (如果方案一無效)

**步驟 1：安全清理**
```sql
sql-scripts/safe_cleanup_before_setup.sql
```

**步驟 2：重新建立**
```sql
sql-scripts/complete_database_setup.sql
```

**步驟 3：重建管理員**
```sql
sql-scripts/create_admin_user.sql
```

**步驟 4：驗證設定**
```sql
sql-scripts/system_health_check.sql
```

## 📊 執行後驗證步驟

### 1. 檢查 SQL 執行結果
確保所有腳本都顯示 "✅ 成功" 訊息

### 2. 重新啟動應用程式
```bash
# 停止開發伺服器 (Ctrl+C)
# 重新啟動
npm run dev
```

### 3. 測試連接狀態
- **首頁測試** - 前往 `https://bespoke-gecko-b54fbd.netlify.app/`
  - 應該顯示 "Supabase 基本連接成功"
- **管理員測試** - 前往 `https://bespoke-gecko-b54fbd.netlify.app/admin`
  - 應該正常顯示管理面板

### 4. 清除瀏覽器快取
```
Ctrl + Shift + R (強制重新整理)
或
F12 > Application > Storage > Clear storage
```

## 🔧 如果仍有問題

### 檢查清單
- [ ] Supabase 專案狀態正常
- [ ] 環境變數設定正確
- [ ] SQL 腳本執行無錯誤
- [ ] 瀏覽器快取已清除
- [ ] 應用程式已重新啟動

### 診斷工具
```sql
-- 執行系統診斷
sql-scripts/system_health_check.sql
```

### 常見錯誤解決
1. **函數依賴錯誤** - 使用 `safe_cleanup_before_setup.sql`
2. **RLS 遞歸錯誤** - 使用 `fix_rls_simple_correct.sql`
3. **權限錯誤** - 使用 `fix_admin_permission.sql`

## 📞 緊急聯絡

如果上述方案都無法解決問題，請：

1. **收集錯誤資訊**
   - 瀏覽器 Console 錯誤訊息
   - Supabase Dashboard Logs
   - SQL 執行結果

2. **提供系統資訊**
   - 當前使用的腳本版本
   - 錯誤發生的具體步驟
   - 系統環境資訊

## 🎉 成功標準

修復完成後，您應該看到：

### 首頁 (`/`)
```
✅ Supabase 基本連接成功！
📊 資料庫結構檢查 (基於連接測試推斷)
✅ user_profiles (用戶資料)
✅ strategies (交易策略)  
✅ trades (交易記錄)
✅ performance_snapshots (績效快照)
```

### 管理員頁面 (`/admin`)
```
✅ Supabase 連接成功
👤 admin@txn.test 登入成功
🎛️ 管理面板正常顯示
```

---

**重要提醒：** 請按照順序執行腳本，並在每個步驟後驗證結果！
