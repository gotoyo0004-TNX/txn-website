import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

// 優化的 Supabase 客戶端配置，解決連接不穩定問題
export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true
  },
  db: {
    schema: 'public'
  },
  global: {
    headers: {
      'x-client-info': 'txn-website'
    }
  },
  realtime: {
    params: {
      eventsPerSecond: 10
    }
  }
})

// 添加連接重試機制
export const supabaseWithRetry = {
  async query<T>(fn: () => Promise<T>, maxRetries = 3): Promise<T> {
    let lastError: any
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        const result = await fn()
        return result
      } catch (error: any) {
        lastError = error
        
        // 特殊處理：如果是路由相關錯誤，不進行重試
        if (this.isRouteError(error)) {
          console.warn('路由錯誤，跳過重試:', error.message)
          throw error
        }
        
        // 如果是網路錯誤或連接錯誤，進行重試
        if (attempt < maxRetries && this.shouldRetry(error)) {
          console.warn(`Supabase 查詢重試 ${attempt}/${maxRetries}:`, error.message)
          await this.delay(Math.pow(2, attempt - 1) * 1000) // 指數退避
          continue
        }
        
        break
      }
    }
    
    throw lastError
  },
  
  isRouteError(error: any): boolean {
    // 檢查是否為路由相關錯誤
    const routeErrors = [
      '404',
      'not found',
      'route not found',
      'page not found'
    ]
    
    return routeErrors.some(errorType => 
      error.message?.toLowerCase().includes(errorType.toLowerCase())
    )
  },
  
  shouldRetry(error: any): boolean {
    // 判斷是否應該重試的錯誤
    const retryableErrors = [
      'Failed to fetch',
      'Network request failed',
      'timeout',
      'ECONNRESET',
      'ENOTFOUND',
      'ECONNREFUSED'
    ]
    
    return retryableErrors.some(errorType => 
      error.message?.toLowerCase().includes(errorType.toLowerCase())
    )
  },
  
  delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }
}

// 添加連接池清理函數
export const cleanupSupabaseConnections = () => {
  // 清理可能被污染的連接
  if (typeof window !== 'undefined') {
    console.log('清理 Supabase 連接池...')
    // 強制清理本地存儲中的過期會話
    const keys = Object.keys(localStorage)
    keys.forEach(key => {
      if (key.startsWith('sb-') && key.includes('auth-token')) {
        try {
          const token = JSON.parse(localStorage.getItem(key) || '{}')
          if (token.expires_at && new Date(token.expires_at * 1000) < new Date()) {
            localStorage.removeItem(key)
          }
        } catch (e) {
          // 忽略解析錯誤
        }
      }
    })
  }
}

// 便捷的重試查詢函數
export const queryWithRetry = supabaseWithRetry.query.bind(supabaseWithRetry)