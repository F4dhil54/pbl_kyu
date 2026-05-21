drop extension if exists "pg_net";


  create table "public"."kudos" (
    "id" uuid not null default gen_random_uuid(),
    "pengirim_id" uuid not null,
    "penerima_id" uuid not null,
    "task_id" uuid,
    "project_id" uuid not null,
    "pesan_apresiasi" text,
    "reaksi_emoji" text,
    "created_at" timestamp with time zone not null default timezone('utc'::text, now())
      );



  create table "public"."notifications" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "project_id" uuid,
    "tipe_notifikasi" text not null,
    "judul" text not null,
    "pesan" text not null,
    "peran_penerima" text,
    "link_type" text,
    "link_id" uuid,
    "is_read" boolean not null default false,
    "read_at" timestamp with time zone,
    "created_at" timestamp with time zone not null default timezone('utc'::text, now())
      );



  create table "public"."pomodoro_sessions" (
    "id" uuid not null default gen_random_uuid(),
    "task_id" uuid not null,
    "user_id" uuid not null,
    "durasi_menit" integer not null default 25,
    "status" text not null default 'running'::text,
    "started_at" timestamp with time zone not null default timezone('utc'::text, now()),
    "ended_at" timestamp with time zone
      );



  create table "public"."profiles" (
    "id" uuid not null,
    "nama" text not null,
    "email" text not null,
    "avatar_url" text,
    "bio" text,
    "created_at" timestamp with time zone not null default timezone('utc'::text, now()),
    "updated_at" timestamp with time zone not null default timezone('utc'::text, now())
      );



  create table "public"."project_members" (
    "id" uuid not null default gen_random_uuid(),
    "project_id" uuid not null,
    "user_id" uuid not null,
    "invited_by" uuid,
    "status_akses" text not null default 'aktif'::text,
    "joined_at" timestamp with time zone default timezone('utc'::text, now()),
    "created_at" timestamp with time zone not null default timezone('utc'::text, now())
      );



  create table "public"."projects" (
    "id" uuid not null default gen_random_uuid(),
    "nama_proyek" text not null,
    "deskripsi" text,
    "pembuat_id" uuid not null,
    "warna_tema" text default '#6366F1'::text,
    "deadline" timestamp with time zone,
    "created_at" timestamp with time zone not null default timezone('utc'::text, now()),
    "updated_at" timestamp with time zone not null default timezone('utc'::text, now())
      );



  create table "public"."task_assignees" (
    "id" uuid not null default gen_random_uuid(),
    "task_id" uuid not null,
    "user_id" uuid not null,
    "assigned_by" uuid,
    "assigned_at" timestamp with time zone not null default timezone('utc'::text, now())
      );



  create table "public"."task_progress_logs" (
    "id" uuid not null default gen_random_uuid(),
    "task_id" uuid not null,
    "logged_by" uuid not null,
    "catatan" text not null,
    "persen_selesai" integer,
    "created_at" timestamp with time zone not null default timezone('utc'::text, now())
      );



  create table "public"."tasks" (
    "id" uuid not null default gen_random_uuid(),
    "project_id" uuid not null,
    "created_by" uuid not null,
    "judul_tugas" text not null,
    "deskripsi_tugas" text,
    "kuadran_eisenhower" text,
    "status_tugas" text not null default 'draft'::text,
    "durasi_pomodoro" integer not null default 25,
    "rejection_reason" text,
    "deadline" timestamp with time zone,
    "accepted_at" timestamp with time zone,
    "done_at" timestamp with time zone,
    "created_at" timestamp with time zone not null default timezone('utc'::text, now()),
    "updated_at" timestamp with time zone not null default timezone('utc'::text, now())
      );



  create table "public"."team_members" (
    "id" uuid not null default gen_random_uuid(),
    "team_id" uuid not null,
    "user_id" uuid not null,
    "joined_at" timestamp with time zone not null default timezone('utc'::text, now())
      );



  create table "public"."teams" (
    "id" uuid not null default gen_random_uuid(),
    "nama_tim" text not null,
    "deskripsi" text,
    "manajer_id" uuid not null,
    "created_at" timestamp with time zone not null default timezone('utc'::text, now()),
    "updated_at" timestamp with time zone not null default timezone('utc'::text, now())
      );


CREATE INDEX idx_kudos_penerima ON public.kudos USING btree (penerima_id);

CREATE INDEX idx_kudos_project ON public.kudos USING btree (project_id);

CREATE INDEX idx_kudos_task ON public.kudos USING btree (task_id);

CREATE UNIQUE INDEX idx_kudos_unique_no_task ON public.kudos USING btree (pengirim_id, penerima_id) WHERE (task_id IS NULL);

CREATE UNIQUE INDEX idx_kudos_unique_with_task ON public.kudos USING btree (pengirim_id, penerima_id, task_id) WHERE (task_id IS NOT NULL);

CREATE INDEX idx_notif_created ON public.notifications USING btree (user_id, created_at DESC);

CREATE INDEX idx_notif_project ON public.notifications USING btree (project_id);

CREATE INDEX idx_notif_user ON public.notifications USING btree (user_id, is_read);

CREATE INDEX idx_pm_project ON public.project_members USING btree (project_id);

CREATE INDEX idx_pm_status ON public.project_members USING btree (project_id, status_akses);

