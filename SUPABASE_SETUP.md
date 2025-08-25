# 🔑 Supabase 環境變數設定指引

## 📋 設定步驟總覽

### 1. 取得 Supabase 憑證
### 2. 設定本地開發環境
### 3. 設定 Netlify 生產環境

---

## 🏠 步驟 1: 取得 Supabase 憑證

### 在 Supabase Dashboard 中：

1. **登入 Supabase**
   - 前往 https://supabase.com/dashboard
   - 登入你的帳戶

2. **選擇你的專案**
   - 點擊你要使用的專案

3. **取得 API 憑證**
   - 點擊左側選單的 **Settings** (設定)
   - 點擊 **API** 分頁
   - 複製以下資訊：
     ```
     Project URL: https://your-project-id.supabase.co
     anon public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
     ```

---

## 💻 步驟 2: 設定本地開發環境

### 已為你建立 `.env.local` 檔案

1. **編輯 `.env.local` 檔案**
   ```bash
   # 在專案根目錄找到 .env.local 檔案
   # 將下面的範例替換為你的實際憑證
   ```

2. **填入你的實際憑證**
   ```env
   NEXT_PUBLIC_SUPABASE_URL=https://your-project-id.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

3. **重新啟動開發伺服器**
   ```bash
   npm run dev
   ```

---

## 🌐 步驟 3: 設定 Netlify 生產環境

### 在 Netlify Dashboard 中：

1. **進入你的網站設定**
   - 前往 https://app.netlify.com/
   - 點擊你的 `txn-website` 網站

2. **設定環境變數**
   - 點擊 **Site settings** (網站設定)
   - 在左側選單點擊 **Environment variables** (環境變數)
   - 點擊 **Add a variable** (新增變數)

3. **新增 Supabase URL**
   - **Key**: `NEXT_PUBLIC_SUPABASE_URL`
   - **Value**: `https://your-project-id.supabase.co`
   - 點擊 **Create variable**

4. **新增 Supabase API Key**
   - **Key**: `NEXT_PUBLIC_SUPABASE_ANON_KEY`  
   - **Value**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - 點擊 **Create variable**

5. **重新部署網站**
   - 點擊 **Deploys** 分頁
   - 點擊 **Trigger deploy** → **Deploy site**

---

## ✅ 驗證設定

### 本地環境驗證
```bash
# 啟動開發伺服器
npm run dev

# 在瀏覽器開發者工具 Console 中執行
console.log('Supabase URL:', process.env.NEXT_PUBLIC_SUPABASE_URL)
```

### 生產環境驗證
```bash
# 檢查 Netlify 部署日誌
# 確認環境變數已正確載入
```

---

## 🔒 安全注意事項

### ✅ 安全做法
- ✅ 使用 `NEXT_PUBLIC_` 前綴的公開變數
- ✅ 使用 Supabase 的 `anon` 金鑰（已限制權限）
- ✅ 在 Supabase 中設定 RLS (Row Level Security)

### ❌ 避免事項
- ❌ 不要將 `service_role` 金鑰放在前端
- ❌ 不要將 `.env.local` 提交到 Git
- ❌ 不要在公開場所分享 API 金鑰

---

## 🚨 故障排除

### 常見問題

1. **環境變數未載入**
   ```bash
   # 確認檔案名稱正確
   .env.local (不是 .env.example)
   
   # 重新啟動開發伺服器
   npm run dev
   ```

2. **Netlify 部署失敗**
   ```bash
   # 檢查環境變數拼寫是否正確
   NEXT_PUBLIC_SUPABASE_URL
   NEXT_PUBLIC_SUPABASE_ANON_KEY
   ```

3. **連接失敗**
   ```bash
   # 確認 Supabase 專案狀態
   # 檢查 API 金鑰是否正確
   ```

---

## 📞 下一步

設定完成後：
1. 測試本地開發環境
2. 確認 Netlify 部署成功  
3. 開始開發 Supabase 功能
4. 設定資料庫結構和 RLS 政策