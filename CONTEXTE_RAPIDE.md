# CONTEXTE RAPIDE — TM Pharma

> À lire en 1 min au début de chaque session. Mis à jour à chaque fin de session (règle 80 % contexte).
> 📁 Copie de référence : `C:\Claude\TM_Projects\TM_Pharma` (disque interne). Une copie existe sur `E:` (amovible, pas toujours connecté) — **travailler sur `C:`**.

## C'est quoi
**TM Pharma** — SaaS B2B multi-tenant **offline-first** de gestion de pharmacies pour l'Afrique (Togo + Gabon d'abord).
Binôme : **Toi (PO)** + **Claude (associé/dev)**.
Docs : `CDC_TM_Pharma_v1.md` (cahier des charges officiel) · `PROGRAMME_DEVELOPPEMENT.md` (plan d'exécution) · `CONTEXTE_RAPIDE.md` (ce fichier).
Archives : `CDC SaaS_Pharmacie V0.pdf` (ex-« OfficineOS », historique) + 4 PDF sources.

## Décisions actées (2026-06-21)
- **Nom produit** : **TM Pharma** (abandon de « OfficineOS » du CDC v0).
- **Plan** : MVP livré sur **12 sprints (S1→S12)**, MVP enrichi = référence ; **jalon Pilote = S8**, MVP complet = S12.
- **Stack** : Supabase (Postgres+RLS+Auth+Storage+Realtime) + Flutter offline (PowerSync + Drift/SQLite). PAS de NestJS/VPS.
- **Marché MVP** : Togo + Gabon. Langues FR + EN. **Mobile Money = V2** (MVP = espèces).
- **IA** : 2 étages → local hors-ligne (FEFO, ruptures, réappro, anti-fraude) + assistant Claude online. Centrale dès le MVP.
- **Habilitation fine** : RBAC granulaire (permissions atomiques) + validation hiérarchique, câblé dès le MVP.
- **Dashboard + KPIs précis** + audit immuable.
- **MVP enrichi (validé)** : scan GS1 (capture) dès le MVP · **impression factures/tickets dès le MVP** (thermique offline + PDF, facture normalisable par pays) · **jalon Pilote fin Sprint 3**.
- **Traçabilité = exigence transversale MVP** (« qui/quoi/quand ») : couche A produit (lot réception→vente, fiche traçabilité lot) + couche B audit chaîné infalsifiable (horodatage device+serveur). Construite à chaque sprint (S0→S6).
- **Traçabilité soumise à habilitation** : tout le monde ne peut PAS la voir. Permissions `trace.lot.view`, `audit.view.own/all`, `trace.export`. Caissier = ses propres actions au plus ; vue complète/export = dirigeant/pharmacien responsable.
- **Vérification d'authenticité externe (réseau GS1/base nationale) → V3** (champs d'accroche `gtin`/`serial`/`verification_status` posés dès le MVP).
- **Expérience & opérations (MVP)** : UX **simple et intuitive** (gros boutons, <3 taps pour vendre, tablette bas de gamme) · **scan code-barres caisse** (caméra + douchette, EAN-13/Code-128/GS1) + recherche manuelle en secours · **réappro assisté** (suggestion IA + bon de commande ; auto = V2) · **reprise de données / onboarding** (import Excel/CSV + catalogue de référence + inventaire initial + assistant guidé) · **logo & identité pharmacie** (sur app, ticket monochrome, facture PDF couleur).

## Règles groupe à respecter
- Migration Supabase **prod** = **feu vert explicite** (« applique »). Toujours préparer + tester + ROLLBACK.
- RLS multi-tenant = priorité sécu n°1 (leçon T&M Business).
- À ~80 % de contexte : préparer la session suivante automatiquement (ce fichier + mémoire + tâches + commit si repo).

