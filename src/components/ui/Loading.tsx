import React from 'react'
import { cn } from '@/lib/utils'

export interface LoadingProps {
  size?: 'sm' | 'md' | 'lg' | 'xl'
  color?: 'primary' | 'accent' | 'white'
  text?: string
  className?: string
}

const Loading: React.FC<LoadingProps> = ({ 
  size = 'md', 
  color = 'primary', 
  text,
  className 
}) => {
  const sizes = {
    sm: "h-4 w-4 border-2",
    md: "h-6 w-6 border-2",
    lg: "h-8 w-8 border-3",
    xl: "h-12 w-12 border-4"
  }
  
  const colors = {
    primary: "border-txn-primary-200 border-t-txn-primary-600",
    accent: "border-txn-accent-200 border-t-txn-accent-600",
    white: "border-white/20 border-t-white"
  }

  return (
    <div className={cn("flex items-center gap-3", className)}>
      <div
        className={cn(
          "animate-spin rounded-full",
          sizes[size],
          colors[color]
        )}
      />
      {text && (
        <span className="text-sm text-txn-primary-600 dark:text-gray-400">
          {text}
        </span>
      )}
    </div>
  )
}

export { Loading }