-- ============================================================================
-- TM Pharma — Migration 0003 : Tables métier minimales (PoC sync offline, S2)
-- Sous-ensemble du modèle de données, suffisant pour démontrer
-- « vente créée hors-ligne → synchronisée sans perte ».
-- Étendu aux Sprints S4–S7 (mouvements, fournisseurs, caisse, facturation…).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- products (catalogue ; stock calculé via les lots)
-- ----------------------------------------------------------------------------
create table public.products (
  id            uuid primary key default gen_random_uuid(),
  tenant_id     uuid not null references public.tenants(id),
  barcode       text,
  name          text not null,           -- DCI ou nom commercial
  selling_price numeric(12,2) not null default 0,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz,
  unique (tenant_id, barcode)
);
create index idx_products_tenant on public.products(tenant_id);
create trigger trg_products_updated before update on public.products
  for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- lots (péremptions & traçabilité ; quantité par lot précis)
-- ----------------------------------------------------------------------------
create table public.lots (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references public.tenants(id),
  product_id      uuid not null references public.products(id),
  lot_number      text,
  expiration_date date,
  quantity        integer not null default 0,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz
);
create index idx_lots_tenant on public.lots(tenant_id);
create index idx_lots_product on public.lots(product_id);
create trigger trg_lots_updated before update on public.lots
  for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- sales (en-tête du ticket ; UUID généré sur l'appareil hors-ligne)
-- ----------------------------------------------------------------------------
create table public.sales (
  id             uuid primary key default gen_random_uuid(),
  tenant_id      uuid not null references public.tenants(id),
  user_id        uuid references public.users(id),
  total_amount   numeric(12,2) not null default 0,
  status         text not null default 'COMPLETED'
                 check (status in ('COMPLETED','VOIDED')),
  payment_method text not null default 'CASH'
                 check (payment_method in ('CASH','MOBILE_MONEY')),
  sold_at        timestamptz,            -- horodatage device (offline)
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  deleted_at     timestamptz
);
create index idx_sales_tenant on public.sales(tenant_id, created_at);
create trigger trg_sales_updated before update on public.sales
  for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- sale_items (lignes ; pointeur direct vers lot_id pour déduire la quantité)
-- ----------------------------------------------------------------------------
create table public.sale_items (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null references public.tenants(id),
  sale_id     uuid not null references public.sales(id) on delete cascade,
  lot_id      uuid references public.lots(id),
  quantity    integer not null default 1,
  unit_price  numeric(12,2) not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);
create index idx_sale_items_tenant on public.sale_items(tenant_id);
create index idx_sale_items_sale on public.sale_items(sale_id);
create trigger trg_sale_items_updated before update on public.sale_items
  for each row execute function public.set_updated_at();

-- ============================================================================
-- RLS — isolation multi-tenant + habilitation (alignée sur le catalogue 0002)
-- ============================================================================
alter table public.products   enable row level security;
alter table public.lots       enable row level security;
alter table public.sales      enable row level security;
alter table public.sale_items enable row level security;

-- products
create policy products_read on public.products
  for select using (tenant_id = private.current_tenant_id() and private.has_permission('stock.view'));
create policy products_write on public.products
  for all using (tenant_id = private.current_tenant_id() and private.has_permission('product.create'))
  with check (tenant_id = private.current_tenant_id() and private.has_permission('product.create'));

-- lots
create policy lots_read on public.lots
  for select using (tenant_id = private.current_tenant_id() and private.has_permission('stock.view'));
create policy lots_write on public.lots
  for all using (tenant_id = private.current_tenant_id() and private.has_permission('stock.adjust'))
  with check (tenant_id = private.current_tenant_id() and private.has_permission('stock.adjust'));

-- sales : lecture dans le tenant ; création réservée à 'pos.sell'.
create policy sales_read on public.sales
  for select using (tenant_id = private.current_tenant_id());
create policy sales_insert on public.sales
  for insert with check (tenant_id = private.current_tenant_id() and private.has_permission('pos.sell'));
create policy sales_update on public.sales
  for update using (tenant_id = private.current_tenant_id() and private.has_permission('pos.refund'))
  with check (tenant_id = private.current_tenant_id());

-- sale_items : suivent la vente.
create policy sale_items_read on public.sale_items
  for select using (tenant_id = private.current_tenant_id());
create policy sale_items_insert on public.sale_items
  for insert with check (tenant_id = private.current_tenant_id() and private.has_permission('pos.sell'));
