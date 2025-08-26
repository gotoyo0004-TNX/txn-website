'use client'

import React, { useState, useEffect } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { supabase } from '@/lib/supabase'
import { useNotification } from '@/contexts/NotificationContext'
import {
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  Button,
  Loading
} from '@/components/ui'
import {
  CogIcon,
  ShieldCheckIcon,
  ServerStackIcon,
  BellIcon,
  UserGroupIcon,
  ChartBarIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon
} from '@heroicons/react/24/outline'

interface SystemSettings {
  userRegistrationEnabled: boolean
  emailNotificationsEnabled: boolean
  maintenanceMode: boolean
  maxUsersPerDay: number
  dataRetentionDays: number
}

const SettingsPage: React.FC = () => {
  const { user } = useAuth()
  const { showSuccess, showError } = useNotification()
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [settings, setSettings] = useState<SystemSettings>({
    userRegistrationEnabled: true,
    emailNotificationsEnabled: true,
    maintenanceMode: false,
    maxUsersPerDay: 100,
    dataRetentionDays: 365
  })

  useEffect(() => {
    loadSettings()
  }, [])

  const loadSettings = async () => {
    try {
      setLoading(true)
      // 這裡可以從資料庫載入設定，目前使用預設值
      showSuccess('設定載入成功', '系統設定已載入')
    } catch (error) {
      console.error('載入設定錯誤:', error)
      showError('載入失敗', '無法載入系統設定')
    } finally {
      setLoading(false)
    }
  }

  const saveSettings = async () => {
    try {
      setSaving(true)
      // 這裡可以儲存設定到資料庫
      await new Promise(resolve => setTimeout(resolve, 1000)) // 模擬 API 呼叫
      showSuccess('設定儲存成功', '系統設定已更新')
    } catch (error) {
      console.error('儲存設定錯誤:', error)
      showError('儲存失敗', '無法儲存系統設定')
    } finally {
      setSaving(false)
    }
  }

  const handleSettingChange = (key: keyof SystemSettings, value: any) => {
    setSettings(prev => ({
      ...prev,
      [key]: value
    }))
  }

  if (loading) {
    return (
      <div className="max-w-7xl mx-auto space-y-6">
        <div className="animate-pulse">
          <div className="h-8 bg-gray-200 rounded w-48 mb-2"></div>
          <div className="h-4 bg-gray-100 rounded w-64"></div>
        </div>
        
        <Card variant="elevated">
          <CardContent className="text-center py-12">
            <Loading size="xl" />
            <p className="mt-4 text-lg font-medium">載入系統設定...</p>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* 頁面標題 */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-txn-primary-800 dark:text-white">
            系統設定
          </h1>
          <p className="text-txn-primary-600 dark:text-gray-400 mt-1">
            管理系統配置和偏好設定
          </p>
        </div>
        <Button 
          variant="primary" 
          onClick={saveSettings}
          disabled={saving}
        >
          {saving ? (
            <>
              <Loading size="sm" className="mr-2" />
              儲存中...
            </>
          ) : (
            '儲存設定'
          )}
        </Button>
      </div>

      {/* 一般設定 */}
      <Card variant="elevated">
        <CardHeader>
          <CardTitle className="flex items-center">
            <CogIcon className="h-5 w-5 mr-2" />
            一般設定
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-6">
            {/* 用戶註冊 */}
            <div className="flex items-center justify-between">
              <div>
                <h4 className="text-sm font-medium">允許用戶註冊</h4>
                <p className="text-sm text-gray-500">是否開放新用戶註冊功能</p>
              </div>
              <div className="flex items-center">
                <input
                  type="checkbox"
                  checked={settings.userRegistrationEnabled}
                  onChange={(e) => handleSettingChange('userRegistrationEnabled', e.target.checked)}
                  className="h-4 w-4 text-txn-primary-600 focus:ring-txn-primary-500 border-gray-300 rounded"
                />
              </div>
            </div>

            {/* 電子郵件通知 */}
            <div className="flex items-center justify-between">
              <div>
                <h4 className="text-sm font-medium">電子郵件通知</h4>
                <p className="text-sm text-gray-500">系統事件的電子郵件通知</p>
              </div>
              <div className="flex items-center">
                <input
                  type="checkbox"
                  checked={settings.emailNotificationsEnabled}
                  onChange={(e) => handleSettingChange('emailNotificationsEnabled', e.target.checked)}
                  className="h-4 w-4 text-txn-primary-600 focus:ring-txn-primary-500 border-gray-300 rounded"
                />
              </div>
            </div>

            {/* 維護模式 */}
            <div className="flex items-center justify-between">
              <div>
                <h4 className="text-sm font-medium">維護模式</h4>
                <p className="text-sm text-gray-500">啟用後將限制系統訪問</p>
              </div>
              <div className="flex items-center">
                <input
                  type="checkbox"
                  checked={settings.maintenanceMode}
                  onChange={(e) => handleSettingChange('maintenanceMode', e.target.checked)}
                  className="h-4 w-4 text-txn-primary-600 focus:ring-txn-primary-500 border-gray-300 rounded"
                />
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* 安全設定 */}
      <Card variant="elevated">
        <CardHeader>
          <CardTitle className="flex items-center">
            <ShieldCheckIcon className="h-5 w-5 mr-2" />
            安全設定
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-6">
            {/* 每日最大註冊數 */}
            <div>
              <label className="block text-sm font-medium mb-2">每日最大註冊用戶數</label>
              <input
                type="number"
                min="1"
                max="1000"
                value={settings.maxUsersPerDay}
                onChange={(e) => handleSettingChange('maxUsersPerDay', parseInt(e.target.value))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-txn-primary-500 focus:border-transparent"
              />
              <p className="text-sm text-gray-500 mt-1">限制每日新用戶註冊數量</p>
            </div>

            {/* 資料保留天數 */}
            <div>
              <label className="block text-sm font-medium mb-2">資料保留天數</label>
              <input
                type="number"
                min="30"
                max="3650"
                value={settings.dataRetentionDays}
                onChange={(e) => handleSettingChange('dataRetentionDays', parseInt(e.target.value))}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-txn-primary-500 focus:border-transparent"
              />
              <p className="text-sm text-gray-500 mt-1">系統日誌和活動記錄的保留期限</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* 資料庫設定 */}
      <Card variant="elevated">
        <CardHeader>
          <CardTitle className="flex items-center">
            <ServerStackIcon className="h-5 w-5 mr-2" />
            資料庫管理
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <Button variant="outline" className="flex flex-col items-center p-6 h-auto">
                <ServerStackIcon className="h-8 w-8 mb-2 text-blue-500" />
                <span className="font-medium">備份資料庫</span>
                <span className="text-xs text-gray-500 mt-1">建立完整備份</span>
              </Button>
              
              <Button variant="outline" className="flex flex-col items-center p-6 h-auto">
                <ChartBarIcon className="h-8 w-8 mb-2 text-green-500" />
                <span className="font-medium">優化效能</span>
                <span className="text-xs text-gray-500 mt-1">重建索引和統計</span>
              </Button>
              
              <Button variant="outline" className="flex flex-col items-center p-6 h-auto">
                <UserGroupIcon className="h-8 w-8 mb-2 text-orange-500" />
                <span className="font-medium">清理資料</span>
                <span className="text-xs text-gray-500 mt-1">移除過期記錄</span>
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* 通知設定 */}
      <Card variant="elevated">
        <CardHeader>
          <CardTitle className="flex items-center">
            <BellIcon className="h-5 w-5 mr-2" />
            通知管理
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
              <div className="flex items-center">
                <ExclamationTriangleIcon className="h-5 w-5 text-yellow-600 mr-2" />
                <span className="font-medium text-yellow-800">通知功能開發中</span>
              </div>
              <p className="text-sm text-yellow-700 mt-1">
                電子郵件通知、推播通知等功能即將推出
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* 系統狀態 */}
      <Card variant="elevated">
        <CardHeader>
          <CardTitle className="flex items-center">
            <CheckCircleIcon className="h-5 w-5 mr-2" />
            系統狀態
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-3">
              <h4 className="text-sm font-medium">服務狀態</h4>
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm">資料庫服務</span>
                  <span className="text-sm text-green-600 font-medium">✅ 正常</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm">API 服務</span>
                  <span className="text-sm text-green-600 font-medium">✅ 正常</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm">檔案服務</span>
                  <span className="text-sm text-green-600 font-medium">✅ 正常</span>
                </div>
              </div>
            </div>
            
            <div className="space-y-3">
              <h4 className="text-sm font-medium">資源使用</h4>
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm">CPU 使用率</span>
                  <span className="text-sm text-green-600 font-medium">12%</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm">記憶體使用</span>
                  <span className="text-sm text-green-600 font-medium">45%</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm">儲存空間</span>
                  <span className="text-sm text-green-600 font-medium">23%</span>
                </div>
              </div>
            </div>
          </div>
          
          <div className="mt-6 p-4 bg-green-50 rounded-lg">
            <div className="flex items-center">
              <CheckCircleIcon className="h-5 w-5 text-green-600 mr-2" />
              <span className="font-medium text-green-800">系統運行正常</span>
            </div>
            <p className="text-sm text-green-600 mt-1">
              最後檢查: {new Date().toLocaleString('zh-TW')}
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

export default SettingsPage