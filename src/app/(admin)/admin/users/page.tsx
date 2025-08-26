'use client'

import React, { useState, useEffect, useMemo } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'
import { useNotification } from '@/contexts/NotificationContext'
import {
  UserRole,
  UserStatus, 
  canManageRole,
  getAssignableRoles,
  ROLE_DISPLAY_NAMES,
  STATUS_DISPLAY_NAMES,
  ROLE_COLORS,
  STATUS_COLORS,
  PAGINATION_CONFIG
} from '@/lib/constants'
import { 
  Card, 
  CardHeader, 
  CardTitle, 
  CardContent, 
  Button, 
  Input,
  Badge
} from '@/components/ui'
import { useConfirmation } from '@/components/ui/ConfirmationProvider'
import { 
  UserGroupIcon,
  MagnifyingGlassIcon,
  ArrowPathIcon,
  PencilIcon,
  XMarkIcon
} from '@heroicons/react/24/outline'

interface UserProfile {
  id: string
  email: string
  full_name: string
  role: UserRole
  status: UserStatus
  trading_experience: string
  initial_capital: number
  currency: string
  timezone: string
  created_at: string
  approved_at: string | null
  approved_by: string | null
  last_login: string | null
}

interface UserListFilters {
  search: string
  roleFilter: UserRole | 'all'
  statusFilter: UserStatus | 'all'
}

