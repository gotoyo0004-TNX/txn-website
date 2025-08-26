# 🚨 TXN 緊急修復 - 快速參考指南

## 立即行動清單 ⚡

### 1️⃣ 問題確認 (30 秒)
- [ ] 首頁是否顯示「Supabase 連接失敗」？
- [ ] 管理面板 `/admin` 是否無法訪問？ 
- [ ] 是否出現 404 或權限錯誤？

### 2️⃣ 執行修復 (2 分鐘)
1. **打開 Supabase Dashboard** → SQL Editor
2. **清空編輯器** → 貼上修復腳本
3. **點擊 Run** → 等待執行完成

### 3️⃣ 立即驗證 (1 分鐘)  
1. **清除瀏覽器快取** (`Ctrl+Shift+Delete`)
2. **重新載入首頁** → 確認連接成功
3. **訪問管理面板** → 測試所有頁面

---

## 🔧 修復腳本位置

**主要腳本**：`/sql-scripts/supabase_safe_emergency_fix.sql`

**快速複製**：
```bash
# 腳本路徑
c:\Users\User\TXN\txn-website\sql-scripts\supabase_safe_emergency_fix.sql
```

---

## 📋 成功標誌

### ✅ 腳本執行成功
```
🎉 Supabase 安全緊急修復完成
🎯 修復成功！系統應該可以正常使用了
```

### ✅ 前端測試通過
- 首頁顯示「Supabase 連接成功」
- 管理面板正常載入
- 所有功能頁面可訪問

---

## ⚠️ 常見錯誤處理

### 錯誤：`permission denied for function pg_stat_reset`
**解決**：使用 `supabase_safe_emergency_fix.sql`（不是其他腳本）

### 錯誤：`policy already exists` 
**解決**：重新執行腳本（有自動清理機制）

### 錯誤：管理員用戶不存在
**解決**：
1. Supabase Dashboard → Authentication → Users
2. 創建用戶：`admin@txn.test`
3. 重新執行腳本

### 前端仍顯示 404
**解決**：
1. 檢查 Netlify 部署狀態
2. 確認前端代碼已更新
3. 等待自動部署完成（1-2分鐘）

---

## 📞 緊急聯絡資源

- **Supabase 狀態**：https://status.supabase.com/
- **Netlify 狀態**：https://www.netlifystatus.com/
- **詳細文檔**：`/docs/SUPABASE_EMERGENCY_FIX_GUIDE.md`

---

## 🔄 定期維護檢查

**每週執行**：
```sql
-- 檢查管理員用戶
SELECT * FROM user_profiles WHERE email = 'admin@txn.test';

-- 檢查連接數量  
SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active';

-- 檢查 RLS 策略
SELECT tablename, COUNT(*) FROM pg_policies GROUP BY tablename;
```

---

**記住**：此指南適用於緊急情況。完整文檔請參考 `SUPABASE_EMERGENCY_FIX_GUIDE.md`