# 🚀 TXN Website 部署指引

## 現況總結
✅ Next.js 專案已完成建立  
✅ TypeScript 和 Tailwind CSS 已配置  
✅ Supabase 客戶端已安裝和配置  
✅ 環境變數範例檔案已建立  
✅ Git 倉庫已初始化並準備推送  
✅ Netlify 配置檔案已建立  
✅ 專案建置測試成功  

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

### 4. 配置 Supabase 環境變數

在本地開發時，建立 `.env.local` 檔案：
```bash
cp .env.example .env.local
```

編輯 `.env.local` 並填入你的 Supabase 憑證：
```
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

## 🎯 完成後你將擁有：

- ✅ GitHub Repository: `https://github.com/YOUR_USERNAME/txn-website`
- ✅ Netlify 網站: `https://your-site-name.netlify.app`
- ✅ 自動 CI/CD：每次推送到 main 分支都會自動部署
- ✅ 現代化技術棧：Next.js + TypeScript + Tailwind + Supabase

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