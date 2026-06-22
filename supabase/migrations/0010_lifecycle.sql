-- ============================================================================
-- TM Pharma — Migration 0010 : Cycle de vie & péremptions (Sprint 9)
-- - `stock_movements.type` étendu : DONATION (don), SUPPLIER_RETURN (retour
--   fournisseur). TRANSFER existait déjà (Sprint 5) ; ce sprint l'utilise
--   réellement côté app pour les sorties vers une autre pharmacie — la
--   réception côté pharmacie destinataire reste hors scope MVP (tenant
--   distinct, nécessiterait un mécanisme d'échange inter-tenant).
-- - `promotions` : remises temporaires par produit, appliquées à la caisse.
-- ============================================================================

alter table public.stock_movements drop constraint stock_movements_type_check;
alter table public.stock_movements add constraint stock_movements_type_check
  check (type in ('RECEIPT','ADJUSTMENT','TRANSFER','DONATION','SUPPLIER_RETURN'));

-- ----------------------------------------------------------------------------
-- promotions — remise (%) sur un produit, valable sur une période.
-- ----------------------------------------------------------------------------
create table public.promotions (
  id               uuid primary key default gen_random_uuid(),
  tenant_id        uuid not null references public.tenants(id),
  product_id       uuid not null references public.products(id),
  discount_percent numeric(5,2) not null check (discount_percent > 0 and discount_percent <= 100),
  starts_at        timestamptz not null default now(),
  ends_at          timestamptz not null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  deleted_at       timestamptz
);
create index idx_promotions_tenant on public.promotions(tenant_id);
create index idx_promotions_product on public.promotions(product_id, starts_at, ends_at);
create trigger trg_promotions_updated before update on public.promotions
  for each row execute function public.set_updated_at();

-- Les nouveaux types de sortie (don, retour fournisseur) suivent la même
-- habilitation que les ajustements manuels (stock.adjust).
drop policy stock_movements_insert on public.stock_movements;
create policy stock_movements_insert on public.stock_movements
  for insert with check (
    tenant_id = private.current_tenant_id()
    and (
      (type = 'RECEIPT' and private.has_permission('stock.receive'))
      or (type in ('ADJUSTMENT','TRANSFER','DONATION','SUPPLIER_RETURN') and private.has_permission('stock.adjust'))
    )
  );

alter table public.promotions enable row level security;

create policy promotions_read on public.promotions
  for select using (tenant_id = private.current_tenant_id());
create policy promotions_write on public.promotions
  for all using (tenant_id = private.current_tenant_id() and private.has_permission('price.edit'))
  with check (tenant_id = private.current_tenant_id() and private.has_permission('price.edit'));
