-- Community hardening.
--
-- The community RPCs are all SECURITY DEFINER, which means RLS never runs for
-- them: whatever the function does not check, nothing else will. Several of
-- them checked nothing, and the client is not the only thing that can call
-- them. This migration adds the missing membership checks, stops handing out
-- display names to strangers, gives users a way to block each other, and
-- indexes the columns every community read filters on.

-- Membership ----------------------------------------------------------------

-- discover_groups only ever offers public groups, but the RPC took any group
-- id, so a private group was one hand-made request away from being joined.
create or replace function public.join_group(p_group uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (
    select 1 from groups g where g.id = p_group and not g.is_private
  ) then
    raise exception 'this group is invite-only' using errcode = '42501';
  end if;
  insert into group_members (group_id, user_id, role)
  values (p_group, auth.uid(), 'member')
  on conflict (group_id, user_id) do nothing;
end;
$$;

-- create_challenge checks group membership; joining one did not, so any
-- challenge id let an outsider onto a private group's leaderboard.
create or replace function public.join_challenge(p_challenge uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (
    select 1 from challenges c
    where c.id = p_challenge
      and (c.created_by = auth.uid()
        or (c.group_id is not null and public.is_group_member(c.group_id)))
  ) then
    raise exception 'not a member of this challenge' using errcode = '42501';
  end if;
  insert into challenge_participants (challenge_id, user_id)
  values (p_challenge, auth.uid())
  on conflict (challenge_id, user_id) do nothing;
end;
$$;

-- Progress is self-reported, so the floor and the window are all that keeps a
-- leaderboard honest: no negatives, no absurd totals, and nothing backdated
-- into a challenge that has not started or has already finished.
create or replace function public.set_challenge_progress(
  p_challenge uuid, p_progress double precision)
returns void language sql security definer set search_path = public as $$
  update challenge_participants cp
  set progress = least(greatest(coalesce(p_progress, 0), 0), 1e9)
  where cp.challenge_id = p_challenge
    and cp.user_id = auth.uid()
    and exists (
      select 1 from challenges c
      where c.id = p_challenge
        and current_date between c.starts_on and c.ends_on);
$$;

-- Display names -------------------------------------------------------------

-- display_name() has always applied the right rule — a name is visible to an
-- accepted friend or a group-mate — and was never called. These two read the
-- profile directly, which handed a stranger's real name to anyone who typed
-- their email into the add-friend sheet. Unconnected users now come back null
-- and render as "Sanora user".
create or replace function public.my_friends()
returns table(user_id uuid, name text, status text, incoming boolean)
language sql stable security definer set search_path = public as $$
  select
    other.id,
    public.display_name(other.id),
    f.status,
    (f.addressee_id = auth.uid() and f.status = 'pending')
  from friendships f
  cross join lateral (
    select case when f.requester_id = auth.uid()
      then f.addressee_id else f.requester_id end as id
  ) other
  where auth.uid() in (f.requester_id, f.addressee_id)
    -- A block is visible only to whoever made it; the blocked user sees the
    -- friendship simply disappear.
    and (f.status <> 'blocked' or f.requester_id = auth.uid())
  order by f.status, f.created_at desc;
$$;

-- Also: the old `c.group_id is null` branch made every group-less challenge
-- world-readable, and the outer select had no ORDER BY, so the medals landed
-- in whatever order the planner felt like.
create or replace function public.challenge_leaderboard(p_challenge uuid)
returns table(user_id uuid, name text, progress double precision, place bigint)
language sql stable security definer set search_path = public as $$
  -- Aliased throughout: the RETURNS TABLE names are in scope inside the body,
  -- so a bare `place` or `progress` here is ambiguous.
  select r.rb_user_id, r.rb_name, r.rb_progress, r.rb_place
  from (
    select cp.user_id as rb_user_id,
      coalesce(public.display_name(cp.user_id), 'Member') as rb_name,
      cp.progress as rb_progress,
      rank() over (order by cp.progress desc) as rb_place
    from challenge_participants cp
    where cp.challenge_id = p_challenge
      and exists (
        select 1 from challenges c
        where c.id = p_challenge
          and ((c.group_id is not null and public.is_group_member(c.group_id))
            or c.created_by = auth.uid()))
  ) r
  order by r.rb_place, r.rb_progress desc;
$$;

-- Blocking ------------------------------------------------------------------

-- The `blocked` status has existed since the first schema with nothing able to
-- set it. Blocking replaces whatever friendship exists in either direction,
-- and send_friend_request refuses to write over it, so declining and blocking
-- are finally different things.
create or replace function public.block_user(p_other uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_other is null or p_other = auth.uid() then return; end if;
  delete from friendships
  where (requester_id = auth.uid() and addressee_id = p_other)
     or (requester_id = p_other and addressee_id = auth.uid());
  insert into friendships (requester_id, addressee_id, status)
  values (auth.uid(), p_other, 'blocked');
end;
$$;

create or replace function public.unblock_user(p_other uuid)
returns void language sql security definer set search_path = public as $$
  delete from friendships
  where requester_id = auth.uid() and addressee_id = p_other
    and status = 'blocked';
$$;

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
    where status = 'blocked'
      and ((requester_id = auth.uid() and addressee_id = target)
        or (requester_id = target and addressee_id = auth.uid()))
  ) then
    return 'blocked';
  end if;
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

-- Indexes -------------------------------------------------------------------

-- Every community read filters on the trailing half of a composite primary
-- key, which no index can serve.
create index if not exists friendships_addressee_idx
  on public.friendships (addressee_id);
create index if not exists group_members_user_idx
  on public.group_members (user_id);
create index if not exists challenge_participants_user_idx
  on public.challenge_participants (user_id);
create index if not exists challenges_group_idx
  on public.challenges (group_id);
create index if not exists groups_owner_idx
  on public.groups (owner_id);

-- Grants --------------------------------------------------------------------

-- Every one of these needs auth.uid(); an anonymous caller gets nothing useful
-- out of them except discover_groups, which would happily list every public
-- group's name and description to the internet.
revoke execute on function
  public.is_connected(uuid, uuid),
  public.display_name(uuid),
  public.send_friend_request(text),
  public.respond_friend_request(uuid, boolean),
  public.remove_friend(uuid),
  public.block_user(uuid),
  public.unblock_user(uuid),
  public.my_friends(),
  public.create_group(text, text, boolean),
  public.join_group(uuid),
  public.leave_group(uuid),
  public.my_groups(),
  public.discover_groups(),
  public.create_challenge(uuid, text, text, double precision, date, date),
  public.join_challenge(uuid),
  public.set_challenge_progress(uuid, double precision),
  public.group_challenges(uuid),
  public.challenge_leaderboard(uuid)
from public, anon;

grant execute on function
  public.send_friend_request(text),
  public.respond_friend_request(uuid, boolean),
  public.remove_friend(uuid),
  public.block_user(uuid),
  public.unblock_user(uuid),
  public.my_friends(),
  public.create_group(text, text, boolean),
  public.join_group(uuid),
  public.leave_group(uuid),
  public.my_groups(),
  public.discover_groups(),
  public.create_challenge(uuid, text, text, double precision, date, date),
  public.join_challenge(uuid),
  public.set_challenge_progress(uuid, double precision),
  public.group_challenges(uuid),
  public.challenge_leaderboard(uuid)
to authenticated;