CREATE INDEX idx_pm_user ON public.project_members USING btree (user_id);

CREATE INDEX idx_projects_pembuat ON public.projects USING btree (pembuat_id);

CREATE INDEX idx_ps_task ON public.pomodoro_sessions USING btree (task_id);

CREATE INDEX idx_ps_user ON public.pomodoro_sessions USING btree (user_id);

CREATE INDEX idx_ta_task ON public.task_assignees USING btree (task_id);

CREATE INDEX idx_ta_user ON public.task_assignees USING btree (user_id);

CREATE INDEX idx_tasks_created_by ON public.tasks USING btree (created_by);

CREATE INDEX idx_tasks_kuadran ON public.tasks USING btree (project_id, kuadran_eisenhower) WHERE (status_tugas = ANY (ARRAY['accept'::text, 'done'::text]));

CREATE INDEX idx_tasks_project ON public.tasks USING btree (project_id);

CREATE INDEX idx_tasks_status ON public.tasks USING btree (project_id, status_tugas);

CREATE INDEX idx_teams_manajer ON public.teams USING btree (manajer_id);

CREATE INDEX idx_tm_team ON public.team_members USING btree (team_id);

CREATE INDEX idx_tm_user ON public.team_members USING btree (user_id);

CREATE INDEX idx_tpl_task ON public.task_progress_logs USING btree (task_id);

CREATE INDEX idx_tpl_user ON public.task_progress_logs USING btree (logged_by);

CREATE UNIQUE INDEX kudos_pkey ON public.kudos USING btree (id);

CREATE UNIQUE INDEX notifications_pkey ON public.notifications USING btree (id);

CREATE UNIQUE INDEX pomodoro_sessions_pkey ON public.pomodoro_sessions USING btree (id);

CREATE UNIQUE INDEX profiles_email_key ON public.profiles USING btree (email);

CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id);

CREATE UNIQUE INDEX project_members_pkey ON public.project_members USING btree (id);

CREATE UNIQUE INDEX project_members_project_id_user_id_key ON public.project_members USING btree (project_id, user_id);

CREATE UNIQUE INDEX projects_pkey ON public.projects USING btree (id);

CREATE UNIQUE INDEX task_assignees_pkey ON public.task_assignees USING btree (id);

CREATE UNIQUE INDEX task_assignees_task_id_user_id_key ON public.task_assignees USING btree (task_id, user_id);

CREATE UNIQUE INDEX task_progress_logs_pkey ON public.task_progress_logs USING btree (id);

CREATE UNIQUE INDEX tasks_pkey ON public.tasks USING btree (id);

CREATE UNIQUE INDEX team_members_pkey ON public.team_members USING btree (id);

CREATE UNIQUE INDEX team_members_team_id_user_id_key ON public.team_members USING btree (team_id, user_id);

CREATE UNIQUE INDEX teams_manajer_id_nama_tim_key ON public.teams USING btree (manajer_id, nama_tim);

CREATE UNIQUE INDEX teams_pkey ON public.teams USING btree (id);

alter table "public"."kudos" add constraint "kudos_pkey" PRIMARY KEY using index "kudos_pkey";

alter table "public"."notifications" add constraint "notifications_pkey" PRIMARY KEY using index "notifications_pkey";

alter table "public"."pomodoro_sessions" add constraint "pomodoro_sessions_pkey" PRIMARY KEY using index "pomodoro_sessions_pkey";

alter table "public"."profiles" add constraint "profiles_pkey" PRIMARY KEY using index "profiles_pkey";

alter table "public"."project_members" add constraint "project_members_pkey" PRIMARY KEY using index "project_members_pkey";

alter table "public"."projects" add constraint "projects_pkey" PRIMARY KEY using index "projects_pkey";

alter table "public"."task_assignees" add constraint "task_assignees_pkey" PRIMARY KEY using index "task_assignees_pkey";

alter table "public"."task_progress_logs" add constraint "task_progress_logs_pkey" PRIMARY KEY using index "task_progress_logs_pkey";

alter table "public"."tasks" add constraint "tasks_pkey" PRIMARY KEY using index "tasks_pkey";

alter table "public"."team_members" add constraint "team_members_pkey" PRIMARY KEY using index "team_members_pkey";

alter table "public"."teams" add constraint "teams_pkey" PRIMARY KEY using index "teams_pkey";

alter table "public"."kudos" add constraint "chk_no_self_kudos" CHECK ((pengirim_id <> penerima_id)) not valid;

alter table "public"."kudos" validate constraint "chk_no_self_kudos";

