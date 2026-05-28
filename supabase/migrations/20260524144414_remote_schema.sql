revoke delete on table "public"."task_assignments" from "anon";

revoke insert on table "public"."task_assignments" from "anon";

revoke references on table "public"."task_assignments" from "anon";

revoke select on table "public"."task_assignments" from "anon";

revoke trigger on table "public"."task_assignments" from "anon";

revoke truncate on table "public"."task_assignments" from "anon";

revoke update on table "public"."task_assignments" from "anon";

revoke delete on table "public"."task_assignments" from "authenticated";

revoke insert on table "public"."task_assignments" from "authenticated";

revoke references on table "public"."task_assignments" from "authenticated";

revoke select on table "public"."task_assignments" from "authenticated";

revoke trigger on table "public"."task_assignments" from "authenticated";

revoke truncate on table "public"."task_assignments" from "authenticated";

revoke update on table "public"."task_assignments" from "authenticated";

revoke delete on table "public"."task_assignments" from "service_role";

revoke insert on table "public"."task_assignments" from "service_role";

revoke references on table "public"."task_assignments" from "service_role";

revoke select on table "public"."task_assignments" from "service_role";

revoke trigger on table "public"."task_assignments" from "service_role";

revoke truncate on table "public"."task_assignments" from "service_role";

revoke update on table "public"."task_assignments" from "service_role";

alter table "public"."task_assignees" drop constraint "task_assignees_task_id_user_id_key";

alter table "public"."task_assignments" drop constraint "task_assignments_task_id_fkey";

alter table "public"."task_assignments" drop constraint "task_assignments_user_id_fkey";

alter table "public"."task_assignments" drop constraint "unique_task_assignment";

alter table "public"."tasks" drop constraint "chk_kuadran_required";

alter table "public"."tasks" drop constraint "tasks_kuadran_eisenhower_check";

alter table "public"."notifications" drop constraint "notifications_tipe_notifikasi_check";

drop view if exists "public"."eisenhower_matrix";

alter table "public"."task_assignments" drop constraint "task_assignments_pkey";

drop index if exists "public"."task_assignees_task_id_user_id_key";

drop index if exists "public"."task_assignments_pkey";

drop index if exists "public"."unique_task_assignment";

drop table "public"."task_assignments";


  create table "public"."project_teams" (
    "id" uuid not null default gen_random_uuid(),
    "project_id" uuid not null,
    "team_id" uuid not null,
    "assigned_at" timestamp with time zone not null default timezone('utc'::text, now())
      );


alter table "public"."notifications" add column "sender_id" uuid;

alter table "public"."task_assignees" add column "project_member_id" uuid;

alter table "public"."task_assignees" add column "project_team_id" uuid;

alter table "public"."task_assignees" alter column "user_id" drop not null;

alter table "public"."task_progress_logs" add column "hambatan" text;

alter table "public"."task_progress_logs" add column "status_progress" text;

CREATE INDEX idx_pt_project ON public.project_teams USING btree (project_id);

CREATE INDEX idx_pt_team ON public.project_teams USING btree (team_id);

CREATE INDEX idx_ta_project_member ON public.task_assignees USING btree (project_member_id);

CREATE INDEX idx_ta_project_team ON public.task_assignees USING btree (project_team_id);

CREATE INDEX idx_tpl_created_at_desc ON public.task_progress_logs USING btree (created_at DESC);

CREATE UNIQUE INDEX project_teams_pkey ON public.project_teams USING btree (id);

CREATE UNIQUE INDEX project_teams_project_id_team_id_key ON public.project_teams USING btree (project_id, team_id);

alter table "public"."project_teams" add constraint "project_teams_pkey" PRIMARY KEY using index "project_teams_pkey";

alter table "public"."notifications" add constraint "notifications_sender_id_fkey" FOREIGN KEY (sender_id) REFERENCES public.profiles(id) ON DELETE SET NULL not valid;

alter table "public"."notifications" validate constraint "notifications_sender_id_fkey";

alter table "public"."project_teams" add constraint "project_teams_project_id_fkey" FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE not valid;

alter table "public"."project_teams" validate constraint "project_teams_project_id_fkey";

alter table "public"."project_teams" add constraint "project_teams_project_id_team_id_key" UNIQUE using index "project_teams_project_id_team_id_key";

alter table "public"."project_teams" add constraint "project_teams_team_id_fkey" FOREIGN KEY (team_id) REFERENCES public.teams(id) ON DELETE CASCADE not valid;

alter table "public"."project_teams" validate constraint "project_teams_team_id_fkey";

alter table "public"."task_assignees" add constraint "task_assignees_project_member_id_fkey" FOREIGN KEY (project_member_id) REFERENCES public.project_members(id) ON DELETE CASCADE not valid;

alter table "public"."task_assignees" validate constraint "task_assignees_project_member_id_fkey";

alter table "public"."task_assignees" add constraint "task_assignees_project_team_id_fkey" FOREIGN KEY (project_team_id) REFERENCES public.project_teams(id) ON DELETE CASCADE not valid;

