create extension if not exists pgcrypto;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'user_role') then
    create type user_role as enum ('visitor', 'tenant', 'owner', 'admin', 'agent');
  end if;
  if not exists (select 1 from pg_type where typname = 'property_type') then
    create type property_type as enum ('apartment', 'house', 'villa', 'studio', 'land', 'shared_room');
  end if;
  if not exists (select 1 from pg_type where typname = 'offer_type') then
    create type offer_type as enum ('rent', 'sale', 'colocation');
  end if;
  if not exists (select 1 from pg_type where typname = 'property_status') then
    create type property_status as enum ('available', 'reserved', 'rented', 'sold');
  end if;
  if not exists (select 1 from pg_type where typname = 'visit_status') then
    create type visit_status as enum ('pending', 'confirmed', 'completed', 'cancelled');
  end if;
  if not exists (select 1 from pg_type where typname = 'payment_status') then
    create type payment_status as enum ('pending', 'successful', 'failed', 'cancelled');
  end if;
  if not exists (select 1 from pg_type where typname = 'payment_purpose') then
    create type payment_purpose as enum ('reservation', 'deposit', 'rent', 'sale_advance', 'full_purchase');
  end if;
  if not exists (select 1 from pg_type where typname = 'contract_type') then
    create type contract_type as enum ('rental', 'colocation', 'land_sale', 'house_sale');
  end if;
  if not exists (select 1 from pg_type where typname = 'contract_status') then
    create type contract_status as enum ('draft', 'pending_signature', 'signed', 'cancelled');
  end if;
  if not exists (select 1 from pg_type where typname = 'issue_category') then
    create type issue_category as enum ('electricity', 'water', 'plumbing', 'lock', 'painting', 'roof', 'internet', 'neighborhood', 'cleaning', 'other');
  end if;
  if not exists (select 1 from pg_type where typname = 'issue_priority') then
    create type issue_priority as enum ('low', 'normal', 'urgent');
  end if;
  if not exists (select 1 from pg_type where typname = 'issue_status') then
    create type issue_status as enum ('new_report', 'in_progress', 'resolved', 'rejected');
  end if;
end $$;

create table if not exists users (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  email text not null unique,
  phone text,
  password_hash text not null,
  role user_role not null default 'visitor',
  is_blocked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table users add column if not exists is_blocked boolean not null default false;
alter table users add column if not exists fcm_token text;

create table if not exists properties (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  type property_type not null,
  offer_type offer_type not null,
  status property_status not null default 'available',
  price integer not null check (price >= 0),
  location text not null,
  description text not null,
  image_url text,
  features text[] not null default '{}',
  rooms integer,
  bathrooms integer,
  surface_area numeric,
  is_furnished boolean not null default false,
  owner_id uuid references users(id) on delete set null,
  tenant_id uuid references users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table properties add column if not exists image_url text;
alter table properties add column if not exists tenant_id uuid references users(id) on delete set null;

create table if not exists visits (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references properties(id) on delete cascade,
  client_id uuid not null references users(id) on delete cascade,
  agent_id uuid references users(id) on delete set null,
  scheduled_at timestamptz not null,
  status visit_status not null default 'pending',
  message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists payments (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique,
  client_id uuid not null references users(id) on delete cascade,
  property_id uuid not null references properties(id) on delete cascade,
  amount integer not null check (amount >= 0),
  phone text not null,
  purpose payment_purpose not null,
  status payment_status not null default 'pending',
  provider text not null default 'paydunya',
  provider_token text,
  checkout_url text,
  receipt_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table payments add column if not exists provider text not null default 'paydunya';
alter table payments add column if not exists provider_token text;
alter table payments add column if not exists checkout_url text;
alter table payments add column if not exists receipt_url text;

create table if not exists contracts (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique,
  type contract_type not null,
  status contract_status not null default 'draft',
  property_id uuid not null references properties(id) on delete cascade,
  client_id uuid not null references users(id) on delete cascade,
  start_date date not null,
  end_date date,
  amount integer not null check (amount >= 0),
  terms text[] not null default '{}',
  signed_at timestamptz,
  signature_name text,
  signature_ip text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table contracts add column if not exists signed_at timestamptz;
alter table contracts add column if not exists signature_name text;
alter table contracts add column if not exists signature_ip text;

create table if not exists receipts (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique,
  payment_id uuid not null references payments(id) on delete cascade,
  client_id uuid not null references users(id) on delete cascade,
  property_id uuid not null references properties(id) on delete cascade,
  amount integer not null check (amount >= 0),
  label text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists issue_reports (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references properties(id) on delete cascade,
  client_id uuid not null references users(id) on delete cascade,
  category issue_category not null,
  priority issue_priority not null default 'normal',
  status issue_status not null default 'new_report',
  description text not null,
  photo_url text,
  agency_comment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table issue_reports add column if not exists photo_url text;

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid references users(id) on delete set null,
  recipient_id uuid references users(id) on delete set null,
  property_id uuid references properties(id) on delete set null,
  subject text not null,
  body text not null,
  status text not null default 'unread',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists calendar_events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  event_type text not null default 'visit',
  property_id uuid references properties(id) on delete set null,
  client_id uuid references users(id) on delete set null,
  agent_id uuid references users(id) on delete set null,
  starts_at timestamptz not null,
  ends_at timestamptz,
  status text not null default 'scheduled',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists contract_signatures (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references contracts(id) on delete cascade,
  signer_id uuid references users(id) on delete set null,
  signer_name text not null,
  signature_text text not null,
  signed_at timestamptz not null default now(),
  ip_address text,
  created_at timestamptz not null default now()
);

create table if not exists admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references users(id) on delete set null,
  action text not null,
  resource text not null,
  resource_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_properties_offer_type on properties(offer_type);
create index if not exists idx_properties_owner on properties(owner_id);
create index if not exists idx_properties_tenant on properties(tenant_id);
create index if not exists idx_visits_client on visits(client_id);
create index if not exists idx_payments_client on payments(client_id);
create index if not exists idx_issue_reports_client on issue_reports(client_id);
create index if not exists idx_messages_sender on messages(sender_id);
create index if not exists idx_messages_recipient on messages(recipient_id);
create index if not exists idx_calendar_events_starts on calendar_events(starts_at);
create index if not exists idx_admin_audit_logs_created on admin_audit_logs(created_at);
