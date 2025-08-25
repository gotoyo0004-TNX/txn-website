import React from 'react'
import { cn } from '@/lib/utils'

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'success' | 'danger' | 'ghost' | 'outline'
  size?: 'sm' | 'md' | 'lg' | 'xl'
  loading?: boolean
  icon?: React.ReactNode
  children: React.ReactNode
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ 
    className, 
    variant = 'primary', 
    size = 'md', 
    loading = false,
    icon,
    disabled,
    children, 
    ...props 
  }, ref) => {
    const baseStyles = "inline-flex items-center justify-center font-medium transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
    
    const variants = {
      primary: "bg-txn-accent text-txn-primary-800 hover:bg-txn-accent-500 focus:ring-txn-accent shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 active:translate-y-0",
      secondary: "bg-txn-primary text-white hover:bg-txn-primary-700 focus:ring-txn-primary-500 border border-txn-primary-600",
      success: "bg-txn-profit text-white hover:bg-txn-profit-700 focus:ring-txn-profit shadow-md hover:shadow-lg",
      danger: "bg-txn-loss text-white hover:bg-txn-loss-700 focus:ring-txn-loss shadow-md hover:shadow-lg",
      ghost: "text-txn-primary-700 hover:bg-txn-primary-50 focus:ring-txn-primary-500",
      outline: "border border-txn-primary-300 text-txn-primary-700 hover:bg-txn-primary-50 focus:ring-txn-primary-500"
    }
    
    const sizes = {
      sm: "px-3 py-1.5 text-xs rounded-md gap-1.5",
      md: "px-4 py-2 text-sm rounded-lg gap-2",
      lg: "px-6 py-3 text-base rounded-lg gap-2.5",
      xl: "px-8 py-4 text-lg rounded-xl gap-3"
    }

    return (
      <button
        className={cn(
          baseStyles,
          variants[variant],
          sizes[size],
          loading && "cursor-wait",
          className
        )}
        disabled={disabled || loading}
        ref={ref}
        {...props}
      >
        {loading ? (
          <>
            <div className="animate-spin rounded-full h-4 w-4 border-2 border-current border-t-transparent" />
            處理中...
          </>
        ) : (
          <>
            {icon && <span className="shrink-0">{icon}</span>}
            {children}
          </>
        )}
      </button>
    )
  }
)
Button.displayName = "Button"

export { Button }