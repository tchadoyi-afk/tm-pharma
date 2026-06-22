-- ============================================================================
-- TM Pharma — Migration 0011 : Mini IA étage 1 (local) + réappro (Sprint 10)
-- - `purchase_orders` / `purchase_order_items` : bon de commande généré à
--   partir des suggestions de réappro (heuristique locale, cf. app).
-- ============================================================================

create table public.purchase_orders (
  id           uuid primary key default gen_random_uuid(),
  tenant_id    uuid not null references public.tenants(id),
  supplier_id  uuid references public.suppliers(id),
  status       text not null default 'DRAFT' check (status in ('DRAFT','SENT','RECEIVED','CANCELLED')),
  created_by   uuid references public.users(id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz
);
create index idx_purchase_orders_tenant on public.purchase_orders(tenant_id, created_at);
create trigger trg_purchase_orders_updated before update on public.purchase_orders
  for each row execute function public.set_updated_at();

create table public.purchase_order_items (
  id                 uuid primary key default gen_random_uuid(),
  tenant_id          uuid not null references public.tenants(id),
  purchase_order_id  uuid not null references public.purchase_orders(id) on delete cascade,
  product_id         uuid not null references public.products(id),
  quantity            integer not null check (quantity > 0),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz
);
create index idx_po_items_tenant on public.purchase_order_items(tenant_id);
create index idx_po_items_order on public.purchase_order_items(purchase_order_id);
create trigger trg_po_items_updated before update on public.purchase_order_items
  for each row execute function public.set_updated_at();

alter table public.purchase_orders      enable row level security;
alter table public.purchase_order_items enable row level security;

create policy purchase_orders_read on public.purchase_orders
  for select using (tenant_id = private.current_tenant_id() and private.has_permission('stock.view'));
create policy purchase_orders_write on public.purchase_orders
  for all using (tenant_id = private.current_tenant_id() and private.has_permission('purchase.order'))
  with check (tenant_id = private.current_tenant_id() and private.has_permission('purchase.order'));

create policy po_items_read on public.purchase_order_items
  for select using (tenant_id = private.current_tenant_id() and private.has_permission('stock.view'));
create policy po_items_write on public.purchase_order_items
  for all using (tenant_id = private.current_tenant_id() and private.has_permission('purchase.order'))
  with check (tenant_id = private.current_tenant_id() and private.has_permission('purchase.order'));
