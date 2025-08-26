# TXN 專案文檔目錄

## 📚 文檔概覽

本目錄包含 TXN 專案的完整維護和交接文檔，讓新的維護者能夠快速上手並有效管理系統。

---

## 🗂️ 文檔結構

### 📋 主要交接文檔
1. **[專案維護交接文檔](./PROJECT_MAINTENANCE_HANDOVER.md)**
   - 最重要的文檔，包含完整的系統概覽
   - 涵蓋日常維護、部署流程、監控指南
   - 新手必讀，建議優先閱讀

### 🚨 緊急修復指南
2. **[Supabase 緊急修復指南](./SUPABASE_EMERGENCY_FIX_GUIDE.md)**
   - 詳細的資料庫問題修復流程
   - 包含故障排除和性能優化
   - 當系統出現連接或權限問題時使用

3. **[快速修復參考](./QUICK_FIX_REFERENCE.md)**
   - 緊急情況下的快速查閱指南
   - 簡化的操作步驟和檢查清單
   - 適合在壓力情況下快速參考

---

## 🎯 使用指南

### 如果你是新接手的維護者
**建議閱讀順序：**
1. 先讀 [`PROJECT_MAINTENANCE_HANDOVER.md`](./PROJECT_MAINTENANCE_HANDOVER.md) 了解整個系統
2. 熟悉 [`QUICK_FIX_REFERENCE.md`](./QUICK_FIX_REFERENCE.md) 以備緊急情況
3. 詳細學習 [`SUPABASE_EMERGENCY_FIX_GUIDE.md`](./SUPABASE_EMERGENCY_FIX_GUIDE.md) 中的修復流程
4. 完成交接檢查清單中的所有項目

### 如果遇到緊急問題
**快速響應流程：**
1. 🚨 **立即查看** [`QUICK_FIX_REFERENCE.md`](./QUICK_FIX_REFERENCE.md)
2. 🔧 **執行修復** 按照快速參考指南操作
3. 📖 **深入了解** 如需詳細說明，參考完整的緊急修復指南
4. 📝 **記錄問題** 更新文檔以改進未來的處理流程

### 如果需要進行日常維護
**參考資源：**
- 日常檢查：[專案維護交接文檔 - 日常維護任務](./PROJECT_MAINTENANCE_HANDOVER.md#-日常維護任務)
- 性能監控：[專案維護交接文檔 - 監控和分析](./PROJECT_MAINTENANCE_HANDOVER.md#-監控和分析)
- 部署流程：[專案維護交接文檔 - 部署流程](./PROJECT_MAINTENANCE_HANDOVER.md#-部署流程)

---

## 🔧 相關技術文件

### 資料庫腳本
位置：`/sql-scripts/`
- `supabase_safe_emergency_fix.sql` - 主要的緊急修復腳本
- `complete_policy_cleanup_and_fix.sql` - RLS 策略修復腳本
- `emergency_connection_fix.sql` - 連接問題修復腳本

### 前端配置
位置：`/src/`
- `lib/supabase.ts` - 資料庫連接配置
- `app/(admin)/layout.tsx` - 管理面板佈局
- `contexts/AuthContext.tsx` - 認證上下文

### 部署配置
位置：專案根目錄
- `netlify.toml` - Netlify 部署配置
- `.env.example` - 環境變數範例
- `package.json` - 專案依賴和腳本

---

## 📊 系統健康檢查

### 快速健康檢查
```bash
# 網站可用性
curl -I https://bespoke-gecko-b54fbd.netlify.app/

# 管理面板
curl -I https://bespoke-gecko-b54fbd.netlify.app/admin
```

### 資料庫健康檢查
```sql
-- 連接狀態
SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active';

-- 管理員用戶
SELECT * FROM user_profiles WHERE email = 'admin@txn.test';

-- RLS 策略
SELECT tablename, COUNT(*) FROM pg_policies GROUP BY tablename;
```

---

## 🔄 文檔維護

### 何時更新文檔
- ✅ 系統架構變更時
- ✅ 新增重要功能時  
- ✅ 修復流程改進時
- ✅ 遇到新問題並解決時
- ✅ 聯絡信息變更時

### 文檔更新流程
1. 修改相應的 Markdown 文件
2. 更新「最後更新」日期
3. 在 Git 中提交變更
4. 通知相關維護人員

---

## 📞 緊急聯絡

### 服務狀態頁面
- **Supabase**：https://status.supabase.com/
- **Netlify**：https://www.netlifystatus.com/

### 技術支援
- **Supabase 支援**：https://supabase.com/support
- **Netlify 支援**：https://www.netlify.com/support/

### 專案相關
- **GitHub Issues**：在專案 Repository 中建立 Issue
- **維護團隊**：[填入團隊聯絡方式]

---

## 💡 提示和最佳實踐

### 維護提示
- 🔄 定期執行健康檢查（每週至少一次）
- 📱 設置系統監控警報
- 💾 定期備份重要配置
- 📚 保持學習新的技術和最佳實踐

### 安全提示
- 🔐 定期更新管理員密碼
- 🛡️ 監控異常登入嘗試
- 🔍 審查資料庫權限設定
- 📊 檢查存取日誌

### 性能提示
- ⚡ 監控查詢響應時間
- 📈 追蹤資料庫大小增長
- 🔧 定期更新依賴套件
- 🚀 優化慢查詢

---

**文檔版本**：v1.0  
**建立日期**：2025-08-26  
**最後更新**：2025-08-26  
**維護者**：[待填入]

---

**重要提醒**：這些文檔是系統維護的重要參考資料，請務必保持更新並妥善保管。如果你對任何內容有疑問，請先查閱相關技術文檔或尋求協助，而非盲目嘗試。