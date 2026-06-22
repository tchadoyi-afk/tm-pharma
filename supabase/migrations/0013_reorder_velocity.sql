-- ============================================================================
-- TM Pharma — Migration 0013 : réappro affiné (vélocité de vente + délai
-- fournisseur + fournisseur par défaut) — raffinement du Sprint 10.
-- Décision actée : ce raffinement reste dans le MVP (il améliore la
-- suggestion existante), pas un nouveau module. Le comparateur multi-
-- fournisseur et l'envoi EDI/API restent V2/V3.
-- ============================================================================

alter table public.suppliers
  add column if not exists lead_time_days integer not null default 0
    check (lead_time_days >= 0);

comment on column public.suppliers.lead_time_days is
  'Délai de livraison habituel de ce fournisseur, en jours. '
  '0 par défaut (inconnu) : le réappro retombe alors sur le seuil bas simple.';

alter table public.products
  add column if not exists default_supplier_id uuid references public.suppliers(id);

comment on column public.products.default_supplier_id is
  'Fournisseur par défaut pour ce produit (pré-rempli sur les suggestions de '
  'réappro et le bon de commande). Optionnel : NULL si jamais reçu / pas encore associé.';
