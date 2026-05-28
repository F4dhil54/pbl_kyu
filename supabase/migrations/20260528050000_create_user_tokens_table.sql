-- 1. Buat tabel user_tokens jika belum ada
CREATE TABLE IF NOT EXISTS public.user_tokens (
  id uuid not null default gen_random_uuid (),
  user_id uuid not null,
  fcm_token text not null,
  created_at timestamp with time zone not null default timezone ('utc'::text, now()),
  updated_at timestamp with time zone not null default timezone ('utc'::text, now()),
  constraint user_tokens_pkey primary key (id),
  constraint user_tokens_user_id_fkey foreign key (user_id) references public.profiles (id) on delete cascade,
  constraint user_tokens_fcm_token_key unique (fcm_token)
);

-- 2. Buat indeks untuk mempercepat pencarian user_id
CREATE INDEX IF NOT EXISTS idx_user_tokens_user ON public.user_tokens (user_id);

-- 3. Aktifkan Row Level Security (RLS)
ALTER TABLE public.user_tokens ENABLE ROW LEVEL SECURITY;

-- 4. Buat Kebijakan Akses (Policies) untuk user_tokens
-- Hapus policy lama jika ada untuk mencegah konflik saat migrasi dijalankan ulang
DROP POLICY IF EXISTS "Allow authenticated users to insert own tokens" ON public.user_tokens;
DROP POLICY IF EXISTS "Allow authenticated users to update own tokens" ON public.user_tokens;
DROP POLICY IF EXISTS "Allow authenticated users to delete own tokens" ON public.user_tokens;
DROP POLICY IF EXISTS "Allow authenticated users to select own tokens" ON public.user_tokens;

-- Izinkan pengguna terautentikasi menyisipkan token miliknya sendiri
CREATE POLICY "Allow authenticated users to insert own tokens"
ON public.user_tokens
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Izinkan pengguna terautentikasi memperbarui/menimpa token (meskipun token tersebut sebelumnya punya user lain)
CREATE POLICY "Allow authenticated users to update own tokens"
ON public.user_tokens
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (auth.uid() = user_id);

-- Izinkan pengguna terautentikasi menghapus token miliknya sendiri
CREATE POLICY "Allow authenticated users to delete own tokens"
ON public.user_tokens
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- Izinkan pengguna terautentikasi melihat token miliknya sendiri
CREATE POLICY "Allow authenticated users to select own tokens"
ON public.user_tokens
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Izinkan service_role akses penuh tanpa batas
DROP POLICY IF EXISTS "Allow service_role full access" ON public.user_tokens;
CREATE POLICY "Allow service_role full access"
ON public.user_tokens
TO service_role
USING (true)
WITH CHECK (true);

-- 5. Berikan hak akses penuh kepada role authenticated dan service_role
GRANT ALL ON TABLE public.user_tokens TO authenticated;
GRANT ALL ON TABLE public.user_tokens TO service_role;
