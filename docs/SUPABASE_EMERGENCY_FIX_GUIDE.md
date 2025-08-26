# TXN 專案 - Supabase 緊急修復指南

## 📋 文檔概述

**文檔目的**：為 TXN 專案維護者提供完整的 Supabase 資料庫緊急修復指南  
**適用場景**：當系統出現連接問題、權限錯誤、404 錯誤或管理面板無法訪問時  
**維護責任**：系統管理員、後端開發者、DevOps 工程師  
**最後更新**：2025-08-26  

---

## 🚨 何時使用此修復腳本

### 常見問題症狀
1. **連接問題**：
   - Supabase 連接時好時壞
   - 首頁顯示「Supabase 連接失敗」
   - API 請求超時或失敗

2. **權限問題**：
   - 管理員無法訪問 `/admin` 頁面
   - 出現「訪問被拒絕」錯誤
   - 權限檢查超時

3. **404 錯誤**：
   - 管理面板某些頁面顯示 404
   - 路由無法正常訪問

4. **RLS 策略問題**：
   - "policy already exists" 錯誤
   - 無限遞歸錯誤
   - 資料庫查詢超時

---

## 🛠️ 修復腳本使用指南

### 步驟 1：訪問 Supabase Dashboard
1. 登入 [Supabase Dashboard](https://supabase.com/dashboard)
2. 選擇 TXN 專案
3. 進入「SQL Editor」頁面

### 步驟 2：執行修復腳本
1. **清空 SQL Editor** 中的現有內容
2. **複製** [`supabase_safe_emergency_fix.sql`](./supabase_safe_emergency_fix.sql) 的完整內容
3. **粘貼** 到 SQL Editor 中
4. **點擊 Run** 執行腳本

### 步驟 3：觀察執行結果
腳本執行時會顯示詳細的進度信息：
```
🚨 開始 Supabase 安全緊急修復...
🔍 當前連接狀態
🧹 開始安全清理所有 RLS 策略...
✅ 已刪除策略: user_profiles.old_policy_name
🛡️ 已重新啟用所有表的 RLS
👤 開始修復管理員用戶資料...
✅ 管理員資料已創建/更新
🧪 開始執行連接和性能測試...
📊 基本查詢測試: 45.2 ms
✅ 查詢性能優秀 (< 50ms)
🎉 Supabase 安全緊急修復完成
```

### 步驟 4：驗證修復效果
執行完成後，立即進行以下測試：
1. **清除瀏覽器快取**：按 `Ctrl+Shift+Delete`
2. **測試首頁連接**：訪問 https://bespoke-gecko-b54fbd.netlify.app/
3. **測試管理面板**：訪問 https://bespoke-gecko-b54fbd.netlify.app/admin
4. **測試各功能頁面**：
   - 控制面板：`/admin`
   - 用戶管理：`/admin/users`
   - 系統統計：`/admin/analytics`
   - 系統設定：`/admin/settings`

---

## 🔧 腳本功能詳解

### 主要修復內容

#### 1. 連接診斷 (Section 1-2)
- **目的**：檢查資料庫連接狀態和長時間運行的查詢
- **安全性**：只讀操作，不會影響現有連接
- **輸出**：顯示當前連接數量和查詢狀態

#### 2. RLS 策略重置 (Section 3-4)
- **目的**：清理所有衝突的 Row Level Security 策略
- **操作**：
  1. 禁用所有表的 RLS
  2. 安全清理所有現有策略
  3. 創建新的簡化策略
  4. 重新啟用 RLS
- **重要性**：解決 "policy already exists" 和無限遞歸問題

#### 3. 索引優化 (Section 5)
- **目的**：創建和優化資料庫索引以提升查詢性能
- **影響**：顯著改善查詢速度，特別是管理員權限檢查

#### 4. 管理員用戶修復 (Section 6)
- **目的**：確保 `admin@txn.test` 用戶資料正確
- **檢查項目**：
  - Auth 系統中是否存在用戶
  - user_profiles 表中是否有對應記錄
  - 用戶角色是否為 'admin'
  - 用戶狀態是否為 'active'

#### 5. 性能測試 (Section 8)
- **目的**：驗證修復效果和系統性能
- **測試項目**：
  - 基本查詢速度
  - 管理員查詢效率
  - 索引使用效果

---

## 📊 預期結果與故障排除

### 成功執行的標誌
1. **腳本輸出**：
   - 所有步驟都顯示 ✅ 成功標記
   - 最終顯示「🎉 修復成功！系統應該可以正常使用了」
   - 查詢性能測試結果 < 200ms

2. **前端測試**：
   - 首頁正常載入，Supabase 連接成功
   - 管理面板可以訪問，不出現超時錯誤
   - 所有管理功能頁面都能正常顯示

### 常見問題與解決方案

#### 問題 1：權限錯誤 (42501)
**症狀**：`ERROR: 42501: permission denied for function xxx`  
**原因**：腳本包含需要超級用戶權限的操作  
**解決方案**：
- 確保使用 `supabase_safe_emergency_fix.sql` 而非其他腳本
- 該腳本專門避免了所有超級用戶操作

#### 問題 2：策略創建失敗
**症狀**：`ERROR: 42710: policy "xxx" already exists`  
**原因**：策略清理不完全  
**解決方案**：
1. 重新執行腳本（腳本有重試機制）
2. 手動清理殘留策略後再執行

#### 問題 3：管理員用戶不存在
**症狀**：「❌ Auth 用戶不存在」  
**解決方案**：
1. 進入 Supabase Dashboard → Authentication → Users
2. 手動創建用戶：
   - Email: `admin@txn.test`
   - Password: 設定安全密碼
   - 確認 Email（如果需要）
3. 重新執行修復腳本

#### 問題 4：前端仍然出現 404
**症狀**：管理面板某些頁面仍顯示 404  
**原因**：前端路由文件缺失  
**解決方案**：
1. 檢查是否存在 `/admin/users/page.tsx` 文件
2. 如果缺失，需要重新部署前端代碼
3. 檢查 Netlify 部署狀態

---

## 🔄 維護和監控

### 定期檢查項目 (建議每週執行)
1. **連接狀態監控**：
   ```sql
   SELECT COUNT(*) as active_connections 
   FROM pg_stat_activity 
   WHERE state = 'active' AND datname = current_database();
   ```

2. **管理員權限檢查**：
   ```sql
   SELECT * FROM user_profiles 
   WHERE email = 'admin@txn.test' 
   AND role = 'admin' AND status = 'active';
   ```

3. **RLS 策略檢查**：
   ```sql
   SELECT tablename, COUNT(*) as policy_count 
   FROM pg_policies 
   WHERE schemaname = 'public' 
   GROUP BY tablename;
   ```

### 性能基準
- **基本查詢**：< 50ms (優秀)，< 200ms (可接受)
- **管理員查詢**：< 100ms
- **連接數量**：通常 < 10 個活躍連接

---

## 📚 相關文件和資源

### 關鍵文件
- **修復腳本**：`/sql-scripts/supabase_safe_emergency_fix.sql`
- **前端配置**：`/src/lib/supabase.ts` (包含重試機制)
- **管理員佈局**：`/src/app/(admin)/layout.tsx`
- **用戶管理**：`/src/app/(admin)/users/page.tsx`

### Supabase Dashboard 快速連結
- **SQL Editor**：https://supabase.com/dashboard/project/[PROJECT_ID]/sql
- **Authentication**：https://supabase.com/dashboard/project/[PROJECT_ID]/auth/users
- **Table Editor**：https://supabase.com/dashboard/project/[PROJECT_ID]/editor

### Netlify Dashboard
- **部署狀態**：https://app.netlify.com/sites/bespoke-gecko-b54fbd/deploys
- **域名管理**：https://app.netlify.com/sites/bespoke-gecko-b54fbd/settings/domain

---

## ⚠️ 注意事項與安全考慮

### 執行前注意事項
1. **備份重要性**：雖然腳本是安全的，但建議在執行前了解當前系統狀態
2. **執行時機**：建議在系統使用量較低的時間執行
3. **權限確認**：確保你有 Supabase 專案的管理員權限

### 安全考慮
1. **策略安全**：腳本創建的是寬鬆策略，確保管理功能可用
2. **密碼管理**：管理員帳號密碼應該強且安全
3. **訪問控制**：定期審查管理員權限

### 緊急聯絡
如果修復腳本無法解決問題，可能需要：
1. **聯絡 Supabase 支援**：https://supabase.com/support
2. **檢查 Netlify 狀態**：https://www.netlifystatus.com/
3. **查看 GitHub Actions**：檢查自動部署是否失敗

---

## 📝 修改記錄

| 日期 | 修改內容 | 修改者 |
|------|----------|--------|
| 2025-08-26 | 創建初始版本，包含完整修復流程 | Qoder AI |
| | 添加權限錯誤處理和安全機制 | |
| | 包含詳細的故障排除指南 | |

---

**重要提醒**：此文檔應該與實際代碼同步更新。當系統架構或 Supabase 配置發生變化時，請同時更新此文檔。