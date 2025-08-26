/**
 * TXN 系統常數定義
 * 包含角色定義、權限等級和系統配置
 */

// =============================================
// 用戶角色定義
// =============================================

/** 系統中所有可用的用戶角色 */
export const USER_ROLES = ['user', 'moderator', 'admin', 'super_admin'] as const;

/** 用戶角色類型 */
export type UserRole = typeof USER_ROLES[number];

/** 角色權限等級對應 */
export const ROLE_LEVELS: Record<UserRole, number> = {
  user: 1,
  moderator: 2,
  admin: 3,
  super_admin: 4,
} as const;

/** 角色顯示名稱 */
export const ROLE_DISPLAY_NAMES: Record<UserRole, string> = {
  user: '一般用戶',
  moderator: '版主',
  admin: '管理員',
  super_admin: '超級管理員',
} as const;

/** 角色描述 */
export const ROLE_DESCRIPTIONS: Record<UserRole, string> = {
  user: '基本用戶權限，可以記錄和管理自己的交易',
  moderator: '內容版主，可以審核用戶內容和協助管理',
  admin: '系統管理員，可以管理用戶和系統設定',
  super_admin: '超級管理員，擁有最高權限包括角色分配',
} as const;

/** 角色顏色配色 (用於 UI 顯示) */
export const ROLE_COLORS: Record<UserRole, string> = {
  user: 'blue',
  moderator: 'green',
  admin: 'purple',
  super_admin: 'red',
} as const;

// =============================================
// 權限檢查函數
// =============================================

/**
 * 檢查用戶是否具有管理員級別的權限
 * @param role 用戶角色
 * @returns 是否為管理員級別
 */
export const isAdminRole = (role: UserRole): boolean => {
  return ROLE_LEVELS[role] >= ROLE_LEVELS.moderator;
};

/**
 * 檢查用戶是否可以修改其他用戶的角色
 * @param currentUserRole 當前用戶角色
 * @param targetRole 目標角色
 * @returns 是否可以修改
 */
export const canManageRole = (currentUserRole: UserRole, targetRole: UserRole): boolean => {
  // 只有超級管理員可以分配角色
  if (currentUserRole !== 'super_admin') {
    return false;
  }
  
  // 超級管理員可以分配除了自己以外的所有角色
  return targetRole !== 'super_admin';
};

/**
 * 檢查用戶是否可以查看管理員面板
 * @param role 用戶角色
 * @returns 是否可以查看
 */
export const canAccessAdminPanel = (role: UserRole): boolean => {
  return isAdminRole(role);
};

/**
 * 檢查用戶是否可以批准/拒絕其他用戶
 * @param role 用戶角色
 * @returns 是否可以操作
 */
export const canManageUsers = (role: UserRole): boolean => {
  return ROLE_LEVELS[role] >= ROLE_LEVELS.admin;
};

/**
 * 獲取用戶可以分配的角色列表
 * @param currentUserRole 當前用戶角色
 * @returns 可分配的角色列表
 */
export const getAssignableRoles = (currentUserRole: UserRole): UserRole[] => {
  if (currentUserRole === 'super_admin') {
    return ['user', 'moderator', 'admin'];
  }
  return [];
};

// =============================================
// 用戶狀態定義
// =============================================

/** 用戶狀態類型 */
export const USER_STATUSES = ['pending', 'active', 'inactive', 'suspended'] as const;
export type UserStatus = typeof USER_STATUSES[number];

/** 用戶狀態顯示名稱 */
export const STATUS_DISPLAY_NAMES: Record<UserStatus, string> = {
  pending: '待審核',
  active: '活躍',
  inactive: '已停用',
  suspended: '已暫停',
} as const;

/** 用戶狀態顏色配色 */
export const STATUS_COLORS: Record<UserStatus, string> = {
  pending: 'yellow',
  active: 'green',
  inactive: 'gray',
  suspended: 'red',
} as const;

// =============================================
// 交易相關常數
// =============================================

/** 交易經驗等級 */
export const TRADING_EXPERIENCE_LEVELS = ['beginner', 'intermediate', 'advanced', 'professional'] as const;
export type TradingExperience = typeof TRADING_EXPERIENCE_LEVELS[number];

/** 交易經驗顯示名稱 */
export const TRADING_EXPERIENCE_DISPLAY_NAMES: Record<TradingExperience, string> = {
  beginner: '新手',
  intermediate: '中級',
  advanced: '進階',
  professional: '專業',
} as const;

/** 支援的貨幣類型 */
export const SUPPORTED_CURRENCIES = ['USD', 'TWD', 'EUR', 'JPY', 'GBP'] as const;
export type Currency = typeof SUPPORTED_CURRENCIES[number];

