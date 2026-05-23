ALTER TABLE "public"."pomodoro_sessions" DROP CONSTRAINT IF EXISTS "pomodoro_sessions_durasi_menit_check";
ALTER TABLE "public"."pomodoro_sessions" ADD CONSTRAINT "pomodoro_sessions_durasi_menit_check" CHECK (durasi_menit >= 1 AND durasi_menit <= 120);
