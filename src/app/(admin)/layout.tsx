'use client'

import React, { useState, useEffect } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { supabase, queryWithRetry } from '@/lib/supabase'
import { useRouter, usePathname } from 'next/navigation'
import { canAccessAdminPanel, UserRole, isValidRole } from '@/lib/constants'
import { 
  Card, 
  CardContent, 
  Button,
  Loading,
  NotificationProvider,
  ConfirmationProvider 
} from '@/components/ui'
import AdminDebugPanel from '@/components/debug/AdminDebugPanel'
import LoadingDebugger from '@/components/debug/LoadingDebugger'
import { 
  ExclamationTriangleIcon, 
  XCircleIcon,
  UserGroupIcon,
  ChartBarIcon,
  CogIcon,
  HomeIcon,
  ArrowLeftOnRectangleIcon,
  ClockIcon
} from '@heroicons/react/24/outline'

interface AdminLayoutProps {
  children: React.ReactNode
}

const AdminLayoutContent: React.FC<AdminLayoutProps> = ({ children }) => {
  const { user, loading: authLoading, signOut } = useAuth()
  const router = useRouter()
  const pathname = usePathname()
  const [isAdmin, setIsAdmin] = useState(false)
  const [userRole, setUserRole] = useState<UserRole | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [loadingTimeout, setLoadingTimeout] = useState(false)
  const [showDebugPanel, setShowDebugPanel] = useState(false)

  // 管理員導航項目
  const adminNavItems = [
    {
      name: '控制面板',
      href: '/admin',
      icon: HomeIcon,
      description: '系統概覽和快速操作'
    },
    {
      name: '用戶管理',
      href: '/admin/users',
      icon: UserGroupIcon,
      description: '管理用戶帳號和權限'
    },
    {
      name: '系統統計',
      href: '/admin/analytics',
      icon: ChartBarIcon,
      description: '查看系統使用統計'
    },
    {
      name: '系統設定',
      href: '/admin/settings',
      icon: CogIcon,
      description: '系統配置和偏好設定'
    }
  ]

  // 設置載入超時檢測
  useEffect(() => {
    let timeoutId: NodeJS.Timeout
    
    if (loading || authLoading) {
      // 5 秒後顯示超時提示
      timeoutId = setTimeout(() => {
        setLoadingTimeout(true)
      }, 5000)
    } else {
      setLoadingTimeout(false)
    }
    
    return () => {
      if (timeoutId) {
        clearTimeout(timeoutId)
      }
    }
  }, [loading, authLoading])

  // 檢查管理員權限
  useEffect(() => {
    const checkAdminAccess = async () => {
      if (authLoading) {
        return
      }

      if (!user) {
        setLoading(false)
        router.push('/auth?redirect=' + encodeURIComponent(pathname))
        return
      }

      try {
        setError(null)
        
        // 使用新的安全函數進行管理員權限檢查
        const result = await queryWithRetry(async () => {
          const timeoutPromise = new Promise((_, reject) => {
            setTimeout(() => reject(new Error('管理員權限檢查超時')), 5000) // 減少到 5 秒
          })

          // 使用我們建立的安全函數
          const userCheckPromise = supabase
            .rpc('get_current_user_info')

          return Promise.race([userCheckPromise, timeoutPromise])
        })
        
        const { data, error } = result as { data: any, error: any }

        if (error) {
          console.error('檢查管理員權限錯誤:', error)

          let errorMessage = '無法驗證管理員權限'

          if (error.code === 'PGRST116') {
            errorMessage = '用戶資料不存在，請聯絡系統管理員'
          } else if (error.message?.includes('row level security')) {
            errorMessage = '資料庫權限設定問題，請聯絡技術支援'
          } else if (error.message?.includes('permission denied')) {
            errorMessage = '沒有權限存取用戶資料'
          } else if (error.code) {
            errorMessage = `資料庫錯誤 (${error.code}): ${error.message}`
          }

          setError(errorMessage)
          setIsAdmin(false)
          setUserRole(null)
        } else {
          // 處理新函數返回的資料格式
          const userData = Array.isArray(data) ? data[0] : data
          const role = userData?.role as string
          const status = userData?.status

          if (!isValidRole(role)) {
            setError('無效的用戶角色')
            setIsAdmin(false)
            setUserRole(null)
          } else if (status !== 'active') {
            setError('帳號狀態異常')
            setIsAdmin(false)
            setUserRole(null)
          } else {
            const hasAdminAccess = canAccessAdminPanel(role)
            setIsAdmin(hasAdminAccess)
            setUserRole(role)

            if (!hasAdminAccess) {
              setError('您沒有管理員權限')
            }
          }
        }
      } catch (error) {
        console.error('檢查管理員權限錯誤:', error)
        
        let errorMessage = '系統錯誤'
        
        if (error instanceof Error) {
          if (error.message.includes('超時')) {
            errorMessage = '管理員權限檢查超時，請稍後再試或檢查網路連線'
          } else if (error.message.includes('Failed to fetch')) {
            errorMessage = '網路連線問題，請檢查網路設定'
          } else {
            errorMessage = error.message
          }
        }
        
        setError(errorMessage)
        setIsAdmin(false)
        setUserRole(null)
      } finally {
        setLoading(false)
      }
    }

    checkAdminAccess()
  }, [user, authLoading, router, pathname])

  // 處理登出
  const handleLogout = async () => {
    try {
      await signOut()
      router.push('/auth')
    } catch (error) {
      console.error('登出錯誤:', error)
    }
  }

  // 返回首頁
  const goToHome = () => {
    router.push('/')
  }

  // 載入中狀態 - 顯示詳細調試信息和超時處理
  if (loading || authLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-txn-primary-50 to-txn-accent-50 dark:from-txn-primary-900 dark:to-txn-primary-800">
        <div className="flex items-center justify-center py-8">
          <div className="w-full max-w-4xl space-y-6 px-4">
            {/* 標準載入指示器 */}
            <Card variant="elevated" className="w-full">
              <CardContent className="text-center py-8">
                <Loading size="xl" />
                <p className="mt-4 text-lg font-medium">載入管理面板中...</p>
                <p className="text-sm text-gray-600 mt-2">
                  正在驗證管理員權限和載入相關資料
                </p>
                
                {/* 載入步驟指示 */}
                <div className="mt-6 max-w-md mx-auto">
                  <div className="space-y-2 text-left">
                    <div className="flex items-center gap-2 text-sm">
                      <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse"></div>
                      <span className={authLoading ? 'text-blue-600' : 'text-green-600'}>
                        {authLoading ? '驗證用戶身份...' : '✓ 用戶身份已驗證'}
                      </span>
                    </div>
                    <div className="flex items-center gap-2 text-sm">
                      <div className={`w-2 h-2 rounded-full ${loading ? 'bg-blue-500 animate-pulse' : 'bg-green-500'}`}></div>
                      <span className={loading ? 'text-blue-600' : 'text-green-600'}>
                        {loading ? '檢查管理員權限...' : '✓ 權限檢查完成'}
                      </span>
                    </div>
                  </div>
                </div>
                
                {/* 超時提示 */}
                {loadingTimeout && (
                  <div className="mt-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
                    <div className="flex items-center gap-2 text-yellow-800 mb-2">
                      <ClockIcon className="h-5 w-5" />
                      <span className="font-medium">載入時間較長</span>
                    </div>
                    <p className="text-sm text-yellow-700 mb-3">
                      系統正在載入中，這可能需要一些時間。如果持續無法載入，請嘗試以下操作：
                    </p>
                    <div className="space-y-2 text-sm text-yellow-700">
                      <div className="flex items-center gap-2">
                        <span>•</span>
                        <span>重新整理頁面 (F5)</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <span>•</span>
                        <span>清除瀏覽器快取</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <span>•</span>
                        <span>檢查網路連線</span>
                      </div>
                    </div>
                    <div className="mt-4 flex gap-2 justify-center">
                      <Button 
                        variant="outline" 
                        size="sm"
                        onClick={() => window.location.reload()}
                      >
                        重新整理
                      </Button>
                      <Button 
                        variant="outline" 
                        size="sm"
                        onClick={() => setShowDebugPanel(!showDebugPanel)}
                      >
                        {showDebugPanel ? '隱藏' : '顯示'}診斷信息
                      </Button>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
            
            {/* 載入問題調試工具 */}
            {(showDebugPanel || process.env.NODE_ENV === 'development') && (
              <LoadingDebugger />
            )}
          </div>
        </div>
      </div>
    )
  }

  // 未登入狀態
  if (!user) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-txn-primary-50 to-txn-accent-50 dark:from-txn-primary-900 dark:to-txn-primary-800 flex items-center justify-center p-4">
        <Card variant="elevated" className="w-full max-w-md">
          <CardContent className="text-center py-8">
            <ExclamationTriangleIcon className="h-16 w-16 text-yellow-500 mx-auto mb-4" />
            <h3 className="text-xl font-semibold mb-2">需要登入</h3>
            <p className="text-gray-600 mb-4">請先登入以訪問管理員面板</p>
            <Button 
              variant="primary" 
              onClick={() => router.push('/auth?redirect=' + encodeURIComponent(pathname))}
            >
              前往登入
            </Button>
          </CardContent>
        </Card>
      </div>
    )
  }

  // 權限不足狀態
  if (!isAdmin || error) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-txn-primary-50 to-txn-accent-50 dark:from-txn-primary-900 dark:to-txn-primary-800 flex items-center justify-center p-4">
        <div className="w-full max-w-4xl space-y-6">
          <Card variant="elevated" className="w-full">
            <CardContent className="text-center py-8">
              <XCircleIcon className="h-16 w-16 text-red-500 mx-auto mb-4" />
              <h3 className="text-xl font-semibold mb-2">訪問被拒絕</h3>
              <p className="text-gray-600 mb-4">
                {error || '您沒有管理員權限訪問此頁面'}
              </p>
              <div className="flex gap-2 justify-center">
                <Button variant="outline" onClick={goToHome}>
                  回到首頁
                </Button>
                <Button variant="primary" onClick={handleLogout}>
                  <ArrowLeftOnRectangleIcon className="h-4 w-4 mr-1" />
                  登出
                </Button>
              </div>
            </CardContent>
          </Card>
          
          {/* 調試面板 - 只在開發模式下顯示 */}
          {process.env.NODE_ENV === 'development' && (
            <AdminDebugPanel />
          )}
        </div>
      </div>
    )
  }

  // 主要管理員布局
  return (
    <div className="min-h-screen bg-gradient-to-br from-txn-primary-50 to-txn-accent-50 dark:from-txn-primary-900 dark:to-txn-primary-800">
      {/* 頂部導航 */}
      <div className="bg-white dark:bg-gray-800 shadow-sm border-b border-gray-200 dark:border-gray-700">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            {/* 左側 - Logo 和標題 */}
            <div className="flex items-center gap-4">
              <h1 className="text-xl font-bold text-txn-primary-800 dark:text-white">
                TXN 管理面板
              </h1>
              <span className="text-sm bg-txn-accent-100 text-txn-accent-800 px-2 py-1 rounded-full">
                {userRole === 'super_admin' ? '超級管理員' : 
                 userRole === 'admin' ? '管理員' : 
                 userRole === 'moderator' ? '版主' : '用戶'}
              </span>
            </div>

            {/* 右側 - 用戶操作 */}
            <div className="flex items-center gap-2">
              <Button 
                variant="outline" 
                size="sm" 
                onClick={goToHome}
              >
                <HomeIcon className="h-4 w-4 mr-1" />
                回到網站
              </Button>
              <Button 
                variant="outline" 
                size="sm" 
                onClick={handleLogout}
              >
                <ArrowLeftOnRectangleIcon className="h-4 w-4 mr-1" />
                登出
              </Button>
            </div>
          </div>
        </div>
      </div>

      {/* 側邊導航和主要內容 */}
      <div className="flex">
        {/* 側邊導航 */}
        <div className="hidden md:flex md:flex-shrink-0">
          <div className="flex flex-col w-64">
            <div className="flex flex-col pt-5 pb-4 bg-white dark:bg-gray-800 shadow-sm">
              <div className="flex-1 flex flex-col px-3 space-y-1">
                {adminNavItems.map((item) => {
                  const Icon = item.icon
                  const isActive = pathname === item.href || 
                    (item.href !== '/admin' && pathname.startsWith(item.href))
                  
                  return (
                    <Button
                      key={item.href}
                      variant={isActive ? "primary" : "ghost"}
                      className="justify-start"
                      onClick={() => router.push(item.href)}
                    >
                      <Icon className="h-5 w-5 mr-3" />
                      <div className="text-left">
                        <div className="font-medium">{item.name}</div>
                        <div className="text-xs opacity-70">{item.description}</div>
                      </div>
                    </Button>
                  )
                })}
              </div>
            </div>
          </div>
        </div>

        {/* 主要內容區域 */}
        <div className="flex-1 overflow-hidden">
          <main className="flex-1 p-4">
            {children}
          </main>
        </div>
      </div>
    </div>
  )
}

const AdminLayout: React.FC<AdminLayoutProps> = ({ children }) => {
  return (
    <NotificationProvider>
      <ConfirmationProvider>
        <AdminLayoutContent>
          {children}
        </AdminLayoutContent>
      </ConfirmationProvider>
    </NotificationProvider>
  )
}

export default AdminLayout