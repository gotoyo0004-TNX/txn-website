-- =============================================
-- TXN 專案資料庫初始化腳本
-- 日期: 2024-08-25
-- 功能: 建立基礎資料表和測試資料
-- 版本: v1.0
-- =============================================

-- 1. 建立用戶資料表 (擴展 Supabase Auth)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    avatar_url TEXT,
    website TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. 建立專案資料表
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'completed')),
    owner_id UUID REFERENCES public.users(id) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 建立任務資料表
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    priority VARCHAR(10) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
    assigned_to UUID REFERENCES public.users(id),
    due_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 建立系統日誌資料表
CREATE TABLE IF NOT EXISTS public.activity_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id),
    action VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID NOT NULL,
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- RLS (Row Level Security) 安全政策設定
-- =============================================

-- 啟用 RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- 用戶資料表政策
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Enable insert for authenticated users only" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 專案資料表政策
CREATE POLICY "Users can view own projects" ON public.projects
    FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY "Users can insert own projects" ON public.projects
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own projects" ON public.projects
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own projects" ON public.projects
    FOR DELETE USING (auth.uid() = owner_id);

-- 任務資料表政策
CREATE POLICY "Users can view project tasks" ON public.tasks
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.projects
            WHERE projects.id = tasks.project_id
            AND projects.owner_id = auth.uid()
        )
        OR auth.uid() = assigned_to
    );

CREATE POLICY "Project owners can manage tasks" ON public.tasks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.projects
            WHERE projects.id = tasks.project_id
            AND projects.owner_id = auth.uid()
        )
    );

-- 活動日誌政策
CREATE POLICY "Users can view own activity logs" ON public.activity_logs
    FOR SELECT USING (auth.uid() = user_id);

-- =============================================
-- 觸發器：自動更新 updated_at 欄位
-- =============================================

-- 建立更新函數
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 為各資料表建立觸發器
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER update_projects_updated_at
    BEFORE UPDATE ON public.projects
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON public.tasks
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- =============================================
-- 測試資料插入（可選）
-- =============================================

-- 注意：以下測試資料需要先有經過認證的用戶
-- 可以在前端註冊用戶後，將 user_id 替換為實際的 UUID

-- INSERT INTO public.projects (name, description, owner_id) VALUES
-- ('TXN 網站開發', 'Next.js + Supabase 全端網站專案', 'YOUR_USER_ID_HERE'),
-- ('範例專案', '用於測試的範例專案', 'YOUR_USER_ID_HERE');

-- INSERT INTO public.tasks (title, description, project_id, status, priority) VALUES
-- ('建立資料庫結構', '設計並實作基礎資料表', (SELECT id FROM public.projects WHERE name = 'TXN 網站開發' LIMIT 1), 'completed', 'high'),
-- ('實作用戶認證', '整合 Supabase Auth 系統', (SELECT id FROM public.projects WHERE name = 'TXN 網站開發' LIMIT 1), 'in_progress', 'high'),
-- ('設計用戶界面', '建立現代化的響應式界面', (SELECT id FROM public.projects WHERE name = 'TXN 網站開發' LIMIT 1), 'pending', 'medium');

-- =============================================
-- 索引優化（提升查詢效能）
-- =============================================

-- 為常用查詢建立索引
CREATE INDEX IF NOT EXISTS idx_projects_owner_id ON public.projects(owner_id);
CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON public.tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON public.tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON public.tasks(status);
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON public.activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON public.activity_logs(created_at);

-- =============================================
-- 執行完成後請確認：
-- 1. 資料表結構正確建立
-- 2. RLS 政策正常生效
-- 3. 觸發器功能正常
-- 4. 索引建立成功
-- 
-- 下一步：
-- 1. 在前端實作用戶註冊/登入功能
-- 2. 建立專案和任務管理界面
-- 3. 測試資料操作功能
-- =============================================