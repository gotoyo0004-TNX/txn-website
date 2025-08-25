'use client'

import { useEffect, useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { useAuth } from '@/contexts/AuthContext'
import { Card, CardHeader, CardTitle, CardContent, Button } from '@/components/ui'

export default function AuthCallbackPage() {
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading')
  const [message, setMessage] = useState('')
  const router = useRouter()
  const searchParams = useSearchParams()
  const { user } = useAuth()

  useEffect(() => {
    const handleAuthCallback = async () => {
      try {
        // 檢查 URL 參數中的錯誤
        const error = searchParams.get('error')
        const errorDescription = searchParams.get('error_description')

        if (error) {
          setStatus('error')
          switch (error) {
            case 'access_denied':
              setMessage('郵件連結已過期或無效，請重新註冊或請求新的確認郵件。')
              break
            default:
              setMessage(errorDescription || '驗證過程中發生錯誤，請稍後再試。')
          }
          return
        }

        // 檢查是否成功驗證
        const accessToken = searchParams.get('access_token')
        const refreshToken = searchParams.get('refresh_token')

        if (accessToken && refreshToken) {
          setStatus('success')
          setMessage('郵件驗證成功！正在重定向到主頁面...')
          
          // 延遲後重定向到主頁
          setTimeout(() => {
            router.push('/')
          }, 2000)
        } else {
          setStatus('error')
          setMessage('無法完成驗證，請稍後再試。')
        }
      } catch (err) {
        console.error('郵件確認處理錯誤:', err)
        setStatus('error')
        setMessage('處理確認請求時發生錯誤。')
      }
    }

    handleAuthCallback()
  }, [searchParams, router])

  const getStatusIcon = () => {
    switch (status) {
      case 'loading':
        return '🔄'
      case 'success':
        return '✅'
      case 'error':
        return '❌'
    }
  }

  const getStatusColor = () => {
    switch (status) {
      case 'loading':
        return 'text-yellow-600 bg-yellow-50 border-yellow-200'
      case 'success':
        return 'text-green-600 bg-green-50 border-green-200'
      case 'error':
        return 'text-red-600 bg-red-50 border-red-200'
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-txn-primary-50 to-txn-accent-50 dark:from-txn-primary-900 dark:to-txn-primary-800 flex items-center justify-center p-4">
      <Card variant="elevated" className="w-full max-w-md">
        <CardHeader className="text-center">
          <div className="w-16 h-16 bg-gradient-accent rounded-xl flex items-center justify-center mx-auto mb-4 shadow-txn-lg">
            <span className="text-txn-primary font-bold text-2xl">T</span>
          </div>
          <CardTitle className="text-2xl">郵件驗證</CardTitle>
        </CardHeader>
        
        <CardContent>
          <div className={`p-4 rounded-lg border ${getStatusColor()}`}>
            <div className="flex items-center gap-3 mb-3">
              <span className="text-2xl">{getStatusIcon()}</span>
              <span className="font-semibold">
                {status === 'loading' && '處理中...'}
                {status === 'success' && '驗證成功！'}
                {status === 'error' && '驗證失敗'}
              </span>
            </div>
            
            <p className="text-sm mb-4">
              {message}
            </p>

            {status === 'loading' && (
              <div className="flex justify-center">
                <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-txn-accent"></div>
              </div>
            )}
          </div>

          <div className="mt-6 space-y-3">
            {status === 'success' && (
              <Button 
                variant="primary" 
                className="w-full"
                onClick={() => router.push('/')}
              >
                立即進入 TXN
              </Button>
            )}
            
            {status === 'error' && (
              <div className="space-y-3">
                <Button 
                  variant="primary" 
                  className="w-full"
                  onClick={() => router.push('/auth')}
                >
                  重新註冊
                </Button>
                <Button 
                  variant="outline" 
                  className="w-full"
                  onClick={() => router.push('/')}
                >
                  回到首頁
                </Button>
              </div>
            )}
          </div>

          {user && (
            <div className="mt-4 p-3 bg-txn-primary-50 rounded-lg">
              <p className="text-sm text-txn-primary-700">
                已登入用戶：{user.email}
              </p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}