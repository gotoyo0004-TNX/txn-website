'use client'

import { Suspense, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/contexts/AuthContext'
import { Card, CardHeader, CardTitle, CardContent, Button } from '@/components/ui'

// AuthCallback 組件內容
function AuthCallbackContent() {
  const router = useRouter()
  const { user } = useAuth()

  useEffect(() => {
    // 如果用戶已登入，重定向到主頁
    if (user) {
      router.push('/')
    }
  }, [user, router])

  return (
    <div className="min-h-screen bg-gradient-to-br from-txn-primary-50 to-txn-accent-50 dark:from-txn-primary-900 dark:to-txn-primary-800 flex items-center justify-center p-4">
      <Card variant="elevated" className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="w-16 h-16 bg-gradient-accent rounded-xl flex items-center justify-center mx-auto mb-4 shadow-txn-lg">
            <span className="text-txn-primary font-bold text-2xl">T</span>
          </div>
          <CardTitle className="text-2xl">帳戶審核中</CardTitle>
        </CardHeader>
        
        <CardContent>
          <div className="p-4 rounded-lg border text-blue-600 bg-blue-50 border-blue-200">
            <div className="flex items-center gap-3 mb-3">
              <span className="text-2xl">⏳</span>
              <span className="font-semibold">等待管理員審核</span>
            </div>
            
            <p className="text-sm mb-4">
              您的帳戶已成功建立，目前正在等待管理員審核。管理員將會在 24 小時內審核您的申請。
            </p>
          </div>

          <div className="mt-6 space-y-3">
            <div className="p-3 bg-gray-50 rounded-lg">
              <h4 className="font-medium text-gray-800 mb-2">審核完成後您可以：</h4>
              <ul className="text-sm text-gray-600 space-y-1">
                <li>• 記錄和追蹤交易日誌</li>
                <li>• 分析交易績效</li>
                <li>• 管理交易策略</li>
                <li>• 查看詳細統計報告</li>
              </ul>
            </div>
            
            <Button 
              variant="outline" 
              className="w-full"
              onClick={() => router.push('/auth')}
            >
              重新登入
            </Button>
            
            <Button 
              variant="primary" 
              className="w-full"
              onClick={() => router.push('/')}
            >
              回到首頁
            </Button>
          </div>

          {user && (
            <div className="mt-4 p-3 bg-txn-primary-50 rounded-lg">
              <p className="text-sm text-txn-primary-700">
                當前用戶：{user.email}
              </p>
              <p className="text-xs text-txn-primary-600 mt-1">
                如有問題請聯繫管理員
              </p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}

// 載入中的後備組件
function LoadingFallback() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-txn-primary-50 to-txn-accent-50 dark:from-txn-primary-900 dark:to-txn-primary-800 flex items-center justify-center p-4">
      <Card variant="elevated" className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="w-16 h-16 bg-gradient-accent rounded-xl flex items-center justify-center mx-auto mb-4 shadow-txn-lg">
            <span className="text-txn-primary font-bold text-2xl">T</span>
          </div>
          <CardTitle className="text-2xl">處理中...</CardTitle>
        </CardHeader>
        
        <CardContent>
          <div className="p-4 rounded-lg border text-yellow-600 bg-yellow-50 border-yellow-200">
            <div className="flex items-center gap-3 mb-3">
              <span className="text-2xl">🔄</span>
              <span className="font-semibold">正在處理您的請求</span>
            </div>
            
            <div className="flex justify-center">
              <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-txn-accent"></div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

export default function AuthCallbackPage() {
  return (
    <Suspense fallback={<LoadingFallback />}>
      <AuthCallbackContent />
    </Suspense>
  )
}