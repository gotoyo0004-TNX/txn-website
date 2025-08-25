# 📊 Supabase SQL 腳本管理

## 📁 資料夾結構

```
sql-scripts/
├── migrations/           # 資料庫遷移腳本
├── tables/              # 資料表建立腳本
├── functions/           # 資料庫函數
├── policies/            # RLS 安全政策
├── triggers/            # 觸發器
├── indexes/             # 索引優化
└── seed-data/           # 初始資料
```

## 📋 腳本命名規範

### 遷移腳本
```
YYYYMMDD_HHMMSS_描述.sql
例如：20240825_143000_create_users_table.sql
```

### 功能腳本
```
功能名稱_操作.sql
例如：user_auth_setup.sql
```

## 🔧 執行順序指南

### 1. 新專案初始化
```sql
-- 1. 建立基礎資料表
-- 2. 設定 RLS 政策
-- 3. 建立必要函數
-- 4. 插入初始資料
```

### 2. 功能更新
```sql
-- 1. 備份現有資料（如需要）
-- 2. 執行結構變更
-- 3. 更新 RLS 政策
-- 4. 測試新功能
```

## ⚠️ 安全提醒

1. **備份優先**：重要變更前先備份
2. **測試環境**：先在測試環境執行
3. **分步執行**：複雜變更分步驟執行
4. **回滾準備**：準備回滾腳本

## 📝 腳本範例

### 建立資料表範例
```sql
-- 建立用戶資料表
CREATE TABLE users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 建立 RLS 政策
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 用戶只能查看自己的資料
CREATE POLICY "Users can view own data" ON users
    FOR SELECT USING (auth.uid() = id);
```