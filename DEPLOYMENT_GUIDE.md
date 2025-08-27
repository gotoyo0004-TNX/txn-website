# 🚀 TXN Website 部署指引

## 現況總結
✅ Next.js 15 專案已完成建立 (使用 App Router)
✅ TypeScript 5 和 Tailwind CSS 4 已配置
✅ Supabase 客戶端已安裝和配置 (含重試機制)
✅ 完整的認證系統已實作 (AuthContext)
✅ 管理員權限系統已建立
✅ RLS 安全策略已配置
✅ 響應式 UI 元件庫已建立
✅ 環境變數範例檔案已建立
✅ Git 倉庫已初始化並準備推送
✅ Netlify 配置檔案已建立 (支援 SPA 路由)
✅ 專案建置測試成功
✅ 除錯工具和診斷系統已整合

## 🔸 需要完成的步驟

### 1. 建立 GitHub Repository

**方法一：網頁操作（推薦）**
1. 前往 https://github.com/new
2. Repository name: `txn-website`
3. 設定為 **Public**
4. **不要**勾選 "Add a README file"（我們已經有了）
5. 點擊 "Create repository"

**方法二：使用 GitHub CLI（如果已安裝）**
```bash
gh repo create txn-website --public --source=. --remote=origin --push
```

### 2. 推送程式碼到 GitHub

在你建立了 GitHub repository 後，執行：
```bash
cd txn-website
git remote add origin https://github.com/YOUR_USERNAME/txn-website.git
git push -u origin main
```

將 `YOUR_USERNAME` 替換為你的 GitHub 用戶名。

### 3. 設定 Netlify 自動部署

1. 前往 https://app.netlify.com/
2. 點擊 "New site from Git"
3. 選擇 "GitHub" 並授權
4. 選擇 `txn-website` 倉庫
5. 部署設定：
   - **Branch to deploy**: `main`
   - **Build command**: `npm run build`
   - **Publish directory**: `.next`
6. 高級設定 - 環境變數：
   - `NEXT_PUBLIC_SUPABASE_URL`: 你的 Supabase 專案 URL
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`: 你的 Supabase 匿名金鑰
7. 點擊 "Deploy site"

### 4. 配置 Supabase 資料庫

**重要：在設定環境變數之前，請先完成資料庫設定**

1. **執行資料庫遷移腳本**
   在 Supabase Dashboard 的 SQL Editor 中執行：
   ```sql
   -- 執行完整的資料庫設定腳本
   -- 請參考下方提供的 SQL 腳本
   ```

2. **建立管理員帳戶**
   執行管理員建立腳本後，使用以下帳戶登入：
   - Email: `admin@txn.test`
   - Password: `admin123456`

3. **設定本地環境變數**
   ```bash
   cp .env.example .env.local
   ```

   編輯 `.env.local` 並填入你的 Supabase 憑證：
   ```env
   NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
   ```

4. **驗證設定**
   啟動開發伺服器後，首頁會顯示 Supabase 連接測試結果

## 🎯 完成後你將擁有：

- ✅ **GitHub Repository**: `https://github.com/YOUR_USERNAME/txn-website`
- ✅ **Netlify 網站**: `https://your-site-name.netlify.app`
- ✅ **自動 CI/CD**: 每次推送到 main 分支都會自動部署
- ✅ **現代化技術棧**: Next.js 15 + TypeScript 5 + Tailwind CSS 4 + Supabase
- ✅ **完整功能**:
  - 用戶認證系統 (註冊/登入/登出)
  - 管理員權限管理
  - 交易日誌功能基礎架構
  - 響應式設計 (支援手機/平板/桌面)
  - 即時資料庫連接測試
  - 安全的 RLS 資料保護

## 📱 本地開發

啟動開發伺服器：
```bash
npm run dev
```

建置生產版本：
```bash
npm run build
```

## 🔗 有用的連結

- [Next.js 文件](https://nextjs.org/docs)
- [Supabase 文件](https://supabase.com/docs)
- [Tailwind CSS 文件](https://tailwindcss.com/docs)
- [Netlify 部署指南](https://docs.netlify.com/)

---

完成這些步驟後，請提供：
1. GitHub Repository URL
2. Netlify 部署 URL

我們就可以開始開發你的網站功能了！🚀