CREATE TABLE public.invitations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  invited_by uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role text NOT NULL,
  status text NOT NULL DEFAULT 'pending'::text, -- 'pending', 'aktif', 'nonaktif'
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT invitations_status_check CHECK (status = ANY (ARRAY['pending'::text, 'aktif'::text, 'nonaktif'::text])),
  CONSTRAINT invitations_pkey PRIMARY KEY (id),
  CONSTRAINT invitations_unique_invite UNIQUE (invited_by, user_id)
);

-- Memberikan hak akses ke role
grant delete on table public.invitations to anon, authenticated, service_role;
grant insert on table public.invitations to anon, authenticated, service_role;
grant references on table public.invitations to anon, authenticated, service_role;
grant select on table public.invitations to anon, authenticated, service_role;
grant trigger on table public.invitations to anon, authenticated, service_role;
grant truncate on table public.invitations to anon, authenticated, service_role;
grant update on table public.invitations to anon, authenticated, service_role;

-- Mengaktifkan Row Level Security (RLS)
alter table public.invitations enable row level security;

-- Kebijakan RLS (Policies)
create policy "invitations_select" on public.invitations
  for select to authenticated
  using (auth.uid() = invited_by or auth.uid() = user_id);

create policy "invitations_insert" on public.invitations
  for insert to authenticated
  with check (auth.uid() = invited_by);

create policy "invitations_update" on public.invitations
  for update to authenticated
  using (auth.uid() = invited_by or auth.uid() = user_id);

create policy "invitations_delete" on public.invitations
  for delete to authenticated
  using (auth.uid() = invited_by or auth.uid() = user_id);
