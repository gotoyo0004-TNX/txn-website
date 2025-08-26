'use client'

import React, { useState, useEffect, useCallback } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'
import { Card, CardHeader, CardTitle, CardContent, Button } from '@/components/ui'

interface TestResult {
  test: string
  status: 'pass' | 'fail' | 'pending'
  message: string
  details?: Record<string, unknown>
}

export default function AdminTestPage() {
  const { user } = useAuth()
  const [testResults, setTestResults] = useState<TestResult[]>([])
  const [isRunning, setIsRunning] = useState(false)

  const addResult = (test: string, status: 'pass' | 'fail' | 'pending', message: string, details?: Record<string, unknown>) => {
    setTestResults(prev => {
      const existing = prev.find(r => r.test === test)
      const newResult = { test, status, message, details }
      
      if (existing) {
        return prev.map(r => r.test === test ? newResult : r)
      } else {
        return [...prev, newResult]
      }
    })
  }

  const runTests = useCallback(async () => {
    setIsRunning(true)
    setTestResults([])

    try {
      // 測試 1: 用戶認證
      addResult('AUTH', 'pending', '檢查用戶認證...')
      
      if (!user) {
        addResult('AUTH', 'fail', '用戶未登入')
        return
      }

      addResult('AUTH', 'pass', `認證成功: ${user.email}`, { userId: user.id })

      // 測試 2: 資料庫連接
      addResult('DATABASE', 'pending', '測試資料庫連接...')
      
      const { data: dbTest, error: dbError } = await supabase
        .from('user_profiles')
        .select('count')
        .limit(1)

      // 檢查是否有錯誤，不需要使用 dbTest 變數

      if (dbError) {
        addResult('DATABASE', 'fail', `資料庫連接失敗: ${dbError.message}`, dbError)
        return
      }

      addResult('DATABASE', 'pass', '資料庫連接正常')

      // 測試 3: 用戶資料查詢
      addResult('USER_PROFILE', 'pending', '查詢用戶資料...')
      
      const { data: profile, error: profileError } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', user.id)
        .single()

      if (profileError) {
        addResult('USER_PROFILE', 'fail', `用戶資料查詢失敗: ${profileError.message}`, {
          error: profileError,
          suggestion: '請執行 fix_admin_permission.sql 修復腳本'
        })
        return
      }

      addResult('USER_PROFILE', 'pass', '用戶資料查詢成功', profile)

      // 測試 4: 管理員權限檢查
      addResult('ADMIN_PERMISSION', 'pending', '檢查管理員權限...')
      
      const isAdmin = ['admin', 'super_admin', 'moderator'].includes(profile.role)
      const isActive = profile.status === 'active'

      if (!isAdmin) {
        addResult('ADMIN_PERMISSION', 'fail', `權限不足: ${profile.role}`, {
          currentRole: profile.role,
          allowedRoles: ['admin', 'super_admin', 'moderator']
        })
        return
      }

      if (!isActive) {
        addResult('ADMIN_PERMISSION', 'fail', `帳號狀態異常: ${profile.status}`, {
          currentStatus: profile.status,
          requiredStatus: 'active'
        })
        return
      }

      addResult('ADMIN_PERMISSION', 'pass', `管理員權限驗證成功: ${profile.role}`)

      // 測試 5: 用戶列表查詢（管理員功能測試）
      addResult('ADMIN_QUERY', 'pending', '測試管理員查詢功能...')
      
      const { data: users, error: usersError } = await supabase
        .from('user_profiles')
        .select('email, role, status, created_at')
        .order('created_at', { ascending: false })
        .limit(10)

      if (usersError) {
        addResult('ADMIN_QUERY', 'fail', `管理員查詢失敗: ${usersError.message}`, usersError)
        return
      }

      addResult('ADMIN_QUERY', 'pass', `成功查詢到 ${users.length} 位用戶`, {
        userCount: users.length,
        sampleUsers: users.slice(0, 3).map(u => ({ email: u.email, role: u.role }))
      })

      // 測試 6: 完整性檢查
      addResult('COMPLETE', 'pass', '🎉 所有測試通過！管理員權限正常', {
        summary: {
          userEmail: user.email,
          role: profile.role,
          status: profile.status,
          totalTests: 6,
          passedTests: 6
        }
      })

    } catch (error) {
      addResult('ERROR', 'fail', `測試過程發生錯誤: ${error}`, error as any)
    } finally {
      setIsRunning(false)
    }
  }, [user]);

  useEffect(() => {
    if (user) {
      runTests()
    }
  }, [user, runTests])

  const getStatusColor = (status: TestResult['status']) => {
    switch (status) {
      case 'pass': return 'text-green-600'
      case 'fail': return 'text-red-600'
      case 'pending': return 'text-blue-600'
      default: return 'text-gray-600'
    }
  }

  const getStatusIcon = (status: TestResult['status']) => {
    switch (status) {
      case 'pass': return '✅'
      case 'fail': return '❌'
      case 'pending': return '🔄'
      default: return '❓'
    }
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-txn-primary-800 dark:text-white">
          管理員權限測試
        </h1>
        <p className="text-txn-primary-600 dark:text-gray-400 mt-1">
          檢查 admin@txn.test 管理員權限是否正常
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>測試結果</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex gap-2">
            <Button 
              onClick={runTests}
              disabled={isRunning}
              variant="primary"
            >
              {isRunning ? '測試中...' : '重新測試'}
            </Button>
          </div>

          <div className="space-y-3">
            {testResults.map((result, index) => (
              <div key={index} className="border rounded p-4">
                <div className="flex items-center gap-2 mb-2">
                  <span className="text-lg">{getStatusIcon(result.status)}</span>
                  <span className="font-medium">{result.test}</span>
                </div>
                <p className={`text-sm ${getStatusColor(result.status)}`}>
                  {result.message}
                </p>
                {result.details && (
                  <details className="mt-2">
                    <summary className="text-xs text-gray-600 cursor-pointer">詳細資料</summary>
                    <pre className="text-xs bg-gray-100 p-2 rounded mt-1 overflow-auto">
                      {JSON.stringify(result.details, null, 2)}
                    </pre>
                  </details>
                )}
              </div>
            ))}
          </div>

          {testResults.length === 0 && !isRunning && (
            <p className="text-center text-gray-500 py-8">
              點擊「重新測試」開始檢查
            </p>
          )}
        </CardContent>
      </Card>

      {/* 修復指南 */}
      <Card>
        <CardHeader>
          <CardTitle>修復指南</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="bg-blue-50 p-4 rounded">
            <h3 className="font-semibold text-blue-800 mb-2">如果測試失敗，請按照以下步驟修復：</h3>
            <ol className="list-decimal list-inside space-y-2 text-blue-700">
              <li>在 Supabase 控制台的 SQL 編輯器中執行 <code>fix_admin_permission.sql</code></li>
              <li>確認腳本執行成功，查看所有 ✅ 成功標記</li>
              <li>清除瀏覽器快取和 localStorage</li>
              <li>重新登入 admin@txn.test</li>
              <li>回到此頁面重新測試</li>
            </ol>
          </div>

          <div className="bg-yellow-50 p-4 rounded">
            <h3 className="font-semibold text-yellow-800 mb-2">常見問題：</h3>
            <ul className="list-disc list-inside space-y-1 text-yellow-700">
              <li><strong>用戶資料不存在：</strong> 需要先在前端註冊 admin@txn.test，然後執行修復腳本</li>
              <li><strong>權限不足：</strong> 確認 role 欄位為 &apos;admin&apos;、&apos;super_admin&apos; 或 &apos;moderator&apos;</li>
              <li><strong>帳號狀態異常：</strong> 確認 status 欄位為 &apos;active&apos;</li>
              <li><strong>RLS 策略問題：</strong> 檢查 Supabase 專案的 Row Level Security 設置</li>
            </ul>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}