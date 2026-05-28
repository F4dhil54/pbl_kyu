-- Migration: Add task_id column to github_commits table
ALTER TABLE public.github_commits 
ADD COLUMN task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE;
