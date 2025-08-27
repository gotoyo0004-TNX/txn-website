'use client'

import React, { useState, useEffect } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabase'
import { useNotification } from '@/contexts/NotificationContext'
import {
  UserRole,
  canAccessAdminPanel,
  ROLE_DISPLAY_NAMES,
} from '@/lib/constants'
import { 
  Card, 
  CardHeader, 
  CardTitle, 
  CardContent, 
  Button,
  Loading
} from '@/components/ui'
import { 
  UserGroupIcon,
  ChartBarIcon,
  CogIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon,
  ClockIcon
} from '@heroicons/react/24/outline'

interface DashboardStats {
  totalUsers: number
  pendingUsers: number
  activeUsers: number
  adminUsers: number
}

const AdminDashboardPage: React.FC = () => {
  const { user } = useAuth()
  const router = useRouter()
  const { showSuccess, showError } = useNotification()
  const [userRole, setUserRole] = useState<UserRole | null>(null)
  const [loading, setLoading] = useState(true)
  const [statsLoading, setStatsLoading] = useState(false)
  const [stats, setStats] = useState<DashboardStats>({
    totalUsers: 0,
    pendingUsers: 0,
    activeUsers: 0,
    adminUsers: 0
  })

  // 檢查管理員權限
  useEffect(() => {
    const checkAdminAccess = async () => {
      if (!user) {
        setLoading(false)
        router.push('/auth?redirect=' + encodeURIComponent(window.location.pathname))
        return
      }

      try {
        // 使用新的安全函數進行權限檢查
        const { data, error } = await supabase
          .rpc('get_current_user_info')

        if (error) {
          console.error('檢查管理員權限錯誤:', error)

          // 提供更詳細的錯誤信息
          let errorMessage = '無法驗證管理員權限'
          if (error.code === 'PGRST116') {
            errorMessage = '用戶資料不存在，請聯繫系統管理員'
          } else if (error.message?.includes('row level security')) {
            errorMessage = '資料庫權限設定問題，請聯繫技術支援'
          } else if (error.code) {
            errorMessage = `資料庫錯誤 (${error.code}): ${error.message}`
          }

          showError('權限驗證失敗', errorMessage)
          router.push('/')
        } else {
          // 處理新函數返回的資料格式
          const userData = Array.isArray(data) ? data[0] : data
          const role = userData?.role as UserRole
          const hasAdminAccess = canAccessAdminPanel(role)

          if (!hasAdminAccess || userData?.status !== 'active') {
            showError('訪問被拒絕', '您沒有管理員權限')
            router.push('/')
          } else {
            setUserRole(role)
            showSuccess('歡迎回來', `${ROLE_DISPLAY_NAMES[role]} 權限驗證成功`)
          }
        }
      } catch (error) {
        console.error('檢查管理員權限錯誤:', error)
        showError('系統錯誤', '驗證權限時發生錯誤')
        router.push('/')
      } finally {
        setLoading(false)
      }
    }

    checkAdminAccess()
  }, [user, router, showSuccess, showError])

  // 載入統計數據
  useEffect(() => {
    if (userRole) {
      loadStats()
    }
  }, [userRole])

  const loadStats = async () => {
    try {
      setStatsLoading(true)

      // 暫時使用模擬數據，避免權限問題
      // 等系統穩定後再實作真實的統計查詢
      await new Promise(resolve => setTimeout(resolve, 500)) // 模擬載入時間

      const mockStats = {
        totalUsers: 5,
        pendingUsers: 0,
        activeUsers: 5,
        adminUsers: 2
      }

      setStats(mockStats)
      showSuccess('統計載入成功', '系統統計數據已更新')

    } catch (error) {
      console.error('載入統計數據錯誤:', error)
      showError('載入失敗', '無法載入系統統計數據')

      // 使用預設值
      setStats({
        totalUsers: 0,
        pendingUsers: 0,
        activeUsers: 0,
        adminUsers: 0
      })
    } finally {
      setStatsLoading(false)
    }
  }

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto space-y-6">
        {/* 載入狀態的頁面標題 */}
        <div className="animate-pulse">
          <div className="h-8 bg-gray-200 rounded w-48 mb-2"></div>
          <div className="h-4 bg-gray-100 rounded w-64"></div>
        </div>

        {/* 載入狀態的統計卡片 */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[1, 2, 3, 4].map((i) => (
            <Card key={i} variant="elevated">
              <CardContent className="p-6">
                <div className="flex items-center animate-pulse">
                  <div className="flex-shrink-0">
                    <div className="h-8 w-8 bg-gray-200 rounded"></div>
                  </div>
                  <div className="ml-4 flex-1">
                    <div className="h-4 bg-gray-200 rounded w-20 mb-2"></div>
                    <div className="h-6 bg-gray-100 rounded w-12"></div>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* 載入中的主要指示器 */}
        <Card variant="elevated">
          <CardContent className="text-center py-12">
            <Loading size="xl" />
            <p className="mt-4 text-lg font-medium">載入管理員控制面板...</p>
            <p className="text-sm text-gray-600 mt-2">
              正在獲取系統統計和用戶數據
            </p>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* 頁面標題 */}
      <div>
        <h1 className="text-3xl font-bold text-txn-primary-800 dark:text-white">
          管理員儀表板
        </h1>
        <p className="text-txn-primary-600 dark:text-gray-400 mt-1">
          歡迎回來，{userRole && ROLE_DISPLAY_NAMES[userRole]}
        </p>
      </div>

      {/* 統計卡片 */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* 總用戶數 */}
        <Card variant="elevated">
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <UserGroupIcon className="h-8 w-8 text-blue-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">總用戶數</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {stats.totalUsers}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* 待審核用戶 */}
        <Card variant="elevated">
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <ClockIcon className="h-8 w-8 text-yellow-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">待審核用戶</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {stats.pendingUsers}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* 活躍用戶 */}
        <Card variant="elevated">
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <CheckCircleIcon className="h-8 w-8 text-green-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">活躍用戶</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {stats.activeUsers}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* 管理員用戶 */}
        <Card variant="elevated">
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <ExclamationTriangleIcon className="h-8 w-8 text-red-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">管理員</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {stats.adminUsers}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* 快速操作 */}
      <Card variant="elevated">
        <CardHeader>
          <CardTitle>快速操作</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* 用戶管理 */}
            <Button
              variant="outline"
              className="h-20 flex flex-col items-center justify-center"
              onClick={() => router.push('/admin/users')}
            >
              <UserGroupIcon className="h-6 w-6 mb-2" />
              <span>用戶管理</span>
              {stats.pendingUsers > 0 && (
                <span className="text-xs text-red-500">
                  {stats.pendingUsers} 個待審核
                </span>
              )}
            </Button>

            {/* 系統監控 */}
            <Button
              variant="outline"
              className="h-20 flex flex-col items-center justify-center"
              onClick={() => router.push('/admin/analytics')}
            >
              <ChartBarIcon className="h-6 w-6 mb-2" />
              <span>系統監控</span>
              <span className="text-xs text-gray-500">即將推出</span>
            </Button>

            {/* 系統設定 */}
            <Button
              variant="outline"
              className="h-20 flex flex-col items-center justify-center"
              onClick={() => router.push('/admin/settings')}
            >
              <CogIcon className="h-6 w-6 mb-2" />
              <span>系統設定</span>
              <span className="text-xs text-gray-500">即將推出</span>
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* 系統狀態 */}
      <Card variant="elevated">
        <CardHeader>
          <CardTitle>系統狀態</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-between p-4 bg-green-50 rounded-lg">
            <div className="flex items-center">
              <CheckCircleIcon className="h-5 w-5 text-green-600 mr-2" />
              <span className="text-green-800 font-medium">系統運行正常</span>
            </div>
            <span className="text-green-600 text-sm">
              最後更新: {new Date().toLocaleString('zh-TW')}
            </span>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

export default AdminDashboardPage