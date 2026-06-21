-- ============================================================================
-- TM Pharma — Migration 0001 : Socle multi-tenant, RBAC, paramètres, audit
-- Sprint 1. Postgres / Supabase.
-- Principes : UUID v4 partout · tenant_id sur toutes les tables métier ·
-- soft-delete + horodatage partout · RLS stricte · audit chaîné (infalsifiable).
-- NB : l'authentification (mot de passe, MFA) est gérée par Supabase Auth
--      (auth.users) — pas de password_hash applicatif.
-- ============================================================================

create extension if not exists pgcrypto;      -- gen_random_uuid(), digest()

-- Schéma privé : fonctions SECURITY DEFINER non exposées par l'API.
create schema if not exists private;

-- ----------------------------------------------------------------------------
-- Helpers communs
-- ----------------------------------------------------------------------------

-- Met à jour updated_at à chaque UPDATE.
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- tenant_id de l'utilisateur courant (depuis son profil applicatif).
create or replace function private.current_tenant_id()
returns uuid language sql stable security definer set search_path = '' as $$
  select u.tenant_id from public.users u where u.id = auth.uid()
$$;

-- L'utilisateur courant possède-t-il la permission <p_code> ?
create or replace function private.has_permission(p_code text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.role_permissions rp on rp.role_id = ur.role_id
    where ur.user_id = auth.uid()
      and rp.permission_code = p_code
  )
$$;

