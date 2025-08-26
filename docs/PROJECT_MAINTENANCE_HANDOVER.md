# TXN 專案維護交接文檔

## 📋 專案概述

**專案名稱**：TXN - 線上交易日誌系統  
**技術棧**：Next.js 15, TypeScript, Tailwind CSS, Supabase, Netlify  
**部署地址**：https://bespoke-gecko-b54fbd.netlify.app/  
**管理面板**：https://bespoke-gecko-b54fbd.netlify.app/admin  
**維護責任**：全端開發者、系統管理員  

---

## 🏗️ 系統架構

### 前端 (Next.js 15)
- **框架**：Next.js 15 with App Router
- **語言**：TypeScript
- **樣式**：Tailwind CSS
- **狀態管理**：React Context API
- **部署**：Netlify 自動部署

### 後端 (Supabase)
- **資料庫**：PostgreSQL
- **認證**：Supabase Auth
- **API**：自動生成 REST API
- **存儲**：Supabase Storage
- **即時功能**：Realtime subscriptions

### 關鍵目錄結構
```
txn-website/
├── src/
│   ├── app/                 # Next.js App Router 頁面
│   │   ├── (admin)/        # 管理員面板
│   │   ├── auth/           # 認證頁面
│   │   └── page.tsx        # 首頁
│   ├── components/         # React 組件
│   ├── contexts/          # React Context
│   ├── lib/               # 工具函數和配置
│   └── styles/            # 全域樣式
├── sql-scripts/           # 資料庫腳本
├── docs/                  # 文檔目錄
└── public/               # 靜態資源
```

---

## 🔧 日常維護任務

### 每日檢查 (5 分鐘)
1. **系統狀態檢查**
   - 訪問首頁確認正常運行
   - 檢查 Supabase 連接狀態
   - 查看 Netlify 部署狀態

2. **關鍵服務監控**
   ```bash
   # 檢查網站可用性
   curl -I https://bespoke-gecko-b54fbd.netlify.app/
   
   # 檢查管理面板
   curl -I https://bespoke-gecko-b54fbd.netlify.app/admin
   ```

### 每週維護 (15 分鐘)
1. **資料庫健康檢查**
   ```sql
   -- 連接數量
   SELECT COUNT(*) as connections FROM pg_stat_activity;
   
   -- 表大小
   SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size 
   FROM pg_tables WHERE schemaname = 'public';
   
   -- 管理員用戶狀態
   SELECT * FROM user_profiles WHERE role = 'admin';
   ```

2. **性能監控**
   ```sql
   -- 慢查詢檢查
   SELECT query, mean_exec_time, calls 
   FROM pg_stat_statements 
   WHERE mean_exec_time > 1000 
   ORDER BY mean_exec_time DESC LIMIT 10;
   ```

3. **安全檢查**
   - 檢查管理員帳號狀態
   - 查看異常登入嘗試
   - 確認 RLS 策略正常

### 每月維護 (30 分鐘)
1. **資料庫優化**
   ```sql
   -- 更新統計信息
   ANALYZE;
   
   -- 檢查索引使用情況
   SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch 
   FROM pg_stat_user_indexes;
   ```

2. **日誌分析**
   - 檢查 Netlify 部署日誌
   - 查看 Supabase 使用統計
   - 分析用戶活動模式

---

## 🚨 緊急情況處理

### 常見問題與解決方案

#### 1. 網站無法訪問
**症狀**：網站返回 500 錯誤或無法載入  
**檢查步驟**：
1. 檢查 Netlify 部署狀態
2. 查看最近的 Git 提交
3. 檢查環境變數設定

**解決方案**：
```bash
# 回滾到上一個成功的部署
# 在 Netlify Dashboard 中點擊 "Rollback"
```

#### 2. Supabase 連接問題
**症狀**：前端顯示資料庫連接失敗  
**緊急修復**：執行 [`supabase_safe_emergency_fix.sql`](../sql-scripts/supabase_safe_emergency_fix.sql)

**詳細指南**：參考 [`SUPABASE_EMERGENCY_FIX_GUIDE.md`](./SUPABASE_EMERGENCY_FIX_GUIDE.md)

#### 3. 管理面板無法訪問
**症狀**：管理員無法登入或看到權限錯誤  
**快速修復**：
1. 檢查管理員用戶是否存在
2. 執行緊急修復腳本
3. 清除瀏覽器快取重試

**快速參考**：[`QUICK_FIX_REFERENCE.md`](./QUICK_FIX_REFERENCE.md)

#### 4. 404 錯誤
**症狀**：某些頁面顯示 404 Not Found  
**檢查項目**：
- 確認路由文件是否存在
- 檢查 Netlify 重定向規則
- 驗證 Next.js 構建是否成功

---

## 🔐 系統訪問權限

### Supabase Dashboard
- **URL**：https://supabase.com/dashboard
- **專案 ID**：[在 Dashboard 中查看]
- **關鍵頁面**：
  - SQL Editor：執行資料庫腳本
  - Authentication：管理用戶
  - Table Editor：查看和編輯資料

### Netlify Dashboard  
- **URL**：https://app.netlify.com/sites/bespoke-gecko-b54fbd
- **關鍵功能**：
  - Deploys：查看部署歷史
  - Settings：環境變數配置
  - Functions：無服務器函數管理

