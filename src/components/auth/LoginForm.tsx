'use client'

import React, { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/contexts/AuthContext'
import { Button, Input, Card, CardHeader, CardTitle, CardContent } from '@/components/ui'
import { EyeIcon, EyeSlashIcon, EnvelopeIcon, LockClosedIcon } from '@heroicons/react/24/outline'

interface LoginFormProps {
  onToggleMode: () => void
  onForgotPassword: () => void
}

const LoginForm: React.FC<LoginFormProps> = ({ onToggleMode, onForgotPassword }) => {
  const { signIn } = useAuth()
  const router = useRouter()
  const [formData, setFormData] = useState({
    email: '',
    password: ''
  })
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData(prev => ({
      ...prev,
      [e.target.name]: e.target.value
    }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')
    setSuccess('')

    try {
      const { error } = await signIn(formData.email, formData.password)
      
      if (error) {
        setError(getErrorMessage(error.message))
      } else {
        // 登入成功
        setSuccess('登入成功！正在重定向...')
        
        // 短暫延遲後重定向到主頁
        setTimeout(() => {
          router.push('/')
        }, 1000)
      }
    } catch (error) {
      console.error('登入錯誤:', error)
      setError('登入時發生錯誤，請稍後再試')
    } finally {
      setLoading(false)
    }
  }

  const getErrorMessage = (message: string) => {
    if (message.includes('Invalid login credentials')) {
      return '帳號或密碼錯誤'
    }
    if (message.includes('Email not confirmed')) {
      return '請先確認您的電子郵件'
    }
    if (message.includes('Too many requests')) {
      return '嘗試次數過多，請稍後再試'
    }
    return '登入失敗，請檢查您的帳號密碼'
  }

  return (
    <Card variant="elevated" className="w-full max-w-md mx-auto">
      <CardHeader className="text-center">
        <div className="w-16 h-16 bg-gradient-accent rounded-xl flex items-center justify-center mx-auto mb-4 shadow-txn-lg">
          <span className="text-txn-primary font-bold text-2xl">T</span>
        </div>
        <CardTitle className="text-2xl">歡迎回到 TXN</CardTitle>
        <p className="text-txn-primary-600 dark:text-gray-400">登入您的交易日誌帳戶</p>
      </CardHeader>
      
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            type="email"
            name="email"
            label="電子郵件"
            placeholder="請輸入您的電子郵件"
            value={formData.email}
            onChange={handleChange}
            leftIcon={<EnvelopeIcon className="h-5 w-5" />}
            required
          />
          
          <Input
            type={showPassword ? 'text' : 'password'}
            name="password"
            label="密碼"
            placeholder="請輸入您的密碼"
            value={formData.password}
            onChange={handleChange}
            leftIcon={<LockClosedIcon className="h-5 w-5" />}
            rightIcon={
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="focus:outline-none"
              >
                {showPassword ? (
                  <EyeSlashIcon className="h-5 w-5" />
                ) : (
                  <EyeIcon className="h-5 w-5" />
                )}
              </button>
            }
            required
          />

          {error && (
            <div className="bg-txn-loss-50 border border-txn-loss-200 text-txn-loss-800 px-4 py-3 rounded-lg text-sm">
              {error}
            </div>
          )}

          {success && (
            <div className="bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-lg text-sm">
              {success}
            </div>
          )}

          <Button
            type="submit"
            variant="primary"
            size="lg"
            loading={loading}
            className="w-full"
          >
            登入
          </Button>

          <div className="text-center space-y-2">
            <button
              type="button"
              onClick={onForgotPassword}
              className="text-txn-accent hover:text-txn-accent-600 text-sm transition-colors"
            >
              忘記密碼？
            </button>
            
            <div className="text-sm text-txn-primary-600 dark:text-gray-400">
              還沒有帳戶？{' '}
              <button
                type="button"
                onClick={onToggleMode}
                className="text-txn-accent hover:text-txn-accent-600 font-medium transition-colors"
              >
                立即註冊
              </button>
            </div>
          </div>
        </form>
      </CardContent>
    </Card>
  )
}

export default LoginForm