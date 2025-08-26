'use client'

import React, { useState, useEffect, useCallback } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui'

interface LoadingDebugInfo {
  step: string
  status: 'loading' | 'success' | 'error'
  message: string
  data?: Record<string, unknown>
  timestamp: string
}

export const LoadingDebugger: React.FC = () => {
  const { user, loading: authLoading } = useAuth()
  const [debugLogs, setDebugLogs] = useState<LoadingDebugInfo[]>([])
  const [isDebugging, setIsDebugging] = useState(false)

  const addLog = (step: string, status: 'loading' | 'success' | 'error', message: string, data?: Record<string, unknown>) => {
    const log: LoadingDebugInfo = {
      step,
      status,
      message,
      data,
      timestamp: new Date().toLocaleTimeString()
    }
    setDebugLogs(prev => [...prev, log])
  }

  const runFullDiagnostic = useCallback(async () => {
    setIsDebugging(true)
    setDebugLogs([])

    try {
      // 步驟 1: 檢查認證狀態
      addLog('AUTH_CHECK', 'loading', '檢查用戶認證狀態...')
      await new Promise(resolve => setTimeout(resolve, 500)) // 模擬延遲
      
      if (authLoading) {
        addLog('AUTH_CHECK', 'loading', '認證仍在載入中...')
        return
      }

      if (!user) {
        addLog('AUTH_CHECK', 'error', '用戶未登入')
        return
      }

      addLog('AUTH_CHECK', 'success', `用戶已登入: ${user.email}`, { 
        email: user.email, 
        id: user.id,
        emailConfirmed: user.email_confirmed_at ? true : false
      })

      // 步驟 2: 檢查 Supabase 連接
      addLog('SUPABASE_CONNECTION', 'loading', '檢查 Supabase 連接...')
      
      try {
        const { data: connectionTest, error: connError } = await supabase
          .from('user_profiles')
          .select('count')
          .limit(1)
        
        // 不需要使用 connectionTest 變數，只檢查是否有錯誤

        if (connError) {
          console.error('Supabase 連接錯誤:', connError)
          addLog('SUPABASE_CONNECTION', 'error', `Supabase 連接失敗: ${connError.message}`, {
            error: {
              code: connError.code,
              message: connError.message,
              details: connError.details,
              hint: connError.hint
            }
          })
          return
        }

        addLog('SUPABASE_CONNECTION', 'success', 'Supabase 連接正常')
      } catch (error) {
        addLog('SUPABASE_CONNECTION', 'error', `Supabase 連接異常: ${error}`, {
          error: {
            message: error instanceof Error ? error.message : String(error),
            type: typeof error
          }
        })
        return
      }

      // 步驟 3: 檢查用戶資料
      addLog('USER_PROFILE', 'loading', '查詢用戶資料...')
      
      try {
        const { data: profileData, error: profileError } = await supabase
          .from('user_profiles')
          .select('*')
          .eq('id', user.id)
          .single()

        if (profileError) {
          console.error('用戶資料查詢錯誤:', profileError)
          addLog('USER_PROFILE', 'error', `用戶資料查詢失敗: ${profileError.message}`, {
            error: {
              code: profileError.code,
              message: profileError.message,
              details: profileError.details,
              hint: profileError.hint
            }
          })
          
          // 如果是因為資料不存在，提供解決方案
          if (profileError.code === 'PGRST116') {
            addLog('USER_PROFILE', 'error', '用戶資料不存在！需要執行修復腳本', {
              solution: '請在 Supabase SQL 編輯器中執行 fix_admin_permission.sql'
            })
          }
          return
        }

        addLog('USER_PROFILE', 'success', '用戶資料查詢成功', profileData && typeof profileData === 'object' ? profileData : { data: 'Profile data received' })

        // 步驟 4: 檢查權限
        addLog('PERMISSION_CHECK', 'loading', '檢查管理員權限...')
        
        const role = profileData?.role
        const status = profileData?.status

        if (!role) {
          addLog('PERMISSION_CHECK', 'error', '用戶角色未設定')
          return
        }

        if (status !== 'active') {
          addLog('PERMISSION_CHECK', 'error', `帳號狀態異常: ${status}`, { 
            currentStatus: status, 
            requiredStatus: 'active' 
          })
          return
        }

        if (!['admin', 'super_admin', 'moderator'].includes(role)) {
          addLog('PERMISSION_CHECK', 'error', `權限不足: ${role}`, { 
            currentRole: role, 
            allowedRoles: ['admin', 'super_admin', 'moderator'] 
          })
          return
        }

        addLog('PERMISSION_CHECK', 'success', `管理員權限驗證成功: ${role}`, {
          role,
          status,
          hasAdminAccess: true
        })

        // 步驟 5: 檢查 RLS 策略
        addLog('RLS_CHECK', 'loading', '檢查 RLS 策略...')
        
        try {
          // 嘗試執行一個需要權限的查詢
          const { data: testQuery, error: rlsError } = await supabase
            .from('user_profiles')
            .select('email, role, status')
            .limit(5)

          if (rlsError) {
            console.error('RLS 查詢錯誤:', rlsError)
            addLog('RLS_CHECK', 'error', `RLS 策略阻止查詢: ${rlsError.message}`, {
              error: {
                code: rlsError.code,
                message: rlsError.message,
                details: rlsError.details,
                hint: rlsError.hint
              }
            })
            return
          }

          addLog('RLS_CHECK', 'success', 'RLS 策略檢查通過', { 
            queryResult: testQuery?.length,
            note: '能夠正常查詢用戶資料'
          })

        } catch (error) {
          addLog('RLS_CHECK', 'error', `RLS 檢查異常: ${error}`, {
            error: {
              message: error instanceof Error ? error.message : String(error),
              type: typeof error
            }
          })
          return
        }

        // 步驟 6: 最終診斷
        addLog('FINAL_DIAGNOSIS', 'success', '✅ 所有檢查都通過！載入問題可能是暫時性的', {
          recommendation: '請嘗試清除瀏覽器快取並重新登入'
        })

      } catch (error) {
        addLog('USER_PROFILE', 'error', `用戶資料查詢異常: ${error}`, {
          error: {
            message: error instanceof Error ? error.message : String(error),
            type: typeof error
          }
        })
      }

    } catch (error) {
      console.error('診斷過程發生錯誤:', error)
      addLog('GENERAL_ERROR', 'error', `診斷過程發生錯誤: ${error}`, {
        error: {
          message: error instanceof Error ? error.message : String(error),
          type: typeof error
        }
      })
    } finally {
      setIsDebugging(false)
    }
  }, [authLoading, user]);

  useEffect(() => {
    // 自動開始診斷
    if (user && !isDebugging && debugLogs.length === 0) {
      runFullDiagnostic()
    }
  }, [user, isDebugging, debugLogs.length, runFullDiagnostic])

  const getStatusIcon = (status: LoadingDebugInfo['status']) => {
    switch (status) {
      case 'loading': return '🔄'
      case 'success': return '✅'
      case 'error': return '❌'
      default: return '❓'
    }
  }

  const getStatusColor = (status: LoadingDebugInfo['status']) => {
    switch (status) {
      case 'loading': return 'text-blue-600'
      case 'success': return 'text-green-600'
      case 'error': return 'text-red-600'
      default: return 'text-gray-600'
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>🐛 載入問題診斷工具</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex gap-2">
          <button 
            onClick={runFullDiagnostic}
            disabled={isDebugging}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
          >
            {isDebugging ? '診斷中...' : '重新診斷'}
          </button>
          
          <button 
            onClick={() => setDebugLogs([])}
            className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
          >
            清除日誌
          </button>
        </div>

        <div className="space-y-2 max-h-96 overflow-y-auto">
          {debugLogs.map((log, index) => (
            <div key={index} className="border rounded p-3 bg-gray-50">
              <div className="flex items-center gap-2 mb-1">
                <span className="text-lg">{getStatusIcon(log.status)}</span>
                <span className="font-medium">{log.step}</span>
                <span className="text-xs text-gray-500">{log.timestamp}</span>
              </div>
              <p className={`text-sm ${getStatusColor(log.status)}`}>
                {log.message}
              </p>
              {log.data && (
                <details className="mt-2">
                  <summary className="text-xs text-gray-600 cursor-pointer">詳細資料</summary>
                  <pre className="text-xs bg-gray-100 p-2 rounded mt-1 overflow-auto">
                    {JSON.stringify(log.data, null, 2)}
                  </pre>
                </details>
              )}
            </div>
          ))}
        </div>

        {debugLogs.length === 0 && !isDebugging && (
          <p className="text-center text-gray-500 py-8">
            點擊「重新診斷」開始檢查載入問題
          </p>
        )}
      </CardContent>
    </Card>
  )
}

export default LoadingDebugger