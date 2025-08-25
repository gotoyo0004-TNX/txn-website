'use client'

import React, { createContext, useContext, useState, useCallback } from 'react'
import { Button } from '@/components/ui'
import { ExclamationTriangleIcon, XMarkIcon } from '@heroicons/react/24/outline'

interface ConfirmationOptions {
  title: string
  message: string
  confirmText?: string
  cancelText?: string
  type?: 'warning' | 'danger' | 'info'
  onConfirm: () => void | Promise<void>
  onCancel?: () => void
}

interface ConfirmationContextType {
  confirm: (options: ConfirmationOptions) => void
}

const ConfirmationContext = createContext<ConfirmationContextType | undefined>(undefined)

export const useConfirmation = () => {
  const context = useContext(ConfirmationContext)
  if (context === undefined) {
    throw new Error('useConfirmation must be used within a ConfirmationProvider')
  }
  return context
}

interface ConfirmationProviderProps {
  children: React.ReactNode
}

export const ConfirmationProvider: React.FC<ConfirmationProviderProps> = ({ children }) => {
  const [confirmationState, setConfirmationState] = useState<ConfirmationOptions | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  const confirm = useCallback((options: ConfirmationOptions) => {
    setConfirmationState(options)
  }, [])

  const handleConfirm = async () => {
    if (!confirmationState) return
    
    setIsLoading(true)
    try {
      await confirmationState.onConfirm()
    } catch (error) {
      console.error('確認操作錯誤:', error)
    } finally {
      setIsLoading(false)
      setConfirmationState(null)
    }
  }

  const handleCancel = () => {
    if (confirmationState?.onCancel) {
      confirmationState.onCancel()
    }
    setConfirmationState(null)
  }

  const value: ConfirmationContextType = {
    confirm
  }

  return (
    <ConfirmationContext.Provider value={value}>
      {children}
      {confirmationState && (
        <ConfirmationDialog
          options={confirmationState}
          isLoading={isLoading}
          onConfirm={handleConfirm}
          onCancel={handleCancel}
        />
      )}
    </ConfirmationContext.Provider>
  )
}

interface ConfirmationDialogProps {
  options: ConfirmationOptions
  isLoading: boolean
  onConfirm: () => void
  onCancel: () => void
}

const ConfirmationDialog: React.FC<ConfirmationDialogProps> = ({
  options,
  isLoading,
  onConfirm,
  onCancel
}) => {
  const getIconAndColor = () => {
    switch (options.type) {
      case 'danger':
        return {
          icon: <ExclamationTriangleIcon className="h-6 w-6 text-red-600" />,
          iconBg: 'bg-red-100',
          confirmButton: 'danger'
        }
      case 'warning':
        return {
          icon: <ExclamationTriangleIcon className="h-6 w-6 text-yellow-600" />,
          iconBg: 'bg-yellow-100',
          confirmButton: 'primary'
        }
      default:
        return {
          icon: <ExclamationTriangleIcon className="h-6 w-6 text-blue-600" />,
          iconBg: 'bg-blue-100',
          confirmButton: 'primary'
        }
    }
  }

  const { icon, iconBg, confirmButton } = getIconAndColor()

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      {/* 背景遮罩 */}
      <div className="flex min-h-full items-center justify-center p-4">
        <div 
          className="fixed inset-0 bg-black bg-opacity-25 transition-opacity"
          onClick={onCancel}
        />
        
        {/* 對話框 */}
        <div className="relative transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6">
          <div className="absolute right-0 top-0 pr-4 pt-4">
            <button
              type="button"
              className="rounded-md bg-white text-gray-400 hover:text-gray-500"
              onClick={onCancel}
              disabled={isLoading}
            >
              <XMarkIcon className="h-6 w-6" />
            </button>
          </div>
          
          <div className="sm:flex sm:items-start">
            <div className={`mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full ${iconBg} sm:mx-0 sm:h-10 sm:w-10`}>
              {icon}
            </div>
            
            <div className="mt-3 text-center sm:ml-4 sm:mt-0 sm:text-left">
              <h3 className="text-lg font-semibold leading-6 text-gray-900">
                {options.title}
              </h3>
              <div className="mt-2">
                <p className="text-sm text-gray-500">
                  {options.message}
                </p>
              </div>
            </div>
          </div>
          
          <div className="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse gap-3">
            <Button
              variant={confirmButton as 'primary' | 'danger'}
              onClick={onConfirm}
              loading={isLoading}
              disabled={isLoading}
            >
              {options.confirmText || '確認'}
            </Button>
            
            <Button
              variant="outline"
              onClick={onCancel}
              disabled={isLoading}
            >
              {options.cancelText || '取消'}
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default ConfirmationProvider