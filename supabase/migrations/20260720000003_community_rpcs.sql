-- Community RPCs.
--
-- profiles is owner-only under RLS, so social features that must reveal a
-- friend's or group-mate's display name go through SECURITY DEFINER
-- functions that first check the caller is actually connected to that user.
-- Everything else (friend requests by email, group/challenge membership) is
-- likewise funnelled through definer functions so the app never needs
-- broader table grants than RLS allows.

create or replace function public.is_connected(a uuid, b uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select a = b
    or exists (
      select 1 from friendships f
      where f.status = 'accepted'
        and ((f.requester_id = a and f.addressee_id = b)
          or (f.requester_id = b and f.addressee_id = a)))
    or exists (
      select 1 from group_members g1
      join group_members g2 on g1.group_id = g2.group_id
      where g1.user_id = a and g2.user_id = b);
$$;

create or replace function public.display_name(uid uuid)
returns text language sql stable security definer set search_path = public as $$
  select case
    when public.is_connected(auth.uid(), uid)
      then nullif((select data->>'name' from profiles where user_id = uid), '')
    else null
  end;
$$;

-- Friend requests -----------------------------------------------------------

create or replace function public.send_friend_request(p_email text)
returns text language plpgsql security definer
set search_path = public, auth as $$
declare
  target uuid;
begin
  select id into target from auth.users where lower(email) = lower(trim(p_email));
  if target is null then return 'not_found'; end if;
  if target = auth.uid() then return 'self'; end if;
  if exists (
    select 1 from friendships
    where status = 'accepted'
      and ((requester_id = auth.uid() and addressee_id = target)
        or (requester_id = target and addressee_id = auth.uid()))
  ) then
    return 'already_friends';
  end if;
  insert into friendships (requester_id, addressee_id, status)
  values (auth.uid(), target, 'pending')
  on conflict (requester_id, addressee_id) do nothing;
  return 'ok';
end;
$$;

create or replace function public.respond_friend_request(p_requester uuid, p_accept boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_accept then
    update friendships set status = 'accepted'
    where requester_id = p_requester and addressee_id = auth.uid()
      and status = 'pending';
  else
    delete from friendships
    where requester_id = p_requester and addressee_id = auth.uid();
  end if;
end;
$$;

create or replace function public.remove_friend(p_other uuid)
returns void language sql security definer set search_path = public as $$
  delete from friendships
  where (requester_id = auth.uid() and addressee_id = p_other)
     or (requester_id = p_other and addressee_id = auth.uid());
$$;

create or replace function public.my_friends()
returns table(user_id uuid, name text, status text, incoming boolean)
language sql stable security definer set search_path = public as $$
  select
    other.id,
    nullif((select data->>'name' from profiles p where p.user_id = other.id), ''),
    f.status,
    (f.addressee_id = auth.uid() and f.status = 'pending')
  from friendships f
  cross join lateral (
    select case when f.requester_id = auth.uid()
      then f.addressee_id else f.requester_id end as id
  ) other
  where auth.uid() in (f.requester_id, f.addressee_id)
  order by f.status, f.created_at desc;
$$;

-- Groups --------------------------------------------------------------------

create or replace function public.create_group(
  p_name text, p_description text, p_private boolean)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  gid uuid;
begin
  insert into groups (name, description, owner_id, is_private)
  values (p_name, coalesce(p_description, ''), auth.uid(), p_private)
  returning id into gid;
  insert into group_members (group_id, user_id, role)
  values (gid, auth.uid(), 'owner');
  return gid;
end;
$$;

create or replace function public.join_group(p_group uuid)
returns void language sql security definer set search_path = public as $$
  insert into group_members (group_id, user_id, role)
  values (p_group, auth.uid(), 'member')
  on conflict (group_id, user_id) do nothing;
$$;

create or replace function public.leave_group(p_group uuid)
returns void language sql security definer set search_path = public as $$
  delete from group_members
  where group_id = p_group and user_id = auth.uid() and role <> 'owner';
$$;

create or replace function public.my_groups()
returns table(
  id uuid, name text, description text, is_private boolean,
  member_count bigint, is_owner boolean)
language sql stable security definer set search_path = public as $$
  select g.id, g.name, g.description, g.is_private,
    (select count(*) from group_members m where m.group_id = g.id),
    g.owner_id = auth.uid()
  from groups g
  join group_members gm on gm.group_id = g.id and gm.user_id = auth.uid()
  order by g.created_at desc;
$$;

create or replace function public.discover_groups()
returns table(id uuid, name text, description text, member_count bigint)
language sql stable security definer set search_path = public as $$
  select g.id, g.name, g.description,
    (select count(*) from group_members m where m.group_id = g.id)
  from groups g
  where not g.is_private
    and not exists (
      select 1 from group_members gm
      where gm.group_id = g.id and gm.user_id = auth.uid())
  order by g.created_at desc
  limit 50;
$$;

-- Challenges ----------------------------------------------------------------

create or replace function public.create_challenge(
  p_group uuid, p_name text, p_metric text, p_target double precision,
  p_starts date, p_ends date)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  cid uuid;
begin
  if p_group is not null and not public.is_group_member(p_group) then
    raise exception 'not a member of the group';
  end if;
  insert into challenges (group_id, name, metric, target, starts_on, ends_on, created_by)
  values (p_group, p_name, p_metric, p_target, p_starts, p_ends, auth.uid())
  returning id into cid;
  insert into challenge_participants (challenge_id, user_id)
  values (cid, auth.uid());
  return cid;
end;
$$;

create or replace function public.join_challenge(p_challenge uuid)
returns void language sql security definer set search_path = public as $$
  insert into challenge_participants (challenge_id, user_id)
  values (p_challenge, auth.uid())
  on conflict (challenge_id, user_id) do nothing;
$$;

create or replace function public.set_challenge_progress(
  p_challenge uuid, p_progress double precision)
returns void language sql security definer set search_path = public as $$
  update challenge_participants set progress = p_progress
  where challenge_id = p_challenge and user_id = auth.uid();
$$;

create or replace function public.group_challenges(p_group uuid)
returns table(
  id uuid, name text, metric text, target double precision,
  starts_on date, ends_on date, joined boolean, my_progress double precision)
language sql stable security definer set search_path = public as $$
  select c.id, c.name, c.metric, c.target, c.starts_on, c.ends_on,
    exists (select 1 from challenge_participants p
      where p.challenge_id = c.id and p.user_id = auth.uid()),
    coalesce((select progress from challenge_participants p
      where p.challenge_id = c.id and p.user_id = auth.uid()), 0)
  from challenges c
  where c.group_id = p_group and public.is_group_member(p_group)
  order by c.ends_on desc;
$$;

create or replace function public.challenge_leaderboard(p_challenge uuid)
returns table(user_id uuid, name text, progress double precision, place bigint)
language sql stable security definer set search_path = public as $$
  select cp.user_id,
    coalesce(nullif((select data->>'name' from profiles p where p.user_id = cp.user_id), ''), 'Member'),
    cp.progress,
    rank() over (order by cp.progress desc)
  from challenge_participants cp
  where cp.challenge_id = p_challenge
    and exists (
      select 1 from challenges c
      where c.id = p_challenge
        and (c.group_id is null
          or public.is_group_member(c.group_id)
          or c.created_by = auth.uid()));
$$;
