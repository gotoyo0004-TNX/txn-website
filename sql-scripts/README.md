# 📊 TXN 系統 SQL 腳本指南

本目錄包含 TXN 交易日誌系統的所有資料庫相關腳本。請按照以下順序執行以確保系統正常運作。

## 🚀 新系統設定 (推薦順序)

### 1. 完整資料庫設定
```sql
-- 執行此腳本建立完整的資料庫結構
sql-scripts/complete_database_setup.sql
```
**功能：**
- 建立所有核心資料表 (user_profiles, strategies, trades, performance_snapshots)
- 設定 RLS 安全策略
- 建立索引和觸發器
- 設定自動化函數

### 2. 建立管理員帳戶
```sql
-- 建立初始管理員帳戶
sql-scripts/create_admin_user.sql
```
**功能：**
- 建立測試管理員帳戶 (admin@txn.test)
- 設定管理員權限
- 提供登入指引

### 3. 系統健康檢查
```sql
-- 驗證系統設定是否正確
sql-scripts/system_health_check.sql
```
**功能：**
- 檢查資料表結構
- 驗證 RLS 策略
- 診斷常見問題
- 提供修復建議

## 🔄 現有系統升級

### 升級到 v2.0
```sql
-- 將現有系統升級到最新版本
sql-scripts/database_update_v2.sql
```
**功能：**
- 安全地更新資料表結構
- 保留現有資料
- 更新 RLS 策略
- 優化索引效能

## 🛠️ 問題修復腳本

### RLS 策略問題
```sql
-- 修復 RLS 無限遞歸問題
sql-scripts/fix_rls_simple_correct.sql
```

### 管理員權限問題
```sql
-- 修復管理員權限相關問題
sql-scripts/fix_admin_permission.sql
```

### 連接問題
```sql
-- 修復資料庫連接問題
sql-scripts/emergency_connection_fix.sql
```

## 📋 腳本分類說明

### 🏗️ 設定腳本
- `complete_database_setup.sql` - 完整資料庫設定
- `create_admin_user.sql` - 管理員帳戶建立
- `database_update_v2.sql` - 系統升級

### 🔍 診斷腳本
- `system_health_check.sql` - 系統健康檢查
- `diagnose_*.sql` - 各種診斷工具

### 🛠️ 修復腳本
- `fix_*.sql` - 各種問題修復
- `emergency_*.sql` - 緊急修復

### 📁 遷移腳本
- `migrations/` - 資料庫版本遷移腳本

## ⚠️ 重要注意事項

### 執行前準備
1. **備份資料庫** - 執行任何腳本前請先備份
2. **測試環境** - 建議先在測試環境執行
3. **維護時間** - 在低流量時間執行

### 執行順序
1. 新系統：`complete_database_setup.sql` → `create_admin_user.sql` → `system_health_check.sql`
2. 升級系統：`database_update_v2.sql` → `system_health_check.sql`
3. 問題修復：先執行診斷腳本，再執行對應修復腳本

### 安全考量
- 所有腳本都包含安全檢查
- RLS 策略確保資料安全
- 管理員權限嚴格控制

## 🎯 常見使用場景

### 場景 1：全新部署
```bash
# 1. 在 Supabase Dashboard 執行
complete_database_setup.sql

# 2. 建立管理員
create_admin_user.sql

# 3. 驗證設定
system_health_check.sql
```

### 場景 2：系統升級
```bash
# 1. 備份資料庫
# 2. 執行升級腳本
database_update_v2.sql

# 3. 檢查系統狀態
system_health_check.sql
```

### 場景 3：問題排除
```bash
# 1. 執行健康檢查
system_health_check.sql

# 2. 根據結果執行對應修復腳本
fix_rls_simple_correct.sql  # RLS 問題
fix_admin_permission.sql    # 權限問題
```

## 📞 支援資訊

### 執行環境
- **Supabase Dashboard** - SQL Editor
- **psql** - 命令列工具
- **pgAdmin** - 圖形化工具

### 日誌查看
執行腳本後，請查看：
1. Supabase Dashboard 的 Logs
2. 應用程式的 Console 輸出
3. 瀏覽器開發者工具

### 常見錯誤
1. **權限不足** - 確保使用 service_role key
2. **表已存在** - 腳本包含 IF EXISTS 檢查
3. **RLS 遞歸** - 使用 fix_rls_simple_correct.sql

## 🔄 版本歷史

### v2.0 (2024-12-19)
- 完整重構資料庫架構
- 新增完整的 RLS 安全策略
- 優化索引效能
- 新增系統健康檢查

### v1.0 (2024-08-25)
- 初始資料庫結構
- 基本 RLS 策略
- 管理員權限系統

## 📚 相關文件

- [部署指南](../DEPLOYMENT_GUIDE.md)
- [專案交接文件](../PROJECT_HANDOVER.md)
- [Supabase 設定指南](../SUPABASE_SETUP.md)

---

**重要提醒：** 執行任何 SQL 腳本前，請務必備份資料庫並在測試環境中驗證！
