-- ============================================================================
-- TM Pharma — Migration 0014 : Gestion fournisseurs complète + rebuts (MVP)
-- Décision 22-23/06/2026 (PROGRAMME_DEVELOPPEMENT.md §8) : portail
-- fournisseurs (suivi de statut côté fournisseur) et workflow rebuts avancés
-- au MVP.
-- - `purchase_orders.status` : ajoute CONFIRMED (le fournisseur a accusé
--   réception de la commande, avant livraison physique) entre SENT et
--   RECEIVED. La validation manuelle (création du brouillon, puis passage
--   explicite à SENT) reste inchangée — aucun statut automatique n'envoie
--   une commande sans action humaine (règle invariante, tous paliers).
-- - `stock_movements.type` : ajoute SCRAP (rebut — produit périmé/abîmé
--   sorti du stock sans don ni retour fournisseur), même habilitation que
--   les autres sorties manuelles (stock.adjust).
-- ============================================================================

alter table public.purchase_orders drop constraint purchase_orders_status_check;
alter table public.purchase_orders add constraint purchase_orders_status_check
  check (status in ('DRAFT','SENT','CONFIRMED','RECEIVED','PARTIALLY_RECEIVED','CANCELLED'));

alter table public.stock_movements drop constraint stock_movements_type_check;
alter table public.stock_movements add constraint stock_movements_type_check
  check (type in ('RECEIPT','ADJUSTMENT','TRANSFER','DONATION','SUPPLIER_RETURN','SCRAP'));

drop policy stock_movements_insert on public.stock_movements;
create policy stock_movements_insert on public.stock_movements
  for insert with check (
    tenant_id = private.current_tenant_id()
    and (
      (type = 'RECEIPT' and private.has_permission('stock.receive'))
      or (type in ('ADJUSTMENT','TRANSFER','DONATION','SUPPLIER_RETURN','SCRAP') and private.has_permission('stock.adjust'))
    )
  );
