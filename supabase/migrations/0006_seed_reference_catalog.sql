-- ============================================================================
-- TM Pharma — Migration 0006 : Pré-chargement du catalogue de référence DCI
-- Sélection de médicaments courants (Togo/Gabon) pour accélérer l'onboarding
-- (le pharmacien coche/ajuste plutôt que de tout ressaisir). Idempotent.
-- ============================================================================

insert into public.reference_products (dci_name, barcode, unit, category) values
  ('Paracétamol 500mg',              '6111000000017', 'boîte',  'Antalgique'),
  ('Ibuprofène 400mg',                '6111000000024', 'boîte',  'Anti-inflammatoire'),
  ('Amoxicilline 500mg',              '6111000000031', 'boîte',  'Antibiotique'),
  ('Métronidazole 500mg',             '6111000000048', 'boîte',  'Antibiotique'),
  ('Artéméther/Luméfantrine 20/120mg','6111000000055', 'boîte',  'Antipaludique'),
  ('Sels de réhydratation orale',     '6111000000062', 'sachet', 'Réhydratation'),
  ('Vitamine C 1g',                   '6111000000079', 'boîte',  'Vitamine'),
  ('Oméprazole 20mg',                 '6111000000086', 'boîte',  'Antiacide'),
  ('Chlorphéniramine 4mg',            '6111000000093', 'boîte',  'Antihistaminique'),
  ('Albendazole 400mg',               '6111000000109', 'comprimé', 'Antiparasitaire')
on conflict (barcode) do update
  set dci_name = excluded.dci_name, unit = excluded.unit, category = excluded.category;