const UsersManagementPage: React.FC = () => {
  const { user } = useAuth()
  const { showSuccess, showError, showInfo } = useNotification()
  const { confirm } = useConfirmation()

  // 狀態管理
  const [users, setUsers] = useState<UserProfile[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [currentUserRole, setCurrentUserRole] = useState<UserRole | null>(null)
  const [editingUserId, setEditingUserId] = useState<string | null>(null)
  const [updatingUserId, setUpdatingUserId] = useState<string | null>(null)

  // 篩選和分頁
  const [filters, setFilters] = useState<UserListFilters>({
    search: '',
    roleFilter: 'all',
    statusFilter: 'all'
  })
  const [currentPage, setCurrentPage] = useState(1)
  const [pageSize, setPageSize] = useState<number>(PAGINATION_CONFIG.DEFAULT_PAGE_SIZE)

  // 載入當前用戶角色
  useEffect(() => {
    const loadCurrentUserRole = async () => {
      if (!user) return

      try {
        const { data, error } = await supabase
          .from('user_profiles')
          .select('role')
          .eq('id', user.id)
          .single()

        if (error) {
          console.error('載入用戶角色錯誤:', error)
        } else {
          setCurrentUserRole(data?.role as UserRole)
        }
      } catch (error) {
        console.error('載入用戶角色錯誤:', error)
      }
    }

    loadCurrentUserRole()
  }, [user])

  // 載入用戶列表
  useEffect(() => {
    if (currentUserRole) {
      loadUsers()
    }
  }, [currentUserRole])

  const loadUsers = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('user_profiles')
        .select(`
          id,
          email,
          full_name,
          role,
          status,
          trading_experience,
          initial_capital,
          currency,
          timezone,
          created_at,
          approved_at,
          approved_by
        `)
        .order('created_at', { ascending: false })

      if (error) {
        console.error('載入用戶列表錯誤:', error)
        showError('載入失敗', '無法載入用戶列表')
      } else {
        setUsers(data as UserProfile[] || [])
      }
    } catch (error) {
      console.error('載入用戶列表錯誤:', error)
      showError('系統錯誤', '載入用戶列表時發生錯誤')
    } finally {
      setLoading(false)
    }
  }

  // 刷新數據
  const refreshData = async () => {
    setRefreshing(true)
    await loadUsers()
    setRefreshing(false)
    showInfo('數據已更新', '用戶列表已重新加載')
  }

  // 篩選後的用戶列表
  const filteredUsers = useMemo(() => {
    return users.filter(user => {
      const matchesSearch = !filters.search || 
        user.full_name?.toLowerCase().includes(filters.search.toLowerCase()) ||
        user.email.toLowerCase().includes(filters.search.toLowerCase())
      
      const matchesRole = filters.roleFilter === 'all' || user.role === filters.roleFilter
      const matchesStatus = filters.statusFilter === 'all' || user.status === filters.statusFilter

      return matchesSearch && matchesRole && matchesStatus
    })
  }, [users, filters])

  // 分頁後的用戶列表
  const paginatedUsers = useMemo(() => {
    const startIndex = (currentPage - 1) * pageSize
    const endIndex = startIndex + pageSize
    return filteredUsers.slice(startIndex, endIndex)
  }, [filteredUsers, currentPage, pageSize])

  const totalPages = Math.ceil(filteredUsers.length / pageSize)

  // 更新用戶角色
  const updateUserRole = async (userId: string, newRole: UserRole) => {
    if (!currentUserRole || !canManageRole(currentUserRole, newRole)) {
      showError('權限不足', '您沒有權限分配此角色')
      return
    }

    setUpdatingUserId(userId)
    try {
      const targetUser = users.find(u => u.id === userId)
      const oldRole = targetUser?.role
      
      const { error } = await supabase
        .from('user_profiles')
        .update({ 
          role: newRole,
          updated_at: new Date().toISOString()
        })
        .eq('id', userId)

      if (error) {
        console.error('更新用戶角色錯誤:', error)
        showError('更新失敗', '更新用戶角色失敗：' + error.message)
      } else {
        showSuccess('更新成功', `用戶角色已更新為 ${ROLE_DISPLAY_NAMES[newRole]}`)
        

        // 記錄管理員操作
        await supabase.from('admin_logs').insert({
          admin_id: user?.id,
          action: 'UPDATE_USER_ROLE',
          target_user_id: userId,
          details: {
            action: 'Role updated',
            old_role: oldRole,
            new_role: newRole,
            updated_by_role: currentUserRole
          }
        })

        loadUsers()
      }
    } catch (error) {
      console.error('更新用戶角色錯誤:', error)
      showError('系統錯誤', '更新用戶角色時發生錯誤')
    } finally {
      setUpdatingUserId(null)
      setEditingUserId(null)
    }
  }

  // 更新用戶狀態
  const updateUserStatus = async (userId: string, newStatus: UserStatus) => {
    const targetUser = users.find(u => u.id === userId)
    if (!targetUser) return

    confirm({
      title: '確認狀態變更',
      message: `您確定要將用戶 ${targetUser.full_name || targetUser.email} 的狀態變更為 ${STATUS_DISPLAY_NAMES[newStatus]} 嗎？`,
      confirmText: '確認變更',
      cancelText: '取消',
      type: newStatus === 'inactive' ? 'danger' : 'warning',
      onConfirm: async () => {
        const oldStatus = targetUser.status
        
        setUpdatingUserId(userId)
        try {
          const { error } = await supabase
            .from('user_profiles')
            .update({ 
              status: newStatus,
              updated_at: new Date().toISOString()
            })
            .eq('id', userId)

          if (error) {
            console.error('更新用戶狀態錯誤:', error)
            showError('更新失敗', '更新用戶狀態失敗：' + error.message)
          } else {
            showSuccess('更新成功', `用戶狀態已更新為 ${STATUS_DISPLAY_NAMES[newStatus]}`)

            // 記錄狀態變更歷史
            await supabase.from('user_status_history').insert({
              user_id: userId,
              old_status: oldStatus,
              new_status: newStatus,
              changed_by: user?.id,
              reason: `狀態由管理員變更為 ${STATUS_DISPLAY_NAMES[newStatus]}`
            })

            loadUsers()
          }
        } catch (error) {
          console.error('更新用戶狀態錯誤:', error)
          showError('系統錯誤', '更新用戶狀態時發生錯誤')
        } finally {
          setUpdatingUserId(null)
        }
      }
    })
  }

  // 格式化日期
  const formatDate = (dateString: string | null) => {
    if (!dateString) return '未設定'
    return new Date(dateString).toLocaleString('zh-TW', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  // 獲取交易經驗標籤
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
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-txn-accent"></div>
      </div>
    )
  }

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* 頁面標題 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-txn-primary-800 dark:text-white">
            用戶管理
          </h1>
          <p className="text-txn-primary-600 dark:text-gray-400 mt-1">
            管理系統用戶和角色權限
          </p>
        </div>
        <Button
          variant="outline"
          onClick={refreshData}
          loading={refreshing}
          disabled={refreshing}
        >
          <ArrowPathIcon className="h-4 w-4 mr-2" />
          刷新數據
        </Button>
      </div>

      {/* 篩選和搜尋 */}
      <Card variant="elevated">
        <CardContent className="py-4">
          <div className="flex flex-col md:flex-row gap-4">
            {/* 搜尋框 */}
            <div className="flex-1">
              <Input
                type="text"
                placeholder="搜尋用戶姓名或郵箱..."
                value={filters.search}
                onChange={(e) => setFilters({ ...filters, search: e.target.value })}
                className="w-full"
                leftIcon={<MagnifyingGlassIcon className="h-5 w-5" />}
              />
            </div>

            {/* 角色篩選 */}
            <div className="md:w-48">
              <select
                value={filters.roleFilter}
                onChange={(e) => setFilters({ ...filters, roleFilter: e.target.value as UserRole | 'all' })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-txn-accent focus:border-transparent"
              >
                <option value="all">所有角色</option>
                <option value="user">一般用戶</option>
                <option value="moderator">版主</option>
                <option value="admin">管理員</option>
                <option value="super_admin">超級管理員</option>
              </select>
            </div>

            {/* 狀態篩選 */}
            <div className="md:w-48">
              <select
                value={filters.statusFilter}
                onChange={(e) => setFilters({ ...filters, statusFilter: e.target.value as UserStatus | 'all' })}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-txn-accent focus:border-transparent"
              >
                <option value="all">所有狀態</option>
                <option value="pending">待審核</option>
                <option value="active">活躍</option>
                <option value="inactive">已停用</option>
                <option value="suspended">已暫停</option>
              </select>
            </div>
          </div>

          {/* 結果統計 */}
          <div className="mt-4 text-sm text-gray-600">
            顯示 {filteredUsers.length} 個用戶中的 {Math.min(pageSize, filteredUsers.length - (currentPage - 1) * pageSize)} 個
          </div>
        </CardContent>
      </Card>

      {/* 用戶列表 */}
      <Card variant="elevated">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <UserGroupIcon className="h-5 w-5" />
            用戶列表
          </CardTitle>
        </CardHeader>
        
        <CardContent>
          {paginatedUsers.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              <UserGroupIcon className="h-12 w-12 mx-auto mb-4 opacity-50" />
              <p>沒有找到符合條件的用戶</p>
            </div>
          ) : (
            <div className="space-y-4">
              {paginatedUsers.map((user) => {
                const isEditing = editingUserId === user.id
                const isUpdating = updatingUserId === user.id
                const canEdit = currentUserRole === 'super_admin'
                const assignableRoles = getAssignableRoles(currentUserRole || 'user')

                return (
                  <div
                    key={user.id}
                    className="border border-gray-200 rounded-lg p-4 bg-white hover:shadow-sm transition-shadow"
                  >
                    <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
                      {/* 用戶基本信息 */}
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <h4 className="font-semibold text-lg">
                            {user.full_name || '未提供姓名'}
                          </h4>
                          <Badge 
                            variant={ROLE_COLORS[user.role] as "default" | "success" | "danger" | "warning" | "info" | "profit" | "loss"}
                            size="sm"
                          >
                            {ROLE_DISPLAY_NAMES[user.role]}
                          </Badge>
                          <Badge 
                            variant={STATUS_COLORS[user.status] as "default" | "success" | "danger" | "warning" | "info" | "profit" | "loss"}
                            size="sm"
                          >
                            {STATUS_DISPLAY_NAMES[user.status]}
                          </Badge>
                        </div>
                        
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-2 text-sm text-gray-600">
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
                            {user.currency} ${user.initial_capital.toLocaleString()}
                          </div>
                          <div>
                            <span className="font-medium">註冊時間：</span>
                            {formatDate(user.created_at)}
                          </div>
                          <div>
                            <span className="font-medium">審核時間：</span>
                            {formatDate(user.approved_at)}
                          </div>
                          <div>
                            <span className="font-medium">時區：</span>
                            {user.timezone}
                          </div>
                        </div>
                      </div>

                      {/* 角色管理區域 */}
                      {canEdit && (
                        <div className="flex flex-col sm:flex-row items-end gap-2 lg:flex-shrink-0">
                          {isEditing ? (
                            <div className="flex items-center gap-2">
                              <select
                                disabled={isUpdating}
                                onChange={(e) => updateUserRole(user.id, e.target.value as UserRole)}
                                className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-txn-accent focus:border-transparent"
                              >
                                <option value="">選擇角色</option>
                                {assignableRoles.map(role => (
                                  <option key={role} value={role}>
                                    {ROLE_DISPLAY_NAMES[role]}
                                  </option>
                                ))}
                              </select>
                              <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => setEditingUserId(null)}
                                disabled={isUpdating}
                              >
                                <XMarkIcon className="h-4 w-4" />
                              </Button>
                            </div>
                          ) : (
                            <div className="flex items-center gap-2">
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => setEditingUserId(user.id)}
                                disabled={isUpdating || assignableRoles.length === 0}
                              >
                                <PencilIcon className="h-4 w-4 mr-1" />
                                編輯角色
                              </Button>
                              
                              <select
                                value={user.status}
                                onChange={(e) => updateUserStatus(user.id, e.target.value as UserStatus)}
                                disabled={isUpdating}
                                className="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-txn-accent focus:border-transparent text-sm"
                              >
                                <option value="pending">待審核</option>
                                <option value="active">活躍</option>
                                <option value="inactive">已停用</option>
                                <option value="suspended">已暫停</option>
                              </select>
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                )
              })}
            </div>
          )}

          {/* 分頁控制 */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between mt-6 pt-4 border-t border-gray-200">
              <div className="flex items-center gap-2">
                <span className="text-sm text-gray-600">每頁顯示：</span>
                <select
                  value={pageSize}
                  onChange={(e) => {
                    setPageSize(Number(e.target.value))
                    setCurrentPage(1)
                  }}
                  className="px-2 py-1 border border-gray-300 rounded text-sm"
                >
                  {PAGINATION_CONFIG.PAGE_SIZE_OPTIONS.map(size => (
                    <option key={size} value={size}>{size}</option>
                  ))}
                </select>
              </div>

              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
                  disabled={currentPage === 1}
                >
                  上一頁
                </Button>
                
                <span className="text-sm text-gray-600">
                  第 {currentPage} 頁，共 {totalPages} 頁
                </span>
                
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
                  disabled={currentPage === totalPages}
                >
                  下一頁
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}

export default UsersManagementPage