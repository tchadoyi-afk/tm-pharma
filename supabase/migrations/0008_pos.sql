-- ============================================================================
-- TM Pharma — Migration 0008 : POS offline-first / caisse (Sprint 7)
-- - `cash_sessions` : ouverture/clôture de caisse (un encaissement appartient
--   à la session ouverte au moment de la vente).
-- - `sales.cash_session_id` : rattachement (nullable, ventes de démo S2/S7
--   antérieures sans session).
-- ============================================================================

create table public.cash_sessions (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references public.tenants(id),
  user_id         uuid references public.users(id),
  status          text not null default 'OPEN' check (status in ('OPEN','CLOSED')),
  opening_amount  numeric(12,2) not null default 0,
  closing_amount  numeric(12,2),
  opened_at       timestamptz not null default now(),
  closed_at       timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create index idx_cash_sessions_tenant on public.cash_sessions(tenant_id, opened_at);
create trigger trg_cash_sessions_updated before update on public.cash_sessions
  for each row execute function public.set_updated_at();

alter table public.sales
  add column cash_session_id uuid references public.cash_sessions(id);

-- ============================================================================
-- RLS
-- ============================================================================
alter table public.cash_sessions enable row level security;

create policy cash_sessions_read on public.cash_sessions
  for select using (tenant_id = private.current_tenant_id());
create policy cash_sessions_insert on public.cash_sessions
  for insert with check (tenant_id = private.current_tenant_id() and private.has_permission('pos.sell'));
create policy cash_sessions_update on public.cash_sessions
  for update using (tenant_id = private.current_tenant_id() and private.has_permission('pos.cash.close'))
  with check (tenant_id = private.current_tenant_id());
