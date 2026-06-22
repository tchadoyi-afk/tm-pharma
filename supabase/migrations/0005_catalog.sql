-- ============================================================================
-- TM Pharma — Migration 0005 : Catalogue & référentiel produits (Sprint 4)
-- - `reference_products` : catalogue de référence partagé (médicaments
--   courants en DCI + codes-barres connus), commun à tous les tenants.
-- - Enrichit `products` (DCI, unité, catégorie, lien vers le référentiel).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- reference_products — catalogue de référence partagé (pas de tenant_id)
-- Pré-chargé : médicaments courants en DCI + codes-barres connus. Coché/ajusté
-- par le pharmacien à l'onboarding (Sprint 6) plutôt que tout ressaisir.
-- ----------------------------------------------------------------------------
create table public.reference_products (
  id          uuid primary key default gen_random_uuid(),
  dci_name    text not null,
  barcode     text,
  unit        text not null default 'unité',
  category    text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (barcode)
);
create index idx_reference_products_dci on public.reference_products(dci_name);
create trigger trg_reference_products_updated before update on public.reference_products
  for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- products — colonnes catalogue
-- ----------------------------------------------------------------------------
alter table public.products
  add column dci_name     text,                 -- nom DCI (si différent du nom commercial)
  add column unit         text not null default 'unité',
  add column category     text,
  add column reference_id uuid references public.reference_products(id);

-- ============================================================================
-- RLS
-- ============================================================================
alter table public.reference_products enable row level security;

-- Catalogue de référence : lecture ouverte à tout utilisateur authentifié
-- (donnée non sensible, partagée entre tenants) ; écriture réservée au
-- backend (service_role) — pas de policy d'écriture côté app pour l'instant.
create policy reference_products_read on public.reference_products
  for select using (auth.role() = 'authenticated');
