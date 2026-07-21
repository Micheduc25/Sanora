-- Verified store receipts behind Premium.
--
-- `subscriptions` records *that* an account is premium; this table records
-- *why*, and is what makes granting it idempotent and auditable. One verified
-- store transaction is one row: a renewal or a replayed receipt updates that
-- row instead of minting a second entitlement, and the unique key is what lets
-- `verify-purchase` refuse a receipt that already belongs to somebody else
-- rather than silently transferring a paid subscription between accounts.

create table public.subscription_receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  platform text not null check (platform in ('ios', 'android')),
  product_id text not null,
  -- The identifier each store keeps stable across renewals: Apple's
  -- original transaction id, Google Play's purchase token. Renewing the same
  -- subscription therefore updates this row rather than inserting a new one.
  transaction_id text not null,
  expires_at timestamptz not null,
  verified_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (platform, transaction_id)
);

create index subscription_receipts_user_idx
  on public.subscription_receipts (user_id, expires_at desc);

create trigger subscription_receipts_touch_updated_at
  before update on public.subscription_receipts
  for each row execute function public.touch_updated_at();

alter table public.subscription_receipts enable row level security;

-- Readable by its owner so the app can show what it is being billed for.
-- There is deliberately no insert, update or delete policy: only the
-- `verify-purchase` edge function writes here, and it runs as the service
-- role, which bypasses RLS. A client that could write this table could write
-- itself a subscription.
create policy "subscription_receipts_read_own" on public.subscription_receipts
  for select using (auth.uid() = user_id);
