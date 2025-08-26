'use client'

import React, { useState, useEffect } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'
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
import { 
  ExclamationTriangleIcon, 
  XCircleIcon,
  UserGroupIcon,
  ChartBarIcon,
  CogIcon,
  HomeIcon,
  ArrowLeftOnRectangleIcon
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
        const { data, error } = await supabase
          .from('user_profiles')
          .select('role, status')
          .eq('id', user.id)
          .single()

        if (error) {
          console.error('檢查管理員權限錯誤:', error)
          setError('無法驗證管理員權限')
          setIsAdmin(false)
          setUserRole(null)
        } else {
          const role = data?.role as string
          const status = data?.status

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
        setError('系統錯誤')
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

  // 載入中狀態
  if (loading || authLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-txn-primary-50 to-txn-accent-50 dark:from-txn-primary-900 dark:to-txn-primary-800 flex items-center justify-center">
        <Loading size="xl" />
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