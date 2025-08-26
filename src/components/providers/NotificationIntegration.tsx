'use client'

import React from 'react'
import { NotificationProvider } from '@/contexts/NotificationContext'
import { ToastContainer } from '@/components/ui/ToastContainer'
import { NOTIFICATION_CONFIG } from '@/lib/constants'

interface NotificationIntegrationProps {
  children: React.ReactNode
  position?: 'top-right' | 'top-left' | 'bottom-right' | 'bottom-left' | 'top-center' | 'bottom-center'
  maxToasts?: number
  className?: string
}

/**
 * 通知系統整合組件
 * 
 * 這個組件提供了完整的通知系統整合，包括：
 * - NotificationProvider 上下文提供者
 * - ToastContainer 顯示容器
 * - 統一的配置管理
 * 
 * 使用方式：
 * ```tsx
 * <NotificationIntegration position="top-right">
 *   <YourApp />
 * </NotificationIntegration>
 * ```
 */
const NotificationIntegration: React.FC<NotificationIntegrationProps> = ({
  children,
  position = 'top-right',
  maxToasts = NOTIFICATION_CONFIG.MAX_TOAST_COUNT,
  className
}) => {
  return (
    <NotificationProvider maxToasts={maxToasts}>
      {children}
      <ToastContainer 
        position={position} 
        className={className}
      />
    </NotificationProvider>
  )
}

export { NotificationIntegration }
export type { NotificationIntegrationProps }