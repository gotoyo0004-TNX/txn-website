# TXN 測試管理員帳號設置指南

## 🔐 測試管理員帳號資訊

### 建議的測試帳號
- **Email**: `admin@txn.test`
- **Password**: `AdminTest123!`
- **角色**: 管理員 (admin)
- **狀態**: 活躍 (active)

## 📋 設置步驟

### 步驟 1: 在 Supabase Auth 中創建用戶
1. 登入 [Supabase Dashboard](https://supabase.com/dashboard)
2. 選擇您的 TXN 專案
3. 前往 **Authentication** → **Users**
4. 點擊 **Add user** 或 **Invite**
5. 輸入以下資訊：
   - **Email**: `admin@txn.test`
   - **Password**: `AdminTest123!`
   - ✅ 勾選 **Auto Confirm User** (自動確認用戶)
6. 點擊 **Send invitation** 或 **Create user**
7. **重要**: 複製生成的 **User ID** (UUID格式)

### 步驟 2: 執行 SQL 腳本設置權限
在 **SQL Editor** 中執行以下腳本：

```sql
-- 替換 'YOUR_USER_ID_HERE' 為步驟1中獲得的實際用戶ID
INSERT INTO public.user_profiles (
    id,
    email,
    full_name,
    role,
    status,
    initial_capital,
    currency,
    timezone,
    trading_experience,
    approved_at,
    approved_by,
    created_at,
    updated_at
) VALUES (
    'YOUR_USER_ID_HERE'::uuid,  -- 替換為實際的用戶ID
    'admin@txn.test',
    'TXN 測試管理員',
    'admin',                    -- 設為管理員角色
    'active',                   -- 設為活躍狀態
    100000.00,
    'USD',
    'Asia/Taipei',
    'professional',
    NOW(),
    'YOUR_USER_ID_HERE'::uuid,  -- 替換為實際的用戶ID
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    role = 'admin',
    status = 'active',
    full_name = 'TXN 測試管理員',
    approved_at = NOW(),
    updated_at = NOW();
```

### 步驟 3: 創建測試用的待審核用戶 (可選)
如果您想要測試用戶審核功能，可以執行以下腳本：

```sql
-- 創建測試用的待審核用戶
INSERT INTO public.user_profiles (
    id,
    email,
    full_name,
    role,
    status,
    initial_capital,
    currency,
    timezone,
    trading_experience,
    created_at,
    updated_at
) VALUES 
(
    gen_random_uuid(),
    'testuser1@example.com',
    '測試用戶一號',
    'user',
    'pending',
    10000.00,
    'USD',
    'Asia/Taipei',
    'beginner',
    NOW() - INTERVAL '2 hours',
    NOW() - INTERVAL '2 hours'
),
(
    gen_random_uuid(),
    'testuser2@example.com',
    '測試用戶二號',
    'user',
    'pending',
    25000.00,
    'USD',
    'Asia/Taipei',
    'intermediate',
    NOW() - INTERVAL '1 hour',
    NOW() - INTERVAL '1 hour'
);
```

## 🧪 測試功能

設置完成後，您可以測試以下功能：

### 1. 登入管理員面板
- 前往 `/auth` 頁面
- 使用 `admin@txn.test` 和 `AdminTest123!` 登入
- 登入後應該會看到成功通知

### 2. 訪問管理員控制面板
- 前往 `/admin` 頁面
- 應該可以看到：
  - ✅ 用戶統計卡片
  - ✅ 待審核用戶列表
  - ✅ 批准/拒絕按鈕
  - ✅ 通知系統
  - ✅ 確認對話框

### 3. 測試管理員操作
- 批准待審核用戶
- 拒絕用戶申請
- 查看操作通知
- 測試確認對話框

## 🔧 故障排除

### 問題：無法登入
**解決方案**:
1. 確認在 Supabase Auth 中用戶已創建且確認
2. 檢查密碼是否正確
3. 確認 Email confirmations 已關閉

### 問題：登入後無法訪問管理員面板
**解決方案**:
1. 確認 SQL 腳本已正確執行
2. 檢查 `user_profiles` 表中的 `role` 是否為 `admin`
3. 檢查 `status` 是否為 `active`

### 問題：看不到待審核用戶
**解決方案**:
1. 執行步驟3的 SQL 腳本創建測試用戶
2. 或者註冊新用戶進行測試

## 📊 驗證設置

執行以下查詢驗證設置是否正確：

```sql
-- 檢查管理員帳號
SELECT id, email, full_name, role, status, created_at 
FROM public.user_profiles 
WHERE email = 'admin@txn.test';

-- 檢查用戶統計
SELECT status, COUNT(*) 
FROM public.user_profiles 
GROUP BY status;

-- 檢查管理員日誌
SELECT action, created_at 
FROM public.admin_logs 
ORDER BY created_at DESC 
LIMIT 5;
```

## 🧹 清理測試數據

測試完成後，如需清理測試數據：

```sql
-- 清理測試用戶（請謹慎執行）
DELETE FROM public.admin_logs WHERE admin_id IN (
    SELECT id FROM public.user_profiles WHERE email LIKE '%@test.com' OR email LIKE '%@example.com'
);

DELETE FROM public.strategies WHERE user_id IN (
    SELECT id FROM public.user_profiles WHERE email LIKE '%@test.com' OR email LIKE '%@example.com'
);

DELETE FROM public.user_profiles WHERE email LIKE '%@test.com' OR email LIKE '%@example.com';
```

---

**注意**: 這些是測試用帳號，請勿在生產環境中使用簡單密碼。