/** 時區選項 */
export const TIMEZONE_OPTIONS = [
  'Asia/Taipei',
  'America/New_York',
  'Europe/London',
  'Asia/Tokyo',
  'Australia/Sydney',
] as const;
export type Timezone = typeof TIMEZONE_OPTIONS[number];

// =============================================
// 系統配置
// =============================================

/** 分頁配置 */
export const PAGINATION_CONFIG = {
  /** 預設每頁顯示數量 */
  DEFAULT_PAGE_SIZE: 20,
  /** 每頁顯示數量選項 */
  PAGE_SIZE_OPTIONS: [10, 20, 50, 100],
  /** 最大每頁顯示數量 */
  MAX_PAGE_SIZE: 100,
} as const;

/** 管理員操作配置 */
export const ADMIN_CONFIG = {
  /** 批量操作最大數量 */
  MAX_BATCH_SIZE: 100,
  /** 管理員日誌保留天數 */
  LOG_RETENTION_DAYS: 90,
  /** 自動刷新間隔 (毫秒) */
  AUTO_REFRESH_INTERVAL: 30000,
} as const;

// =============================================
// 工具函數
// =============================================

/**
 * 驗證角色是否有效
 * @param role 要驗證的角色
 * @returns 是否為有效角色
 */
export const isValidRole = (role: string): role is UserRole => {
  return USER_ROLES.includes(role as UserRole);
};

/**
 * 驗證狀態是否有效
 * @param status 要驗證的狀態
 * @returns 是否為有效狀態
 */
export const isValidStatus = (status: string): status is UserStatus => {
  return USER_STATUSES.includes(status as UserStatus);
};

/**
 * 格式化角色顯示 (包含描述)
 * @param role 用戶角色
 * @returns 格式化的角色字串
 */
export const formatRoleWithDescription = (role: UserRole): string => {
  return `${ROLE_DISPLAY_NAMES[role]} - ${ROLE_DESCRIPTIONS[role]}`;
};

/**
 * 根據角色權限等級排序
 * @param roles 角色列表
 * @returns 排序後的角色列表
 */
export const sortRolesByLevel = (roles: UserRole[]): UserRole[] => {
  return roles.sort((a, b) => ROLE_LEVELS[a] - ROLE_LEVELS[b]);
};

// =============================================
// 通知系統相關常數
// =============================================

/** 通知類型 */
export const NOTIFICATION_TYPES = ['success', 'error', 'warning', 'info'] as const;
export type NotificationType = typeof NOTIFICATION_TYPES[number];

/** 通知優先級 */
export const NOTIFICATION_PRIORITIES = ['low', 'normal', 'high', 'urgent'] as const;
export type NotificationPriority = typeof NOTIFICATION_PRIORITIES[number];

/** 通知動作類型 */
export const NOTIFICATION_ACTION_TYPES = [
  'USER_APPROVED',
  'USER_REJECTED', 
  'USER_ROLE_CHANGED',
  'USER_STATUS_CHANGED',
  'SYSTEM_MAINTENANCE',
  'SECURITY_ALERT',
  'DATA_EXPORT_READY',
  'BACKUP_COMPLETED'
] as const;
export type NotificationActionType = typeof NOTIFICATION_ACTION_TYPES[number];

/** 通知狀態 */
export const NOTIFICATION_STATUSES = ['unread', 'read', 'archived'] as const;
export type NotificationStatus = typeof NOTIFICATION_STATUSES[number];

/** 通知渠道 */
export const NOTIFICATION_CHANNELS = [
  'user_management',
  'system_alerts',
  'trade_updates', 
  'account_updates',
  'announcements'
] as const;
export type NotificationChannel = typeof NOTIFICATION_CHANNELS[number];

/** 通知配置 */
export const NOTIFICATION_CONFIG = {
  /** Toast 通知的預設顯示時間 (毫秒) */
  TOAST_DURATION: {
    success: 4000,
    error: 6000,
    warning: 5000,
    info: 4000,
  } as Record<NotificationType, number>,
  
  /** 最大同時顯示的 Toast 數量 */
  MAX_TOAST_COUNT: 5,
  
  /** 通知中心每頁顯示數量 */
  NOTIFICATION_PAGE_SIZE: 20,
  
  /** 通知自動清理天數 */
  AUTO_CLEANUP_DAYS: 30,
  
  /** 身份驗證通知的有效時間 (分鐘) */
  SECURITY_NOTIFICATION_EXPIRY: 10,
} as const;

