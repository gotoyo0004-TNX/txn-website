'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

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

  useEffect(() => {
    async function testConnection() {
      try {
        // 直接檢查資料表存在性 - 這樣也能測試連接
        const tableChecks = await Promise.allSettled([
          supabase.from('user_profiles').select('id').limit(1),
          supabase.from('strategies').select('id').limit(1),
          supabase.from('trades').select('id').limit(1),
          supabase.from('performance_snapshots').select('id').limit(1)
        ])

        // 檢查是否有任何成功的連接
        const hasAnyConnection = tableChecks.some(result => 
          result.status === 'fulfilled' && 
          (result.value.error === null || 
           (result.value.error && !result.value.error.message.includes('JWT')))
        )

        if (!hasAnyConnection) {
          // 所有查詢都失敗，可能是連接問題
          const firstError = tableChecks[0].status === 'fulfilled' 
            ? tableChecks[0].value.error?.message 
            : tableChecks[0].reason?.message
          
          setStatus(prev => ({
            ...prev,
            connection: 'failed',
            error: firstError || '無法連接到 Supabase'
          }))
          return
        }

        // 連接成功，檢查各表狀態
        const tableExists = {
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
        
        setStatus({
          connection: 'connected',
          tables: tableExists,
          error: null
        })
        
      } catch (err) {
        console.error('Supabase 連接測試錯誤:', err)
        setStatus(prev => ({
          ...prev,
          connection: 'failed',
          error: err instanceof Error ? err.message : '未知錯誤'
        }))
      }
    }

    testConnection()
  }, [])

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
        return '測試連接中...'
      case 'connected':
        return 'Supabase 連接成功！'
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
          
          {status.error && (
            <div className="mt-2 text-sm">
              <strong>錯誤詳情：</strong>
              <p className="mt-1 bg-white p-2 rounded border text-gray-700">
                {status.error}
              </p>
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
            🗄️ 資料庫結構檢查
          </h3>
          
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
                {tablesSetup 
                  ? 'TXN 資料庫結構完整！可以開始交易日誌功能開發' 
                  : someTablesExist 
                    ? '部分資料表存在，可能需要完整的遷移'
                    : '尚未建立 TXN 專用資料表，需要執行 SQL 腳本'}
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