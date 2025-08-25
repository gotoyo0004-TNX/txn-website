# TXN Website

這是一個使用 Next.js 和 Supabase 建立的現代化全端網站專案。

## 技術棧

- **前端框架**: Next.js 15 with TypeScript
- **樣式**: Tailwind CSS
- **後端/資料庫**: Supabase
- **部署**: Netlify
- **版本控制**: GitHub

## 開發環境設定

1. 複製環境變數檔案：
```bash
cp .env.example .env.local
```

2. 在 `.env.local` 中填入你的 Supabase 憑證：
```
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
```

3. 安裝依賴並啟動開發伺服器：
```bash
npm install
npm run dev
```

## 部署設定

### GitHub Repository 設定
1. 在 GitHub 上建立新的公開倉庫，名稱為 `txn-website`
2. 設定遠端倉庫：
```bash
git remote add origin https://github.com/YOUR_USERNAME/txn-website.git
git push -u origin main
```

### Netlify 自動部署設定
1. 登入 Netlify 控制台
2. 點擊 "New site from Git"
3. 選擇 GitHub 並授權
4. 選擇 `txn-website` 倉庫
5. 設定建置命令：`npm run build`
6. 設定發佈目錄：`.next`
7. 在環境變數中加入 Supabase 憑證

## 專案結構

```
txn-website/
├── src/
│   ├── app/              # Next.js App Router
│   └── lib/
│       └── supabase.ts   # Supabase 客戶端配置
├── public/               # 靜態資源
├── .env.example          # 環境變數範例
└── ...                   # 其他配置檔案
```