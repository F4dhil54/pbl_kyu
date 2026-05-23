-- Create policy to allow authenticated users to insert notifications
create policy "notif: insert_policy"
on "public"."notifications"
as permissive
for insert
to authenticated
with check (true);
