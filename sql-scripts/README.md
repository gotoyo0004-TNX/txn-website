# TXN 資料庫遷移腳本

本目錄包含 TXN 交易日誌系統的所有資料庫遷移腳本。

## 📁 腳本目錄結構

```
sql-scripts/
├── migrations/
│   ├── 20240825_143000_initial_database_setup.sql     # 初始資料庫設置 (已棄用)
│   ├── 20240825_150000_txn_database_structure.sql     # TXN 專用資料表結構
│   └── 20250825_160000_auth_system_database_update.sql # 🆕 用戶認證系統兼容更新
└── README.md
```

## 🚀 執行順序

**重要：請按照以下順序執行腳本**

### 第一次安裝
如果您是第一次設置資料庫：

1. **跳過** `20240825_143000_initial_database_setup.sql` (已棄用)
2. **執行** `20240825_150000_txn_database_structure.sql` (建立基礎結構)
3. **執行** `20250825_160000_auth_system_database_update.sql` (配合認證系統)

### 從舊版本升級
如果您已經執行過舊腳本：

1. **直接執行** `20250825_160000_auth_system_database_update.sql`

## 📋 最新腳本功能 (20250825_160000)

### ✅ **已實作功能**
- **用戶認證系統完整支援**
  - 與 `AuthContext.tsx` 完全匹配的資料表結構
  - 自動建立用戶資料 (`user_profiles`)
  - 預設策略自動產生

- **安全性增強**
  - Row Level Security (RLS) 政策
  - 用戶資料隔離保護
  - 清除舊政策並重新建立

- **自動化功能**
  - 交易損益自動計算
  - 風險回報比 (R/R Ratio) 計算
  - 策略統計自動更新
  - `updated_at` 欄位自動維護

### 🚀 **準備中的功能**
- **交易記錄管理** (第二階段開發)
  - 新增/編輯交易 Modal 視窗
  - 交易表單組件
  - CRUD 功能
  - 篩選器和排序

- **數據視覺化** (第三階段開發)
  - 績效快照表 (`performance_snapshots`)
  - KPI 計算邏輯
  - 儀表板數據優化

## 🔧 如何執行腳本

### 方法 1: Supabase 管理介面
1. 登入 [Supabase Dashboard](https://supabase.com/dashboard)
2. 選擇您的專案
3. 點選左側 "SQL Editor"
4. 複製腳本內容並執行

### 方法 2: 命令列 (需要 psql)
```bash
# 連接到您的 Supabase 資料庫
psql "postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres"

# 執行腳本
\i sql-scripts/migrations/20250825_160000_auth_system_database_update.sql
```

## ✅ 執行後驗證

執行腳本後，您可以運行以下查詢來驗證安裝：

```sql
-- 檢查資料表和政策
SELECT * FROM validate_txn_database();

-- 檢查觸發器
SELECT 
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND event_object_table IN ('user_profiles', 'strategies', 'trades', 'performance_snapshots')
ORDER BY event_object_table, trigger_name;
```

## 🔍 資料表結構說明

### `user_profiles` - 用戶資料表
- 擴展 Supabase Auth 的用戶資料
- 包含 TXN 專用欄位：初始資金、幣別、交易經驗等
- 與 `AuthContext.tsx` 預設值完全匹配

### `strategies` - 交易策略表
- 用戶自定義交易策略
- 自動計算統計數據（勝率、平均損益等）
- 新用戶會自動獲得 3 個預設策略

### `trades` - 交易記錄表
- 核心交易數據存儲
- 自動計算損益和風險回報比
- 支援加密貨幣精度 (8 位小數)

### `performance_snapshots` - 績效快照表
- 用於儀表板性能優化
- 每日績效數據快照
- 權益曲線數據存儲

## 🛠️ 故障排除

### 常見問題

**1. RLS 政策錯誤**
```sql
-- 如果遇到權限問題，檢查 RLS 政策
SELECT * FROM pg_policies WHERE schemaname = 'public';
```

**2. 觸發器未生效**
```sql
-- 檢查觸發器狀態
SELECT * FROM information_schema.triggers 
WHERE trigger_schema = 'public';
```

**3. 預設策略未建立**
```sql
-- 手動為現有用戶建立預設策略
SELECT create_default_strategies() FROM auth.users;
```

## 📞 技術支援

如果您在執行腳本時遇到問題：

1. 檢查 Supabase 連接是否正常
2. 確認您有足夠的資料庫權限
3. 查看 Supabase 日誌了解詳細錯誤
4. 參考本 README 的故障排除部分

---

**最後更新：2025-08-25**  
**版本：v3.0 (Auth System Compatible)**