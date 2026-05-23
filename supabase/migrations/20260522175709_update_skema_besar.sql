
  create table "public"."task_assignments" (
    "id" uuid not null default gen_random_uuid(),
    "task_id" uuid not null,
    "user_id" uuid not null,
    "assigned_at" timestamp with time zone default timezone('utc'::text, now())
      );



  create table "public"."task_attachments" (
    "id" uuid not null default gen_random_uuid(),
    "task_id" uuid not null,
    "log_id" uuid,
    "tipe_lampiran" text not null,
    "file_path_or_url" text not null,
    "nama_file" text not null,
    "uploaded_at" timestamp with time zone default timezone('utc'::text, now())
      );


alter table "public"."profiles" add column "role" text default 'Tim'::text;

alter table "public"."projects" add column "kategori" text default 'Lainnya'::text;

alter table "public"."projects" add column "progress_persen" integer default 0;

alter table "public"."projects" add column "status_aktif" boolean default true;

alter table "public"."projects" add column "tautan_github" text;

alter table "public"."task_progress_logs" add column "jenis_aksi" text default 'memperbarui'::text;

alter table "public"."task_progress_logs" add column "kudos_by" uuid[] default '{}'::uuid[];

alter table "public"."task_progress_logs" add column "kudos_count" integer default 0;

alter table "public"."tasks" add column "dibuat_oleh_role" text default 'Manajer'::text;

alter table "public"."tasks" add column "keputusan_manajer" text default 'Menunggu'::text;

alter table "public"."tasks" add column "prioritas" text default 'Schedule'::text;

alter table "public"."tasks" add column "scheduled_for" timestamp with time zone;

CREATE INDEX idx_attach_task ON public.task_attachments USING btree (task_id);

CREATE UNIQUE INDEX task_assignments_pkey ON public.task_assignments USING btree (id);

CREATE UNIQUE INDEX task_attachments_pkey ON public.task_attachments USING btree (id);

CREATE UNIQUE INDEX unique_task_assignment ON public.task_assignments USING btree (task_id, user_id);

alter table "public"."task_assignments" add constraint "task_assignments_pkey" PRIMARY KEY using index "task_assignments_pkey";

alter table "public"."task_attachments" add constraint "task_attachments_pkey" PRIMARY KEY using index "task_attachments_pkey";

alter table "public"."projects" add constraint "projects_progress_persen_check" CHECK (((progress_persen >= 0) AND (progress_persen <= 100))) not valid;

alter table "public"."projects" validate constraint "projects_progress_persen_check";

alter table "public"."task_assignments" add constraint "task_assignments_task_id_fkey" FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE not valid;

alter table "public"."task_assignments" validate constraint "task_assignments_task_id_fkey";

alter table "public"."task_assignments" add constraint "task_assignments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."task_assignments" validate constraint "task_assignments_user_id_fkey";

alter table "public"."task_assignments" add constraint "unique_task_assignment" UNIQUE using index "unique_task_assignment";

alter table "public"."task_attachments" add constraint "task_attachments_log_id_fkey" FOREIGN KEY (log_id) REFERENCES public.task_progress_logs(id) ON DELETE CASCADE not valid;

alter table "public"."task_attachments" validate constraint "task_attachments_log_id_fkey";

alter table "public"."task_attachments" add constraint "task_attachments_task_id_fkey" FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE not valid;

alter table "public"."task_attachments" validate constraint "task_attachments_task_id_fkey";

alter table "public"."task_attachments" add constraint "task_attachments_tipe_lampiran_check" CHECK ((tipe_lampiran = ANY (ARRAY['foto'::text, 'file'::text, 'link'::text]))) not valid;

alter table "public"."task_attachments" validate constraint "task_attachments_tipe_lampiran_check";

alter table "public"."tasks" add constraint "tasks_dibuat_oleh_role_check" CHECK ((dibuat_oleh_role = ANY (ARRAY['Manajer'::text, 'Tim'::text]))) not valid;

alter table "public"."tasks" validate constraint "tasks_dibuat_oleh_role_check";

alter table "public"."tasks" add constraint "tasks_keputusan_manajer_check" CHECK ((keputusan_manajer = ANY (ARRAY['Menunggu'::text, 'Setujui'::text, 'Tidak Setujui'::text]))) not valid;

alter table "public"."tasks" validate constraint "tasks_keputusan_manajer_check";

alter table "public"."tasks" add constraint "tasks_prioritas_check" CHECK ((prioritas = ANY (ARRAY['Do'::text, 'Schedule'::text, 'Delegate'::text]))) not valid;

alter table "public"."tasks" validate constraint "tasks_prioritas_check";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  INSERT INTO public.profiles (id, nama, email, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'nama', 'User Baru'),
    new.email,
    COALESCE(new.raw_user_meta_data->>'role', 'Tim') -- <--- Bagian krusial penangkap data role
  );
  RETURN new;
END;
$function$
;

grant delete on table "public"."task_assignments" to "anon";

grant insert on table "public"."task_assignments" to "anon";

grant references on table "public"."task_assignments" to "anon";

grant select on table "public"."task_assignments" to "anon";

grant trigger on table "public"."task_assignments" to "anon";

grant truncate on table "public"."task_assignments" to "anon";

grant update on table "public"."task_assignments" to "anon";

grant delete on table "public"."task_assignments" to "authenticated";

grant insert on table "public"."task_assignments" to "authenticated";

grant references on table "public"."task_assignments" to "authenticated";

grant select on table "public"."task_assignments" to "authenticated";

grant trigger on table "public"."task_assignments" to "authenticated";

grant truncate on table "public"."task_assignments" to "authenticated";

grant update on table "public"."task_assignments" to "authenticated";

grant delete on table "public"."task_assignments" to "service_role";

grant insert on table "public"."task_assignments" to "service_role";

grant references on table "public"."task_assignments" to "service_role";

grant select on table "public"."task_assignments" to "service_role";

grant trigger on table "public"."task_assignments" to "service_role";

grant truncate on table "public"."task_assignments" to "service_role";

grant update on table "public"."task_assignments" to "service_role";

grant delete on table "public"."task_attachments" to "anon";

grant insert on table "public"."task_attachments" to "anon";

grant references on table "public"."task_attachments" to "anon";

grant select on table "public"."task_attachments" to "anon";

grant trigger on table "public"."task_attachments" to "anon";

grant truncate on table "public"."task_attachments" to "anon";

grant update on table "public"."task_attachments" to "anon";

grant delete on table "public"."task_attachments" to "authenticated";

grant insert on table "public"."task_attachments" to "authenticated";

grant references on table "public"."task_attachments" to "authenticated";

grant select on table "public"."task_attachments" to "authenticated";

grant trigger on table "public"."task_attachments" to "authenticated";

grant truncate on table "public"."task_attachments" to "authenticated";

grant update on table "public"."task_attachments" to "authenticated";

grant delete on table "public"."task_attachments" to "service_role";

grant insert on table "public"."task_attachments" to "service_role";

grant references on table "public"."task_attachments" to "service_role";

grant select on table "public"."task_attachments" to "service_role";

grant trigger on table "public"."task_attachments" to "service_role";

grant truncate on table "public"."task_attachments" to "service_role";

grant update on table "public"."task_attachments" to "service_role";


  create policy "Enable read access for own data"
  on "public"."notifications"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "Allow access to avatars 1oj01fe_0"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using ((bucket_id = 'avatars'::text));



  create policy "Allow access to avatars 1oj01fe_1"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using ((bucket_id = 'avatars'::text));



  create policy "Allow access to avatars 1oj01fe_2"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check ((bucket_id = 'avatars'::text));



