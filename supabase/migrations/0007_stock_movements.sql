-- ============================================================================
-- TM Pharma — Migration 0007 : Stocks & lots + scan GS1 (Sprint 5)
-- - `suppliers` : fournisseurs (par tenant), pour la réception de commandes.
-- - `stock_movements` : journal des entrées/sorties/ajustements par lot,
--   traçabilité indépendante de `lots.quantity` (qui reste la valeur courante).
-- - `products.low_stock_threshold` : seuil d'alerte stock bas par produit.
-- ============================================================================

alter table public.products
  add column low_stock_threshold integer not null default 0;

-- ----------------------------------------------------------------------------
-- suppliers — fournisseurs (par tenant)
-- ----------------------------------------------------------------------------
create table public.suppliers (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null references public.tenants(id),
  name        text not null,
  phone       text,
  email       text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);
create index idx_suppliers_tenant on public.suppliers(tenant_id);
create trigger trg_suppliers_updated before update on public.suppliers
  for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- stock_movements — journal des mouvements de stock (par lot)
-- type : RECEIPT (réception fournisseur), ADJUSTMENT (correction manuelle),
--        TRANSFER (entre pharmacies, Sprint ultérieur).
-- quantity_delta : signé (+ entrée, - sortie).
-- ----------------------------------------------------------------------------
create table public.stock_movements (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references public.tenants(id),
  product_id      uuid not null references public.products(id),
  lot_id          uuid references public.lots(id),
  supplier_id     uuid references public.suppliers(id),
  type            text not null check (type in ('RECEIPT','ADJUSTMENT','TRANSFER')),
  quantity_delta  integer not null,
  reason          text,
  created_by      uuid references public.users(id),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz
);
create index idx_stock_movements_tenant on public.stock_movements(tenant_id, created_at);
create index idx_stock_movements_product on public.stock_movements(product_id);
create index idx_stock_movements_lot on public.stock_movements(lot_id);
create trigger trg_stock_movements_updated before update on public.stock_movements
  for each row execute function public.set_updated_at();

-- ============================================================================
-- RLS
-- ============================================================================
alter table public.suppliers       enable row level security;
alter table public.stock_movements enable row level security;

-- suppliers : lecture sous stock.view (visible aux gestionnaires de stock),
-- écriture réservée à supplier.manage.
create policy suppliers_read on public.suppliers
  for select using (tenant_id = private.current_tenant_id() and private.has_permission('stock.view'));
create policy suppliers_write on public.suppliers
  for all using (tenant_id = private.current_tenant_id() and private.has_permission('supplier.manage'))
  with check (tenant_id = private.current_tenant_id() and private.has_permission('supplier.manage'));

-- stock_movements : lecture sous stock.view ; écriture sous stock.receive
-- (réceptions) ou stock.adjust (ajustements) — vérifié côté policy via le
-- type pour ne pas dupliquer la table.
create policy stock_movements_read on public.stock_movements
  for select using (tenant_id = private.current_tenant_id() and private.has_permission('stock.view'));
create policy stock_movements_insert on public.stock_movements
  for insert with check (
    tenant_id = private.current_tenant_id()
    and (
      (type = 'RECEIPT' and private.has_permission('stock.receive'))
      or (type in ('ADJUSTMENT','TRANSFER') and private.has_permission('stock.adjust'))
    )
  );
