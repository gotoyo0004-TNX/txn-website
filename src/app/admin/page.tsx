'use client'

import React, { useState, useEffect } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'
import { Card, CardHeader, CardTitle, CardContent, Button } from '@/components/ui'
import { 
  UserGroupIcon, 
  CheckCircleIcon, 
  XCircleIcon, 
  ClockIcon,
  ExclamationTriangleIcon 
} from '@heroicons/react/24/outline'

interface PendingUser {
  id: string
  email: string
  full_name: string
  trading_experience: string
  initial_capital: number
  created_at: string
}

interface UserStats {
  total: number
  active: number
  pending: number
  inactive: number
}

const AdminPanel: React.FC = () => {
  const { user } = useAuth()
  const [isAdmin, setIsAdmin] = useState(false)
  const [loading, setLoading] = useState(true)
  const [pendingUsers, setPendingUsers] = useState<PendingUser[]>([])
  const [userStats, setUserStats] = useState<UserStats>({ total: 0, active: 0, pending: 0, inactive: 0 })
  const [actionLoading, setActionLoading] = useState<string | null>(null)

  // 檢查是否為管理員
  useEffect(() => {
    const checkAdminStatus = async () => {
      if (!user) {
        setLoading(false)
        return
      }

      try {
        const { data, error } = await supabase
          .from('user_profiles')
          .select('role, status')
          .eq('id', user.id)
          .single()

        if (error) {
          console.error('檢查管理員狀態錯誤:', error)
          setIsAdmin(false)
        } else {
          setIsAdmin(data?.role === 'admin' && data?.status === 'active')
        }
      } catch (error) {
        console.error('檢查管理員狀態錯誤:', error)
        setIsAdmin(false)
      } finally {
        setLoading(false)
      }
    }

    checkAdminStatus()
  }, [user])

  // 載入待審核用戶
  useEffect(() => {
    if (isAdmin) {
      loadPendingUsers()
      loadUserStats()
    }
  }, [isAdmin])

  const loadPendingUsers = async () => {
    try {
      const { data, error } = await supabase
        .from('user_profiles')
        .select('id, email, full_name, trading_experience, initial_capital, created_at')
        .eq('status', 'pending')
        .order('created_at', { ascending: true })

      if (error) {
        console.error('載入待審核用戶錯誤:', error)
      } else {
        setPendingUsers(data || [])
      }
    } catch (error) {
      console.error('載入待審核用戶錯誤:', error)
    }
  }

  const loadUserStats = async () => {
    try {
      const { data, error } = await supabase
        .from('user_profiles')
        .select('status')

      if (error) {
        console.error('載入用戶統計錯誤:', error)
        return
      }

      const stats = data.reduce((acc, user) => {
        acc.total += 1
        acc[user.status as keyof Omit<UserStats, 'total'>] += 1
        return acc
      }, { total: 0, active: 0, pending: 0, inactive: 0 })

      setUserStats(stats)
    } catch (error) {
      console.error('載入用戶統計錯誤:', error)
    }
  }

  const approveUser = async (userId: string) => {
    setActionLoading(userId)
    try {
      const { error } = await supabase.rpc('approve_user', {
        target_user_id: userId
      })

      if (error) {
        console.error('批准用戶錯誤:', error)
        alert('批准用戶失敗：' + error.message)
      } else {
        alert('用戶已成功批准！')
        loadPendingUsers()
        loadUserStats()
      }
    } catch (error) {
      console.error('批准用戶錯誤:', error)
      alert('批准用戶時發生錯誤')
    } finally {
      setActionLoading(null)
    }
  }

  const rejectUser = async (userId: string) => {
    const reason = prompt('請輸入拒絕原因（可選）：') || '管理員拒絕'
    
    setActionLoading(userId)
    try {
      const { error } = await supabase.rpc('deactivate_user', {
        target_user_id: userId,
        reason: reason
      })

      if (error) {
        console.error('拒絕用戶錯誤:', error)
        alert('拒絕用戶失敗：' + error.message)
      } else {
        alert('用戶已被拒絕')
        loadPendingUsers()
        loadUserStats()
      }
    } catch (error) {
      console.error('拒絕用戶錯誤:', error)
      alert('拒絕用戶時發生錯誤')
    } finally {
      setActionLoading(null)
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString('zh-TW', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const getTradingExperienceLabel = (experience: string) => {
    const labels: Record<string, string> = {
      beginner: '新手',
      intermediate: '中級',
      advanced: '進階',
      professional: '專業'
    }
    return labels[experience] || experience
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-txn-primary-50 to-txn-accent-50 dark:from-txn-primary-900 dark:to-txn-primary-800 flex items-center justify-center">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-txn-accent"></div>
      </div>
    )
  }

  if (!user) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-txn-primary-50 to-txn-accent-50 dark:from-txn-primary-900 dark:to-txn-primary-800 flex items-center justify-center p-4">
        <Card variant="elevated" className="w-full max-w-md">
          <CardContent className="text-center py-8">
            <ExclamationTriangleIcon className="h-16 w-16 text-yellow-500 mx-auto mb-4" />
            <h3 className="text-xl font-semibold mb-2">需要登入</h3>
            <p className="text-gray-600 mb-4">請先登入以訪問管理員面板</p>
            <Button variant="primary" onClick={() => window.location.href = '/auth'}>
              前往登入
            </Button>
          </CardContent>
        </Card>
      </div>
    )
  }

  if (!isAdmin) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-txn-primary-50 to-txn-accent-50 dark:from-txn-primary-900 dark:to-txn-primary-800 flex items-center justify-center p-4">
        <Card variant="elevated" className="w-full max-w-md">
          <CardContent className="text-center py-8">
            <XCircleIcon className="h-16 w-16 text-red-500 mx-auto mb-4" />
            <h3 className="text-xl font-semibold mb-2">訪問被拒絕</h3>
            <p className="text-gray-600 mb-4">您沒有管理員權限訪問此頁面</p>
            <Button variant="primary" onClick={() => window.location.href = '/'}>
              回到首頁
            </Button>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-txn-primary-50 to-txn-accent-50 dark:from-txn-primary-900 dark:to-txn-primary-800 p-4">
      <div className="max-w-7xl mx-auto space-y-6">
        {/* 頁面標題 */}
        <div className="text-center">
          <h1 className="text-3xl font-bold text-txn-primary-800 dark:text-white mb-2">
            TXN 管理員控制面板
          </h1>
          <p className="text-txn-primary-600 dark:text-gray-400">
            用戶審核與系統管理
          </p>
        </div>

        {/* 統計卡片 */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card variant="elevated" className="text-center">
            <CardContent className="py-6">
              <UserGroupIcon className="h-8 w-8 text-blue-500 mx-auto mb-2" />
              <div className="text-2xl font-bold text-blue-600">{userStats.total}</div>
              <div className="text-sm text-gray-600">總用戶數</div>
            </CardContent>
          </Card>

          <Card variant="elevated" className="text-center">
            <CardContent className="py-6">
              <CheckCircleIcon className="h-8 w-8 text-green-500 mx-auto mb-2" />
              <div className="text-2xl font-bold text-green-600">{userStats.active}</div>
              <div className="text-sm text-gray-600">活躍用戶</div>
            </CardContent>
          </Card>

          <Card variant="elevated" className="text-center">
            <CardContent className="py-6">
              <ClockIcon className="h-8 w-8 text-yellow-500 mx-auto mb-2" />
              <div className="text-2xl font-bold text-yellow-600">{userStats.pending}</div>
              <div className="text-sm text-gray-600">待審核</div>
            </CardContent>
          </Card>

          <Card variant="elevated" className="text-center">
            <CardContent className="py-6">
              <XCircleIcon className="h-8 w-8 text-red-500 mx-auto mb-2" />
              <div className="text-2xl font-bold text-red-600">{userStats.inactive}</div>
              <div className="text-sm text-gray-600">已停用</div>
            </CardContent>
          </Card>
        </div>

        {/* 待審核用戶列表 */}
        <Card variant="elevated">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <ClockIcon className="h-5 w-5" />
              待審核用戶 ({pendingUsers.length})
            </CardTitle>
          </CardHeader>
          
          <CardContent>
            {pendingUsers.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                <ClockIcon className="h-12 w-12 mx-auto mb-4 opacity-50" />
                <p>目前沒有待審核的用戶</p>
              </div>
            ) : (
              <div className="space-y-4">
                {pendingUsers.map((user) => (
                  <div
                    key={user.id}
                    className="border border-gray-200 rounded-lg p-4 bg-white"
                  >
                    <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <h4 className="font-semibold text-lg">{user.full_name || '未提供姓名'}</h4>
                          <span className="text-sm bg-yellow-100 text-yellow-800 px-2 py-1 rounded">
                            待審核
                          </span>
                        </div>
                        
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-2 text-sm text-gray-600">
                          <div>
                            <span className="font-medium">電子郵件：</span>
                            {user.email}
                          </div>
                          <div>
                            <span className="font-medium">交易經驗：</span>
                            {getTradingExperienceLabel(user.trading_experience)}
                          </div>
                          <div>
                            <span className="font-medium">初始資金：</span>
                            ${user.initial_capital.toLocaleString()}
                          </div>
                        </div>
                        
                        <div className="text-xs text-gray-500 mt-2">
                          註冊時間：{formatDate(user.created_at)}
                        </div>
                      </div>

                      <div className="flex gap-2">
                        <Button
                          variant="success"
                          size="sm"
                          onClick={() => approveUser(user.id)}
                          loading={actionLoading === user.id}
                          disabled={actionLoading !== null}
                        >
                          <CheckCircleIcon className="h-4 w-4 mr-1" />
                          批准
                        </Button>
                        
                        <Button
                          variant="danger"
                          size="sm"
                          onClick={() => rejectUser(user.id)}
                          loading={actionLoading === user.id}
                          disabled={actionLoading !== null}
                        >
                          <XCircleIcon className="h-4 w-4 mr-1" />
                          拒絕
                        </Button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

export default AdminPanel