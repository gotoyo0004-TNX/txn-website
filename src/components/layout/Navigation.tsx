'use client'

import React, { useState } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { Button, Badge } from '@/components/ui'
import { UserIcon, ArrowRightOnRectangleIcon } from '@heroicons/react/24/outline'
import Link from 'next/link'

const Navigation: React.FC = () => {
  const { user, signOut, loading } = useAuth()
  const [loggingOut, setLoggingOut] = useState(false)

  const handleSignOut = async () => {
    setLoggingOut(true)
    try {
      await signOut()
    } catch (error) {
      console.error('登出錯誤:', error)
    } finally {
      setLoggingOut(false)
    }
  }

  if (loading) {
    return (
      <nav className="bg-white dark:bg-txn-primary-800 border-b border-txn-primary-200 dark:border-txn-primary-700">
        <div className="container mx-auto px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-txn-primary-200 dark:bg-txn-primary-600 rounded animate-pulse"></div>
              <div className="w-20 h-6 bg-txn-primary-200 dark:bg-txn-primary-600 rounded animate-pulse"></div>
            </div>
          </div>
        </div>
      </nav>
    )
  }

  return (
    <nav className="bg-white dark:bg-txn-primary-800 border-b border-txn-primary-200 dark:border-txn-primary-700 shadow-txn-sm">
      <div className="container mx-auto px-4 py-3">
        <div className="flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3 hover:opacity-80 transition-opacity">
            <div className="w-10 h-10 bg-gradient-accent rounded-xl flex items-center justify-center shadow-txn-md">
              <span className="text-txn-primary font-bold text-lg">T</span>
            </div>
            <div>
              <h1 className="text-xl font-bold text-txn-primary-800 dark:text-white">TXN</h1>
              <p className="text-xs text-txn-primary-600 dark:text-gray-400">交易日誌系統</p>
            </div>
          </Link>

          <div className="flex items-center gap-4">
            {user ? (
              <>
                <div className="flex items-center gap-3">
                  <div className="flex items-center gap-2">
                    <UserIcon className="h-5 w-5 text-txn-primary-600 dark:text-gray-400" />
                    <span className="text-sm text-txn-primary-800 dark:text-white">
                      {user.email}
                    </span>
                  </div>
                  <Badge variant="success" size="sm">
                    已登入
                  </Badge>
                </div>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={handleSignOut}
                  loading={loggingOut}
                  disabled={loggingOut}
                  icon={<ArrowRightOnRectangleIcon className="h-4 w-4" />}
                >
                  {loggingOut ? '登出中...' : '登出'}
                </Button>
              </>
            ) : (
              <div className="flex items-center gap-3">
                <Link href="/auth">
                  <Button variant="outline" size="sm">
                    登入
                  </Button>
                </Link>
                <Link href="/auth">
                  <Button variant="primary" size="sm">
                    註冊
                  </Button>
                </Link>
              </div>
            )}
          </div>
        </div>
      </div>
    </nav>
  )
}

export default Navigation