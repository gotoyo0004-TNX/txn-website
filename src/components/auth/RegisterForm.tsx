'use client'

import React, { useState } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { Button, Input, Card, CardHeader, CardTitle, CardContent, Badge } from '@/components/ui'
import { EyeIcon, EyeSlashIcon, EnvelopeIcon, LockClosedIcon, UserIcon } from '@heroicons/react/24/outline'

interface RegisterFormProps {
  onToggleMode: () => void
}

const RegisterForm: React.FC<RegisterFormProps> = ({ onToggleMode }) => {
  const { signUp } = useAuth()
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    fullName: '',
    tradingExperience: 'beginner' as 'beginner' | 'intermediate' | 'advanced' | 'professional',
    initialCapital: 10000
  })
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState(false)

  const tradingExperienceOptions = [
    { value: 'beginner', label: '新手', description: '剛開始接觸交易' },
    { value: 'intermediate', label: '中級', description: '有一些交易經驗' },
    { value: 'advanced', label: '進階', description: '經驗豐富的交易者' },
    { value: 'professional', label: '專業', description: '專業交易者' }
  ]

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const value = e.target.type === 'number' ? Number(e.target.value) : e.target.value
    setFormData(prev => ({
      ...prev,
      [e.target.name]: value
    }))
  }

  const validateForm = () => {
    if (formData.password !== formData.confirmPassword) {
      setError('密碼確認不符')
      return false
    }
    if (formData.password.length < 6) {
      setError('密碼長度至少需要 6 個字元')
      return false
    }
    if (formData.initialCapital <= 0) {
      setError('初始資金必須大於 0')
      return false
    }
    return true
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    if (!validateForm()) {
      setLoading(false)
      return
    }

    try {
      const { error } = await signUp(formData.email, formData.password, {
        full_name: formData.fullName,
        trading_experience: formData.tradingExperience,
        initial_capital: formData.initialCapital
      })
      
      if (error) {
        setError(getErrorMessage(error.message))
      } else {
        setSuccess(true)
      }
    } catch (err) {
      setError('註冊時發生錯誤，請稍後再試')
    } finally {
      setLoading(false)
    }
  }

  const getErrorMessage = (message: string) => {
    if (message.includes('User already registered')) {
      return '此電子郵件已被註冊'
    }
    if (message.includes('Password should be at least 6 characters')) {
      return '密碼長度至少需要 6 個字元'
    }
    if (message.includes('Unable to validate email address')) {
      return '電子郵件格式不正確'
    }
    return '註冊失敗，請檢查您的資料'
  }

  if (success) {
    return (
      <Card variant="elevated" className="w-full max-w-md mx-auto">
        <CardContent className="text-center py-8">
          <div className="text-6xl mb-4">🎉</div>
          <h3 className="text-xl font-semibold text-txn-primary-800 dark:text-white mb-2">
            註冊成功！
          </h3>
          <p className="text-txn-primary-600 dark:text-gray-400 mb-6">
            我們已發送確認郵件到您的信箱，請點擊郵件中的連結來啟用您的帳戶。
          </p>
          <Button
            variant="primary"
            onClick={onToggleMode}
          >
            返回登入
          </Button>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card variant="elevated" className="w-full max-w-lg mx-auto">
      <CardHeader className="text-center">
        <div className="w-16 h-16 bg-gradient-accent rounded-xl flex items-center justify-center mx-auto mb-4 shadow-txn-lg">
          <span className="text-txn-primary font-bold text-2xl">T</span>
        </div>
        <CardTitle className="text-2xl">加入 TXN</CardTitle>
        <p className="text-txn-primary-600 dark:text-gray-400">開始您的交易日誌之旅</p>
      </CardHeader>
      
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            type="text"
            name="fullName"
            label="姓名"
            placeholder="請輸入您的姓名"
            value={formData.fullName}
            onChange={handleChange}
            leftIcon={<UserIcon className="h-5 w-5" />}
            required
          />

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
            placeholder="請輸入密碼（至少 6 個字元）"
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

          <Input
            type={showConfirmPassword ? 'text' : 'password'}
            name="confirmPassword"
            label="確認密碼"
            placeholder="請再次輸入密碼"
            value={formData.confirmPassword}
            onChange={handleChange}
            leftIcon={<LockClosedIcon className="h-5 w-5" />}
            rightIcon={
              <button
                type="button"
                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                className="focus:outline-none"
              >
                {showConfirmPassword ? (
                  <EyeSlashIcon className="h-5 w-5" />
                ) : (
                  <EyeIcon className="h-5 w-5" />
                )}
              </button>
            }
            required
          />

          <div className="space-y-2">
            <label className="text-sm font-medium text-txn-primary-700 dark:text-gray-300">
              交易經驗
            </label>
            <div className="grid grid-cols-2 gap-2">
              {tradingExperienceOptions.map((option) => (
                <label
                  key={option.value}
                  className={`relative flex flex-col p-3 border rounded-lg cursor-pointer transition-all ${
                    formData.tradingExperience === option.value
                      ? 'border-txn-accent bg-txn-accent-50'
                      : 'border-txn-primary-300 hover:border-txn-accent-300'
                  }`}
                >
                  <input
                    type="radio"
                    name="tradingExperience"
                    value={option.value}
                    checked={formData.tradingExperience === option.value}
                    onChange={handleChange}
                    className="sr-only"
                  />
                  <span className="font-medium text-sm">{option.label}</span>
                  <span className="text-xs text-txn-primary-500">{option.description}</span>
                </label>
              ))}
            </div>
          </div>

          <Input
            type="number"
            name="initialCapital"
            label="初始資金 (USD)"
            placeholder="10000"
            value={formData.initialCapital}
            onChange={handleChange}
            min="1"
            step="100"
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
            註冊帳戶
          </Button>

          <div className="text-center">
            <div className="text-sm text-txn-primary-600 dark:text-gray-400">
              已經有帳戶？{' '}
              <button
                type="button"
                onClick={onToggleMode}
                className="text-txn-accent hover:text-txn-accent-600 font-medium transition-colors"
              >
                立即登入
              </button>
            </div>
          </div>
        </form>
      </CardContent>
    </Card>
  )
}

export default RegisterForm