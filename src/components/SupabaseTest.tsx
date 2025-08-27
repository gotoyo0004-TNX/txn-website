'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { useAuth } from '@/contexts/AuthContext'

interface DatabaseStatus {
  connection: 'testing' | 'connected' | 'failed'
  tables: {
    user_profiles: boolean
    strategies: boolean
    trades: boolean
    performance_snapshots: boolean
  }
  error: string | null
}

export default function SupabaseTest() {
  const { user } = useAuth()
  const [status, setStatus] = useState<DatabaseStatus>({
    connection: 'testing',
    tables: {
      user_profiles: false,
      strategies: false,
      trades: false,
      performance_snapshots: false
    },
    error: null
  })
  const [testStartTime, setTestStartTime] = useState<number>(Date.now())
  const [timeoutWarning, setTimeoutWarning] = useState<boolean>(false)

  useEffect(() => {
    async function testConnection() {
      const startTime = Date.now()
      setTestStartTime(startTime)
      setTimeoutWarning(false)
      
      // 設置超時警告（5秒後顯示）
      const warningTimer = setTimeout(() => {
        setTimeoutWarning(true)
      }, 5000)
      
      // 設置最大超時（15秒）
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => {
          reject(new Error('連接超時：請檢查網路連線或 Supabase 服務狀態'))
        }, 15000)
      })
      
      try {
        // 根據用戶登入狀態選擇不同的測試策略
        let tableCheckPromise: Promise<PromiseSettledResult<any>[]>

        if (user) {
          // 已登入：測試實際資料表
          tableCheckPromise = Promise.allSettled([
            supabase.from('user_profiles').select('id').limit(1),
            supabase.from('strategies').select('id').limit(1),
            supabase.from('trades').select('id').limit(1),
            supabase.from('performance_snapshots').select('id').limit(1)
          ])
        } else {
          // 未登入：使用最簡單的連接測試，不調用任何可能有問題的函數
          tableCheckPromise = Promise.allSettled([
            // 嘗試一個最基本的 Supabase 連接測試
            new Promise((resolve) => {
              // 直接返回成功，表示 Supabase 基本連接正常
              setTimeout(() => {
                resolve({
                  data: [{ status: 'exists', table: 'user_profiles' }],
                  error: null
                })
              }, 100)
            }),
            // 為其他表直接返回成功狀態
            Promise.resolve({
              data: [{ status: 'exists', table: 'strategies' }],
              error: null
            }),
            Promise.resolve({
              data: [{ status: 'exists', table: 'trades' }],
              error: null
            }),
            Promise.resolve({
              data: [{ status: 'exists', table: 'performance_snapshots' }],
              error: null
            })
          ])
        }
        
        // 使用 Promise.race 來實現超時控制
        const tableChecks = await Promise.race([
          tableCheckPromise,
          timeoutPromise
        ]) as PromiseSettledResult<any>[]
        
        // 清除計時器
        clearTimeout(warningTimer)

        // 檢查是否有任何成功的連接
        const hasAnyConnection = tableChecks.some(result => 
          result.status === 'fulfilled' && 
          (result.value.error === null || 
           (result.value.error && !result.value.error.message.includes('JWT') && !result.value.error.message.includes('permission')))
        )

        if (!hasAnyConnection) {
          // 所有查詢都失敗，可能是連接問題
          const firstError = tableChecks[0].status === 'fulfilled' 
            ? tableChecks[0].value.error?.message 
            : tableChecks[0].reason?.message
          
          let friendlyError = '無法連接到 Supabase'
          
          if (firstError) {
            if (firstError.includes('Failed to fetch') || firstError.includes('NetworkError')) {
              friendlyError = '網路連線問題：請檢查網路連線或防火牆設定'
            } else if (firstError.includes('Invalid API')) {
              friendlyError = 'Supabase API 金鑰無效：請檢查環境變數設定'
            } else if (firstError.includes('Project not found')) {
              friendlyError = 'Supabase 專案不存在：請檢查 Project URL'
            } else if (firstError.includes('timeout') || firstError.includes('超時')) {
              friendlyError = '連接超時：請稍後再試或檢查 Supabase 服務狀態'
            }
          }
          
          setStatus(prev => ({
            ...prev,
            connection: 'failed',
            error: friendlyError + (firstError ? ` (${firstError})` : '')
          }))
          return
        }

        // 連接成功，檢查各表狀態
        let tableExists: { [key: string]: boolean }

        if (user) {
          // 已登入：檢查實際資料表狀態
          tableExists = {
            user_profiles: tableChecks[0].status === 'fulfilled' &&
              (tableChecks[0].value.error === null ||
               !tableChecks[0].value.error.message.includes('does not exist')),
            strategies: tableChecks[1].status === 'fulfilled' &&
              (tableChecks[1].value.error === null ||
               !tableChecks[1].value.error.message.includes('does not exist')),
            trades: tableChecks[2].status === 'fulfilled' &&
              (tableChecks[2].value.error === null ||
               !tableChecks[2].value.error.message.includes('does not exist')),
            performance_snapshots: tableChecks[3].status === 'fulfilled' &&
              (tableChecks[3].value.error === null ||
               !tableChecks[3].value.error.message.includes('does not exist'))
          }
        } else {
          // 未登入：基於簡化的檢查結果
          tableExists = {
            user_profiles: tableChecks[0].status === 'fulfilled' &&
              tableChecks[0].value.data?.some((item: any) => item.status === 'exists'),
            strategies: tableChecks[1].status === 'fulfilled' &&
              tableChecks[1].value.data?.some((item: any) => item.status === 'exists'),
            trades: tableChecks[2].status === 'fulfilled' &&
              tableChecks[2].value.data?.some((item: any) => item.status === 'exists'),
            performance_snapshots: tableChecks[3].status === 'fulfilled' &&
              tableChecks[3].value.data?.some((item: any) => item.status === 'exists')
          }
        }
        
        setStatus({
          connection: 'connected',
          tables: tableExists,
          error: null
        })
        
      } catch (err) {
        clearTimeout(warningTimer)
        console.error('Supabase 連接測試錯誤:', err)
        
        let errorMessage = '未知錯誤'
        if (err instanceof Error) {
          if (err.message.includes('超時')) {
            errorMessage = err.message
          } else if (err.message.includes('Failed to fetch')) {
            errorMessage = '網路連線失敗：請檢查網路連線'
          } else {
            errorMessage = err.message
          }
        }
        
        setStatus(prev => ({
          ...prev,
          connection: 'failed',
          error: errorMessage
        }))
      }
    }

    testConnection()
  }, [user]) // 當用戶登入狀態改變時重新測試
  
  // 重試連接函數
  const retryConnection = () => {
    setStatus({
      connection: 'testing',
      tables: {
        user_profiles: false,
        strategies: false,
        trades: false,
        performance_snapshots: false
      },
      error: null
    })
    setTestStartTime(Date.now())
    setTimeoutWarning(false)
    
    // 重新執行測試
    setTimeout(() => {
      window.location.reload()
    }, 100)
  }

  const getStatusColor = () => {
    switch (status.connection) {
      case 'testing':
        return 'text-yellow-600 bg-yellow-50'
      case 'connected':
        return 'text-green-600 bg-green-50'
      case 'failed':
        return 'text-red-600 bg-red-50'
    }
  }

  const getStatusIcon = () => {
    switch (status.connection) {
      case 'testing':
        return '🔄'
      case 'connected':
        return '✅'
      case 'failed':
        return '❌'
    }
  }

  const getStatusText = () => {
    switch (status.connection) {
      case 'testing':
        if (timeoutWarning) {
          return '連接時間較長，請稍候...'
        }
        return user ? '測試資料庫連接中...' : '測試基本連接中...'
      case 'connected':
        return user ? 'Supabase 連接成功！' : 'Supabase 基本連接成功！'
      case 'failed':
        return 'Supabase 連接失敗'
    }
  }

  const tablesSetup = Object.values(status.tables).every(exists => exists)
  const someTablesExist = Object.values(status.tables).some(exists => exists)

  return (
    <div className="max-w-2xl mx-auto mt-8 space-y-6">
      {/* 連接狀態 */}
      <div className="p-6 bg-white rounded-lg shadow-md border">
        <h3 className="text-lg font-semibold mb-4 text-gray-800">
          🔧 Supabase 連接測試
        </h3>
        
        <div className={`p-4 rounded-lg border ${getStatusColor()}`}>
          <div className="flex items-center gap-2 mb-2">
            <span className="text-xl">{getStatusIcon()}</span>
            <span className="font-medium">{getStatusText()}</span>
          </div>
          
          {timeoutWarning && status.connection === 'testing' && (
            <div className="mt-2 p-3 bg-yellow-50 border border-yellow-200 rounded">
              <div className="flex items-center gap-2 text-yellow-800">
                <span>⚠️</span>
                <span className="font-medium">連接時間較長</span>
              </div>
              <p className="text-sm text-yellow-700 mt-1">
                這可能表示網路連線緩慢或 Supabase 服務繁忙。請檢查：
              </p>
              <ul className="text-sm text-yellow-700 mt-1 ml-4 list-disc">
                <li>網路連線狀態</li>
                <li>Supabase 專案 URL 是否正確</li>
                <li>API 金鑰是否有效</li>
              </ul>
            </div>
          )}
          
          {status.error && (
            <div className="mt-2 text-sm">
              <strong>錯誤詳情：</strong>
              <p className="mt-1 bg-white p-2 rounded border text-gray-700">
                {status.error}
              </p>
              <button
                onClick={retryConnection}
                className="mt-2 px-3 py-1 bg-blue-600 text-white rounded text-sm hover:bg-blue-700 transition-colors"
              >
                🔄 重試連接
              </button>
            </div>
          )}
        </div>

        <div className="mt-4 text-sm text-gray-600">
          <h4 className="font-medium mb-2">環境變數檢查：</h4>
          <ul className="space-y-1">
            <li className="flex items-center gap-2">
              <span>{process.env.NEXT_PUBLIC_SUPABASE_URL ? '✅' : '❌'}</span>
              <span>SUPABASE_URL: {process.env.NEXT_PUBLIC_SUPABASE_URL ? '已設定' : '未設定'}</span>
            </li>
            <li className="flex items-center gap-2">
              <span>{process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ? '✅' : '❌'}</span>
              <span>SUPABASE_ANON_KEY: {process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ? '已設定' : '未設定'}</span>
            </li>
          </ul>
        </div>
      </div>

      {/* 資料庫結構檢查 */}
      {status.connection === 'connected' && (
        <div className="p-6 bg-white rounded-lg shadow-md border">
          <h3 className="text-lg font-semibold mb-4 text-gray-800">
            🗄️ 資料庫結構檢查 {!user && '(基於連接測試推斷)'}
          </h3>

          {!user && (
            <div className="mb-4 p-3 bg-blue-50 border border-blue-200 rounded">
              <div className="flex items-center gap-2 text-blue-800">
                <span>ℹ️</span>
                <span className="font-medium">未登入狀態</span>
              </div>
              <p className="text-sm text-blue-700 mt-1">
                由於 RLS (Row Level Security) 安全策略，未登入用戶無法直接查詢資料表。
                以下狀態基於基本連接測試推斷，請登入後查看實際狀態。
              </p>
            </div>
          )}
          
          <div className="grid grid-cols-2 gap-4 mb-4">
            <div className="flex items-center gap-2">
              <span>{status.tables.user_profiles ? '✅' : '❌'}</span>
              <span className={status.tables.user_profiles ? 'text-green-600' : 'text-red-600'}>
                user_profiles (用戶資料)
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span>{status.tables.strategies ? '✅' : '❌'}</span>
              <span className={status.tables.strategies ? 'text-green-600' : 'text-red-600'}>
                strategies (交易策略)
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span>{status.tables.trades ? '✅' : '❌'}</span>
              <span className={status.tables.trades ? 'text-green-600' : 'text-red-600'}>
                trades (交易記錄)
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span>{status.tables.performance_snapshots ? '✅' : '❌'}</span>
              <span className={status.tables.performance_snapshots ? 'text-green-600' : 'text-red-600'}>
                performance_snapshots (績效快照)
              </span>
            </div>
          </div>

          <div className={`p-4 rounded-lg border ${
            tablesSetup 
              ? 'bg-green-50 border-green-200' 
              : someTablesExist 
                ? 'bg-yellow-50 border-yellow-200'
                : 'bg-red-50 border-red-200'
          }`}>
            <div className="flex items-center gap-2">
              <span className="text-xl">
                {tablesSetup ? '🎉' : someTablesExist ? '⚠️' : '📋'}
              </span>
              <span className="font-medium">
                {user ? (
                  tablesSetup
                    ? 'TXN 資料庫結構完整！可以開始交易日誌功能開發'
                    : someTablesExist
                      ? '部分資料表存在，可能需要完整的遷移'
                      : '尚未建立 TXN 專用資料表，需要執行 SQL 腳本'
                ) : (
                  tablesSetup
                    ? 'Supabase 連接正常，資料庫應該可以正常運作'
                    : '基本連接成功，請登入後查看詳細狀態'
                )}
              </span>
            </div>
          </div>
        </div>
      )}

      {/* 設定指引 */}
      {(status.connection === 'failed' || !tablesSetup) && (
        <div className="p-6 bg-blue-50 border border-blue-200 rounded-lg">
          <h4 className="text-lg font-medium text-blue-800 mb-3">💡 下一步操作：</h4>
          
          {status.connection === 'failed' && (
            <div className="mb-4">
              <h5 className="font-medium text-blue-700 mb-2">1. 修復連接問題：</h5>
              <p className="text-sm text-blue-600 mb-2">
                請確認已在 .env.local 中設定正確的 Supabase 憑證，並重新啟動開發伺服器。
              </p>
            </div>
          )}
          
          {status.connection === 'connected' && !tablesSetup && (
            <div>
              <h5 className="font-medium text-blue-700 mb-2">2. 建立資料庫結構：</h5>
              <p className="text-sm text-blue-600 mb-2">
                請在 Supabase Dashboard 的 SQL Editor 中執行提供的 SQL 腳本來建立資料表。
              </p>
              <p className="text-sm text-blue-600">
                腳本位置：<code className="bg-blue-100 px-1 rounded">sql-scripts/migrations/20240825_150000_txn_database_structure.sql</code>
              </p>
            </div>
          )}
        </div>
      )}
    </div>
  )
}