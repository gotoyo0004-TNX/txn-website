'use client'

import React from 'react'
import { ToastNotification } from './ToastNotification'
import { useNotification } from '@/contexts/NotificationContext'
import { cn } from '@/lib/utils'

// =============================================
// 類型定義
// =============================================

export type ToastPosition = 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left' | 'top-center' | 'bottom-center'

interface ToastContainerProps {
  position?: ToastPosition
  className?: string
}

// =============================================
// Toast 容器組件
// =============================================

const ToastContainer: React.FC<ToastContainerProps> = ({ 
  position = 'top-right',
  className 
}) => {
  const { toasts, removeToast } = useNotification()

  // 位置樣式映射
  const positionClasses: Record<ToastPosition, string> = {
    'top-right': 'top-4 right-4',
    'top-left': 'top-4 left-4',
    'bottom-right': 'bottom-4 right-4',
    'bottom-left': 'bottom-4 left-4',
    'top-center': 'top-4 left-1/2 transform -translate-x-1/2',
    'bottom-center': 'bottom-4 left-1/2 transform -translate-x-1/2',
  }

  if (toasts.length === 0) {
    return null
  }

  return (
    <div
      className={cn(
        "fixed z-50 pointer-events-none",
        "w-full max-w-sm", // 響應式寬度
        "sm:w-96", // 桌面寬度
        positionClasses[position],
        className
      )}
      aria-live="polite"
      aria-label="通知區域"
    >
      <div className="space-y-3">
        {toasts.map((toast, index) => (
          <div
            key={toast.id}
            className="pointer-events-auto"
            style={{
              zIndex: toasts.length - index, // 確保新的通知在上層
            }}
          >
            <ToastNotification
              toast={toast}
              onDismiss={removeToast}
              className={cn(
                "transition-all duration-300 ease-in-out",
                // 根據位置調整動畫方向
                position.includes('right') && "animate-slide-in-right",
                // 左側進入動畫
                position.includes('left') && "animate-slide-in-left"
              )}
            />
          </div>
        ))}
      </div>
    </div>
  )
}

export { ToastContainer }
export type { ToastContainerProps }