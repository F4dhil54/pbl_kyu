-- Migration: Add 'scheduled' status to status_tugas check constraint
ALTER TABLE "public"."tasks" DROP CONSTRAINT IF EXISTS "tasks_status_tugas_check";
ALTER TABLE "public"."tasks" ADD CONSTRAINT "tasks_status_tugas_check" CHECK (status_tugas = ANY (ARRAY['draft'::text, 'review'::text, 'accept'::text, 'done'::text, 'scheduled'::text]));