alter table "public"."task_assignees" validate constraint "task_assignees_project_team_id_fkey";

alter table "public"."task_assignees" add constraint "task_assignees_target_check" CHECK ((((project_member_id IS NOT NULL) AND (project_team_id IS NULL)) OR ((project_member_id IS NULL) AND (project_team_id IS NOT NULL)) OR ((user_id IS NOT NULL) AND (project_member_id IS NULL) AND (project_team_id IS NULL)))) not valid;

alter table "public"."task_assignees" validate constraint "task_assignees_target_check";

alter table "public"."task_progress_logs" add constraint "task_progress_logs_status_progress_check" CHECK ((status_progress = ANY (ARRAY['Akan Dikerjakan'::text, 'Sedang Dikerjakan'::text, 'Selesai Dikerjakan'::text]))) not valid;

alter table "public"."task_progress_logs" validate constraint "task_progress_logs_status_progress_check";

alter table "public"."notifications" add constraint "notifications_tipe_notifikasi_check" CHECK ((tipe_notifikasi = ANY (ARRAY['task_submitted'::text, 'task_accepted'::text, 'task_rejected'::text, 'task_done'::text, 'kudos_received'::text, 'project_invite'::text, 'access_revoked'::text, 'pesan'::text, 'mention'::text, 'undangan'::text, 'tugas'::text, 'proyek'::text, 'kudos'::text]))) not valid;

alter table "public"."notifications" validate constraint "notifications_tipe_notifikasi_check";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.chk_task_assignee_project_match()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_task_project_id UUID;
    v_member_project_id UUID;
    v_team_project_id UUID;
    v_member_user_id UUID;
BEGIN
    -- 1. Ambil ID Proyek dari tugas yang sedang diproses
    SELECT project_id INTO v_task_project_id 
    FROM public.tasks 
    WHERE id = NEW.task_id;

    -- 2. JIKA MENUGASKAN KE INDIVIDU (project_member_id)
    IF NEW.project_member_id IS NOT NULL THEN
        -- Ambil data project_id dan user_id asli dari tabel project_members
        SELECT project_id, user_id INTO v_member_project_id, v_member_user_id 
        FROM public.project_members 
        WHERE id = NEW.project_member_id;

        -- Gembok A: Pastikan anggota tersebut berasal dari proyek yang sama dengan tugasnya
        IF v_task_project_id != v_member_project_id THEN
            RAISE EXCEPTION 'Pelanggaran Keamanan: Anggota ini tidak terdaftar di dalam proyek terkait!';
        END IF;

        -- Gembok B (Sinkronisasi): Jika user_id lama ikut diisi oleh Flutter, pastikan nilainya sama dengan pemilik project_member_id
        IF NEW.user_id IS NOT NULL AND NEW.user_id != v_member_user_id THEN
            RAISE EXCEPTION 'Pelanggaran Integritas: user_id tidak cocok dengan project_member_id yang dipilih!';
        END IF;
    END IF;

    -- 3. JIKA MENUGASKAN KE KELOMPOK TIM (project_team_id)
    IF NEW.project_team_id IS NOT NULL THEN
        -- Ambil data project_id dari tabel project_teams
        SELECT project_id INTO v_team_project_id 
        FROM public.project_teams 
        WHERE id = NEW.project_team_id;

        -- Gembok C: Pastikan kelompok tim tersebut memang sudah diundang ke proyek yang sama dengan tugasnya
        IF v_task_project_id != v_team_project_id THEN
            RAISE EXCEPTION 'Pelanggaran Keamanan: Kelompok Tim ini belum dimasukkan ke dalam proyek terkait!';
        END IF;
    END IF;

    RETURN NEW;
END;
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


grant delete on table "public"."project_teams" to "anon";

grant insert on table "public"."project_teams" to "anon";

grant references on table "public"."project_teams" to "anon";

grant select on table "public"."project_teams" to "anon";

grant trigger on table "public"."project_teams" to "anon";

grant truncate on table "public"."project_teams" to "anon";

grant update on table "public"."project_teams" to "anon";

grant delete on table "public"."project_teams" to "authenticated";

grant insert on table "public"."project_teams" to "authenticated";

grant references on table "public"."project_teams" to "authenticated";

grant select on table "public"."project_teams" to "authenticated";

grant trigger on table "public"."project_teams" to "authenticated";

grant truncate on table "public"."project_teams" to "authenticated";

grant update on table "public"."project_teams" to "authenticated";

grant delete on table "public"."project_teams" to "service_role";

grant insert on table "public"."project_teams" to "service_role";

grant references on table "public"."project_teams" to "service_role";

grant select on table "public"."project_teams" to "service_role";

grant trigger on table "public"."project_teams" to "service_role";

grant truncate on table "public"."project_teams" to "service_role";

grant update on table "public"."project_teams" to "service_role";

CREATE TRIGGER trg_task_assignee_project_check BEFORE INSERT OR UPDATE ON public.task_assignees FOR EACH ROW EXECUTE FUNCTION public.chk_task_assignee_project_match();


