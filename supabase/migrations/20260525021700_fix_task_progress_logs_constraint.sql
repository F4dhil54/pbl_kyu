-- ============================================================
-- Migration: Fix task_progress_logs status_progress constraint
-- Memastikan status_progress dapat menyimpan nilai 'Selesai' 
-- sesuai dengan opsi yang dikirimkan oleh Flutter client.
-- ============================================================

-- 1. Hapus check constraint lama jika ada
ALTER TABLE "public"."task_progress_logs" DROP CONSTRAINT IF EXISTS "task_progress_logs_status_progress_check";

-- 2. Buat kembali check constraint baru dengan menyertakan 'Selesai'
ALTER TABLE "public"."task_progress_logs" ADD CONSTRAINT "task_progress_logs_status_progress_check"
  CHECK (status_progress = ANY (ARRAY[
    'Akan Dikerjakan'::text,
    'Sedang Dikerjakan'::text,
    'Selesai Dikerjakan'::text,
    'Selesai'::text
  ]));
