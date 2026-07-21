-- Atomic AI metering and self-service account deletion.

-- The edge functions previously read `ai_usage.calls` and wrote back
-- `calls + 1`, so two concurrent requests both read N and both wrote N+1 —
-- the free-tier allowance leaked under exactly the concurrency it exists to
-- limit. Doing the whole thing in one statement closes that window.
--
-- The conditional `where` is what enforces the cap: once the row is at the
-- limit the update matches nothing, `returning` yields no row, and the caller
-- gets false without the counter running away.
create or replace function public.consume_ai_call(
  p_user_id uuid,
  p_limit integer
)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_premium boolean;
  v_calls integer;
begin
  select tier = 'premium' and (valid_until is null or valid_until > now())
    into v_premium
    from public.subscriptions
   where user_id = p_user_id;

  if coalesce(v_premium, false) then
    return true;
  end if;

  insert into public.ai_usage (user_id, day, calls)
  values (p_user_id, current_date, 1)
      on conflict (user_id, day)
      do update set calls = public.ai_usage.calls + 1
       where public.ai_usage.calls < p_limit
   returning calls into v_calls;

  return v_calls is not null;
end;
$$;

-- Only the edge functions (service role) meter usage; a client that could
-- call this directly could burn or bypass its own allowance.
revoke execute on function public.consume_ai_call(uuid, integer) from public;
revoke execute on function public.consume_ai_call(uuid, integer) from anon;
revoke execute on function public.consume_ai_call(uuid, integer)
  from authenticated;

-- Erasure. Every user-owned table references auth.users with `on delete
-- cascade`, so removing the auth row removes the personal data with it.
-- Apple 5.1.1(v) and GDPR both require this to be reachable in-app.
create or replace function public.delete_account()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'Not signed in.';
  end if;

  -- Meal photos live outside the cascade.
  delete from storage.objects
   where bucket_id = 'meal-photos'
     and (storage.foldername(name))[1] = v_user::text;

  delete from auth.users where id = v_user;
end;
$$;

grant execute on function public.delete_account() to authenticated;

-- Lets a client insert a profile without minting an id, so the row's identity
-- is the server's concern and re-onboarding cannot collide with itself.
alter table public.profiles alter column id set default gen_random_uuid();
