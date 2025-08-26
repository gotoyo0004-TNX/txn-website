'use client'

import React, { useEffect, useState, useCallback } from 'react'
import { 
  CheckCircleIcon, 
  XCircleIcon, 
  ExclamationTriangleIcon,
  InformationCircleIcon,
  XMarkIcon
} from '@heroicons/react/24/outline'
import { ToastNotification as ToastNotificationType, NotificationType } from '@/lib/constants'
import { Button } from './Button'
import { cn } from '@/lib/utils'

// =============================================
// 類型定義
// =============================================

interface ToastNotificationProps {
  toast: ToastNotificationType
  onDismiss: (id: string) => void
  className?: string
}

// =============================================
// Toast 通知組件
// =============================================

const ToastNotification: React.FC<ToastNotificationProps> = ({ 
  toast, 
  onDismiss, 
  className 
}) => {
  const [isVisible, setIsVisible] = useState(false)
  const [isLeaving, setIsLeaving] = useState(false)

  // 處理關閉動畫
  const handleDismiss = useCallback(() => {
    setIsLeaving(true)
    setTimeout(() => {
      onDismiss(toast.id)
    }, 150) // 動畫時間
  }, [onDismiss, toast.id])

  // 處理動作按鈕點擊
  const handleAction = useCallback((actionFn: () => void) => {
    try {
      actionFn()
    } catch (error) {
      console.error('Toast action error:', error)
    }
  }, [])

  // 進入動畫
  useEffect(() => {
    const timer = setTimeout(() => setIsVisible(true), 10)
    return () => clearTimeout(timer)
  }, [])

  // 自動關閉
  useEffect(() => {
    if (toast.duration && toast.duration > 0) {
      const timer = setTimeout(handleDismiss, toast.duration)
      return () => clearTimeout(timer)
    }
  }, [toast.duration, handleDismiss])

  // 圖標組件
  const getIconComponent = (type: NotificationType) => {
    const iconClass = "h-5 w-5 flex-shrink-0"
    
    switch (type) {
      case 'success':
        return <CheckCircleIcon className={cn(iconClass, "text-green-500")} />
      case 'error':
        return <XCircleIcon className={cn(iconClass, "text-red-500")} />
      case 'warning':
        return <ExclamationTriangleIcon className={cn(iconClass, "text-yellow-500")} />
      case 'info':
        return <InformationCircleIcon className={cn(iconClass, "text-blue-500")} />
      default:
        return <InformationCircleIcon className={cn(iconClass, "text-gray-500")} />
    }
  }

  // 通知樣式
  const getNotificationStyles = (type: NotificationType) => {
    switch (type) {
      case 'success':
        return "bg-green-50 border-green-200 border-l-green-500"
      case 'error':
        return "bg-red-50 border-red-200 border-l-red-500"
      case 'warning':
        return "bg-yellow-50 border-yellow-200 border-l-yellow-500"
      case 'info':
        return "bg-blue-50 border-blue-200 border-l-blue-500"
      default:
        return "bg-gray-50 border-gray-200 border-l-gray-500"
    }
  }

  return (
    <div
      className={cn(
        "relative overflow-hidden transition-all duration-300 ease-in-out",
        "transform-gpu", // 硬件加速
        isVisible && !isLeaving 
          ? "translate-x-0 opacity-100 scale-100" 
          : "translate-x-full opacity-0 scale-95",
        className
      )}
      role="alert"
      aria-live="polite"
    >
      <div
        className={cn(
          "flex items-start gap-3 p-4 rounded-lg border shadow-lg",
          "bg-white dark:bg-gray-800",
          "border-l-4", // 左側色條
          getNotificationStyles(toast.type)
        )}
      >
        {/* 圖標 */}
        <div className="flex-shrink-0 mt-0.5">
          {getIconComponent(toast.type)}
        </div>

        {/* 內容區域 */}
        <div className="flex-1 min-w-0">
          {/* 標題 */}
          <h4 className="text-sm font-semibold mb-1 text-gray-900 dark:text-gray-100">
            {toast.title}
          </h4>

          {/* 訊息 */}
          {toast.message && (
            <p className="text-sm text-gray-600 dark:text-gray-300 mb-2 leading-relaxed">
              {toast.message}
            </p>
          )}

          {/* 動作按鈕 */}
          {toast.actions && toast.actions.length > 0 && (
            <div className="flex gap-2 mt-3">
              {toast.actions.map((action) => (
                <Button
                  key={action.id}
                  variant={action.style === 'primary' ? 'primary' : 'outline'}
                  size="sm"
                  onClick={() => handleAction(action.action)}
                  className="text-xs px-3 py-1"
                >
                  {action.label}
                </Button>
              ))}
            </div>
          )}
        </div>

        {/* 關閉按鈕 */}
        {toast.dismissible && (
          <button
            type="button"
            onClick={handleDismiss}
            className={cn(
              "flex-shrink-0 p-1 rounded-md transition-colors",
              "hover:bg-gray-100 dark:hover:bg-gray-700",
              "focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-txn-accent"
            )}
            aria-label="關閉通知"
          >
            <XMarkIcon className="h-4 w-4 text-gray-400 hover:text-gray-600" />
          </button>
        )}
      </div>

      {/* 進度條 (如果有持續時間) */}
      {toast.duration && toast.duration > 0 && (
        <ProgressBar 
          duration={toast.duration} 
          color={getProgressBarColor(toast.type)}
          onComplete={handleDismiss}
        />
      )}
    </div>
  )
}

// =============================================
// 進度條組件
// =============================================

interface ProgressBarProps {
  duration: number
  color: string
  onComplete: () => void
}

const ProgressBar: React.FC<ProgressBarProps> = ({ duration, color, onComplete }) => {
  const [progress, setProgress] = useState(100)

  useEffect(() => {
    const interval = setInterval(() => {
      setProgress((prev) => {
        const newProgress = prev - (100 / (duration / 75)) // 75ms 間隔
        if (newProgress <= 0) {
          clearInterval(interval)
          onComplete()
          return 0
        }
        return newProgress
      })
    }, 75)

    return () => clearInterval(interval)
  }, [duration, onComplete])

  return (
    <div className="absolute bottom-0 left-0 right-0 h-1 bg-gray-200 dark:bg-gray-700">
      <div 
        className={cn("h-full transition-all duration-75 ease-linear", color)}
        style={{ width: `${progress}%` }}
      />
    </div>
  )
}

// 進度條顏色
const getProgressBarColor = (type: NotificationType): string => {
  switch (type) {
    case 'success':
      return 'bg-green-500'
    case 'error':
      return 'bg-red-500'
    case 'warning':
      return 'bg-yellow-500'
    case 'info':
      return 'bg-blue-500'
    default:
      return 'bg-gray-500'
  }
}

export { ToastNotification }
export type { ToastNotificationProps }