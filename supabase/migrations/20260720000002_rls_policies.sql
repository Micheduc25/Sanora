-- Row Level Security: every user-owned table is readable and writable only
-- by its owner; reference data is read-only; community tables restrict
-- visibility to membership. Service role (edge functions) bypasses RLS.

alter table public.profiles enable row level security;
alter table public.metric_entries enable row level security;
alter table public.meals enable row level security;
alter table public.habits enable row level security;
alter table public.habit_logs enable row level security;
alter table public.chat_messages enable row level security;
alter table public.reminders enable row level security;
alter table public.workouts enable row level security;
alter table public.foods enable row level security;
alter table public.ai_usage enable row level security;
alter table public.subscriptions enable row level security;
alter table public.friendships enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.challenges enable row level security;
alter table public.challenge_participants enable row level security;

-- Owner-only CRUD, applied uniformly to personal-data tables.
do $$
declare
  t text;
begin
  foreach t in array array[
    'profiles', 'metric_entries', 'meals', 'habits', 'habit_logs',
    'chat_messages', 'reminders', 'workouts'
  ]
  loop
    execute format($f$
      create policy "%1$s_select_own" on public.%1$I
        for select using (auth.uid() = user_id);
      create policy "%1$s_insert_own" on public.%1$I
        for insert with check (auth.uid() = user_id);
      create policy "%1$s_update_own" on public.%1$I
        for update using (auth.uid() = user_id)
        with check (auth.uid() = user_id);
      create policy "%1$s_delete_own" on public.%1$I
        for delete using (auth.uid() = user_id);
    $f$, t);
  end loop;
end;
$$;

create policy "foods_read_all" on public.foods
  for select to authenticated, anon using (true);

create policy "ai_usage_read_own" on public.ai_usage
  for select using (auth.uid() = user_id);

create policy "subscriptions_read_own" on public.subscriptions
  for select using (auth.uid() = user_id);

-- Friendships: either side can see the row; only the requester creates it;
-- only the addressee accepts/blocks; either side can end it.
create policy "friendships_select" on public.friendships
  for select using (auth.uid() in (requester_id, addressee_id));
create policy "friendships_insert" on public.friendships
  for insert with check (auth.uid() = requester_id);
create policy "friendships_update" on public.friendships
  for update using (auth.uid() = addressee_id)
  with check (auth.uid() = addressee_id);
create policy "friendships_delete" on public.friendships
  for delete using (auth.uid() in (requester_id, addressee_id));

create or replace function public.is_group_member(gid uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from group_members
    where group_id = gid and user_id = auth.uid()
  );
$$;

create policy "groups_select_member_or_public" on public.groups
  for select using (
    not is_private
    or owner_id = auth.uid()
    or public.is_group_member(id)
  );
create policy "groups_insert_own" on public.groups
  for insert with check (auth.uid() = owner_id);
create policy "groups_update_owner" on public.groups
  for update using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);
create policy "groups_delete_owner" on public.groups
  for delete using (auth.uid() = owner_id);

create policy "group_members_select" on public.group_members
  for select using (
    user_id = auth.uid() or public.is_group_member(group_id)
  );
create policy "group_members_join_self" on public.group_members
  for insert with check (auth.uid() = user_id);
create policy "group_members_leave_self" on public.group_members
  for delete using (auth.uid() = user_id);

create policy "challenges_select" on public.challenges
  for select using (
    group_id is null
    or public.is_group_member(group_id)
    or created_by = auth.uid()
  );
create policy "challenges_insert" on public.challenges
  for insert with check (
    auth.uid() = created_by
    and (group_id is null or public.is_group_member(group_id))
  );
create policy "challenges_delete_creator" on public.challenges
  for delete using (auth.uid() = created_by);

create policy "challenge_participants_select" on public.challenge_participants
  for select using (
    user_id = auth.uid()
    or exists (
      select 1 from public.challenges c
      where c.id = challenge_id
        and (c.group_id is null or public.is_group_member(c.group_id))
    )
  );
create policy "challenge_participants_join_self" on public.challenge_participants
  for insert with check (auth.uid() = user_id);
create policy "challenge_participants_update_self" on public.challenge_participants
  for update using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
create policy "challenge_participants_leave_self" on public.challenge_participants
  for delete using (auth.uid() = user_id);

-- Meal photos: users only touch files under their own folder.
create policy "meal_photos_read_own" on storage.objects
  for select using (
    bucket_id = 'meal-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "meal_photos_write_own" on storage.objects
  for insert with check (
    bucket_id = 'meal-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "meal_photos_delete_own" on storage.objects
  for delete using (
    bucket_id = 'meal-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
