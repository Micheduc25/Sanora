-- Group invites.
--
-- A private group is not listed in discover_groups and join_group refuses it
-- outright, so until now one could only ever hold its owner. This is the way
-- in: the owner names someone by the email they signed up with, and that
-- person accepts. Accepting is what writes group_members — join_group stays
-- strict, since an invite is the only exception and it has its own RPC.
--
-- Invites are addressed to a user, not handed out as a shareable code: a code
-- that leaks admits anyone who has it, which is exactly the property a private
-- group is meant not to have.

create table if not exists public.group_invites (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  invited_user uuid not null references auth.users (id) on delete cascade,
  -- Kept alongside the id so the owner's list renders without reading
  -- auth.users; it is the address they typed, so it reveals nothing new.
  invited_email text not null,
  created_by uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '14 days',
  unique (group_id, invited_user)
);

alter table public.group_invites enable row level security;

-- No policies on purpose: every read and write goes through the definer
-- functions below, which check membership. RLS with no policy denies the
-- table to anyone who reaches it another way.

create index if not exists group_invites_invited_user_idx
  on public.group_invites (invited_user);
create index if not exists group_invites_group_idx
  on public.group_invites (group_id);

-- Sending -------------------------------------------------------------------

-- Owner-only. A plain member who could invite would let anyone admitted to a
-- family group quietly widen it, which is the same hole join_group just had.
-- Returns a status code the way send_friend_request does:
-- ok | not_found | self | not_owner | already_member | already_invited | blocked
create or replace function public.invite_to_group(p_group uuid, p_email text)
returns text language plpgsql security definer
set search_path = public, auth as $$
declare
  target uuid;
  address text := lower(trim(coalesce(p_email, '')));
begin
  if not exists (
    select 1 from groups g where g.id = p_group and g.owner_id = auth.uid()
  ) then
    return 'not_owner';
  end if;

  select id into target from auth.users where lower(email) = address;
  if target is null then return 'not_found'; end if;
  if target = auth.uid() then return 'self'; end if;

  if exists (
    select 1 from group_members m
    where m.group_id = p_group and m.user_id = target
  ) then
    return 'already_member';
  end if;

  -- A block is a refusal to be contacted at all; an invite is contact.
  if exists (
    select 1 from friendships f
    where f.status = 'blocked'
      and ((f.requester_id = auth.uid() and f.addressee_id = target)
        or (f.requester_id = target and f.addressee_id = auth.uid()))
  ) then
    return 'blocked';
  end if;

  -- An expired invite is dead but still occupies the unique pair, so clear it
  -- first: re-inviting someone whose invite lapsed has to work.
  delete from group_invites
  where group_id = p_group and invited_user = target and expires_at <= now();

  insert into group_invites (group_id, invited_user, invited_email, created_by)
  values (p_group, target, address, auth.uid())
  on conflict (group_id, invited_user) do nothing;
  if not found then return 'already_invited'; end if;
  return 'ok';
end;
$$;

-- Answering -----------------------------------------------------------------

create or replace function public.accept_group_invite(p_invite uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  gid uuid;
begin
  select group_id into gid from group_invites
  where id = p_invite and invited_user = auth.uid() and expires_at > now();
  if gid is null then
    raise exception 'this invite is no longer valid'
      using errcode = '42501';
  end if;
  insert into group_members (group_id, user_id, role)
  values (gid, auth.uid(), 'member')
  on conflict (group_id, user_id) do nothing;
  delete from group_invites where id = p_invite;
  return gid;
end;
$$;

-- One function for two buttons: the owner revoking an invite they sent and the
-- invitee declining it are the same row disappearing, and each side may only
-- reach their own.
create or replace function public.revoke_group_invite(p_invite uuid)
returns void language sql security definer set search_path = public as $$
  delete from group_invites i
  where i.id = p_invite
    and (i.invited_user = auth.uid()
      or exists (
        select 1 from groups g
        where g.id = i.group_id and g.owner_id = auth.uid()));
$$;

-- Reading -------------------------------------------------------------------

-- The invitee's side: enough about the group to decide, without joining it.
create or replace function public.my_group_invites()
returns table(
  id uuid, group_id uuid, group_name text, group_description text,
  invited_by text, expires_at timestamptz)
language sql stable security definer set search_path = public as $$
  select i.id, g.id, g.name, g.description,
    public.display_name(i.created_by), i.expires_at
  from group_invites i
  join groups g on g.id = i.group_id
  where i.invited_user = auth.uid() and i.expires_at > now()
  order by i.created_at desc;
$$;

-- The owner's side: who is still outstanding on one group.
create or replace function public.group_invites(p_group uuid)
returns table(id uuid, email text, expires_at timestamptz)
language sql stable security definer set search_path = public as $$
  select i.id, i.invited_email, i.expires_at
  from group_invites i
  where i.group_id = p_group
    and i.expires_at > now()
    and exists (
      select 1 from groups g
      where g.id = p_group and g.owner_id = auth.uid())
  order by i.created_at desc;
$$;

-- Grants --------------------------------------------------------------------

revoke execute on function
  public.invite_to_group(uuid, text),
  public.accept_group_invite(uuid),
  public.revoke_group_invite(uuid),
  public.my_group_invites(),
  public.group_invites(uuid)
from public, anon;

grant execute on function
  public.invite_to_group(uuid, text),
  public.accept_group_invite(uuid),
  public.revoke_group_invite(uuid),
  public.my_group_invites(),
  public.group_invites(uuid)
to authenticated;