/** 通知圖標配置 */
export const NOTIFICATION_ICONS: Record<NotificationType, string> = {
  success: '✅',
  error: '❌', 
  warning: '⚠️',
  info: 'ℹ️',
} as const;

/** 通知樣式配置 */
export const NOTIFICATION_STYLES: Record<NotificationType, string> = {
  success: 'bg-green-50 border-green-200 text-green-800',
  error: 'bg-red-50 border-red-200 text-red-800',
  warning: 'bg-yellow-50 border-yellow-200 text-yellow-800',
  info: 'bg-blue-50 border-blue-200 text-blue-800',
} as const;

// =============================================
// 通知系統類型定義
// =============================================

/** 基礎通知物件 */
export interface BaseNotification {
  id: string;
  type: NotificationType;
  title: string;
  message?: string;
  priority: NotificationPriority;
  actionType?: NotificationActionType;
  createdAt: Date;
  updatedAt?: Date;
}

/** Toast 通知物件 */
export interface ToastNotification extends BaseNotification {
  duration?: number;
  dismissible?: boolean;
  actions?: ToastAction[];
}

/** Toast 動作 */
export interface ToastAction {
  id: string;
  label: string;
  action: () => void;
  style?: 'primary' | 'secondary';
}

/** 持久化通知物件 */
export interface PersistentNotification extends BaseNotification {
  userId: string;
  status: NotificationStatus;
  channels: NotificationChannel[];
  metadata?: Record<string, unknown>;
  expiresAt?: Date;
  readAt?: Date;
  archivedAt?: Date;
}

/** 通知偏好設定 */
export interface NotificationPreferences {
  userId: string;
  enabledChannels: NotificationChannel[];
  enabledActionTypes: NotificationActionType[];
  quietHours?: {
    start: string; // HH:MM 格式
    end: string;   // HH:MM 格式
    timezone: string;
  };
  emailDigest?: {
    enabled: boolean;
    frequency: 'daily' | 'weekly' | 'never';
  };
}

/** 通知統計 */
export interface NotificationStats {
  totalCount: number;
  unreadCount: number;
  byType: Record<NotificationType, number>;
  byPriority: Record<NotificationPriority, number>;
  recentCount24h: number;
}

// =============================================
// 通知系統工具函數
// =============================================

/**
 * 生成通知 ID
 */
