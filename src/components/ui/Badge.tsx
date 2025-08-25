import React from 'react'
import { cn } from '@/lib/utils'

export interface BadgeProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'success' | 'danger' | 'warning' | 'info' | 'profit' | 'loss'
  size?: 'sm' | 'md' | 'lg'
  children: React.ReactNode
}

const Badge = React.forwardRef<HTMLDivElement, BadgeProps>(
  ({ className, variant = 'default', size = 'md', children, ...props }, ref) => {
    const baseStyles = "inline-flex items-center font-medium rounded-full border transition-colors"
    
    const variants = {
      default: "bg-txn-primary-100 text-txn-primary-800 border-txn-primary-200",
      success: "bg-txn-profit-100 text-txn-profit-800 border-txn-profit-200",
      danger: "bg-txn-loss-100 text-txn-loss-800 border-txn-loss-200",
      warning: "bg-txn-accent-100 text-txn-accent-800 border-txn-accent-200",
      info: "bg-blue-100 text-blue-800 border-blue-200",
      profit: "bg-txn-profit-100 text-txn-profit-800 border-txn-profit-200 font-mono",
      loss: "bg-txn-loss-100 text-txn-loss-800 border-txn-loss-200 font-mono"
    }
    
    const sizes = {
      sm: "px-2 py-1 text-xs",
      md: "px-3 py-1 text-sm",
      lg: "px-4 py-1.5 text-base"
    }

    return (
      <div
        ref={ref}
        className={cn(
          baseStyles,
          variants[variant],
          sizes[size],
          className
        )}
        {...props}
      >
        {children}
      </div>
    )
  }
)
Badge.displayName = "Badge"

export { Badge }