## État actuel
- Phase : **S1, S2, S2b, S3, S4, S5, S6, S7, S8, S9, S10 faits en local** (reste = pièces cloud). Repo git, branche `claude/dreamy-sagan-2zd94w` (+ poussé sur GitHub). Commits : `7c7ddd3` (S1), `4218b36` (S2), `34be20d` (démo+CI), `5f5e131` (Drift), `af75472` (S3 auth+RBAC), `8b85211` (S3 validation+rôles), `7783d4c` (doc), S4, S5, S6, S7, S8, S9+S10, puis ajout scan caméra (ce commit).
- **Scan code-barres par caméra (complément S5/S7)** : jusqu'ici le scan ne fonctionnait qu'avec une douchette physique (clavier émulé) sur les champs de recherche caisse/réception. Ajout de `mobile_scanner` : `app/lib/core/scanning/barcode_scanner_sheet.dart` (bottom sheet caméra réutilisable, formats EAN-13/EAN-8/UPC-A/UPC-E/Code-128, retourne la valeur brute scannée) câblé sur un bouton caméra dans `pos_screen.dart` (caisse) et `stock_screen.dart` (réception, alimente le même parseur GS1 existant). Permission caméra ajoutée à `AndroidManifest.xml` (web : API navigateur, pas de permission manifeste). Catalogue (`catalog_screen.dart`, association manuelle de code-barres) non câblé dans cette passe — hors du périmètre demandé (caisse + réception).
- **S10 — Mini IA étage 1 (local) + réappro** :
  - `0011_purchase_orders.sql` : `purchase_orders` (statut DRAFT/SENT/RECEIVED/CANCELLED) + `purchase_order_items`, RLS lecture sous `stock.view` / écriture sous `purchase.order`.
  - `sync_rules.yaml` : `purchase_orders`/`purchase_order_items` ajoutés au bucket `by_tenant`.
  - `app/lib/core/sync/schema.dart` : tables `purchase_orders`/`purchase_order_items` côté PowerSync local.
  - `app/lib/features/reorder/` : `reorder_suggestion.dart` (heuristique pure — produits sous le seuil bas, quantité suggérée ramène le stock à 2x le seuil, pas d'historique de ventes dans cette première version), `purchase_order_model.dart`, `purchase_order_repository.dart` (création du bon de commande DRAFT à partir des suggestions sélectionnées), `reorder_screen.dart` (liste des suggestions avec cases à cocher, génération du bon sous `purchase.order`).
  - Route `/reorder` + bouton accueil sous `PermissionGate(purchase.order)`.
  - `app/lib/features/pos/fefo.dart` : **FEFO intelligent** — nouvelle fonction `pickFefoAllocation` répartissant une quantité sur plusieurs lots (du plus proche de la péremption au plus lointain) quand aucun lot seul ne suffit ; `pickFefoLot` (lot unique) conservé pour compatibilité. `pos_repository.dart::checkout` utilise désormais l'allocation multi-lots (plusieurs `sale_items` par ligne de panier si répartie sur plusieurs lots).
  - `app/lib/features/fraud/fraud_signals.dart` : heuristique anti-fraude locale (pure) — remises répétées juste sous le seuil d'approbation, ventes hors plage horaire, montant largement supérieur à la moyenne de la session. Câblée à la clôture de caisse (`pos_screen.dart::_closeSession`) : boîte de dialogue d'anomalies avant confirmation si signaux détectés (la clôture reste possible après confirmation explicite).
  - Tests : `reorder_suggestion_test.dart`, `fraud_signals_test.dart`, ajout de cas `pickFefoAllocation` dans `fefo_test.dart`.
  - **Limite connue (MVP)** : suggestion de réappro sans historique de vélocité de ventes (`sale_items`) — raffinement possible en V2. Signal de fraude « remises » non alimenté en pratique tant que le panier ne transporte pas de `discountPercent` par vente (paramètre prêt côté fonction pure, pas encore branché à un champ `sales`).
- **S9 — Cycle de vie & péremptions** :
  - `0010_lifecycle.sql` : élargit `stock_movements.type` à `DONATION`/`SUPPLIER_RETURN` (en plus de `RECEIPT`/`ADJUSTMENT`/`TRANSFER`, tous sous `stock.adjust` sauf RECEPTION) ; nouvelle table `promotions` (remise % par produit avec fenêtre de validité), RLS lecture tenant / écriture sous `price.edit`.
  - `sync_rules.yaml` : `promotions` ajouté au bucket `by_tenant`.
  - `app/lib/core/sync/schema.dart` : table `promotions` côté PowerSync local.
  - `app/lib/features/lifecycle/` : `expiry_alerts.dart` (seuils J-90/J-30/J-7/expiré, pure), `lifecycle_screen.dart` (liste des lots en alerte triés par péremption, sortie de stock hors-vente — don/retour fournisseur/transfert — sous `stock.adjust`).
  - `app/lib/features/stock/stock_repository.dart` étendu : `recordStockExit` (sortie non-vente, décrémente le lot et journalise un mouvement négatif), `watchAllLots` (jointure lot+produit pour le suivi des péremptions).
  - `app/lib/features/promotions/` : `promotion_model.dart`, `promotion_pricing.dart` (`applyActivePromotion`, pure — applique la plus forte remise active), `promotions_repository.dart`, `promotions_screen.dart` (liste + création — fenêtre de validité par défaut 7 jours, pas de sélecteur de date dans cette première version).
  - `app/lib/features/pos/pos_screen.dart` : `_addToCart` applique désormais la promotion active du produit au moment de l'ajout au panier.
  - Routes `/lifecycle` (sous `stock.adjust`) et `/promotions` (sous `price.edit`) + boutons accueil.
  - Tests : `expiry_alerts_test.dart`, `promotion_pricing_test.dart`.
  - **Limite connue (MVP)** : le transfert inter-pharmacie (`TRANSFER`) ne journalise que le côté sortant — la réception côté pharmacie destinataire (tenant distinct) est hors scope MVP.
  - ✅ Vérifié (S9+S10, Flutter 3.44.2/Dart 3.12.2) : `flutter analyze` → 0 issue ; `flutter test` → 68/68 passés.
- **S8 — Facturation & impression (🚩 jalon Pilote)** :
  - `0009_invoices.sql` : `invoices` (numéro unique par tenant, lié à `sales`), fonction serveur `next_invoice_number()` (incrément atomique de `pharmacy_settings.invoice_next_number`, verrou de ligne — backstop côté cloud), RLS lecture tenant / insertion sous `invoice.issue`.
  - `sync_rules.yaml` : `invoices` ajouté au bucket `by_tenant`.
  - `app/lib/core/sync/schema.dart` : table `invoices` + colonne `pharmacy_settings.invoice_next_number` côté PowerSync local.
  - Dépendances ajoutées : `pdf`, `printing`, `esc_pos_utils_plus`.
  - `app/lib/features/invoicing/` : `invoice_numbering.dart` (formatage préfixe+compteur sur 6 chiffres), `invoice_models.dart` (`InvoiceLine`/`PharmacyInfo`/`InvoiceData`), `receipt_text.dart` (lignes textuelles pures, réutilisées par ticket et facture), `invoice_repository.dart` (numérotation séquentielle **locale** par tenant — lecture/incrément de `pharmacy_settings.invoice_next_number`, écrit `invoices`, assemble le contenu depuis `sale_items`→`lots`→`products` ; crée une `pharmacy_settings` par défaut si absente en mode démo), `invoice_pdf.dart` (facture A4 avec logo optionnel + ticket PDF étroit 58mm imitant le format thermique), `thermal_ticket.dart` (octets ESC/POS bruts via `esc_pos_utils_plus`, prêts pour une intégration imprimante Bluetooth/USB — pilote matériel hors scope MVP).
  - `app/lib/features/pos/pos_screen.dart` : après encaissement, émission automatique de la facture puis boîte de dialogue « Ticket thermique » / « Facture PDF » (impression via `printing` — boîte de dialogue système, fonctionne avec une imprimante thermique configurée comme imprimante système).
  - Tests : `invoice_numbering_test.dart`, `receipt_text_test.dart` (contenu lignes, sous-totaux, total).
  - ✅ Vérifié (Flutter 3.44.2/Dart 3.12.2) : `flutter analyze` → 0 issue ; `flutter test` → 41/41 passés.
  - **Limite connue (MVP)** : la numérotation de facture est incrémentée localement par appareil (pas de verrou distribué offline) — risque de collision si deux caissiers ouvrent une session simultanément sans synchro entre-temps ; acceptable pour une pharmacie mono-poste, à revisiter si multi-postes simultanés.
- **S7 — POS offline-first (caisse)** :
  - `0008_pos.sql` : `cash_sessions` (ouverture/clôture, total calculé depuis les ventes — jamais saisi à la main), `sales.cash_session_id`.
  - `sync_rules.yaml` : `cash_sessions` ajouté au bucket `by_tenant`.
  - `app/lib/core/sync/schema.dart` : table `cash_sessions` + colonne `sales.cash_session_id` côté PowerSync local.
  - `app/lib/features/pos/` : `cart_model.dart` (panier immuable, add/remove par produit), `fefo.dart` (sélection FEFO — prélève dans le lot qui périme le plus tôt), `pos_repository.dart` étendu (`openCashSession`/`closeCashSession`/`checkout` : résout le lot FEFO par ligne avant toute écriture, décrémente la quantité, journalise vente+lignes ; lève `InsufficientStockException` si aucun lot ne couvre seul la quantité), `pos_screen.dart` (recherche/scan produit, panier, encaissement espèces sous `pos.sell`, clôture sous `pos.cash.close`).
  - Route `/pos` + bouton accueil sous `PermissionGate(pos.sell)` (la démo S2 `/pos-demo` reste accessible).
  - Tests : `cart_model_test.dart`, `fefo_test.dart` (choix du lot le plus proche de la péremption, lots sans date priorisés en dernier, stock insuffisant).
  - ✅ Vérifié (Flutter 3.44.2/Dart 3.12.2) : `flutter analyze` → 0 issue ; `flutter test` → 35/35 passés.
- **S6 — Reprise de données / onboarding** :
  - Pas de migration DB (réutilise `products`/`lots`/`stock_movements` existants).
  - `app/lib/features/onboarding/` : `csv_import.dart` (parseur CSV RFC 4180 minimal sans dépendance externe, `parseProductCsv` colonnes nom/code_barres/prix/dci/categorie, `markDuplicates` doublons internes + existants), `onboarding_repository.dart` (import en masse → produits créés, inventaire initial → lots de départ), `onboarding_screen.dart` (assistant en 2 étapes : import CSV collé avec prévisu/doublons signalés, puis saisie des quantités de départ par produit importé).
  - Route `/onboarding` + bouton accueil sous `PermissionGate(settings.manage)`.
  - Tests : `csv_import_test.dart` (parsing CSV champs cités, lignes invalides ignorées, doublons internes/existants).
  - ✅ Vérifié (Flutter 3.44.2/Dart 3.12.2) : `flutter analyze` → 0 issue ; `flutter test` → 27/27 passés.
- **S5 — Stocks & lots + scan GS1** :
  - `0007_stock_movements.sql` : `suppliers` (par tenant), `stock_movements` (journal RECEIPT/ADJUSTMENT/TRANSFER, RLS séparant `stock.receive`/`stock.adjust`), `products.low_stock_threshold`.
  - `sync_rules.yaml` : `suppliers`/`stock_movements` ajoutés au bucket `by_tenant`.
  - `app/lib/core/sync/schema.dart` : tables `suppliers`/`stock_movements` + colonne `low_stock_threshold` côté PowerSync local.
  - `app/lib/features/stock/` : `gs1_parser.dart` (décodage AI 01/17/10 — GTIN/péremption/lot, FNC1 géré), `stock_models.dart`, `stock_repository.dart` (réception → crée/complète un lot + journalise le mouvement ; ajustement manuel ; vue agrégée stock par produit), `stock_screen.dart` (liste avec ruptures signalées sous seuil, réception via scan/saisie GS1 ou champs manuels sous `stock.receive`).
  - Route `/stock` + bouton accueil sous `PermissionGate(stock.view)`.
  - Tests : `gs1_parser_test.dart` (GTIN/péremption/lot, FNC1, chaînes invalides).
  - ✅ Vérifié (Flutter 3.44.2/Dart 3.12.2) : `flutter analyze` → 0 issue ; `flutter test` → 18/18 passés.
- **S4 — Catalogue & référentiel produits** :
  - `0005_catalog.sql` : `reference_products` (catalogue DCI global, RLS lecture authentifiée) + colonnes `products.dci_name/unit/category/reference_id`.
  - `0006_seed_reference_catalog.sql` : 10 médicaments courants pré-chargés (DCI + code-barres).
  - `sync_rules.yaml` : bucket global `reference_catalog` (hors partition tenant).
  - `app/lib/core/sync/schema.dart` : colonnes catalogue + table `reference_products` côté PowerSync local.
  - `app/lib/features/catalog/` : `product_model.dart` (+ `normalizeBarcode`), `products_repository.dart` (recherche nom/DCI/code-barres, création produit depuis le référentiel ou en saisie libre, association code-barres au vol, édition prix), `catalog_screen.dart` (recherche instantanée, FAB ajout sous `product.create`, édition prix sous `price.edit`).
  - Route `/catalog` + bouton accueil sous `PermissionGate(stock.view)`.
  - Tests : `product_model_test.dart` (normalisation code-barres + parsing).
  - ✅ Vérifié (Flutter 3.44.2/Dart 3.12.2) : `flutter analyze` → 0 issue (2 `use_build_context_synchronously` corrigés avec garde `context.mounted` dans `_editPrice`/`_attachBarcode`) ; `flutter test` → 13/13 passés.
- Plateformes : **Android + Web** (iOS repoussé). Une seule app Flutter.
- **S1 — socle** :
  - `supabase/migrations/0001_core.sql` : tenants, users (liés `auth.users`), RBAC, `pharmacy_settings` (logo/identité/devise XOF·XAF), `audit_log` immuable **chaîné par hash**, **RLS** + habilitation.
  - `0002_seed_permissions.sql` : catalogue des permissions.
  - `app/` : Flutter (Riverpod Notifier, go_router, i18n FR/EN, thème M3).
- **S2 — sync offline (PowerSync)** :
  - `0003_business_core.sql` : products, lots, sales, sale_items + RLS.
  - `supabase/sync_rules.yaml` : bucket par tenant.
  - `app/lib/core/sync/` : `schema.dart` (tables offline), `supabase_connector.dart` (upload CRUD + conflits **LWW**), `sync_service.dart` (base locale toujours ouverte, synchro si configurée), `config/env.dart` (--dart-define).
  - `flutter analyze` OK, test OK.
- **S2b — démo + Drift + CI** :
  - `app/lib/features/pos/` : `pos_repository.dart` (créer vente+ligne en local, watch, file d'upload) + `pos_demo_screen.dart` (route `/pos-demo`, accès depuis l'accueil) → prouve l'écriture **offline**.
  - `app/lib/core/db/app_database.dart` (+ `.g.dart`) : couche **Drift typée** sur la connexion PowerSync (table `Sales`). build_runner OK.
  - `.github/workflows/ci.yml` : format + analyze + test sur push/PR.
- **S3 — auth + RBAC (entamé)** :
  - `0004_my_permissions.sql` : RPC `my_permissions()`.
  - `app/lib/core/auth/` : `AuthRepository` (signIn/out/state, tolérant hors config) + providers.
  - `app/lib/core/rbac/` : `permissions.dart` (catalogue `Permissions` + `PermissionSet`), `rbac_providers.dart` (`permissionsProvider` via RPC, `watchCan`), `permission_gate.dart` (widget).
  - `app/lib/features/auth/login_screen.dart` + garde go_router (`routerProvider`, redirect gardé par `Env.isConfigured`).
  - `app/lib/core/rbac/approval_policy.dart` : **validation hiérarchique** (seuils remise/ajustement, prix & remboursement toujours) + tests.
  - `app/lib/features/admin/` : `roles_repository.dart` (cloud, graceful) + `roles_screen.dart` (catalogue permissions groupé par module, liste rôles si configuré), route `/admin/roles`, lien accueil sous `PermissionGate(user.manage)`.
  - **Mode local = tous les droits** (dev) pour explorer l'UI. 8 tests verts.
  - **Reste S3 (cloud uniquement)** : test auth réel, **enrôlement MFA** (API Supabase), **persistance CRUD rôles** (créer rôle + écrire role_permissions), création profil/tenant à l'inscription/onboarding.
- ⏳ **Pas encore branché au cloud** : Supabase CLI/Docker absents. Migrations = fichiers, jamais appliquées. Projet Supabase + instance PowerSync = **coût → feu vert PO requis**. C'est ce qui manque pour clore officiellement le **jalon S2** (test live : vente offline → synchro sans perte).
- ⚠️ Incident 21/06 : disque `E:` déconnecté → tout sur `C:` (repo git = sauvegarde).

## ▶ POINT DE REPRISE (prochaine session)
S9+S10 faits en local (Cycle de vie & péremptions + Mini IA étage 1 local & réappro). Tout vérifié (`flutter analyze` 0 issue, `flutter test` 68/68).
Au choix du PO :
1. **S11 et suite** (cf. `PROGRAMME_DEVELOPPEMENT.md`) pour continuer le plan S1→S12 en local.
2. **Provisionner Supabase + PowerSync** (coût) → appliquer 0001→0011, instance PowerSync, `env.json`, puis valider en live (auth + MFA + CRUD rôles + vente offline→synchro + catalogue partagé + facturation + réappro/anti-fraude).

> Reco Claude : poursuivre la dynamique avec le sprint suivant du programme (S11) tant que le cloud n'est pas provisionné.

Outillage machine : git, Node/npm, Flutter/Dart (`C:\flutter`), VS Code ✓ · Supabase CLI, Docker ✗.
Lancer l'app configurée : `flutter run --dart-define-from-file=env.json` (modèle : `app/.env.example`).
