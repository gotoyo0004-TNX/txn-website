'use client'

import React, { useState, useEffect } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'
import { useNotification } from '@/contexts/NotificationContext'
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
  PlusIcon,
  PencilIcon,
  TrashIcon,
  MagnifyingGlassIcon,
  UserCircleIcon,
  CheckBadgeIcon,
  XCircleIcon
} from '@heroicons/react/24/outline'

interface UserProfile {
  id: string
  email: string
  full_name?: string
  role: 'admin' | 'user' | 'moderator'
  status: 'active' | 'inactive' | 'banned'
  created_at: string
  updated_at: string
  approved_at?: string
}

const UsersPage: React.FC = () => {
  const { user } = useAuth()
  const { showSuccess, showError } = useNotification()
  const [loading, setLoading] = useState(true)
  const [users, setUsers] = useState<UserProfile[]>([])
  const [searchTerm, setSearchTerm] = useState('')

  useEffect(() => {
    loadUsers()
  }, [])

  const loadUsers = async () => {
    try {
      setLoading(true)
      
      const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) {
        throw error
      }

      setUsers(data || [])
    } catch (error) {
      console.error('載入用戶列表錯誤:', error)
      showError('載入失敗', '無法載入用戶列表')
    } finally {
      setLoading(false)
    }
  }

  const filteredUsers = users.filter(user =>
    user.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    user.full_name?.toLowerCase().includes(searchTerm.toLowerCase())
  )

  const getRoleDisplay = (role: string) => {
    switch (role) {
      case 'admin':
        return { text: '管理員', color: 'text-red-600 bg-red-100' }
      case 'moderator':
        return { text: '版主', color: 'text-orange-600 bg-orange-100' }
      case 'user':
        return { text: '一般用戶', color: 'text-green-600 bg-green-100' }
      default:
        return { text: role, color: 'text-gray-600 bg-gray-100' }
    }
  }

  const getStatusDisplay = (status: string) => {
    switch (status) {
      case 'active':
        return { text: '啟用', color: 'text-green-600 bg-green-100', icon: CheckBadgeIcon }
      case 'inactive':
        return { text: '未啟用', color: 'text-yellow-600 bg-yellow-100', icon: XCircleIcon }
      case 'banned':
        return { text: '封禁', color: 'text-red-600 bg-red-100', icon: XCircleIcon }
      default:
        return { text: status, color: 'text-gray-600 bg-gray-100', icon: UserCircleIcon }
    }
  }

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto space-y-6">
        <Card variant="elevated">
          <CardContent className="text-center py-12">
            <Loading size="xl" />
            <p className="mt-4 text-lg font-medium">載入用戶列表...</p>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* 頁面標題和操作 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-txn-primary-800 dark:text-white">
            用戶管理
          </h1>
          <p className="text-txn-primary-600 dark:text-gray-400 mt-1">
            管理系統用戶帳號和權限設定
          </p>
        </div>
        <div className="flex gap-2">
          <Button 
            variant="outline" 
            onClick={loadUsers}
            disabled={loading}
          >
            <MagnifyingGlassIcon className="h-4 w-4 mr-2" />
            重新載入
          </Button>
          <Button variant="primary">
            <PlusIcon className="h-4 w-4 mr-2" />
            新增用戶
          </Button>
        </div>
      </div>

      {/* 搜尋和篩選 */}
      <Card variant="elevated">
        <CardContent className="p-4">
          <div className="flex items-center gap-4">
            <div className="flex-1">
              <div className="relative">
                <MagnifyingGlassIcon className="h-5 w-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  placeholder="搜尋用戶信箱或姓名..."
                  className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-txn-accent-500 focus:border-transparent"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
              </div>
            </div>
            <div className="text-sm text-gray-500">
              共 {filteredUsers.length} 位用戶
            </div>
          </div>
        </CardContent>
      </Card>

      {/* 用戶列表 */}
      <Card variant="elevated">
        <CardHeader>
          <CardTitle className="flex items-center">
            <UserGroupIcon className="h-5 w-5 mr-2" />
            用戶列表
          </CardTitle>
        </CardHeader>
        <CardContent>
          {filteredUsers.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200">
                    <th className="text-left py-3 px-4 font-medium text-gray-700">用戶</th>
                    <th className="text-left py-3 px-4 font-medium text-gray-700">角色</th>
                    <th className="text-left py-3 px-4 font-medium text-gray-700">狀態</th>
                    <th className="text-left py-3 px-4 font-medium text-gray-700">註冊時間</th>
                    <th className="text-left py-3 px-4 font-medium text-gray-700">操作</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredUsers.map((userProfile) => {
                    const roleDisplay = getRoleDisplay(userProfile.role)
                    const statusDisplay = getStatusDisplay(userProfile.status)
                    const StatusIcon = statusDisplay.icon

                    return (
                      <tr key={userProfile.id} className="border-b border-gray-100 hover:bg-gray-50">
                        <td className="py-4 px-4">
                          <div className="flex items-center">
                            <UserCircleIcon className="h-8 w-8 text-gray-400 mr-3" />
                            <div>
                              <div className="font-medium text-gray-900">
                                {userProfile.full_name || '未設定姓名'}
                              </div>
                              <div className="text-sm text-gray-500">
                                {userProfile.email}
                              </div>
                            </div>
                          </div>
                        </td>
                        <td className="py-4 px-4">
                          <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${roleDisplay.color}`}>
                            {roleDisplay.text}
                          </span>
                        </td>
                        <td className="py-4 px-4">
                          <div className="flex items-center">
                            <StatusIcon className="h-4 w-4 mr-1" />
                            <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${statusDisplay.color}`}>
                              {statusDisplay.text}
                            </span>
                          </div>
                        </td>
                        <td className="py-4 px-4">
                          <div className="text-sm text-gray-900">
                            {new Date(userProfile.created_at).toLocaleDateString('zh-TW')}
                          </div>
                          <div className="text-xs text-gray-500">
                            {new Date(userProfile.created_at).toLocaleTimeString('zh-TW')}
                          </div>
                        </td>
                        <td className="py-4 px-4">
                          <div className="flex items-center gap-2">
                            <Button variant="ghost" size="sm">
                              <PencilIcon className="h-4 w-4" />
                            </Button>
                            <Button variant="ghost" size="sm" className="text-red-600 hover:text-red-700">
                              <TrashIcon className="h-4 w-4" />
                            </Button>
                          </div>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="text-center py-12">
              <UserGroupIcon className="h-16 w-16 mx-auto mb-4 text-gray-400" />
              <h3 className="text-lg font-semibold mb-2">沒有找到用戶</h3>
              <p className="text-gray-600 mb-4">
                {searchTerm ? '沒有符合搜尋條件的用戶' : '系統中還沒有用戶'}
              </p>
              {!searchTerm && (
                <Button variant="primary">
                  <PlusIcon className="h-4 w-4 mr-2" />
                  新增第一位用戶
                </Button>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* 用戶統計卡片 */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card variant="elevated">
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <UserGroupIcon className="h-8 w-8 text-blue-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">總用戶數</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {users.length}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card variant="elevated">
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <CheckBadgeIcon className="h-8 w-8 text-green-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">活躍用戶</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {users.filter(u => u.status === 'active').length}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card variant="elevated">
          <CardContent className="p-6">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <UserCircleIcon className="h-8 w-8 text-orange-600" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-500">管理員</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                  {users.filter(u => u.role === 'admin').length}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

export default UsersPage