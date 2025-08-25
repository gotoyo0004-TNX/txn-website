import React from 'react'
import { cn } from '@/lib/utils'

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  error?: string
  label?: string
  helperText?: string
  leftIcon?: React.ReactNode
  rightIcon?: React.ReactNode
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, error, label, helperText, leftIcon, rightIcon, ...props }, ref) => {
    return (
      <div className="space-y-2">
        {label && (
          <label className="text-sm font-medium text-txn-primary-700 dark:text-gray-300">
            {label}
          </label>
        )}
        <div className="relative">
          {leftIcon && (
            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-txn-primary-400">
              {leftIcon}
            </div>
          )}
          <input
            type={type}
            className={cn(
              "flex h-12 w-full rounded-lg border bg-white px-3 py-2 text-sm transition-colors",
              "placeholder:text-txn-primary-400 focus:outline-none focus:ring-2 focus:ring-offset-2",
              "disabled:cursor-not-allowed disabled:opacity-50",
              error 
                ? "border-txn-loss focus:border-txn-loss focus:ring-txn-loss" 
                : "border-txn-primary-300 focus:border-txn-accent focus:ring-txn-accent",
              leftIcon && "pl-10",
              rightIcon && "pr-10",
              "dark:bg-txn-primary-800 dark:border-txn-primary-600 dark:text-gray-100",
              className
            )}
            ref={ref}
            {...props}
          />
          {rightIcon && (
            <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-txn-primary-400">
              {rightIcon}
            </div>
          )}
        </div>
        {error && (
          <p className="text-sm text-txn-loss">{error}</p>
        )}
        {helperText && !error && (
          <p className="text-sm text-txn-primary-500 dark:text-gray-400">{helperText}</p>
        )}
      </div>
    )
  }
)
Input.displayName = "Input"

export { Input }