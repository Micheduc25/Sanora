-- Bodi initial schema.
-- Client apps are offline-first: rows are created on-device with client
-- UUIDs and replayed here as idempotent upserts, so every user-owned table
-- keys on a client-generated id plus an enforced user_id.

create extension if not exists pgcrypto;

-- Single row per user; the full profile and computed health profile are
-- stored as documents because the app is their source of truth, while
-- frequently-queried values live in generated columns for analytics.
create table public.profiles (
  id uuid primary key,
  user_id uuid not null unique references auth.users (id) on delete cascade,
  data jsonb not null,
  health jsonb not null,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.metric_entries (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  type text not null,
  value double precision not null,
  note text not null default '',
  recorded_at timestamptz not null
);

create index metric_entries_user_type_time_idx
  on public.metric_entries (user_id, type, recorded_at desc);

create table public.meals (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  type text not null,
  source text not null,
  components jsonb not null default '[]',
  nutrition jsonb not null default '{}',
  confidence double precision not null default 0.8,
  ai_notes text not null default '',
  healthier_swaps jsonb not null default '[]',
  is_favorite boolean not null default false,
  eaten_at timestamptz not null
);

create index meals_user_time_idx on public.meals (user_id, eaten_at desc);

create table public.habits (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  emoji text not null default '✅',
  description text not null default '',
  scheduled_weekdays jsonb not null default '[]',
  daily_target integer not null default 1,
  active boolean not null default true,
  reminder_time text,
  created_at timestamptz not null
);

create table public.habit_logs (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  habit_id uuid not null,
  day_key text not null,
  count integer not null default 1,
  logged_at timestamptz not null
);

create index habit_logs_user_habit_day_idx
  on public.habit_logs (user_id, habit_id, day_key);

create table public.chat_messages (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  pending boolean not null default false,
  sent_at timestamptz not null
);

create index chat_messages_user_time_idx
  on public.chat_messages (user_id, sent_at);

create table public.reminders (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null,
  title text not null,
  body text not null default '',
  time text not null,
  weekdays jsonb not null default '[]',
  enabled boolean not null default true,
  created_at timestamptz not null
);

create table public.workouts (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  category text not null,
  difficulty text not null default 'Beginner',
  duration_minutes integer not null,
  estimated_calories integer not null,
  exercises jsonb not null default '[]',
  completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null
);

-- Shared read-only reference data; expandable server-side without an app
-- release. Mirrors assets/data/foods.json.
create table public.foods (
  id text primary key,
  name text not null,
  aliases jsonb not null default '[]',
  region text not null default '',
  category text not null default '',
  nutrition_per100g jsonb not null,
  typical_serving_g double precision not null default 100,
  serving_label text not null default ''
);

-- AI usage metering: free tier gets a daily allowance, premium unlimited.
create table public.ai_usage (
  user_id uuid not null references auth.users (id) on delete cascade,
  day date not null,
  calls integer not null default 0,
  primary key (user_id, day)
);

create table public.subscriptions (
  user_id uuid primary key references auth.users (id) on delete cascade,
  tier text not null default 'free' check (tier in ('free', 'premium')),
  valid_until timestamptz,
  updated_at timestamptz not null default now()
);

-- Community
create table public.friendships (
  requester_id uuid not null references auth.users (id) on delete cascade,
  addressee_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'blocked')),
  created_at timestamptz not null default now(),
  primary key (requester_id, addressee_id),
  check (requester_id <> addressee_id)
);

create table public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text not null default '',
  owner_id uuid not null references auth.users (id) on delete cascade,
  is_private boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.group_members (
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create table public.challenges (
  id uuid primary key default gen_random_uuid(),
  group_id uuid references public.groups (id) on delete cascade,
  name text not null,
  metric text not null, -- steps | workouts | habit_completion | water
  target double precision not null,
  starts_on date not null,
  ends_on date not null,
  created_by uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  check (ends_on >= starts_on)
);

create table public.challenge_participants (
  challenge_id uuid not null references public.challenges (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  progress double precision not null default 0,
  joined_at timestamptz not null default now(),
  primary key (challenge_id, user_id)
);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

create trigger subscriptions_touch_updated_at
  before update on public.subscriptions
  for each row execute function public.touch_updated_at();

-- Meal photo storage (paths are <user_id>/<meal_id>.jpg).
insert into storage.buckets (id, name, public)
values ('meal-photos', 'meal-photos', false)
on conflict (id) do nothing;