-- ----------------------------------------------------------------------------
-- Table : tenants (la pharmacie cliente)
-- ----------------------------------------------------------------------------
create table public.tenants (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text unique,
  status      text not null default 'TRIAL'
              check (status in ('ACTIVE','TRIAL','SUSPENDED')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);
create trigger trg_tenants_updated before update on public.tenants
  for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- Table : users (profil applicatif lié à auth.users)
-- ----------------------------------------------------------------------------
create table public.users (
  id          uuid primary key references auth.users(id) on delete cascade,
  tenant_id   uuid not null references public.tenants(id),
  full_name   text,
  email       text,
  status      text not null default 'ACTIVE'
              check (status in ('ACTIVE','SUSPENDED')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);
create index idx_users_tenant on public.users(tenant_id);
create trigger trg_users_updated before update on public.users
  for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- RBAC : permissions (catalogue global), roles, role_permissions, user_roles
-- ----------------------------------------------------------------------------
create table public.permissions (
  code        text primary key,          -- ex: 'pos.sell'
  label       text not null,
  module      text not null
);

create table public.roles (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null references public.tenants(id),
  name        text not null,
  description text,
  is_system   boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz,
  unique (tenant_id, name)
);
create index idx_roles_tenant on public.roles(tenant_id);
create trigger trg_roles_updated before update on public.roles
  for each row execute function public.set_updated_at();

create table public.role_permissions (
  role_id         uuid not null references public.roles(id) on delete cascade,
  permission_code text not null references public.permissions(code) on delete cascade,
  tenant_id       uuid not null references public.tenants(id),
  primary key (role_id, permission_code)
);
create index idx_role_perms_tenant on public.role_permissions(tenant_id);

create table public.user_roles (
  user_id     uuid not null references public.users(id) on delete cascade,
  role_id     uuid not null references public.roles(id) on delete cascade,
  tenant_id   uuid not null references public.tenants(id),
  created_at  timestamptz not null default now(),
  primary key (user_id, role_id)
);
create index idx_user_roles_tenant on public.user_roles(tenant_id);

-- ----------------------------------------------------------------------------
-- Table : pharmacy_settings (identité légale + logo + facturation)
-- Devise : XOF (FCFA UEMOA, Togo) ou XAF (FCFA CEMAC, Gabon).
-- ----------------------------------------------------------------------------
create table public.pharmacy_settings (
  tenant_id           uuid primary key references public.tenants(id) on delete cascade,
  legal_name          text,
  tax_id              text,            -- n° fiscal
  rccm                text,            -- registre du commerce
  address             text,
  city                text,
  country             text check (country in ('TG','GA')),
  phone               text,
  email               text,
  logo_path           text,            -- chemin dans Supabase Storage
  currency            text not null default 'XOF' check (currency in ('XOF','XAF')),
  invoice_prefix      text,
  invoice_next_number bigint not null default 1,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);
create trigger trg_pharmacy_settings_updated before update on public.pharmacy_settings
  for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- Table : audit_log (immuable, chaînée par hash → infalsifiable)
-- ----------------------------------------------------------------------------
create table public.audit_log (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null references public.tenants(id),
  user_id     uuid,                    -- null = action système
  action      text not null,           -- CREATE / UPDATE / DELETE / LOGIN / VIEW...
  entity      text,
  entity_id   uuid,
  before      jsonb,
  after       jsonb,
  device_ts   timestamptz,             -- horodatage device (offline)
  server_ts   timestamptz not null default now(),
  prev_hash   text,
  hash        text,
  created_at  timestamptz not null default now()
);
create index idx_audit_tenant on public.audit_log(tenant_id, server_ts);

-- Chaînage : chaque entrée scelle la précédente (par tenant).
create or replace function public.audit_log_chain()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_prev text;
begin
  select a.hash into v_prev
  from public.audit_log a
  where a.tenant_id = new.tenant_id
  order by a.server_ts desc, a.id desc
  limit 1;

  new.prev_hash := v_prev;
  new.hash := encode(
    digest(
      coalesce(v_prev,'') ||
      new.tenant_id::text || coalesce(new.user_id::text,'') ||
      new.action || coalesce(new.entity,'') || coalesce(new.entity_id::text,'') ||
      coalesce(new.before::text,'') || coalesce(new.after::text,'') ||
      new.server_ts::text,
      'sha256'
    ),
    'hex'
  );
  return new;
end;
$$;
create trigger trg_audit_chain before insert on public.audit_log
  for each row execute function public.audit_log_chain();

-- Immuabilité : interdit UPDATE / DELETE sur le journal.
create or replace function public.audit_log_immutable()
returns trigger language plpgsql as $$
begin
  raise exception 'audit_log est immuable (ni UPDATE ni DELETE autorisés)';
end;
$$;
create trigger trg_audit_no_update before update on public.audit_log
  for each row execute function public.audit_log_immutable();
create trigger trg_audit_no_delete before delete on public.audit_log
  for each row execute function public.audit_log_immutable();

-- ============================================================================
-- RLS — isolation multi-tenant + habilitation
-- ============================================================================
alter table public.tenants            enable row level security;
alter table public.users              enable row level security;
alter table public.permissions        enable row level security;
alter table public.roles              enable row level security;
alter table public.role_permissions   enable row level security;
alter table public.user_roles         enable row level security;
alter table public.pharmacy_settings  enable row level security;
alter table public.audit_log          enable row level security;

-- tenants : on ne voit que sa propre pharmacie.
create policy tenant_self_read on public.tenants
  for select using (id = private.current_tenant_id());

-- users : isolation par tenant.
create policy users_isolation on public.users
  for select using (tenant_id = private.current_tenant_id());
create policy users_admin_write on public.users
  for all using (tenant_id = private.current_tenant_id() and private.has_permission('user.manage'))
  with check (tenant_id = private.current_tenant_id() and private.has_permission('user.manage'));

-- permissions : catalogue global, lecture pour tout utilisateur authentifié.
create policy permissions_read on public.permissions
  for select to authenticated using (true);

-- roles / role_permissions / user_roles : visibles dans le tenant, gérés sous 'user.manage'.
create policy roles_read on public.roles
  for select using (tenant_id = private.current_tenant_id());
create policy roles_write on public.roles
  for all using (tenant_id = private.current_tenant_id() and private.has_permission('user.manage'))
  with check (tenant_id = private.current_tenant_id() and private.has_permission('user.manage'));

create policy role_perms_read on public.role_permissions
  for select using (tenant_id = private.current_tenant_id());
create policy role_perms_write on public.role_permissions
  for all using (tenant_id = private.current_tenant_id() and private.has_permission('user.manage'))
  with check (tenant_id = private.current_tenant_id() and private.has_permission('user.manage'));

create policy user_roles_read on public.user_roles
  for select using (tenant_id = private.current_tenant_id());
create policy user_roles_write on public.user_roles
  for all using (tenant_id = private.current_tenant_id() and private.has_permission('user.manage'))
  with check (tenant_id = private.current_tenant_id() and private.has_permission('user.manage'));

-- pharmacy_settings : lecture dans le tenant, écriture sous 'settings.manage'.
create policy pharmacy_settings_read on public.pharmacy_settings
  for select using (tenant_id = private.current_tenant_id());
create policy pharmacy_settings_write on public.pharmacy_settings
  for all using (tenant_id = private.current_tenant_id() and private.has_permission('settings.manage'))
  with check (tenant_id = private.current_tenant_id() and private.has_permission('settings.manage'));

-- audit_log : insertion par tout utilisateur du tenant ; lecture soumise à habilitation.
create policy audit_insert on public.audit_log
  for insert with check (tenant_id = private.current_tenant_id());
create policy audit_read_all on public.audit_log
  for select using (tenant_id = private.current_tenant_id() and private.has_permission('audit.view.all'));
create policy audit_read_own on public.audit_log
  for select using (tenant_id = private.current_tenant_id()
                    and user_id = auth.uid()
                    and private.has_permission('audit.view.own'));
