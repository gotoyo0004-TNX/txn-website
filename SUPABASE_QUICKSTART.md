# 🚀 Supabase 快速設定指引

## 📋 設定檢查清單

### ✅ 本地開發環境
- [ ] 建立 `.env.local` 檔案
- [ ] 設定 `NEXT_PUBLIC_SUPABASE_URL`
- [ ] 設定 `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- [ ] 重新啟動開發伺服器 (`npm run dev`)

### ✅ Netlify 生產環境
- [ ] 登入 Netlify Dashboard
- [ ] 進入網站設定 → Environment variables
- [ ] 新增 `NEXT_PUBLIC_SUPABASE_URL`
- [ ] 新增 `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- [ ] 觸發重新部署

---

## 🔑 取得 Supabase 憑證

### 步驟 1: 進入 Supabase Dashboard
```
https://supabase.com/dashboard
```

### 步驟 2: 選擇專案並取得 API 設定
```
左側選單 → Settings → API
```

### 步驟 3: 複製必要資訊
```
Project URL: https://xxxxxxxxxx.supabase.co
anon public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 💻 設定範例

### .env.local 檔案內容
```env
# Supabase 設定
NEXT_PUBLIC_SUPABASE_URL=https://xxxxxxxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Netlify 環境變數設定
```
Key: NEXT_PUBLIC_SUPABASE_URL
Value: https://xxxxxxxxxx.supabase.co

Key: NEXT_PUBLIC_SUPABASE_ANON_KEY  
Value: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 🧪 測試連接

### 方法 1: 網站測試頁面
訪問首頁的 "Supabase 連接測試" 區域查看連接狀態

### 方法 2: 開發者工具
```javascript
// 在瀏覽器 Console 中執行
console.log('Supabase URL:', process.env.NEXT_PUBLIC_SUPABASE_URL)
console.log('API Key Set:', !!process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY)
```

### 方法 3: 本地命令列
```bash
# 檢查環境變數是否載入
npm run dev
# 然後查看終端輸出或瀏覽器測試頁面
```

---

## 🔧 故障排除

### ❌ 問題：環境變數未載入
**解決方案：**
1. 確認檔案名稱為 `.env.local`（不是 `.env.example`）
2. 重新啟動開發伺服器
3. 清除瀏覽器快取

### ❌ 問題：Netlify 部署失敗
**解決方案：**
1. 檢查環境變數拼寫是否正確
2. 確認 Supabase 專案狀態正常
3. 查看 Netlify 建置日誌

### ❌ 問題：連接測試失敗
**解決方案：**
1. 驗證 Supabase URL 和 API Key 正確性
2. 檢查 Supabase 專案是否暫停
3. 確認網路連接正常

---

## 📞 下一步

設定完成後即可：
1. ✅ 開始建立資料庫結構
2. ✅ 實作用戶認證功能  
3. ✅ 開發業務邏輯
4. ✅ 設定 RLS 安全政策

---

**💡 提示：** 設定完成後，網站首頁的測試區域應該顯示 "✅ Supabase 連接成功！"