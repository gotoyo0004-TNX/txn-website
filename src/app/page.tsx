import Image from "next/image";
import SupabaseTest from "@/components/SupabaseTest";

export default function Home() {
  return (
    <div className="font-sans min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
      {/* Header */}
      <header className="container mx-auto px-8 py-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="w-10 h-10 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-lg">T</span>
            </div>
            <h1 className="text-2xl font-bold text-gray-800 dark:text-white">TXN Website</h1>
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-300">
            Next.js + Supabase + Netlify
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-8 py-12">
        <div className="text-center mb-12">
          <h2 className="text-4xl font-bold text-gray-800 dark:text-white mb-4">
            🚀 專案初始化完成！
          </h2>
          <p className="text-lg text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
            TXN 網站專案已成功建立，包含 Next.js、TypeScript、Tailwind CSS 和 Supabase 整合。
          </p>
        </div>

        {/* Tech Stack */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
          <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md">
            <div className="text-3xl mb-3">⚡</div>
            <h3 className="font-semibold text-gray-800 dark:text-white mb-2">Next.js 15</h3>
            <p className="text-sm text-gray-600 dark:text-gray-300">React 框架，支援 SSR 和 App Router</p>
          </div>
          <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md">
            <div className="text-3xl mb-3">🎨</div>
            <h3 className="font-semibold text-gray-800 dark:text-white mb-2">Tailwind CSS</h3>
            <p className="text-sm text-gray-600 dark:text-gray-300">實用優先的 CSS 框架</p>
          </div>
          <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md">
            <div className="text-3xl mb-3">🗄️</div>
            <h3 className="font-semibold text-gray-800 dark:text-white mb-2">Supabase</h3>
            <p className="text-sm text-gray-600 dark:text-gray-300">開源的 Firebase 替代方案</p>
          </div>
          <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md">
            <div className="text-3xl mb-3">🌐</div>
            <h3 className="font-semibold text-gray-800 dark:text-white mb-2">Netlify</h3>
            <p className="text-sm text-gray-600 dark:text-gray-300">自動化部署和託管平台</p>
          </div>
        </div>

        {/* Supabase Connection Test */}
        <SupabaseTest />

        {/* Getting Started */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-8 mt-12">
          <h3 className="text-2xl font-bold text-gray-800 dark:text-white mb-6 text-center">
            🛠️ 開始開發
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h4 className="font-semibold text-gray-800 dark:text-white mb-3">📝 設定 Supabase</h4>
              <ol className="text-sm text-gray-600 dark:text-gray-300 space-y-2">
                <li>1. 在 .env.local 中設定 Supabase 憑證</li>
                <li>2. 在 Netlify 中設定環境變數</li>
                <li>3. 重新啟動開發伺服器</li>
              </ol>
            </div>
            <div>
              <h4 className="font-semibold text-gray-800 dark:text-white mb-3">🚀 本地開發</h4>
              <div className="bg-gray-100 dark:bg-gray-700 p-3 rounded text-sm font-mono">
                <div>npm run dev</div>
                <div className="text-gray-500 dark:text-gray-400"># 啟動開發伺服器</div>
              </div>
            </div>
          </div>
        </div>


      </main>

      {/* Footer */}
      <footer className="bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700 py-8 mt-16">
        <div className="container mx-auto px-8">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <div className="flex items-center gap-2">
              <div className="w-6 h-6 bg-gradient-to-br from-blue-500 to-indigo-600 rounded">
                <span className="sr-only">TXN</span>
              </div>
              <span className="text-gray-600 dark:text-gray-300">TXN Website © 2024</span>
            </div>
            <div className="flex gap-6">
              <a
                className="text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                href="https://github.com/gotoyo0004-TNX/txn-website"
                target="_blank"
                rel="noopener noreferrer"
              >
                GitHub
              </a>
              <a
                className="text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                href="https://bespoke-gecko-b54fbd.netlify.app/"
                target="_blank"
                rel="noopener noreferrer"
              >
                線上版本
              </a>
              <a
                className="text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 transition-colors"
                href="https://supabase.com"
                target="_blank"
                rel="noopener noreferrer"
              >
                Supabase
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
