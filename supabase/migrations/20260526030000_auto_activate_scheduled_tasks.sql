-- ============================================================
-- Migration: Auto-activate scheduled tasks when time has passed
-- Saat scheduled_for <= NOW() dan status_tugas = 'scheduled',
-- otomatis diubah menjadi 'accept' (Tugas Aktif).
-- ============================================================

-- Fungsi untuk mengaktifkan semua tugas terjadwal yang sudah waktunya
CREATE OR REPLACE FUNCTION public.activate_expired_scheduled_tasks()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.tasks
  SET 
    status_tugas = 'accept',
    keputusan_manajer = 'Setujui',
    updated_at = NOW()
  WHERE 
    status_tugas = 'scheduled'
    AND scheduled_for IS NOT NULL
    AND scheduled_for <= NOW();
END;
$$;

-- Jalankan sekali langsung untuk mengaktifkan tugas yang sudah terjadwal
SELECT public.activate_expired_scheduled_tasks();
