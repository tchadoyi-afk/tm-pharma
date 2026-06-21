-- ============================================================================
-- TM Pharma — Migration 0002 : Catalogue global des permissions (RBAC)
-- Les rôles sont créés par tenant lors de l'onboarding (Sprint 6) à partir
-- de ce catalogue. Idempotent.
-- ============================================================================

insert into public.permissions (code, label, module) values
  -- Caisse / vente
  ('pos.sell',             'Encaisser une vente',                 'POS'),
  ('pos.refund',           'Effectuer un remboursement',          'POS'),
  ('pos.discount.apply',   'Appliquer une remise',                'POS'),
  ('pos.cash.close',       'Clôturer la caisse',                  'POS'),
  -- Stock
  ('stock.view',           'Consulter le stock',                  'Stock'),
  ('stock.adjust',         'Ajuster le stock',                    'Stock'),
  ('stock.transfer',       'Transférer entre pharmacies',         'Stock'),
  ('stock.receive',        'Réceptionner une commande',           'Stock'),
  -- Catalogue / prix
  ('product.create',       'Créer un produit',                    'Catalogue'),
  ('price.edit',           'Modifier un prix',                    'Catalogue'),
  -- Fournisseurs / réappro
  ('supplier.manage',      'Gérer les fournisseurs',              'Achats'),
  ('purchase.order',       'Émettre un bon de commande',          'Achats'),
  -- Facturation
  ('invoice.issue',        'Émettre une facture',                 'Facturation'),
  -- Rapports / KPI
  ('report.financial.view','Voir les rapports financiers',        'Pilotage'),
  -- Traçabilité / audit (accès restreint)
  ('trace.lot.view',       'Voir la traçabilité d''un lot',       'Traçabilité'),
  ('audit.view.own',       'Voir ses propres actions',            'Traçabilité'),
  ('audit.view.all',       'Voir le journal d''audit complet',    'Traçabilité'),
  ('trace.export',         'Exporter les données de traçabilité', 'Traçabilité'),
  -- Administration
  ('user.manage',          'Gérer les utilisateurs et rôles',     'Admin'),
  ('settings.manage',      'Gérer les paramètres de la pharmacie','Admin'),
  -- IA
  ('ai.assistant.use',     'Utiliser l''assistant IA',            'IA')
on conflict (code) do update
  set label = excluded.label, module = excluded.module;
