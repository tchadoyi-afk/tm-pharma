-- ============================================================================
-- TM Pharma — Migration 0015 : Réception partielle réelle des bons de commande
-- Décision 24/06/2026 : la réception partielle saisit désormais une quantité
-- reçue par ligne (plutôt qu'un simple changement de statut), pour permettre
-- un suivi exact des reliquats et créer les mouvements de stock correspondants.
-- ============================================================================

alter table public.purchase_order_items
  add column received_quantity integer not null default 0
  check (received_quantity >= 0);
