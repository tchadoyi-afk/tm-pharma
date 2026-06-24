-- ============================================================================
-- TM Pharma — Migration 0017 : traçabilité des imports (gap audit CDC #2)
-- L'onboarding (Sprint 6) importe le catalogue depuis un CSV directement
-- dans `products`/`lots`, sans laisser de trace de l'opération d'import
-- elle-même (qui, quand, combien de lignes, doublons ignorés) — aucun
-- rejouable/audit de l'import. `import_jobs` / `import_rows` corrigent ça.
-- ============================================================================

create table public.import_jobs (
  id               uuid primary key default gen_random_uuid(),
  tenant_id        uuid not null references public.tenants(id),
  source_filename  text,
  total_rows       integer not null default 0,
  imported_rows    integer not null default 0,
  duplicate_rows   integer not null default 0,
  status           text not null default 'COMPLETED'
    check (status in ('COMPLETED','FAILED')),
  created_by       uuid references public.users(id),
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  deleted_at       timestamptz
);
create index idx_import_jobs_tenant on public.import_jobs(tenant_id, created_at);
create trigger trg_import_jobs_updated before update on public.import_jobs
  for each row execute function public.set_updated_at();

create table public.import_rows (
  id             uuid primary key default gen_random_uuid(),
  tenant_id      uuid not null references public.tenants(id),
  import_job_id  uuid not null references public.import_jobs(id) on delete cascade,
  row_number     integer not null,
  raw_data       jsonb not null,
  status         text not null check (status in ('IMPORTED','DUPLICATE_SKIPPED')),
  product_id     uuid references public.products(id),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  deleted_at     timestamptz
);
create index idx_import_rows_tenant on public.import_rows(tenant_id);
create index idx_import_rows_job on public.import_rows(import_job_id);
create trigger trg_import_rows_updated before update on public.import_rows
  for each row execute function public.set_updated_at();

alter table public.import_jobs enable row level security;
alter table public.import_rows enable row level security;

-- Même habilitation que l'onboarding (settings.manage) : la reprise de
-- données est une opération d'administration, pas un usage courant.
create policy import_jobs_read on public.import_jobs
  for select using (tenant_id = private.current_tenant_id() and private.has_permission('settings.manage'));
create policy import_jobs_write on public.import_jobs
  for all using (tenant_id = private.current_tenant_id() and private.has_permission('settings.manage'))
  with check (tenant_id = private.current_tenant_id() and private.has_permission('settings.manage'));

create policy import_rows_read on public.import_rows
  for select using (tenant_id = private.current_tenant_id() and private.has_permission('settings.manage'));
create policy import_rows_write on public.import_rows
  for all using (tenant_id = private.current_tenant_id() and private.has_permission('settings.manage'))
  with check (tenant_id = private.current_tenant_id() and private.has_permission('settings.manage'));
