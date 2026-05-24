-- ============================================================
-- Migration: Fix tasks table constraints
-- Memastikan semua status_tugas yang valid tersedia di constraint,
-- dan menghapus trigger yang mungkin memblokir insert draft/scheduled.
-- ============================================================

-- 1. Pastikan constraint status_tugas mencakup semua nilai yang digunakan kode
ALTER TABLE "public"."tasks" DROP CONSTRAINT IF EXISTS "tasks_status_tugas_check";
ALTER TABLE "public"."tasks" ADD CONSTRAINT "tasks_status_tugas_check"
  CHECK (status_tugas = ANY (ARRAY[
    'draft'::text,
    'review'::text,
    'accept'::text,
    'done'::text,
    'scheduled'::text
  ]));

-- 2. Pastikan constraint keputusan_manajer valid
ALTER TABLE "public"."tasks" DROP CONSTRAINT IF EXISTS "tasks_keputusan_manajer_check";
ALTER TABLE "public"."tasks" ADD CONSTRAINT "tasks_keputusan_manajer_check"
  CHECK (keputusan_manajer = ANY (ARRAY[
    'Menunggu'::text,
    'Setujui'::text,
    'Tidak Setujui'::text
  ]));

-- 3. Hapus constraint chk_done_at jika ada (menyebabkan hang pada non-done status)
ALTER TABLE "public"."tasks" DROP CONSTRAINT IF EXISTS "chk_done_at";
ALTER TABLE "public"."tasks" DROP CONSTRAINT IF EXISTS "tasks_done_at_check";

-- 4. Set default nilai yang aman untuk kolom-kolom penting
ALTER TABLE "public"."tasks" ALTER COLUMN "status_tugas" SET DEFAULT 'draft';
ALTER TABLE "public"."tasks" ALTER COLUMN "keputusan_manajer" SET DEFAULT 'Menunggu';
ALTER TABLE "public"."tasks" ALTER COLUMN "dibuat_oleh_role" SET DEFAULT 'Manajer';

-- 5. Pastikan done_at nullable (tidak ada constraint NOT NULL yang memblokir)
ALTER TABLE "public"."tasks" ALTER COLUMN "done_at" DROP NOT NULL;
