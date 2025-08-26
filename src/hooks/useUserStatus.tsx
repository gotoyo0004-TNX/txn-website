'use client'

import { useState, useEffect, useCallback } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'
import { UserRole, UserStatus, canAccessAdminPanel } from '@/lib/constants'

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
  updated_at?: string
  approved_at?: string
  approved_by?: string
}

interface UserStatusReturn {
  profile: UserProfile | null
  role: UserRole | null
  status: UserStatus | null
  loading: boolean
  isAdmin: boolean
  canAccessAdmin: boolean
  isPending: boolean
  refreshProfile: () => Promise<void>
}

export const useUserStatus = (): UserStatusReturn => {
  const { user } = useAuth()
  const [profile, setProfile] = useState<UserProfile | null>(null)
  const [role, setRole] = useState<UserRole | null>(null)
  const [status, setStatus] = useState<UserStatus | null>(null)
  const [loading, setLoading] = useState(true)

  const fetchUserProfile = useCallback(async () => {
    if (!user) {
      setLoading(false)
      setProfile(null)
      setRole(null)
      setStatus(null)
      return
    }

    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', user.id)
        .single()

      if (error) {
        console.error('獲取用戶資料錯誤:', error)
        setProfile(null)
        setRole(null)
        setStatus(null)
        return
      }

      setProfile(data)
      setRole(data.role)
      setStatus(data.status)
    } catch (error) {
      console.error('獲取用戶資料錯誤:', error)
      setProfile(null)
      setRole(null)
      setStatus(null)
    } finally {
      setLoading(false)
    }
  }, [user])

  useEffect(() => {
    fetchUserProfile()
  }, [fetchUserProfile])

  // 計算權限狀態
  const computedValues = {
    isPending: profile?.status === 'pending',
    // 注意：根據管理員權限驗證規範，所有非'user'角色的用戶都可以訪問管理面板
    isAdmin: role !== null && role !== 'user',
    canAccessAdmin: role !== null && canAccessAdminPanel(role) && status === 'active'
  }

  return {
    profile,
    role,
    status,
    loading,
    isAdmin: computedValues.isAdmin,
    canAccessAdmin: computedValues.canAccessAdmin,
    isPending: computedValues.isPending,
    refreshProfile: fetchUserProfile
  }
}

// 用戶狀態檢查組件
interface UserStatusGuardProps {
  children: React.ReactNode
  allowedStatuses?: UserStatus[]
  requireAdmin?: boolean
  fallback?: React.ReactNode
}

export const UserStatusGuard: React.FC<UserStatusGuardProps> = ({
  children,
  allowedStatuses = ['active'],
  requireAdmin = false,
  fallback = null
}) => {
  const { user } = useAuth()
  const { profile, loading, isAdmin, canAccessAdmin, isPending } = useUserStatus()

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-txn-accent"></div>
      </div>
    )
  }

  if (!user) {
    return fallback || (
      <div className="text-center p-8">
        <p className="text-gray-600">請先登入以查看此內容</p>
      </div>
    )
  }

  if (!profile) {
    return fallback || (
      <div className="text-center p-8">
        <p className="text-gray-600">無法載入用戶資料</p>
      </div>
    )
  }

  // 檢查管理員權限
  if (requireAdmin && !canAccessAdmin) {
    return fallback || (
      <div className="text-center p-8">
        <p className="text-red-600">您沒有權限訪問此內容</p>
      </div>
    )
  }

  // 檢查用戶狀態
  if (!allowedStatuses.includes(profile.status)) {
    if (isPending) {
      return fallback || (
        <div className="text-center p-8">
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6 max-w-md mx-auto">
            <div className="text-yellow-600 mb-2">⏳</div>
            <h3 className="font-semibold text-yellow-800 mb-2">帳戶審核中</h3>
            <p className="text-yellow-700 text-sm">
              您的帳戶正在等待管理員審核，請耐心等待。
            </p>
          </div>
        </div>
      )
    }

    if (profile.status === 'inactive') {
      return fallback || (
        <div className="text-center p-8">
          <div className="bg-red-50 border border-red-200 rounded-lg p-6 max-w-md mx-auto">
            <div className="text-red-600 mb-2">🚫</div>
            <h3 className="font-semibold text-red-800 mb-2">帳戶已停用</h3>
            <p className="text-red-700 text-sm">
              您的帳戶已被停用，如有疑問請聯繫管理員。
            </p>
          </div>
        </div>
      )
    }
  }

  return <>{children}</>
}

export default useUserStatus