'use client'

import React, { createContext, useContext, useReducer, useEffect, useCallback } from 'react'
import { 
  ToastNotification, 
  generateNotificationId,
  NOTIFICATION_CONFIG,
  sortNotificationsByPriority
} from '@/lib/constants'

// =============================================
// 通知狀態類型定義
// =============================================

interface NotificationState {
  toasts: ToastNotification[]
  isVisible: boolean
  maxToasts: number
}

type NotificationAction = 
  | { type: 'ADD_TOAST'; payload: Omit<ToastNotification, 'id' | 'createdAt'> }
  | { type: 'REMOVE_TOAST'; payload: { id: string } }
  | { type: 'CLEAR_ALL_TOASTS' }
  | { type: 'SET_VISIBILITY'; payload: { visible: boolean } }
  | { type: 'UPDATE_TOAST'; payload: { id: string; updates: Partial<ToastNotification> } }

// =============================================
// 通知上下文類型
// =============================================

interface NotificationContextType {
  // 狀態
  toasts: ToastNotification[]
  isVisible: boolean
  
  // 動作
  addToast: (notification: Omit<ToastNotification, 'id' | 'createdAt'>) => string
  removeToast: (id: string) => void
  clearAllToasts: () => void
  setVisibility: (visible: boolean) => void
  
  // 快捷方法
  showSuccess: (title: string, message?: string, options?: Partial<ToastNotification>) => string
  showError: (title: string, message?: string, options?: Partial<ToastNotification>) => string
  showWarning: (title: string, message?: string, options?: Partial<ToastNotification>) => string
  showInfo: (title: string, message?: string, options?: Partial<ToastNotification>) => string
}

// =============================================
// 狀態管理
// =============================================

const initialState: NotificationState = {
  toasts: [],
  isVisible: true,
  maxToasts: NOTIFICATION_CONFIG.MAX_TOAST_COUNT,
}

function notificationReducer(state: NotificationState, action: NotificationAction): NotificationState {
  switch (action.type) {
    case 'ADD_TOAST': {
      const newToast: ToastNotification = {
        ...action.payload,
        id: generateNotificationId(),
        createdAt: new Date(),
      }
      
      let updatedToasts = [...state.toasts, newToast]
      
      // 按優先級排序
      updatedToasts = sortNotificationsByPriority(updatedToasts) as ToastNotification[]
      
      // 限制最大數量
      if (updatedToasts.length > state.maxToasts) {
        updatedToasts = updatedToasts.slice(0, state.maxToasts)
      }
      
      return {
        ...state,
        toasts: updatedToasts,
      }
    }
    
    case 'REMOVE_TOAST':
      return {
        ...state,
        toasts: state.toasts.filter(toast => toast.id !== action.payload.id),
      }
    
    case 'CLEAR_ALL_TOASTS':
      return {
        ...state,
        toasts: [],
      }
    
    case 'SET_VISIBILITY':
      return {
        ...state,
        isVisible: action.payload.visible,
      }
    
    case 'UPDATE_TOAST':
      return {
        ...state,
        toasts: state.toasts.map(toast => 
          toast.id === action.payload.id 
            ? { ...toast, ...action.payload.updates }
            : toast
        ),
      }
    
    default:
      return state
  }
}

// =============================================
// Context 創建
// =============================================

const NotificationContext = createContext<NotificationContextType | undefined>(undefined)

export const useNotification = () => {
  const context = useContext(NotificationContext)
  if (context === undefined) {
    throw new Error('useNotification must be used within a NotificationProvider')
  }
  return context
}

// =============================================
// Provider 組件
// =============================================

interface NotificationProviderProps {
  children: React.ReactNode
  maxToasts?: number
}

export const NotificationProvider: React.FC<NotificationProviderProps> = ({ 
  children, 
  maxToasts = NOTIFICATION_CONFIG.MAX_TOAST_COUNT 
}) => {
  const [state, dispatch] = useReducer(notificationReducer, {
    ...initialState,
    maxToasts,
  })

  // =============================================
  // 基本動作
  // =============================================

  const addToast = useCallback((notification: Omit<ToastNotification, 'id' | 'createdAt'>): string => {
    const id = generateNotificationId()
    dispatch({ 
      type: 'ADD_TOAST', 
      payload: {
        ...notification,
        duration: notification.duration ?? NOTIFICATION_CONFIG.TOAST_DURATION[notification.type],
        dismissible: notification.dismissible ?? true,
      }
    })
    return id
  }, [])

  const removeToast = useCallback((id: string) => {
    dispatch({ type: 'REMOVE_TOAST', payload: { id } })
  }, [])

  const clearAllToasts = useCallback(() => {
    dispatch({ type: 'CLEAR_ALL_TOASTS' })
  }, [])

  const setVisibility = useCallback((visible: boolean) => {
    dispatch({ type: 'SET_VISIBILITY', payload: { visible } })
  }, [])

  // =============================================
  // 快捷方法
  // =============================================

  const showSuccess = useCallback((
    title: string, 
    message?: string, 
    options?: Partial<ToastNotification>
  ): string => {
    return addToast({
      type: 'success',
      title,
      message,
      priority: 'normal',
      ...options,
    })
  }, [addToast])

  const showError = useCallback((
    title: string, 
    message?: string, 
    options?: Partial<ToastNotification>
  ): string => {
    return addToast({
      type: 'error',
      title,
      message,
      priority: 'high',
      ...options,
    })
  }, [addToast])

  const showWarning = useCallback((
    title: string, 
    message?: string, 
    options?: Partial<ToastNotification>
  ): string => {
    return addToast({
      type: 'warning',
      title,
      message,
      priority: 'normal',
      ...options,
    })
  }, [addToast])

  const showInfo = useCallback((
    title: string, 
    message?: string, 
    options?: Partial<ToastNotification>
  ): string => {
    return addToast({
      type: 'info',
      title,
      message,
      priority: 'low',
      ...options,
    })
  }, [addToast])

  // =============================================
  // 自動移除 Toast
  // =============================================

  useEffect(() => {
    const timers: Record<string, NodeJS.Timeout> = {}

    state.toasts.forEach(toast => {
      if (toast.duration && toast.duration > 0 && !timers[toast.id]) {
        timers[toast.id] = setTimeout(() => {
          removeToast(toast.id)
          delete timers[toast.id]
        }, toast.duration)
      }
    })

    // 清理定時器
    return () => {
      Object.values(timers).forEach(timer => {
        clearTimeout(timer)
      })
    }
  }, [state.toasts, removeToast])

  // =============================================
  // Context Value
  // =============================================

  const contextValue: NotificationContextType = {
    // 狀態
    toasts: state.toasts,
    isVisible: state.isVisible,
    
    // 動作
    addToast,
    removeToast,
    clearAllToasts,
    setVisibility,
    
    // 快捷方法
    showSuccess,
    showError,
    showWarning,
    showInfo,
  }

  return (
    <NotificationContext.Provider value={contextValue}>
      {children}
    </NotificationContext.Provider>
  )
}

export default NotificationProvider