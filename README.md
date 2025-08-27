# 🚀 TXN 交易日誌系統

一個專業的線上交易日誌平台，透過直覺的數據視覺化和深度分析，賦能每一位交易者在充滿挑戰的市場中自信地成長。

## ✨ 主要功能

- 📊 **交易記錄管理** - 完整記錄每筆交易的詳細資訊
- 📈 **績效分析** - 深度分析交易表現和趨勢
- 🎯 **策略管理** - 管理和追蹤不同的交易策略
- 👥 **用戶管理** - 完整的用戶認證和權限管理系統
- 🔒 **安全保護** - 採用 RLS (Row Level Security) 確保資料安全
- 📱 **響應式設計** - 支援桌面和行動裝置

## 🛠️ 技術棧

- **前端框架**: Next.js 15 with TypeScript
- **樣式框架**: Tailwind CSS 4 (最新版本)
- **後端/資料庫**: Supabase (PostgreSQL + 即時功能)
- **認證系統**: Supabase Auth
- **部署平台**: Netlify (自動化 CI/CD)
- **版本控制**: GitHub
- **圖示庫**: Heroicons
- **開發工具**: ESLint, Turbopack

## 🚀 快速開始

### 前置需求
- Node.js 18 或以上版本
- Git
- Supabase 帳戶
- Netlify 帳戶 (用於部署)

### 本地開發設定

1. **複製專案**
```bash
git clone https://github.com/YOUR_USERNAME/txn-website.git
cd txn-website
```

2. **安裝依賴**
```bash
npm install
```

3. **環境變數設定**
```bash
cp .env.example .env.local
```

在 `.env.local` 中填入你的 Supabase 憑證：
```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
```

4. **啟動開發伺服器**
```bash
npm run dev
```

5. **開啟瀏覽器**
前往 [http://localhost:3000](http://localhost:3000) 查看應用程式

## 🗄️ 資料庫設定

### Supabase 設定步驟

1. **建立 Supabase 專案**
   - 前往 [Supabase](https://supabase.com) 建立新專案
   - 記錄專案 URL 和 API 金鑰

2. **執行資料庫遷移**
   - 在 Supabase Dashboard 的 SQL Editor 中執行 `sql-scripts/complete_database_setup.sql`
   - 這將建立所有必要的資料表和安全策略

3. **建立管理員帳戶**
   - 執行 `sql-scripts/create_admin_user.sql` 建立初始管理員

## 🚀 部署設定

### 自動化部署流程
本專案已配置完整的 CI/CD 流程，推送到 main 分支即可自動部署。

### GitHub Repository 設定
```bash
# 設定遠端倉庫
git remote add origin https://github.com/YOUR_USERNAME/txn-website.git
git push -u origin main
```

### Netlify 自動部署設定
1. 登入 [Netlify](https://app.netlify.com/)
2. 點擊 "New site from Git"
3. 選擇 GitHub 並授權
4. 選擇 `txn-website` 倉庫
5. 部署設定會自動從 `netlify.toml` 讀取
6. 在環境變數中加入：
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`

## 📁 專案結構

```
txn-website/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── (admin)/           # 管理員路由群組
│   │   ├── auth/              # 認證頁面
│   │   ├── layout.tsx         # 根布局
│   │   └── page.tsx           # 首頁
│   ├── components/            # React 元件
│   │   ├── auth/              # 認證相關元件
│   │   ├── debug/             # 除錯工具
│   │   ├── layout/            # 版面元件
│   │   ├── providers/         # Context 提供者
│   │   └── ui/                # UI 元件庫
│   ├── contexts/              # React Context
│   │   ├── AuthContext.tsx    # 認證狀態管理
│   │   └── NotificationContext.tsx # 通知系統
│   ├── hooks/                 # 自定義 Hooks
│   └── lib/                   # 工具函式和配置
│       ├── supabase.ts        # Supabase 客戶端
│       ├── constants.ts       # 常數定義
│       └── utils.ts           # 工具函式
├── sql-scripts/               # 資料庫腳本
│   ├── migrations/            # 資料庫遷移腳本
│   └── *.sql                  # 各種修復和設定腳本
├── docs/                      # 專案文件
├── public/                    # 靜態資源
├── .env.example               # 環境變數範例
├── netlify.toml               # Netlify 部署配置
└── package.json               # 專案依賴
```

## 🔧 可用腳本

```bash
npm run dev          # 啟動開發伺服器 (使用 Turbopack)
npm run build        # 建置生產版本
npm run start        # 啟動生產伺服器
npm run lint         # 執行 ESLint 檢查
```

## 🛡️ 安全功能

- **Row Level Security (RLS)** - 資料庫層級的安全控制
- **JWT 認證** - 安全的用戶認證機制
- **角色權限管理** - 細緻的用戶權限控制
- **CSRF 保護** - 跨站請求偽造防護
- **環境變數保護** - 敏感資訊安全存儲

## 📚 相關文件

- [部署指南](./DEPLOYMENT_GUIDE.md) - 詳細的部署步驟
- [專案交接文件](./PROJECT_HANDOVER.md) - 完整的專案說明
- [Supabase 設定指南](./SUPABASE_SETUP.md) - 資料庫設定說明
- [工作流程](./WORKFLOW.md) - 開發工作流程

## 🐛 問題排除

### 常見問題

1. **Supabase 連接失敗**
   - 檢查環境變數是否正確設定
   - 確認 Supabase 專案狀態正常
   - 查看瀏覽器開發者工具的錯誤訊息

2. **管理員權限問題**
   - 執行 `sql-scripts/fix_admin_permission.sql`
   - 確認用戶角色設定正確

3. **RLS 策略問題**
   - 執行 `sql-scripts/fix_rls_simple_correct.sql`
   - 清除瀏覽器快取後重新登入

## 🤝 貢獻指南

1. Fork 此專案
2. 建立功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交變更 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 開啟 Pull Request

## 📄 授權條款

此專案採用 MIT 授權條款 - 詳見 [LICENSE](LICENSE) 檔案

## 📞 聯絡資訊

如有任何問題或建議，請透過以下方式聯絡：

- 專案 Issues: [GitHub Issues](https://github.com/YOUR_USERNAME/txn-website/issues)
- Email: your-email@example.com

---

**TXN 交易日誌系統** - 讓每一筆交易都成為成長的基石 🚀