export const generateNotificationId = (): string => {
  return `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
};

/**
 * 檢查通知是否已過期
 */
export const isNotificationExpired = (notification: PersistentNotification): boolean => {
  if (!notification.expiresAt) return false;
  return new Date() > new Date(notification.expiresAt);
};

/**
 * 獲取通知優先級數值
 */
export const getNotificationPriorityValue = (priority: NotificationPriority): number => {
  const priorityMap: Record<NotificationPriority, number> = {
    low: 1,
    normal: 2, 
    high: 3,
    urgent: 4,
  };
  return priorityMap[priority];
};

/**
 * 根據優先級排序通知
 */
export const sortNotificationsByPriority = (notifications: BaseNotification[]): BaseNotification[] => {
  return notifications.sort((a, b) => {
    const priorityDiff = getNotificationPriorityValue(b.priority) - getNotificationPriorityValue(a.priority);
    if (priorityDiff !== 0) return priorityDiff;
    // 優先級相同時按時間排序 (新的在前)
    return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
  });
};

// =============================================
// 通知系統常數定義
// =============================================

/** 廣播狀態 */
export const BROADCAST_STATUSES = ['pending', 'sending', 'sent', 'failed'] as const;

/** 廣播狀態類型 */
export type BroadcastStatus = typeof BROADCAST_STATUSES[number];

/** 通知頻道顯示名稱 */
export const NOTIFICATION_CHANNEL_DISPLAY_NAMES: Record<NotificationChannel, string> = {
  user_management: '用戶管理',
  system_alerts: '系統警告',
  trade_updates: '交易更新', 
  account_updates: '帳戶更新',
  announcements: '系統公告',
} as const;

/** 通知頻道描述 */
export const NOTIFICATION_CHANNEL_DESCRIPTIONS: Record<NotificationChannel, string> = {
  user_management: '用戶註冊、審核、角色變更等通知',
  system_alerts: '系統錯誤、維護、安全警告等',
  trade_updates: '交易記錄、策略更新等通知',
  account_updates: '個人帳戶相關通知',
  announcements: '平台公告和重要消息',
} as const;

/** 通知頻道圖標 */
export const NOTIFICATION_CHANNEL_ICONS: Record<NotificationChannel, string> = {
  user_management: 'UserGroupIcon',
  system_alerts: 'ExclamationTriangleIcon',
  trade_updates: 'ChartBarIcon',
  account_updates: 'UserIcon', 
  announcements: 'SpeakerphoneIcon',
} as const;

/** 通知頻道顏色 */
export const NOTIFICATION_CHANNEL_COLORS: Record<NotificationChannel, string> = {
  user_management: 'blue',
  system_alerts: 'red',
  trade_updates: 'green',
  account_updates: 'purple',
  announcements: 'yellow',
} as const;

/** 通知優先級顯示名稱 */
export const NOTIFICATION_PRIORITY_DISPLAY_NAMES: Record<NotificationPriority, string> = {
  low: '低',
  normal: '普通',
  high: '高',
  urgent: '緊急',
} as const;

/** 通知優先級顏色 */
export const NOTIFICATION_PRIORITY_COLORS: Record<NotificationPriority, string> = {
  low: 'gray',
  normal: 'blue', 
  high: 'yellow',
  urgent: 'red',
} as const;

/** 廣播狀態顯示名稱 */
export const BROADCAST_STATUS_DISPLAY_NAMES: Record<BroadcastStatus, string> = {
  pending: '待發送',
  sending: '發送中',
  sent: '已發送',
  failed: '發送失敗',
} as const;

/** 廣播狀態顏色 */
export const BROADCAST_STATUS_COLORS: Record<BroadcastStatus, string> = {
  pending: 'yellow',
  sending: 'blue',
  sent: 'green', 
  failed: 'red',
} as const;

// =============================================
// 通知系統配置
// =============================================

/** 即時通知配置 */
export const REALTIME_CONFIG = {
  /** 重連間隔 (毫秒) */
  RECONNECT_INTERVAL: 3000,
  /** 最大重連次數 */
  MAX_RECONNECT_ATTEMPTS: 5,
  /** 心跳間隔 (毫秒) */
  HEARTBEAT_INTERVAL: 30000,
} as const;

// =============================================
// 通知相關工具函數
// =============================================

/**
 * 驗證通知頻道是否有效
 * @param channel 要驗證的頻道
 * @returns 是否為有效頻道
 */
export const isValidNotificationChannel = (channel: string): channel is NotificationChannel => {
  return NOTIFICATION_CHANNELS.includes(channel as NotificationChannel);
};

/**
 * 驗證通知優先級是否有效
 * @param priority 要驗證的優先級
 * @returns 是否為有效優先級
 */
export const isValidNotificationPriority = (priority: string): priority is NotificationPriority => {
  return NOTIFICATION_PRIORITIES.includes(priority as NotificationPriority);
};

/**
 * 檢查用戶是否可以接收特定頻道的通知
 * @param userRole 用戶角色
 * @param channel 通知頻道
 * @returns 是否可以接收
 */
export const canReceiveNotification = (userRole: UserRole, channel: NotificationChannel): boolean => {
  // 管理員頻道只有非 'user' 角色可以接收
  const adminChannels: NotificationChannel[] = ['user_management', 'system_alerts'];
  
  if (adminChannels.includes(channel)) {
    return userRole !== 'user';
  }
  
  return true;
};

/**
 * 獲取優先級數值 (用於排序)
 * @param priority 優先級
 * @returns 數值等級
 */
export const getNotificationPriorityLevel = (priority: NotificationPriority): number => {
  const levels: Record<NotificationPriority, number> = {
    low: 1,
    normal: 2,
    high: 3,
    urgent: 4,
  };
  return levels[priority];
};

/**
 * 檢查優先級是否符合最小要求
 * @param priority 通知優先級
 * @param minPriority 最小要求優先級
 * @returns 是否符合要求
 */
export const meetsPriorityRequirement = (
  priority: NotificationPriority, 
  minPriority: NotificationPriority
): boolean => {
  return getNotificationPriorityLevel(priority) >= getNotificationPriorityLevel(minPriority);
};

/**
 * 格式化通知時間顯示
 * @param date 通知時間
 * @returns 格式化的時間字串
 */
export const formatNotificationTime = (date: Date | string): string => {
  const notificationDate = typeof date === 'string' ? new Date(date) : date;
  const now = new Date();
  const diffMs = now.getTime() - notificationDate.getTime();
  const diffMins = Math.floor(diffMs / (1000 * 60));
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
  
  if (diffMins < 1) {
    return '剛剛';
  } else if (diffMins < 60) {
    return `${diffMins} 分鐘前`;
  } else if (diffHours < 24) {
    return `${diffHours} 小時前`;
  } else if (diffDays < 7) {
    return `${diffDays} 天前`;
  } else {
    return notificationDate.toLocaleDateString('zh-TW');
  }
};

