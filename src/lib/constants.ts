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

/** 通知配置 */
export const NOTIFICATION_CONFIG = {
  /** 預設顯示時間 (毫秒) */
  DEFAULT_DURATION: 5000,
  /** 最大顯示數量 */
  MAX_NOTIFICATIONS: 5,
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