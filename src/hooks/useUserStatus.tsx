'use client'

import { useState, useEffect } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'

interface UserProfile {
  id: string
  email: string
  full_name: string
  role: 'admin' | 'user'
  status: 'active' | 'inactive' | 'pending'
  trading_experience: string
  initial_capital: number
  created_at: string
}

interface UseUserStatusReturn {
  userProfile: UserProfile | null
  loading: boolean
  error: string | null
  isAdmin: boolean
  isActive: boolean
  isPending: boolean
  refreshProfile: () => Promise<void>
}

export const useUserStatus = (): UseUserStatusReturn => {
  const { user } = useAuth()
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchUserProfile = async () => {
    if (!user) {
      setUserProfile(null)
      setLoading(false)
      return
    }

    try {
      setLoading(true)
      setError(null)

      const { data, error: fetchError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', user.id)
        .single()

      if (fetchError) {
        console.error('Error fetching user profile:', fetchError)
        setError('無法載入用戶資料')
        setUserProfile(null)
      } else {
        setUserProfile(data)
      }
    } catch (err) {
      console.error('Error in fetchUserProfile:', err)
      setError('載入用戶資料時發生錯誤')
      setUserProfile(null)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchUserProfile()
  }, [user])

  // 計算狀態
  const isAdmin = userProfile?.role === 'admin' && userProfile?.status === 'active'
  const isActive = userProfile?.status === 'active'
  const isPending = userProfile?.status === 'pending'

  return {
    userProfile,
    loading,
    error,
    isAdmin,
    isActive,
    isPending,
    refreshProfile: fetchUserProfile
  }
}

// 用戶狀態檢查組件
interface UserStatusGuardProps {
  children: React.ReactNode
  allowedStatuses?: Array<'active' | 'inactive' | 'pending'>
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
  const { userProfile, loading, isAdmin, isActive, isPending } = useUserStatus()

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

  if (!userProfile) {
    return fallback || (
      <div className="text-center p-8">
        <p className="text-gray-600">無法載入用戶資料</p>
      </div>
    )
  }

  // 檢查管理員權限
  if (requireAdmin && !isAdmin) {
    return fallback || (
      <div className="text-center p-8">
        <p className="text-red-600">您沒有權限訪問此內容</p>
      </div>
    )
  }

  // 檢查用戶狀態
  if (!allowedStatuses.includes(userProfile.status)) {
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

    if (userProfile.status === 'inactive') {
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