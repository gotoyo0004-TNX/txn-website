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

// 便捷的重試查詢函數
export const queryWithRetry = supabaseWithRetry.query.bind(supabaseWithRetry)