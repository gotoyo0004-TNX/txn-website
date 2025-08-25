'use client'

import React, { useState } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { Button, Input, Card, CardHeader, CardTitle, CardContent } from '@/components/ui'
import { EnvelopeIcon, ArrowLeftIcon } from '@heroicons/react/24/outline'

interface ForgotPasswordFormProps {
  onBackToLogin: () => void
}

const ForgotPasswordForm: React.FC<ForgotPasswordFormProps> = ({ onBackToLogin }) => {
  const { resetPassword } = useAuth()
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    try {
      const { error } = await resetPassword(email)
      
      if (error) {
        setError(getErrorMessage(error.message))
      } else {
        setSuccess(true)
      }
    } catch (err) {
      setError('發送重設郵件時發生錯誤，請稍後再試')
    } finally {
      setLoading(false)
    }
  }

  const getErrorMessage = (message: string) => {
    if (message.includes('User not found')) {
      return '找不到此電子郵件帳戶'
    }
    if (message.includes('Invalid email')) {
      return '電子郵件格式不正確'
    }
    return '發送重設郵件失敗，請稍後再試'
  }

  if (success) {
    return (
      <Card variant="elevated" className="w-full max-w-md mx-auto">
        <CardContent className="text-center py-8">
          <div className="text-6xl mb-4">📧</div>
          <h3 className="text-xl font-semibold text-txn-primary-800 dark:text-white mb-2">
            重設郵件已發送
          </h3>
          <p className="text-txn-primary-600 dark:text-gray-400 mb-6">
            我們已發送密碼重設連結到您的信箱：<br />
            <span className="font-medium">{email}</span>
          </p>
          <p className="text-sm text-txn-primary-500 dark:text-gray-500 mb-6">
            請檢查您的信箱（包含垃圾郵件資料夾），並點擊郵件中的連結來重設您的密碼。
          </p>
          <Button
            variant="primary"
            onClick={onBackToLogin}
          >
            返回登入
          </Button>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card variant="elevated" className="w-full max-w-md mx-auto">
      <CardHeader className="text-center">
        <div className="w-16 h-16 bg-gradient-accent rounded-xl flex items-center justify-center mx-auto mb-4 shadow-txn-lg">
          <span className="text-txn-primary font-bold text-2xl">T</span>
        </div>
        <CardTitle className="text-2xl">重設密碼</CardTitle>
        <p className="text-txn-primary-600 dark:text-gray-400">
          輸入您的電子郵件，我們將發送重設連結給您
        </p>
      </CardHeader>
      
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            type="email"
            name="email"
            label="電子郵件"
            placeholder="請輸入您的電子郵件"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            leftIcon={<EnvelopeIcon className="h-5 w-5" />}
            required
          />

          {error && (
            <div className="bg-txn-loss-50 border border-txn-loss-200 text-txn-loss-800 px-4 py-3 rounded-lg text-sm">
              {error}
            </div>
          )}

          <Button
            type="submit"
            variant="primary"
            size="lg"
            loading={loading}
            className="w-full"
          >
            發送重設郵件
          </Button>

          <div className="text-center">
            <button
              type="button"
              onClick={onBackToLogin}
              className="inline-flex items-center gap-2 text-txn-accent hover:text-txn-accent-600 text-sm transition-colors"
            >
              <ArrowLeftIcon className="h-4 w-4" />
              返回登入
            </button>
          </div>
        </form>
      </CardContent>
    </Card>
  )
}

export default ForgotPasswordForm