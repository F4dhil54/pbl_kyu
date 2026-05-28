-- 1. Drop existing unique indexes on kudos that might conflict
DROP INDEX IF EXISTS idx_kudos_unique_no_task;
DROP INDEX IF EXISTS idx_kudos_unique_with_task;

-- 2. Add task_progress_log_id column referencing task_progress_logs
ALTER TABLE public.kudos ADD COLUMN IF NOT EXISTS task_progress_log_id UUID REFERENCES public.task_progress_logs(id) ON DELETE CASCADE;

-- 3. Create new precise unique indexes for kudos:
-- A. Unique reaction per sender-receiver for a specific task (only if task_progress_log_id is null)
CREATE UNIQUE INDEX IF NOT EXISTS idx_kudos_unique_task ON public.kudos (pengirim_id, penerima_id, task_id) WHERE (task_id IS NOT NULL AND task_progress_log_id IS NULL);

-- B. Unique reaction per sender-receiver for a specific progress log
CREATE UNIQUE INDEX IF NOT EXISTS idx_kudos_unique_log ON public.kudos (pengirim_id, penerima_id, task_progress_log_id) WHERE (task_progress_log_id IS NOT NULL);

-- C. Unique reaction per sender-receiver for a specific GitHub commit
CREATE UNIQUE INDEX IF NOT EXISTS idx_kudos_unique_commit ON public.kudos (pengirim_id, penerima_id, github_commit_id) WHERE (github_commit_id IS NOT NULL);

-- D. Unique general appreciation (when task, log, and commit are all null)
CREATE UNIQUE INDEX IF NOT EXISTS idx_kudos_unique_general ON public.kudos (pengirim_id, penerima_id) WHERE (task_id IS NULL AND task_progress_log_id IS NULL AND github_commit_id IS NULL);
