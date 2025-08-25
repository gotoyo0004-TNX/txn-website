import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      // TXN 品牌色彩系統
      colors: {
        txn: {
          // 主色調 - 深邃科技藍
          primary: {
            50: '#F7FAFC',
            100: '#EDF2F7',
            200: '#E2E8F0',
            300: '#CBD5E0',
            400: '#A0AEC0',
            500: '#718096',
            600: '#4A5568',
            700: '#2D3748',
            800: '#1A202C',
            900: '#171923',
            DEFAULT: '#1A202C',
          },
          // 強調色 - 活力金
          accent: {
            50: '#FFFBEB',
            100: '#FEF3C7',
            200: '#FDE68A',
            300: '#FCD34D',
            400: '#FBBF24',
            500: '#F59E0B',
            600: '#D97706',
            700: '#B45309',
            800: '#92400E',
            900: '#78350F',
            DEFAULT: '#FBBF24',
          },
          // 獲利色 - 沉穩森林綠
          profit: {
            50: '#F0FDF4',
            100: '#DCFCE7',
            200: '#BBF7D0',
            300: '#86EFAC',
            400: '#4ADE80',
            500: '#22C55E',
            600: '#228B22',
            700: '#15803D',
            800: '#166534',
            900: '#14532D',
            DEFAULT: '#228B22',
          },
          // 虧損色 - 冷靜緋紅
          loss: {
            50: '#FEF2F2',
            100: '#FEE2E2',
            200: '#FECACA',
            300: '#FCA5A5',
            400: '#F87171',
            500: '#EF4444',
            600: '#DC143C',
            700: '#B91C1C',
            800: '#991B1B',
            900: '#7F1D1D',
            DEFAULT: '#DC143C',
          },
        },
      },
      // TXN 字體系統
      fontFamily: {
        sans: ['Inter', 'Nunito Sans', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
        mono: ['Roboto Mono', 'Fira Code', 'Consolas', 'Courier New', 'monospace'],
      },
      // 自定義陰影
      boxShadow: {
        'txn-sm': '0 2px 4px rgba(26, 32, 44, 0.1)',
        'txn-md': '0 4px 8px rgba(26, 32, 44, 0.12), 0 2px 4px rgba(26, 32, 44, 0.08)',
        'txn-lg': '0 8px 16px rgba(26, 32, 44, 0.15), 0 4px 8px rgba(26, 32, 44, 0.1)',
        'txn-xl': '0 16px 32px rgba(26, 32, 44, 0.2), 0 8px 16px rgba(26, 32, 44, 0.15)',
      },
      // 自定義動畫
      animation: {
        'fade-in': 'fadeIn 0.3s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
        'slide-down': 'slideDown 0.3s ease-out',
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        slideDown: {
          '0%': { transform: 'translateY(-10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
      // 自定義間距
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
        '128': '32rem',
      },
      // 自定義邊框半徑
      borderRadius: {
        'xl': '0.75rem',
        '2xl': '1rem',
        '3xl': '1.5rem',
      },
      // 響應式斷點
      screens: {
        'xs': '475px',
        '3xl': '1600px',
      },
      // 自定義漸層
      backgroundImage: {
        'gradient-primary': 'linear-gradient(135deg, #1A202C 0%, #2D3748 100%)',
        'gradient-accent': 'linear-gradient(135deg, #FBBF24 0%, #F59E0B 100%)',
        'gradient-profit': 'linear-gradient(135deg, #228B22 0%, #22C55E 100%)',
        'gradient-loss': 'linear-gradient(135deg, #DC143C 0%, #EF4444 100%)',
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
        'gradient-conic': 'conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))',
      },
      // 自定義字體大小
      fontSize: {
        'xs': ['0.75rem', { lineHeight: '1rem' }],
        'sm': ['0.875rem', { lineHeight: '1.25rem' }],
        'base': ['1rem', { lineHeight: '1.5rem' }],
        'lg': ['1.125rem', { lineHeight: '1.75rem' }],
        'xl': ['1.25rem', { lineHeight: '1.75rem' }],
        '2xl': ['1.5rem', { lineHeight: '2rem' }],
        '3xl': ['1.875rem', { lineHeight: '2.25rem' }],
        '4xl': ['2.25rem', { lineHeight: '2.5rem' }],
        '5xl': ['3rem', { lineHeight: '1' }],
        '6xl': ['3.75rem', { lineHeight: '1' }],
        '7xl': ['4.5rem', { lineHeight: '1' }],
        '8xl': ['6rem', { lineHeight: '1' }],
        '9xl': ['8rem', { lineHeight: '1' }],
      },
      // 自定義最大寬度
      maxWidth: {
        'xs': '20rem',
        'sm': '24rem',
        'md': '28rem',
        'lg': '32rem',
        'xl': '36rem',
        '2xl': '42rem',
        '3xl': '48rem',
        '4xl': '56rem',
        '5xl': '64rem',
        '6xl': '72rem',
        '7xl': '80rem',
      },
    },
  },
  plugins: [],
  darkMode: 'media', // 使用系統偏好設定
}

export default config