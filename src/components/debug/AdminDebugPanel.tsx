'use client'

import React, { useState, useEffect } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'
import { 
  canAccessAdminPanel, 
  isValidRole, 
  ROLE_DISPLAY_NAMES,
  UserRole 
} from '@/lib/constants'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui'

interface DebugInfo {
  authUser: any
  profileData: any
  hasAdminAccess: boolean
  errors: string[]
}

export const AdminDebugPanel: React.FC = () => {
  const { user } = useAuth()
  const [debugInfo, setDebugInfo] = useState<DebugInfo | null>(null)
  const [loading, setLoading] = useState(false)

  const runDiagnostic = async () => {
    if (!user) return

    setLoading(true)
    const errors: string[] = []
    let profileData = null
    let hasAdminAccess = false

    try {
      // 檢查用戶資料
      const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', user.id)
        .single()

      if (error) {
        errors.push(`資料庫查詢錯誤: ${error.message}`)
      } else {
        profileData = data
        
        // 檢查角色有效性
        if (!isValidRole(data?.role)) {
          errors.push(`無效的角色: ${data?.role}`)
        } else {
          hasAdminAccess = canAccessAdminPanel(data.role as UserRole)
        }

        // 檢查狀態
        if (data?.status !== 'active') {
          errors.push(`帳號狀態異常: ${data?.status}`)
        }
      }

      setDebugInfo({
        authUser: user,
        profileData,
        hasAdminAccess,
        errors
      })
    } catch (error) {
      errors.push(`系統錯誤: ${error}`)
      setDebugInfo({
        authUser: user,
        profileData: null,
        hasAdminAccess: false,
        errors
      })
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (user) {
      runDiagnostic()
    }
  }, [user])

  if (!user) {
    return (
      <Card>
        <CardContent className="p-6 text-center">
          <p className="text-red-600">未登入</p>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>管理員權限診斷</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {loading ? (
          <p>診斷中...</p>
        ) : debugInfo ? (
          <div className="space-y-4">
            {/* 認證用戶信息 */}
            <div>
              <h3 className="font-semibold mb-2">認證用戶信息</h3>
              <div className="bg-gray-50 p-3 rounded text-sm">
                <p><strong>UUID:</strong> {debugInfo.authUser.id}</p>
                <p><strong>Email:</strong> {debugInfo.authUser.email}</p>
                <p><strong>Email 已驗證:</strong> {debugInfo.authUser.email_confirmed_at ? '是' : '否'}</p>
              </div>
            </div>

            {/* 用戶資料 */}
            <div>
              <h3 className="font-semibold mb-2">用戶資料</h3>
              <div className="bg-gray-50 p-3 rounded text-sm">
                {debugInfo.profileData ? (
                  <>
                    <p><strong>角色:</strong> {debugInfo.profileData.role} ({ROLE_DISPLAY_NAMES[debugInfo.profileData.role as UserRole] || '未知'})</p>
                    <p><strong>狀態:</strong> {debugInfo.profileData.status}</p>
                    <p><strong>姓名:</strong> {debugInfo.profileData.full_name || '未設定'}</p>
                    <p><strong>建立時間:</strong> {new Date(debugInfo.profileData.created_at).toLocaleString('zh-TW')}</p>
                  </>
                ) : (
                  <p className="text-red-600">無用戶資料</p>
                )}
              </div>
            </div>

            {/* 權限檢查結果 */}
            <div>
              <h3 className="font-semibold mb-2">權限檢查結果</h3>
              <div className={`p-3 rounded text-sm ${debugInfo.hasAdminAccess ? 'bg-green-50 text-green-800' : 'bg-red-50 text-red-800'}`}>
                {debugInfo.hasAdminAccess ? '✅ 可以訪問管理面板' : '❌ 無法訪問管理面板'}
              </div>
            </div>

            {/* 錯誤信息 */}
            {debugInfo.errors.length > 0 && (
              <div>
                <h3 className="font-semibold mb-2 text-red-600">錯誤信息</h3>
                <div className="bg-red-50 p-3 rounded text-sm">
                  {debugInfo.errors.map((error, index) => (
                    <p key={index} className="text-red-800">• {error}</p>
                  ))}
                </div>
              </div>
            )}

            {/* 建議修復方案 */}
            {!debugInfo.hasAdminAccess && (
              <div>
                <h3 className="font-semibold mb-2 text-blue-600">建議修復方案</h3>
                <div className="bg-blue-50 p-3 rounded text-sm text-blue-800">
                  <p>1. 在 Supabase 控制台執行 SQL 腳本：<code>fix_admin_permission.sql</code></p>
                  <p>2. 確保用戶資料中的 role 欄位為 'admin'、'moderator' 或 'super_admin'</p>
                  <p>3. 確保用戶資料中的 status 欄位為 'active'</p>
                  <p>4. 重新登入以刷新權限</p>
                </div>
              </div>
            )}
          </div>
        ) : (
          <button 
            onClick={runDiagnostic}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            開始診斷
          </button>
        )}
      </CardContent>
    </Card>
  )
}

export default AdminDebugPanel