### GitHub Repository
- **URL**：[在 Netlify 設定中查看連結的 GitHub repo]
- **分支策略**：
  - `main`：生產環境
  - `develop`：開發環境
  - `feature/*`：功能分支

---

## 📊 監控和分析

### 關鍵指標
1. **網站性能**
   - 首次內容繪製 (FCP) < 1.5s
   - 最大內容繪製 (LCP) < 2.5s
   - 累積佈局偏移 (CLS) < 0.1

2. **資料庫性能**
   - 查詢響應時間 < 200ms
   - 連接數量 < 20
   - 資料庫大小增長率

3. **用戶活動**
   - 日活躍用戶 (DAU)
   - 管理面板使用頻率
   - 錯誤率 < 1%

### 監控工具設定
1. **Netlify Analytics**：自動啟用
2. **Supabase Metrics**：在 Dashboard 中查看
3. **瀏覽器開發者工具**：本地調試使用

---

## 🚀 部署流程

### 自動部署 (推薦)
1. **觸發條件**：推送到 `main` 分支
2. **構建命令**：`npm run build`
3. **發布目錄**：`.next`
4. **環境變數**：在 Netlify 中設定

### 手動部署 (緊急情況)
```bash
# 本地構建
npm install
npm run build

# 手動上傳到 Netlify
# 使用 Netlify CLI 或直接拖拽 .next 資料夾
```

### 環境變數清單
```env
NEXT_PUBLIC_SUPABASE_URL=https://[project-id].supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=[anon-key]
NEXT_PUBLIC_SITE_URL=https://bespoke-gecko-b54fbd.netlify.app
```

---

## 🛠️ 開發環境設置

### 本地開發
```bash
# 克隆專案
git clone [repository-url]
cd txn-website

# 安裝依賴
npm install

# 設置環境變數
cp .env.example .env.local
# 編輯 .env.local 填入正確的值

# 啟動開發服務器
npm run dev
```

### 常用命令
```bash
npm run dev          # 開發模式
npm run build        # 生產構建
npm run start        # 生產模式預覽
npm run lint         # 代碼檢查
npm run type-check   # TypeScript 檢查
```

---

## 📚 重要文件說明

### 配置文件
- **`package.json`**：依賴管理和腳本
- **`next.config.js`**：Next.js 配置
- **`tailwind.config.js`**：樣式配置
- **`tsconfig.json`**：TypeScript 配置
- **`netlify.toml`**：Netlify 部署配置

### 核心代碼
- **`src/lib/supabase.ts`**：資料庫連接和重試機制
- **`src/contexts/AuthContext.tsx`**：用戶認證狀態管理
- **`src/app/(admin)/layout.tsx`**：管理面板佈局和權限檢查
- **`src/components/ui/`**：共用 UI 組件

### 資料庫腳本
- **`supabase_safe_emergency_fix.sql`**：緊急修復腳本
- **`complete_policy_cleanup_and_fix.sql`**：RLS 策略修復
- **其他修復腳本**：針對特定問題的解決方案

---

## 🔄 版本更新流程

### 小版本更新 (Bug 修復)
1. 創建 hotfix 分支
2. 修復問題並測試
3. 合併到 main 觸發部署
4. 更新文檔

### 大版本更新 (功能添加)
1. 創建 feature 分支
2. 開發和測試新功能
3. 合併到 develop 分支測試
4. 合併到 main 部署到生產環境
5. 更新用戶文檔

---

## 📞 聯絡資訊和資源

### 技術支援
- **Supabase 支援**：https://supabase.com/support
- **Netlify 支援**：https://www.netlify.com/support/
- **Next.js 文檔**：https://nextjs.org/docs

### 狀態頁面
- **Supabase 狀態**：https://status.supabase.com/
- **Netlify 狀態**：https://www.netlifystatus.com/

### 學習資源
- **Supabase 教學**：https://supabase.com/docs
- **Next.js 學習**：https://nextjs.org/learn
- **Tailwind CSS**：https://tailwindcss.com/docs

---

## 📝 交接檢查清單

### 基本訪問確認
- [ ] 可以訪問 Supabase Dashboard
- [ ] 可以訪問 Netlify Dashboard  
- [ ] 可以訪問 GitHub Repository
- [ ] 熟悉本地開發環境設置

### 系統理解確認
- [ ] 理解整體系統架構
- [ ] 知道如何執行緊急修復
- [ ] 熟悉日常維護任務
- [ ] 了解部署流程

### 文檔和工具
- [ ] 閱讀完整的維護指南
- [ ] 測試過緊急修復腳本
- [ ] 設置好監控和警報
- [ ] 建立聯絡方式

### 實際操作測試
- [ ] 成功執行一次完整的部署
- [ ] 完成一次資料庫維護檢查
- [ ] 處理一個模擬的緊急情況
- [ ] 驗證所有系統功能正常

---

**最後更新**：2025-08-26  
**維護者**：[填入接手人姓名和聯絡方式]  
**上一任維護者**：[填入交接人姓名和聯絡方式]

---

**重要提醒**：
1. 在進行任何系統修改前，請先在測試環境驗證
2. 執行資料庫腳本前請確認理解其影響
3. 遇到不確定的情況請先諮詢而非嘗試
4. 定期備份重要配置和資料
5. 保持文檔更新，記錄所有重要變更