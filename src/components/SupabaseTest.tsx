'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

interface DatabaseStatus {
  connection: 'testing' | 'connected' | 'failed'
  tables: {
    users: boolean
    projects: boolean
    tasks: boolean
    activity_logs: boolean
  }
  error: string | null
}

export default function SupabaseTest() {
  const [status, setStatus] = useState<DatabaseStatus>({
    connection: 'testing',
    tables: {
      users: false,
      projects: false,
      tasks: false,
      activity_logs: false
    },
    error: null
  })

  useEffect(() => {
    async function testConnection() {
      try {
        // 測試基本連接
        const { data: connectionTest, error: connectionError } = await supabase
          .from('information_schema.tables')
          .select('table_name')
          .eq('table_schema', 'public')
          .limit(1)
        
        if (connectionError) {
          setStatus(prev => ({
            ...prev,
            connection: 'failed',
            error: connectionError.message
          }))
          return
        }

        // 檢查資料表是否存在
        const { data: tableList, error: tableError } = await supabase
          .from('information_schema.tables')
          .select('table_name')
          .eq('table_schema', 'public')
          .in('table_name', ['users', 'projects', 'tasks', 'activity_logs'])
        
        if (tableError) {
          setStatus(prev => ({
            ...prev,
            connection: 'connected',
            error: `資料表檢查失敗: ${tableError.message}`
          }))
          return
        }

        const existingTables = tableList?.map(t => t.table_name) || []
        
        setStatus({
          connection: 'connected',
          tables: {
            users: existingTables.includes('users'),
            projects: existingTables.includes('projects'),
            tasks: existingTables.includes('tasks'),
            activity_logs: existingTables.includes('activity_logs')
          },
          error: null
        })
        
      } catch (err) {
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
              <span>{status.tables.users ? '✅' : '❌'}</span>
              <span className={status.tables.users ? 'text-green-600' : 'text-red-600'}>
                users (用戶)
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span>{status.tables.projects ? '✅' : '❌'}</span>
              <span className={status.tables.projects ? 'text-green-600' : 'text-red-600'}>
                projects (專案)
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span>{status.tables.tasks ? '✅' : '❌'}</span>
              <span className={status.tables.tasks ? 'text-green-600' : 'text-red-600'}>
                tasks (任務)
              </span>
            </div>
            <div className="flex items-center gap-2">
              <span>{status.tables.activity_logs ? '✅' : '❌'}</span>
              <span className={status.tables.activity_logs ? 'text-green-600' : 'text-red-600'}>
                activity_logs (日誌)
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
                  ? '資料庫結構完整！可以開始開發功能' 
                  : someTablesExist 
                    ? '部分資料表存在，可能需要完整的遷移'
                    : '尚未建立資料表，需要執行 SQL 腳本'}
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
                腳本位置：<code className="bg-blue-100 px-1 rounded">sql-scripts/migrations/20240825_143000_initial_database_setup.sql</code>
              </p>
            </div>
          )}
        </div>
      )}
    </div>
  )
}