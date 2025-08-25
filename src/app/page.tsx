import Image from "next/image";
import SupabaseTest from "@/components/SupabaseTest";
import { Button, Card, CardHeader, CardTitle, CardContent, Badge } from "@/components/ui";

export default function Home() {
  return (
    <div className="font-sans min-h-screen bg-gradient-to-br from-txn-primary-50 to-txn-accent-50 dark:from-txn-primary-900 dark:to-txn-primary-800">
      {/* Header */}
      <header className="container mx-auto px-8 py-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-gradient-accent rounded-xl flex items-center justify-center shadow-txn-lg">
              <span className="text-txn-primary font-bold text-xl">T</span>
            </div>
            <div>
              <h1 className="text-3xl font-bold text-gradient-primary">TXN</h1>
              <p className="text-sm text-txn-primary-600 dark:text-gray-400">交易日誌系統</p>
            </div>
          </div>
          <Badge variant="warning" size="sm">
            v1.0 MVP 開發中
          </Badge>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-8 py-12">
        <div className="text-center mb-12">
          <h2 className="text-5xl font-bold text-gradient-primary mb-6">
            🚀 TXN 交易日誌系統
          </h2>
          <p className="text-xl text-txn-primary-600 dark:text-gray-300 max-w-3xl mx-auto leading-relaxed">
            打造市場上最優雅、最高效的線上交易日誌。透過直覺的數據視覺化和深度分析，
            賦能每一位交易者在充滿挑戰的市場中自信地成長。
          </p>
          <div className="flex justify-center gap-4 mt-8">
            <Button variant="primary" size="lg">
              開始使用
            </Button>
            <Button variant="outline" size="lg">
              了解更多
            </Button>
          </div>
        </div>

        {/* Tech Stack */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
          <Card variant="kpi">
            <CardContent className="text-center">
              <div className="text-4xl mb-4">⚡</div>
              <h3 className="font-semibold text-txn-primary-800 dark:text-white mb-2">Next.js 15</h3>
              <p className="text-sm text-txn-primary-600 dark:text-gray-300">React 框架，支援 SSR 和 App Router</p>
            </CardContent>
          </Card>
          <Card variant="kpi">
            <CardContent className="text-center">
              <div className="text-4xl mb-4">🎨</div>
              <h3 className="font-semibold text-txn-primary-800 dark:text-white mb-2">TXN Design</h3>
              <p className="text-sm text-txn-primary-600 dark:text-gray-300">專業的交易界面設計系統</p>
            </CardContent>
          </Card>
          <Card variant="kpi">
            <CardContent className="text-center">
              <div className="text-4xl mb-4">🗄️</div>
              <h3 className="font-semibold text-txn-primary-800 dark:text-white mb-2">Supabase</h3>
              <p className="text-sm text-txn-primary-600 dark:text-gray-300">開源的 Firebase 替代方案</p>
            </CardContent>
          </Card>
          <Card variant="kpi">
            <CardContent className="text-center">
              <div className="text-4xl mb-4">🌐</div>
              <h3 className="font-semibold text-txn-primary-800 dark:text-white mb-2">Netlify</h3>
              <p className="text-sm text-txn-primary-600 dark:text-gray-300">自動化部署和託管平台</p>
            </CardContent>
          </Card>
        </div>

        {/* Supabase Connection Test */}
        <SupabaseTest />

        {/* Getting Started */}
        <Card variant="elevated" className="mt-12">
          <CardHeader>
            <CardTitle className="text-2xl text-center">
              🛠️ 開始開發
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              <div>
                <h4 className="font-semibold text-txn-primary-800 dark:text-white mb-4">📝 設定 Supabase</h4>
                <div className="space-y-3">
                  <div className="flex items-center gap-2">
                    <Badge variant="info" size="sm">1</Badge>
                    <span className="text-sm text-txn-primary-600 dark:text-gray-300">在 .env.local 中設定 Supabase 憑證</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant="info" size="sm">2</Badge>
                    <span className="text-sm text-txn-primary-600 dark:text-gray-300">在 Netlify 中設定環境變數</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge variant="info" size="sm">3</Badge>
                    <span className="text-sm text-txn-primary-600 dark:text-gray-300">重新啟動開發伺服器</span>
                  </div>
                </div>
              </div>
              <div>
                <h4 className="font-semibold text-txn-primary-800 dark:text-white mb-4">🚀 本地開發</h4>
                <div className="bg-txn-primary-800 rounded-lg p-4">
                  <code className="text-txn-accent font-mono text-sm">
                    <div>npm run dev</div>
                    <div className="text-txn-primary-400 mt-1"># 啟動開發伺服器</div>
                  </code>
                </div>
                <div className="mt-4">
                  <Button variant="primary" size="sm">
                    查看設定指引
                  </Button>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>


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
