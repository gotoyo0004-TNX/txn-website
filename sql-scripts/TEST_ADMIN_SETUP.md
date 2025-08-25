# TXN 測試管理員帳號設置指南

## ⚠️ 重要更新：外鍵約束錯誤修復

如果您遇到以下錯誤：
```
ERROR: 23503: insert or update on table "user_profiles" violates foreign key constraint "user_profiles_id_fkey"
```

請使用修復版腳本：`20250825_180000_create_test_admin_fixed.sql`

## 🔐 測試管理員帳號資訊

### 建議的測試帳號
- **Email**: `admin@txn.test`
- **Password**: `AdminTest123!`
- **角色**: 管理員 (admin)
- **狀態**: 活躍 (active)

## 📋 設置步驟 (修復版)

修復版腳本提供三種方法，請選擇最適合您情況的方法：

### 🔧 方法選擇指南

1. **方法一 (推薦)**: 需要真正登入測試 → 手動在 Supabase Auth 創建用戶
2. **方法二**: 已有認證用戶 → 自動檢測並設置為管理員
3. **方法三**: 僅測試面板顯示 → 純數據測試，無法登入

---

### 📱 方法一：手動設置 (推薦)

#### 步驟 1: 在 Supabase Auth 中創建用戶
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

#### 步驟 2: 執行修復版 SQL 腳本
1. 在 **SQL Editor** 中執行 `20250825_180000_create_test_admin_fixed.sql`
2. 找到「方法一」部分，取消註釋相關代碼
3. 將 `'YOUR_ACTUAL_USER_ID_HERE'` 替換為步驟1中獲得的實際用戶ID
4. 執行腳本

**示例代碼**：
```sql
-- 在修復版腳本中取消註釋並替換 UUID
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
    '你的實際用戶ID'::uuid,  -- 替換為真實的用戶 ID
    'admin@txn.test',
    'TXN 測試管理員',
    'admin',
    'active',
    100000.00,
    'USD',
    'Asia/Taipei',
    'professional',
    NOW(),
    '你的實際用戶ID'::uuid,  -- 替換為真實的用戶 ID
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

---

### 🔍 方法二：自動檢測設置

如果您已經在 Supabase Auth 中創建了 `admin@txn.test` 用戶：

1. 直接執行 `20250825_180000_create_test_admin_fixed.sql`
2. 腳本會自動檢測現有認證用戶
3. 自動設置為管理員角色
4. 無需手動替換 UUID

---

### 🧪 方法三：純測試環境

如果您只需要測試管理面板顯示，不需要登入功能：

1. 直接執行 `20250825_180000_create_test_admin_fixed.sql`
2. 腳本會自動創建測試用戶數據
3. 創建的用戶無法登入，但可在管理面板中查看
4. 適合測試 UI 顯示和功能

### 💡 測試數據說明
修復版腳本會自動創建以下測試數據：

#### 測試用戶類型：
- **待審核用戶**: 3個用戶，不同經驗等級
- **活躍用戶**: 1個已批准的用戶
- **停用用戶**: 1個已停用的用戶
- **管理員日誌**: 示例操作記錄
- **測試策略**: 預設交易策略

#### 測試數據特點：
- 使用動態 UUID，避免外鍵約束錯誤
- 包含完整的用戶狀態流程
- 提供豐富的測試場景

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

### 問題：外鍵約束錯誤
**錯誤訊息**: `violates foreign key constraint "user_profiles_id_fkey"`
**解決方案**:
1. ✅ 使用修復版腳本 `20250825_180000_create_test_admin_fixed.sql`
2. 選擇適合的方法（一、二、三）
3. 確保在 Supabase Auth 中有對應的用戶記錄

### 問題：無法登入
**解決方案**:
1. 確認使用方法一或方法二創建了認證用戶
2. 檢查 Supabase Auth 中用戶已創建且確認
3. 確認密碼是否正確：`AdminTest123!`
4. 確認 Email confirmations 已關閉

### 問題：登入後無法訪問管理員面板
**解決方案**:
1. 確認修復版 SQL 腳本已正確執行
2. 檢查 `user_profiles` 表中的 `role` 是否為 `admin`
3. 檢查 `status` 是否為 `active`
4. 檢查控制台是否有錯誤訊息

### 問題：看不到待審核用戶
**解決方案**:
1. 修復版腳本會自動創建測試用戶
2. 如果沒有，請重新執行腳本
3. 或者註冊新用戶進行測試

### 問題：方法三無法登入
**說明**: 
- 方法三僅創建數據庫記錄，不創建認證用戶
- 如需登入，請使用方法一或方法二
- 方法三適合純 UI 測試

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