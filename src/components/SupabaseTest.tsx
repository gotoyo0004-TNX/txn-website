'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'

export default function SupabaseTest() {
  const [connectionStatus, setConnectionStatus] = useState<'testing' | 'connected' | 'failed'>('testing')
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function testConnection() {
      try {
        // 測試 Supabase 連接
        const { data, error } = await supabase.from('_test').select('*').limit(1)
        
        if (error) {
          // 如果是因為表格不存在的錯誤，表示連接正常
          if (error.message.includes('relation "_test" does not exist')) {
            setConnectionStatus('connected')
            setError(null)
          } else {
            setConnectionStatus('failed')
            setError(error.message)
          }
        } else {
          setConnectionStatus('connected')
          setError(null)
        }
      } catch (err) {
        setConnectionStatus('failed')
        setError(err instanceof Error ? err.message : '未知錯誤')
      }
    }

    testConnection()
  }, [])

  const getStatusColor = () => {
    switch (connectionStatus) {
      case 'testing':
        return 'text-yellow-600 bg-yellow-50'
      case 'connected':
        return 'text-green-600 bg-green-50'
      case 'failed':
        return 'text-red-600 bg-red-50'
    }
  }

  const getStatusIcon = () => {
    switch (connectionStatus) {
      case 'testing':
        return '🔄'
      case 'connected':
        return '✅'
      case 'failed':
        return '❌'
    }
  }

  const getStatusText = () => {
    switch (connectionStatus) {
      case 'testing':
        return '測試連接中...'
      case 'connected':
        return 'Supabase 連接成功！'
      case 'failed':
        return 'Supabase 連接失敗'
    }
  }

  return (
    <div className="max-w-md mx-auto mt-8 p-6 bg-white rounded-lg shadow-md border">
      <h3 className="text-lg font-semibold mb-4 text-gray-800">
        🔧 Supabase 連接測試
      </h3>
      
      <div className={`p-4 rounded-lg border ${getStatusColor()}`}>
        <div className="flex items-center gap-2 mb-2">
          <span className="text-xl">{getStatusIcon()}</span>
          <span className="font-medium">{getStatusText()}</span>
        </div>
        
        {error && (
          <div className="mt-2 text-sm">
            <strong>錯誤詳情：</strong>
            <p className="mt-1 bg-white p-2 rounded border text-gray-700">
              {error}
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

      {connectionStatus === 'failed' && (
        <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded">
          <h4 className="text-sm font-medium text-blue-800 mb-1">💡 設定提示：</h4>
          <p className="text-sm text-blue-700">
            請確認已在 .env.local 中設定正確的 Supabase 憑證，並重新啟動開發伺服器。
          </p>
        </div>
      )}
    </div>
  )
}