alter table "public"."kudos" add constraint "kudos_penerima_id_fkey" FOREIGN KEY (penerima_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."kudos" validate constraint "kudos_penerima_id_fkey";

alter table "public"."kudos" add constraint "kudos_pengirim_id_fkey" FOREIGN KEY (pengirim_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."kudos" validate constraint "kudos_pengirim_id_fkey";

alter table "public"."kudos" add constraint "kudos_pesan_apresiasi_check" CHECK ((char_length(pesan_apresiasi) <= 500)) not valid;

alter table "public"."kudos" validate constraint "kudos_pesan_apresiasi_check";

alter table "public"."kudos" add constraint "kudos_project_id_fkey" FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE not valid;

alter table "public"."kudos" validate constraint "kudos_project_id_fkey";

alter table "public"."kudos" add constraint "kudos_reaksi_emoji_check" CHECK ((char_length(reaksi_emoji) <= 10)) not valid;

alter table "public"."kudos" validate constraint "kudos_reaksi_emoji_check";

alter table "public"."kudos" add constraint "kudos_task_id_fkey" FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE SET NULL not valid;

alter table "public"."kudos" validate constraint "kudos_task_id_fkey";

alter table "public"."notifications" add constraint "chk_read_at" CHECK (((is_read = false) OR (read_at IS NOT NULL))) not valid;

alter table "public"."notifications" validate constraint "chk_read_at";

alter table "public"."notifications" add constraint "notifications_link_type_check" CHECK ((link_type = ANY (ARRAY['task'::text, 'project'::text, 'kudos'::text]))) not valid;

alter table "public"."notifications" validate constraint "notifications_link_type_check";

alter table "public"."notifications" add constraint "notifications_peran_penerima_check" CHECK ((peran_penerima = ANY (ARRAY['manager'::text, 'member'::text]))) not valid;

alter table "public"."notifications" validate constraint "notifications_peran_penerima_check";

alter table "public"."notifications" add constraint "notifications_project_id_fkey" FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE not valid;

alter table "public"."notifications" validate constraint "notifications_project_id_fkey";

alter table "public"."notifications" add constraint "notifications_tipe_notifikasi_check" CHECK ((tipe_notifikasi = ANY (ARRAY['task_submitted'::text, 'task_accepted'::text, 'task_rejected'::text, 'task_done'::text, 'kudos_received'::text, 'project_invite'::text, 'access_revoked'::text]))) not valid;

alter table "public"."notifications" validate constraint "notifications_tipe_notifikasi_check";

alter table "public"."notifications" add constraint "notifications_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."notifications" validate constraint "notifications_user_id_fkey";

alter table "public"."pomodoro_sessions" add constraint "chk_ended_after_start" CHECK (((ended_at IS NULL) OR (ended_at > started_at))) not valid;

alter table "public"."pomodoro_sessions" validate constraint "chk_ended_after_start";

alter table "public"."pomodoro_sessions" add constraint "chk_ended_if_done" CHECK (((status = 'running'::text) OR (ended_at IS NOT NULL))) not valid;

alter table "public"."pomodoro_sessions" validate constraint "chk_ended_if_done";

alter table "public"."pomodoro_sessions" add constraint "pomodoro_sessions_durasi_menit_check" CHECK (((durasi_menit >= 5) AND (durasi_menit <= 120))) not valid;

alter table "public"."pomodoro_sessions" validate constraint "pomodoro_sessions_durasi_menit_check";

alter table "public"."pomodoro_sessions" add constraint "pomodoro_sessions_status_check" CHECK ((status = ANY (ARRAY['running'::text, 'completed'::text, 'interrupted'::text]))) not valid;

alter table "public"."pomodoro_sessions" validate constraint "pomodoro_sessions_status_check";

alter table "public"."pomodoro_sessions" add constraint "pomodoro_sessions_task_id_fkey" FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE not valid;

alter table "public"."pomodoro_sessions" validate constraint "pomodoro_sessions_task_id_fkey";

alter table "public"."pomodoro_sessions" add constraint "pomodoro_sessions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."pomodoro_sessions" validate constraint "pomodoro_sessions_user_id_fkey";

alter table "public"."profiles" add constraint "profiles_bio_check" CHECK ((char_length(bio) <= 300)) not valid;

alter table "public"."profiles" validate constraint "profiles_bio_check";

alter table "public"."profiles" add constraint "profiles_email_check" CHECK ((email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'::text)) not valid;

alter table "public"."profiles" validate constraint "profiles_email_check";

alter table "public"."profiles" add constraint "profiles_email_key" UNIQUE using index "profiles_email_key";

alter table "public"."profiles" add constraint "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."profiles" validate constraint "profiles_id_fkey";

alter table "public"."profiles" add constraint "profiles_nama_check" CHECK ((char_length(TRIM(BOTH FROM nama)) >= 2)) not valid;

alter table "public"."profiles" validate constraint "profiles_nama_check";

alter table "public"."project_members" add constraint "project_members_invited_by_fkey" FOREIGN KEY (invited_by) REFERENCES public.profiles(id) ON DELETE SET NULL not valid;

alter table "public"."project_members" validate constraint "project_members_invited_by_fkey";

alter table "public"."project_members" add constraint "project_members_project_id_fkey" FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE not valid;

alter table "public"."project_members" validate constraint "project_members_project_id_fkey";

alter table "public"."project_members" add constraint "project_members_project_id_user_id_key" UNIQUE using index "project_members_project_id_user_id_key";

alter table "public"."project_members" add constraint "project_members_status_akses_check" CHECK ((status_akses = ANY (ARRAY['aktif'::text, 'non-aktif'::text]))) not valid;

alter table "public"."project_members" validate constraint "project_members_status_akses_check";

alter table "public"."project_members" add constraint "project_members_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."project_members" validate constraint "project_members_user_id_fkey";

alter table "public"."projects" add constraint "projects_nama_proyek_check" CHECK ((char_length(TRIM(BOTH FROM nama_proyek)) >= 3)) not valid;

alter table "public"."projects" validate constraint "projects_nama_proyek_check";

alter table "public"."projects" add constraint "projects_pembuat_id_fkey" FOREIGN KEY (pembuat_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."projects" validate constraint "projects_pembuat_id_fkey";

alter table "public"."task_assignees" add constraint "task_assignees_assigned_by_fkey" FOREIGN KEY (assigned_by) REFERENCES public.profiles(id) ON DELETE SET NULL not valid;

alter table "public"."task_assignees" validate constraint "task_assignees_assigned_by_fkey";

alter table "public"."task_assignees" add constraint "task_assignees_task_id_fkey" FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE not valid;

alter table "public"."task_assignees" validate constraint "task_assignees_task_id_fkey";

alter table "public"."task_assignees" add constraint "task_assignees_task_id_user_id_key" UNIQUE using index "task_assignees_task_id_user_id_key";

alter table "public"."task_assignees" add constraint "task_assignees_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."task_assignees" validate constraint "task_assignees_user_id_fkey";

alter table "public"."task_progress_logs" add constraint "task_progress_logs_catatan_check" CHECK ((char_length(TRIM(BOTH FROM catatan)) >= 1)) not valid;

alter table "public"."task_progress_logs" validate constraint "task_progress_logs_catatan_check";

alter table "public"."task_progress_logs" add constraint "task_progress_logs_logged_by_fkey" FOREIGN KEY (logged_by) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."task_progress_logs" validate constraint "task_progress_logs_logged_by_fkey";

alter table "public"."task_progress_logs" add constraint "task_progress_logs_persen_selesai_check" CHECK (((persen_selesai >= 0) AND (persen_selesai <= 100))) not valid;

alter table "public"."task_progress_logs" validate constraint "task_progress_logs_persen_selesai_check";

alter table "public"."task_progress_logs" add constraint "task_progress_logs_task_id_fkey" FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE not valid;

alter table "public"."task_progress_logs" validate constraint "task_progress_logs_task_id_fkey";

alter table "public"."tasks" add constraint "chk_done_at" CHECK (((status_tugas <> 'done'::text) OR (done_at IS NOT NULL))) not valid;

alter table "public"."tasks" validate constraint "chk_done_at";

alter table "public"."tasks" add constraint "chk_kuadran_required" CHECK (((status_tugas <> ALL (ARRAY['accept'::text, 'done'::text])) OR (kuadran_eisenhower IS NOT NULL))) not valid;

alter table "public"."tasks" validate constraint "chk_kuadran_required";

alter table "public"."tasks" add constraint "tasks_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.profiles(id) ON DELETE RESTRICT not valid;

alter table "public"."tasks" validate constraint "tasks_created_by_fkey";

alter table "public"."tasks" add constraint "tasks_durasi_pomodoro_check" CHECK (((durasi_pomodoro >= 5) AND (durasi_pomodoro <= 120))) not valid;

alter table "public"."tasks" validate constraint "tasks_durasi_pomodoro_check";

alter table "public"."tasks" add constraint "tasks_judul_tugas_check" CHECK ((char_length(TRIM(BOTH FROM judul_tugas)) >= 3)) not valid;

alter table "public"."tasks" validate constraint "tasks_judul_tugas_check";

alter table "public"."tasks" add constraint "tasks_kuadran_eisenhower_check" CHECK ((kuadran_eisenhower = ANY (ARRAY['Q1'::text, 'Q2'::text, 'Q3'::text, 'Q4'::text]))) not valid;

alter table "public"."tasks" validate constraint "tasks_kuadran_eisenhower_check";

alter table "public"."tasks" add constraint "tasks_project_id_fkey" FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE not valid;

alter table "public"."tasks" validate constraint "tasks_project_id_fkey";

alter table "public"."tasks" add constraint "tasks_status_tugas_check" CHECK ((status_tugas = ANY (ARRAY['draft'::text, 'review'::text, 'accept'::text, 'done'::text]))) not valid;

alter table "public"."tasks" validate constraint "tasks_status_tugas_check";

alter table "public"."team_members" add constraint "team_members_team_id_fkey" FOREIGN KEY (team_id) REFERENCES public.teams(id) ON DELETE CASCADE not valid;

alter table "public"."team_members" validate constraint "team_members_team_id_fkey";

alter table "public"."team_members" add constraint "team_members_team_id_user_id_key" UNIQUE using index "team_members_team_id_user_id_key";

alter table "public"."team_members" add constraint "team_members_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."team_members" validate constraint "team_members_user_id_fkey";

alter table "public"."teams" add constraint "teams_manajer_id_fkey" FOREIGN KEY (manajer_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."teams" validate constraint "teams_manajer_id_fkey";

alter table "public"."teams" add constraint "teams_manajer_id_nama_tim_key" UNIQUE using index "teams_manajer_id_nama_tim_key";

alter table "public"."teams" add constraint "teams_nama_tim_check" CHECK ((char_length(TRIM(BOTH FROM nama_tim)) >= 2)) not valid;

alter table "public"."teams" validate constraint "teams_nama_tim_check";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.chk_project_owner_as_member()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  if new.user_id = (select pembuat_id from projects where id = new.project_id) then
    raise exception 'Pembuat proyek tidak diperbolehkan mendaftar sebagai anggota biasa di proyek miliknya sendiri.';
  end if;
  return new;
end;
$function$
;

create or replace view "public"."eisenhower_matrix" as  SELECT t.project_id,
    t.kuadran_eisenhower,
    t.id AS task_id,
    t.judul_tugas,
    t.status_tugas,
    t.deadline,
    t.durasi_pomodoro,
    array_agg(ta.user_id) AS assignee_ids
   FROM (public.tasks t
     LEFT JOIN public.task_assignees ta ON ((ta.task_id = t.id)))
  WHERE (t.status_tugas = ANY (ARRAY['accept'::text, 'done'::text]))
  GROUP BY t.project_id, t.kuadran_eisenhower, t.id, t.judul_tugas, t.status_tugas, t.deadline, t.durasi_pomodoro
  ORDER BY t.kuadran_eisenhower, t.deadline;


CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  insert into public.profiles (id, nama, email, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nama', 'Pengguna Baru'), -- Mengambil nama dari metadata registrasi Flutter
    new.email,
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.is_project_manager(p_project_id uuid, p_user_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
  select exists (
    select 1 from projects
    where id = p_project_id and pembuat_id = p_user_id
  );
$function$
;

CREATE OR REPLACE FUNCTION public.is_project_member(p_project_id uuid, p_user_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
  select exists (
    select 1 from project_members
    where project_id = p_project_id
      and user_id    = p_user_id
      and status_akses = 'aktif'
  );
$function$
;

create or replace view "public"."kudos_leaderboard" as  SELECT k.project_id,
    k.penerima_id,
    p.nama,
    p.avatar_url,
    count(*) AS total_kudos,
    array_agg(DISTINCT k.reaksi_emoji) FILTER (WHERE (k.reaksi_emoji IS NOT NULL)) AS emojis
   FROM (public.kudos k
     JOIN public.profiles p ON ((p.id = k.penerima_id)))
  GROUP BY k.project_id, k.penerima_id, p.nama, p.avatar_url;


CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$function$
;

grant delete on table "public"."kudos" to "anon";

grant insert on table "public"."kudos" to "anon";

grant references on table "public"."kudos" to "anon";

grant select on table "public"."kudos" to "anon";

grant trigger on table "public"."kudos" to "anon";

grant truncate on table "public"."kudos" to "anon";

grant update on table "public"."kudos" to "anon";

grant delete on table "public"."kudos" to "authenticated";

grant insert on table "public"."kudos" to "authenticated";

grant references on table "public"."kudos" to "authenticated";

grant select on table "public"."kudos" to "authenticated";

grant trigger on table "public"."kudos" to "authenticated";

grant truncate on table "public"."kudos" to "authenticated";

grant update on table "public"."kudos" to "authenticated";

grant delete on table "public"."kudos" to "service_role";

grant insert on table "public"."kudos" to "service_role";

grant references on table "public"."kudos" to "service_role";

grant select on table "public"."kudos" to "service_role";

grant trigger on table "public"."kudos" to "service_role";

grant truncate on table "public"."kudos" to "service_role";

grant update on table "public"."kudos" to "service_role";

grant delete on table "public"."notifications" to "anon";

grant insert on table "public"."notifications" to "anon";

grant references on table "public"."notifications" to "anon";

grant select on table "public"."notifications" to "anon";

grant trigger on table "public"."notifications" to "anon";

grant truncate on table "public"."notifications" to "anon";

grant update on table "public"."notifications" to "anon";

grant delete on table "public"."notifications" to "authenticated";

grant insert on table "public"."notifications" to "authenticated";

grant references on table "public"."notifications" to "authenticated";

grant select on table "public"."notifications" to "authenticated";

grant trigger on table "public"."notifications" to "authenticated";

grant truncate on table "public"."notifications" to "authenticated";

grant update on table "public"."notifications" to "authenticated";

grant delete on table "public"."notifications" to "service_role";

grant insert on table "public"."notifications" to "service_role";

grant references on table "public"."notifications" to "service_role";

grant select on table "public"."notifications" to "service_role";

grant trigger on table "public"."notifications" to "service_role";

grant truncate on table "public"."notifications" to "service_role";

grant update on table "public"."notifications" to "service_role";

grant delete on table "public"."pomodoro_sessions" to "anon";

grant insert on table "public"."pomodoro_sessions" to "anon";

grant references on table "public"."pomodoro_sessions" to "anon";

grant select on table "public"."pomodoro_sessions" to "anon";

grant trigger on table "public"."pomodoro_sessions" to "anon";

grant truncate on table "public"."pomodoro_sessions" to "anon";

grant update on table "public"."pomodoro_sessions" to "anon";

grant delete on table "public"."pomodoro_sessions" to "authenticated";

grant insert on table "public"."pomodoro_sessions" to "authenticated";

grant references on table "public"."pomodoro_sessions" to "authenticated";

grant select on table "public"."pomodoro_sessions" to "authenticated";

grant trigger on table "public"."pomodoro_sessions" to "authenticated";

grant truncate on table "public"."pomodoro_sessions" to "authenticated";

grant update on table "public"."pomodoro_sessions" to "authenticated";

grant delete on table "public"."pomodoro_sessions" to "service_role";

grant insert on table "public"."pomodoro_sessions" to "service_role";

grant references on table "public"."pomodoro_sessions" to "service_role";

grant select on table "public"."pomodoro_sessions" to "service_role";

grant trigger on table "public"."pomodoro_sessions" to "service_role";

grant truncate on table "public"."pomodoro_sessions" to "service_role";

grant update on table "public"."pomodoro_sessions" to "service_role";

grant delete on table "public"."profiles" to "anon";

grant insert on table "public"."profiles" to "anon";

grant references on table "public"."profiles" to "anon";

grant select on table "public"."profiles" to "anon";

grant trigger on table "public"."profiles" to "anon";

grant truncate on table "public"."profiles" to "anon";

grant update on table "public"."profiles" to "anon";

grant delete on table "public"."profiles" to "authenticated";

grant insert on table "public"."profiles" to "authenticated";

grant references on table "public"."profiles" to "authenticated";

grant select on table "public"."profiles" to "authenticated";

grant trigger on table "public"."profiles" to "authenticated";

grant truncate on table "public"."profiles" to "authenticated";

grant update on table "public"."profiles" to "authenticated";

grant delete on table "public"."profiles" to "service_role";

grant insert on table "public"."profiles" to "service_role";

grant references on table "public"."profiles" to "service_role";

grant select on table "public"."profiles" to "service_role";

grant trigger on table "public"."profiles" to "service_role";

grant truncate on table "public"."profiles" to "service_role";

grant update on table "public"."profiles" to "service_role";

grant delete on table "public"."project_members" to "anon";

grant insert on table "public"."project_members" to "anon";

grant references on table "public"."project_members" to "anon";

grant select on table "public"."project_members" to "anon";

grant trigger on table "public"."project_members" to "anon";

grant truncate on table "public"."project_members" to "anon";

grant update on table "public"."project_members" to "anon";

grant delete on table "public"."project_members" to "authenticated";

grant insert on table "public"."project_members" to "authenticated";

grant references on table "public"."project_members" to "authenticated";

grant select on table "public"."project_members" to "authenticated";

grant trigger on table "public"."project_members" to "authenticated";

grant truncate on table "public"."project_members" to "authenticated";

grant update on table "public"."project_members" to "authenticated";

grant delete on table "public"."project_members" to "service_role";

grant insert on table "public"."project_members" to "service_role";

grant references on table "public"."project_members" to "service_role";

grant select on table "public"."project_members" to "service_role";

grant trigger on table "public"."project_members" to "service_role";

grant truncate on table "public"."project_members" to "service_role";

grant update on table "public"."project_members" to "service_role";

grant delete on table "public"."projects" to "anon";

grant insert on table "public"."projects" to "anon";

grant references on table "public"."projects" to "anon";

grant select on table "public"."projects" to "anon";

grant trigger on table "public"."projects" to "anon";

grant truncate on table "public"."projects" to "anon";

grant update on table "public"."projects" to "anon";

grant delete on table "public"."projects" to "authenticated";

grant insert on table "public"."projects" to "authenticated";

grant references on table "public"."projects" to "authenticated";

grant select on table "public"."projects" to "authenticated";

grant trigger on table "public"."projects" to "authenticated";

grant truncate on table "public"."projects" to "authenticated";

grant update on table "public"."projects" to "authenticated";

grant delete on table "public"."projects" to "service_role";

grant insert on table "public"."projects" to "service_role";

grant references on table "public"."projects" to "service_role";

grant select on table "public"."projects" to "service_role";

grant trigger on table "public"."projects" to "service_role";

grant truncate on table "public"."projects" to "service_role";

grant update on table "public"."projects" to "service_role";

grant delete on table "public"."task_assignees" to "anon";

grant insert on table "public"."task_assignees" to "anon";

grant references on table "public"."task_assignees" to "anon";

grant select on table "public"."task_assignees" to "anon";

grant trigger on table "public"."task_assignees" to "anon";

grant truncate on table "public"."task_assignees" to "anon";

grant update on table "public"."task_assignees" to "anon";

grant delete on table "public"."task_assignees" to "authenticated";

grant insert on table "public"."task_assignees" to "authenticated";

grant references on table "public"."task_assignees" to "authenticated";

grant select on table "public"."task_assignees" to "authenticated";

grant trigger on table "public"."task_assignees" to "authenticated";

grant truncate on table "public"."task_assignees" to "authenticated";

grant update on table "public"."task_assignees" to "authenticated";

grant delete on table "public"."task_assignees" to "service_role";

grant insert on table "public"."task_assignees" to "service_role";

grant references on table "public"."task_assignees" to "service_role";

grant select on table "public"."task_assignees" to "service_role";

grant trigger on table "public"."task_assignees" to "service_role";

grant truncate on table "public"."task_assignees" to "service_role";

grant update on table "public"."task_assignees" to "service_role";

grant delete on table "public"."task_progress_logs" to "anon";

grant insert on table "public"."task_progress_logs" to "anon";

grant references on table "public"."task_progress_logs" to "anon";

grant select on table "public"."task_progress_logs" to "anon";

grant trigger on table "public"."task_progress_logs" to "anon";

grant truncate on table "public"."task_progress_logs" to "anon";

grant update on table "public"."task_progress_logs" to "anon";

grant delete on table "public"."task_progress_logs" to "authenticated";

grant insert on table "public"."task_progress_logs" to "authenticated";

grant references on table "public"."task_progress_logs" to "authenticated";

grant select on table "public"."task_progress_logs" to "authenticated";

grant trigger on table "public"."task_progress_logs" to "authenticated";

grant truncate on table "public"."task_progress_logs" to "authenticated";

grant update on table "public"."task_progress_logs" to "authenticated";

grant delete on table "public"."task_progress_logs" to "service_role";

grant insert on table "public"."task_progress_logs" to "service_role";

grant references on table "public"."task_progress_logs" to "service_role";

grant select on table "public"."task_progress_logs" to "service_role";

grant trigger on table "public"."task_progress_logs" to "service_role";

grant truncate on table "public"."task_progress_logs" to "service_role";

grant update on table "public"."task_progress_logs" to "service_role";

grant delete on table "public"."tasks" to "anon";

grant insert on table "public"."tasks" to "anon";

grant references on table "public"."tasks" to "anon";

grant select on table "public"."tasks" to "anon";

grant trigger on table "public"."tasks" to "anon";

grant truncate on table "public"."tasks" to "anon";

grant update on table "public"."tasks" to "anon";

grant delete on table "public"."tasks" to "authenticated";

grant insert on table "public"."tasks" to "authenticated";

grant references on table "public"."tasks" to "authenticated";

grant select on table "public"."tasks" to "authenticated";

grant trigger on table "public"."tasks" to "authenticated";

grant truncate on table "public"."tasks" to "authenticated";

grant update on table "public"."tasks" to "authenticated";

grant delete on table "public"."tasks" to "service_role";

grant insert on table "public"."tasks" to "service_role";

grant references on table "public"."tasks" to "service_role";

grant select on table "public"."tasks" to "service_role";

grant trigger on table "public"."tasks" to "service_role";

grant truncate on table "public"."tasks" to "service_role";

grant update on table "public"."tasks" to "service_role";

grant delete on table "public"."team_members" to "anon";

grant insert on table "public"."team_members" to "anon";

grant references on table "public"."team_members" to "anon";

grant select on table "public"."team_members" to "anon";

grant trigger on table "public"."team_members" to "anon";

grant truncate on table "public"."team_members" to "anon";

grant update on table "public"."team_members" to "anon";

grant delete on table "public"."team_members" to "authenticated";

grant insert on table "public"."team_members" to "authenticated";

grant references on table "public"."team_members" to "authenticated";

grant select on table "public"."team_members" to "authenticated";

grant trigger on table "public"."team_members" to "authenticated";

grant truncate on table "public"."team_members" to "authenticated";

grant update on table "public"."team_members" to "authenticated";

grant delete on table "public"."team_members" to "service_role";

grant insert on table "public"."team_members" to "service_role";

grant references on table "public"."team_members" to "service_role";

grant select on table "public"."team_members" to "service_role";

grant trigger on table "public"."team_members" to "service_role";

grant truncate on table "public"."team_members" to "service_role";

grant update on table "public"."team_members" to "service_role";

grant delete on table "public"."teams" to "anon";

grant insert on table "public"."teams" to "anon";

grant references on table "public"."teams" to "anon";

grant select on table "public"."teams" to "anon";

grant trigger on table "public"."teams" to "anon";

grant truncate on table "public"."teams" to "anon";

grant update on table "public"."teams" to "anon";

grant delete on table "public"."teams" to "authenticated";

grant insert on table "public"."teams" to "authenticated";

grant references on table "public"."teams" to "authenticated";

grant select on table "public"."teams" to "authenticated";

grant trigger on table "public"."teams" to "authenticated";

grant truncate on table "public"."teams" to "authenticated";

grant update on table "public"."teams" to "authenticated";

grant delete on table "public"."teams" to "service_role";

grant insert on table "public"."teams" to "service_role";

grant references on table "public"."teams" to "service_role";

grant select on table "public"."teams" to "service_role";

grant trigger on table "public"."teams" to "service_role";

grant truncate on table "public"."teams" to "service_role";

grant update on table "public"."teams" to "service_role";


  create policy "kudos: insert_policy"
  on "public"."kudos"
  as permissive
  for insert
  to public
with check (((pengirim_id = auth.uid()) AND (pengirim_id <> penerima_id) AND (public.is_project_manager(project_id, auth.uid()) OR public.is_project_member(project_id, auth.uid()))));



  create policy "kudos: select_policy"
  on "public"."kudos"
  as permissive
  for select
  to public
using ((public.is_project_manager(project_id, auth.uid()) OR public.is_project_member(project_id, auth.uid())));



  create policy "notif: select_policy"
  on "public"."notifications"
  as permissive
  for select
  to public
using ((user_id = auth.uid()));



  create policy "notif: update_policy"
  on "public"."notifications"
  as permissive
  for update
  to public
using ((user_id = auth.uid()));



  create policy "pomodoro: select_policy"
  on "public"."pomodoro_sessions"
  as permissive
  for select
  to public
using (((user_id = auth.uid()) OR public.is_project_manager(( SELECT tasks.project_id
   FROM public.tasks
  WHERE (tasks.id = pomodoro_sessions.task_id)), auth.uid())));



  create policy "pomodoro: write_policy"
  on "public"."pomodoro_sessions"
  as permissive
  for all
  to public
using ((user_id = auth.uid()));



  create policy "profiles: update_self"
  on "public"."profiles"
  as permissive
  for update
  to public
using ((id = auth.uid()));



  create policy "profiles: view_colleagues"
  on "public"."profiles"
  as permissive
  for select
  to public
using (((id = auth.uid()) OR (EXISTS ( SELECT 1
   FROM (public.project_members pm
     JOIN public.project_members pm2 ON ((pm.project_id = pm2.project_id)))
  WHERE ((pm.user_id = auth.uid()) AND (pm2.user_id = profiles.id) AND (pm.status_akses = 'aktif'::text) AND (pm2.status_akses = 'aktif'::text))))));



  create policy "pm: select_policy"
  on "public"."project_members"
  as permissive
  for select
  to public
using ((public.is_project_manager(project_id, auth.uid()) OR public.is_project_member(project_id, auth.uid())));



  create policy "pm: write_policy"
  on "public"."project_members"
  as permissive
  for all
  to public
using (public.is_project_manager(project_id, auth.uid()));



  create policy "projects: access_policy"
  on "public"."projects"
  as permissive
  for select
  to public
using (((pembuat_id = auth.uid()) OR public.is_project_member(id, auth.uid())));



  create policy "projects: creation_policy"
  on "public"."projects"
  as permissive
  for insert
  to public
with check ((pembuat_id = auth.uid()));



  create policy "projects: manager_policy"
  on "public"."projects"
  as permissive
  for all
  to public
using ((pembuat_id = auth.uid()));



  create policy "ta: select_policy"
  on "public"."task_assignees"
  as permissive
  for select
  to public
using (((user_id = auth.uid()) OR public.is_project_manager(( SELECT tasks.project_id
   FROM public.tasks
  WHERE (tasks.id = task_assignees.task_id)), auth.uid())));



  create policy "ta: write_policy"
  on "public"."task_assignees"
  as permissive
  for all
  to public
using (public.is_project_manager(( SELECT tasks.project_id
   FROM public.tasks
  WHERE (tasks.id = task_assignees.task_id)), auth.uid()));



  create policy "logs: insert_policy"
  on "public"."task_progress_logs"
  as permissive
  for insert
  to public
with check (((logged_by = auth.uid()) AND (public.is_project_manager(( SELECT tasks.project_id
   FROM public.tasks
  WHERE (tasks.id = task_progress_logs.task_id)), auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.task_assignees
  WHERE ((task_assignees.task_id = task_progress_logs.task_id) AND (task_assignees.user_id = auth.uid())))))));



  create policy "logs: select_policy"
  on "public"."task_progress_logs"
  as permissive
  for select
  to public
using (((logged_by = auth.uid()) OR public.is_project_manager(( SELECT tasks.project_id
   FROM public.tasks
  WHERE (tasks.id = task_progress_logs.task_id)), auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.task_assignees
  WHERE ((task_assignees.task_id = task_progress_logs.task_id) AND (task_assignees.user_id = auth.uid()))))));



  create policy "tasks: delete_policy"
  on "public"."tasks"
  as permissive
  for delete
  to public
using ((public.is_project_manager(project_id, auth.uid()) OR ((created_by = auth.uid()) AND (status_tugas = 'draft'::text))));



  create policy "tasks: insert_policy"
  on "public"."tasks"
  as permissive
  for insert
  to public
with check (((created_by = auth.uid()) AND (public.is_project_manager(project_id, auth.uid()) OR public.is_project_member(project_id, auth.uid()))));



  create policy "tasks: select_policy"
  on "public"."tasks"
  as permissive
  for select
  to public
using ((public.is_project_manager(project_id, auth.uid()) OR (EXISTS ( SELECT 1
   FROM public.task_assignees
  WHERE ((task_assignees.task_id = tasks.id) AND (task_assignees.user_id = auth.uid())))) OR (created_by = auth.uid())));



  create policy "tasks: update_policy"
  on "public"."tasks"
  as permissive
  for update
  to public
using ((public.is_project_manager(project_id, auth.uid()) OR ((created_by = auth.uid()) AND (status_tugas = ANY (ARRAY['draft'::text, 'review'::text])))));



  create policy "team_members: select_policy"
  on "public"."team_members"
  as permissive
  for select
  to public
using (((EXISTS ( SELECT 1
   FROM public.teams
  WHERE ((teams.id = team_members.team_id) AND (teams.manajer_id = auth.uid())))) OR (user_id = auth.uid())));



  create policy "team_members: write_policy"
  on "public"."team_members"
  as permissive
  for all
  to public
using ((EXISTS ( SELECT 1
   FROM public.teams
  WHERE ((teams.id = team_members.team_id) AND (teams.manajer_id = auth.uid())))));



  create policy "teams: owner_only"
  on "public"."teams"
  as permissive
  for all
  to public
using ((manajer_id = auth.uid()));


CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_project_members_owner_check BEFORE INSERT OR UPDATE ON public.project_members FOR EACH ROW EXECUTE FUNCTION public.chk_project_owner_as_member();

CREATE TRIGGER trg_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_tasks_updated_at BEFORE UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_teams_updated_at BEFORE UPDATE ON public.teams FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


