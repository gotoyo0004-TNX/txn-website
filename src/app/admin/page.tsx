'use client'

import React, { useState, useEffect } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'
import { 
  Card, 
  CardHeader, 
  CardTitle, 
  CardContent, 
  Button, 
  NotificationProvider,
  ConfirmationProvider,
  useNotification,
  useConfirmation
} from '@/components/ui'
import { 
  UserGroupIcon, 
  CheckCircleIcon, 
  XCircleIcon, 
  ClockIcon,
  ExclamationTriangleIcon,
  DocumentTextIcon,
  ArrowPathIcon,
  EyeIcon
} from '@heroicons/react/24/outline'

interface PendingUser {
  id: string
  email: string
  full_name: string
  trading_experience: string
  initial_capital: number
  created_at: string
  role: string
  currency: string
  timezone: string
}

interface UserStats {
  total: number
  active: number
  pending: number
  inactive: number
}

interface AdminLog {
  id: string
  action: string
  target_user_id: string
  created_at: string
  details: Record<string, unknown>
  target_user?: {
    email: string
    full_name: string
  }
}

const AdminPanelContent: React.FC = () => {
  const { user } = useAuth()
  const { addNotification } = useNotification()
  const { confirm } = useConfirmation()
  const [isAdmin, setIsAdmin] = useState(false)
  const [loading, setLoading] = useState(true)
  const [pendingUsers, setPendingUsers] = useState<PendingUser[]>([])
  const [userStats, setUserStats] = useState<UserStats>({ total: 0, active: 0, pending: 0, inactive: 0 })
  const [actionLoading, setActionLoading] = useState<string | null>(null)
  const [adminLogs, setAdminLogs] = useState<AdminLog[]>([])
  const [showLogs, setShowLogs] = useState(false)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  
  // 批量操作相關狀態
  const [selectedUsers, setSelectedUsers] = useState<Set<string>>(new Set())
  const [batchLoading, setBatchLoading] = useState(false)
  const [selectAll, setSelectAll] = useState(false)

  // 檢查是否為管理員
  useEffect(() => {
    const checkAdminStatus = async () => {
      if (!user) {
        setLoading(false)
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
          console.error('檢查管理員狀態錯誤:', error)
          setError('無法驗證管理員權限')
          setIsAdmin(false)
          addNotification({
            type: 'error',
            title: '權限驗證失敗',
            message: '無法驗證您的管理員權限，請稍後再試'
          })
        } else {
          const isValidAdmin = data?.role === 'admin' && data?.status === 'active'
          setIsAdmin(isValidAdmin)
          
          if (isValidAdmin) {
            addNotification({
              type: 'success',
              title: '歡迎回來',
              message: '管理員權限驗證成功'
            })
          }
        }
      } catch (error) {
        console.error('檢查管理員狀態錯誤:', error)
        setError('系統錯誤')
        setIsAdmin(false)
        addNotification({
          type: 'error',
          title: '系統錯誤',
          message: '系統發生錯誤，請稍後再試'
        })
      } finally {
        setLoading(false)
      }
    }

    checkAdminStatus()
  }, [user, addNotification])

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
        .select('id, email, full_name, trading_experience, initial_capital, created_at, role, currency, timezone')
        .eq('status', 'pending')
        .order('created_at', { ascending: true })

      if (error) {
        console.error('載入待審核用戶錯誤:', error)
        addNotification({
          type: 'error',
          title: '載入失敗',
          message: '無法載入待審核用戶列表'
        })
      } else {
        setPendingUsers(data || [])
      }
    } catch (error) {
      console.error('載入待審核用戶錯誤:', error)
      addNotification({
        type: 'error',
        title: '系統錯誤',
        message: '載入數據時發生錯誤'
      })
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
        addNotification({
          type: 'error',
          title: '批准失敗',
          message: '批准用戶失敗：' + error.message
        })
      } else {
        addNotification({
          type: 'success',
          title: '批准成功',
          message: '用戶已成功批准！'
        })
        loadPendingUsers()
        loadUserStats()
      }
    } catch (error) {
      console.error('批准用戶錯誤:', error)
      addNotification({
        type: 'error',
        title: '系統錯誤',
        message: '批准用戶時發生錯誤'
      })
    } finally {
      setActionLoading(null)
    }
  }

  const rejectUser = async (userId: string) => {
    confirm({
      title: '確認拒絕用戶',
      message: '您確定要拒絕這個用戶嗎？此操作無法撤銷。',
      confirmText: '確認拒絕',
      cancelText: '取消',
      type: 'danger',
      onConfirm: async () => {
        const reason = '管理員拒絕'
        
        setActionLoading(userId)
        try {
          const { error } = await supabase.rpc('deactivate_user', {
            target_user_id: userId,
            reason: reason
          })

          if (error) {
            console.error('拒絕用戶錯誤:', error)
            addNotification({
              type: 'error',
              title: '拒絕失敗',
              message: '拒絕用戶失敗：' + error.message
            })
          } else {
            addNotification({
              type: 'success',
              title: '拒絕成功',
              message: '用戶已被拒絕'
            })
            loadPendingUsers()
            loadUserStats()
          }
        } catch (error) {
          console.error('拒絕用戶錯誤:', error)
          addNotification({
            type: 'error',
            title: '系統錯誤',
            message: '拒絕用戶時發生錯誤'
          })
        } finally {
          setActionLoading(null)
        }
      }
    })
  }

  // 批量操作相關函數
  const handleSelectUser = (userId: string, checked: boolean) => {
    const newSelected = new Set(selectedUsers)
    if (checked) {
      newSelected.add(userId)
    } else {
      newSelected.delete(userId)
    }
    setSelectedUsers(newSelected)
    setSelectAll(newSelected.size === pendingUsers.length && pendingUsers.length > 0)
  }

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedUsers(new Set(pendingUsers.map(user => user.id)))
    } else {
      setSelectedUsers(new Set())
    }
    setSelectAll(checked)
  }

  const batchApproveUsers = async () => {
    if (selectedUsers.size === 0) {
      addNotification({
        type: 'warning',
        title: '沒有選擇用戶',
        message: '請先選擇要批准的用戶'
      })
      return
    }

    confirm({
      title: '批量批准用戶',
      message: `您確定要批准這 ${selectedUsers.size} 個用戶嗎？`,
      confirmText: '批准全部',
      cancelText: '取消',
      type: 'warning',
      onConfirm: async () => {
        setBatchLoading(true)
        const userIds = Array.from(selectedUsers)
        let successCount = 0
        let failureCount = 0

        for (const userId of userIds) {
          try {
            const { error } = await supabase.rpc('approve_user', {
              target_user_id: userId
            })
            if (error) {
              console.error(`批准用戶 ${userId} 失敗:`, error)
              failureCount++
            } else {
              successCount++
            }
          } catch (error) {
            console.error(`批准用戶 ${userId} 錯誤:`, error)
            failureCount++
          }
        }

        if (successCount > 0) {
          addNotification({
            type: 'success',
            title: '批量批准完成',
            message: `成功批准 ${successCount} 個用戶${failureCount > 0 ? `，${failureCount} 個失敗` : ''}`
          })
        }

        if (failureCount > 0 && successCount === 0) {
          addNotification({
            type: 'error',
            title: '批量批准失敗',
            message: `所有 ${failureCount} 個用戶批准失敗`
          })
        }

        setSelectedUsers(new Set())
        setSelectAll(false)
        setBatchLoading(false)
        loadPendingUsers()
        loadUserStats()
      }
    })
  }

  const batchRejectUsers = async () => {
    if (selectedUsers.size === 0) {
      addNotification({
        type: 'warning',
        title: '沒有選擇用戶',
        message: '請先選擇要拒絕的用戶'
      })
      return
    }

    confirm({
      title: '批量拒絕用戶',
      message: `您確定要拒絕這 ${selectedUsers.size} 個用戶嗎？此操作無法撤銷。`,
      confirmText: '拒絕全部',
      cancelText: '取消',
      type: 'danger',
      onConfirm: async () => {
        setBatchLoading(true)
        const userIds = Array.from(selectedUsers)
        const reason = '管理員批量拒絕'
        let successCount = 0
        let failureCount = 0

        for (const userId of userIds) {
          try {
            const { error } = await supabase.rpc('deactivate_user', {
              target_user_id: userId,
              reason: reason
            })
            if (error) {
              console.error(`拒絕用戶 ${userId} 失敗:`, error)
              failureCount++
            } else {
              successCount++
            }
          } catch (error) {
            console.error(`拒絕用戶 ${userId} 錯誤:`, error)
            failureCount++
          }
        }

        if (successCount > 0) {
          addNotification({
            type: 'success',
            title: '批量拒絕完成',
            message: `成功拒絕 ${successCount} 個用戶${failureCount > 0 ? `，${failureCount} 個失敗` : ''}`
          })
        }

        if (failureCount > 0 && successCount === 0) {
          addNotification({
            type: 'error',
            title: '批量拒絕失敗',
            message: `所有 ${failureCount} 個用戶拒絕失敗`
          })
        }

        setSelectedUsers(new Set())
        setSelectAll(false)
        setBatchLoading(false)
        loadPendingUsers()
        loadUserStats()
      }
    })
  }

  const refreshData = async () => {
    setRefreshing(true)
    await Promise.all([
      loadPendingUsers(),
      loadUserStats()
    ])
    setRefreshing(false)
    addNotification({
      type: 'info',
      title: '數據已更新',
      message: '用戶數據已重新加載'
    })
  }

  // 在用戶列表更新後，清空選擇
  useEffect(() => {
    setSelectedUsers(new Set())
    setSelectAll(false)
  }, [pendingUsers])

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
            <div className="flex items-center justify-between">
              <CardTitle className="flex items-center gap-2">
                <ClockIcon className="h-5 w-5" />
                待審核用戶 ({pendingUsers.length})
              </CardTitle>
              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={refreshData}
                  loading={refreshing}
                  disabled={refreshing}
                >
                  <ArrowPathIcon className="h-4 w-4 mr-1" />
                  刷新
                </Button>
              </div>
            </div>
            
            {/* 批量操作工具欄 */}
            {pendingUsers.length > 0 && (
              <div className="flex items-center justify-between mt-4 p-3 bg-gray-50 rounded-lg">
                <div className="flex items-center gap-3">
                  <label className="flex items-center gap-2 text-sm">
                    <input
                      type="checkbox"
                      checked={selectAll}
                      onChange={(e) => handleSelectAll(e.target.checked)}
                      className="rounded border-gray-300 text-txn-accent focus:ring-txn-accent"
                    />
                    全選 ({selectedUsers.size}/{pendingUsers.length})
                  </label>
                </div>
                
                {selectedUsers.size > 0 && (
                  <div className="flex items-center gap-2">
                    <span className="text-sm text-gray-600">
                      已選擇 {selectedUsers.size} 個用戶
                    </span>
                    <Button
                      variant="success"
                      size="sm"
                      onClick={batchApproveUsers}
                      loading={batchLoading}
                      disabled={batchLoading}
                    >
                      <CheckCircleIcon className="h-4 w-4 mr-1" />
                      批量批准
                    </Button>
                    <Button
                      variant="danger"
                      size="sm"
                      onClick={batchRejectUsers}
                      loading={batchLoading}
                      disabled={batchLoading}
                    >
                      <XCircleIcon className="h-4 w-4 mr-1" />
                      批量拒絕
                    </Button>
                  </div>
                )}
              </div>
            )}
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
                    className={`border border-gray-200 rounded-lg p-4 bg-white transition-all ${
                      selectedUsers.has(user.id) ? 'ring-2 ring-txn-accent bg-txn-accent-50' : ''
                    }`}
                  >
                    <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
                      {/* 選擇框 */}
                      <div className="flex items-start gap-3">
                        <input
                          type="checkbox"
                          checked={selectedUsers.has(user.id)}
                          onChange={(e) => handleSelectUser(user.id, e.target.checked)}
                          className="mt-1 rounded border-gray-300 text-txn-accent focus:ring-txn-accent"
                        />
                        
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
                      </div>

                      {/* 操作按鈕 */}
                      <div className="flex gap-2 md:flex-shrink-0">
                        <Button
                          variant="success"
                          size="sm"
                          onClick={() => approveUser(user.id)}
                          loading={actionLoading === user.id}
                          disabled={actionLoading !== null || batchLoading}
                        >
                          <CheckCircleIcon className="h-4 w-4 mr-1" />
                          批准
                        </Button>
                        
                        <Button
                          variant="danger"
                          size="sm"
                          onClick={() => rejectUser(user.id)}
                          loading={actionLoading === user.id}
                          disabled={actionLoading !== null || batchLoading}
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

const AdminPanel: React.FC = () => {
  return (
    <NotificationProvider>
      <ConfirmationProvider>
        <AdminPanelContent />
      </ConfirmationProvider>
    </NotificationProvider>
  )
}

export default AdminPanel