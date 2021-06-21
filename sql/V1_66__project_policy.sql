grant update on project to app_user;

-- Project creator can update his/her projects
create policy project_creator_update on project
for update using (
  id in (select id from project where creator_id = public.get_current_user_id())
);

-- Any logged in user can create a new project
create policy project_app_user_create on project
for insert to app_user with check(true);