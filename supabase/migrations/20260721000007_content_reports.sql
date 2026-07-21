-- Reporting objectionable content.
--
-- Blocking (20260721000006) lets someone remove another user from their own
-- view; it tells us nothing. App Store Guideline 1.2 wants the other half:
-- a way to flag user-generated content — group names and descriptions,
-- challenge names, the display names on a leaderboard — and a record we can
-- act on. Every report lands here with the reporter attached, so a pattern of
-- reports against one target is a query rather than an investigation.

create table public.content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users (id) on delete cascade,
  target_type text not null check (target_type in ('group', 'challenge', 'user')),
  target_id uuid not null,
  reason text not null
    check (reason in ('spam', 'harassment', 'hate', 'sexual', 'other')),
  note text not null default '',
  status text not null default 'pending'
    check (status in ('pending', 'reviewed', 'actioned', 'dismissed')),
  created_at timestamptz not null default now()
);

-- One open report per person per target: re-reporting updates the reason and
-- the note instead of stacking rows, so the count on a target is the number
-- of people bothered by it and not the number of times one person tapped.
create unique index content_reports_reporter_target_idx
  on public.content_reports (reporter_id, target_type, target_id);

-- Triage reads "everything still pending, worst-reported first".
create index content_reports_triage_idx
  on public.content_reports (status, target_type, target_id);

alter table public.content_reports enable row level security;

-- No policy grants insert: reports are written only through report_content
-- below, which is what checks the target exists and is one the reporter can
-- actually see. Reading your own back is what lets the app say "reported".
create policy "content_reports_select_own" on public.content_reports
  for select using (auth.uid() = reporter_id);

-- Reporting is gated on visibility, not membership: a public group in
-- Discover is reportable before joining it, and a person is reportable if
-- they are connected — a friend, or a group-mate whose name reached a
-- leaderboard. Anything else is a target the reporter could not have seen.
create or replace function public.report_content(
  p_target_type text, p_target_id uuid, p_reason text, p_note text)
returns void language plpgsql security definer set search_path = public as $$
declare
  visible boolean;
begin
  if auth.uid() is null then
    raise exception 'Not signed in.' using errcode = '42501';
  end if;

  visible := case p_target_type
    when 'group' then exists (
      select 1 from groups g
      where g.id = p_target_id
        and (not g.is_private or public.is_group_member(g.id)))
    when 'challenge' then exists (
      select 1 from challenges c
      where c.id = p_target_id
        and (c.created_by = auth.uid()
          or (c.group_id is not null and public.is_group_member(c.group_id))))
    when 'user' then p_target_id <> auth.uid()
      and public.is_connected(auth.uid(), p_target_id)
    else false
  end;

  if not visible then
    raise exception 'there is nothing here to report' using errcode = '42501';
  end if;

  insert into content_reports (reporter_id, target_type, target_id, reason, note)
  values (
    auth.uid(), p_target_type, p_target_id, p_reason,
    -- A note is optional and free text; the cap is what keeps a report a
    -- report.
    left(coalesce(trim(p_note), ''), 1000))
  on conflict (reporter_id, target_type, target_id) do update
    set reason = excluded.reason,
        note = excluded.note,
        status = 'pending',
        created_at = now();
end;
$$;

revoke execute on function public.report_content(text, uuid, text, text)
  from public, anon;
grant execute on function public.report_content(text, uuid, text, text)
  to authenticated;
