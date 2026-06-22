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
- Phase : **S1, S2, S2b, S3, S4 faits ; S5 fait en local** (reste = pièces cloud). Repo git `C:\Claude\TM_Projects\TM_Pharma`, branche `main` (+ poussé sur GitHub). Commits : `7c7ddd3` (S1), `4218b36` (S2), `34be20d` (démo+CI), `5f5e131` (Drift), `af75472` (S3 auth+RBAC), `8b85211` (S3 validation+rôles), `7783d4c` (doc), S4, puis S5 (ce commit).
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
S4 fait en local (catalogue & référentiel DCI). **Priorité immédiate : lancer `flutter analyze` + `flutter test` (app/)** — pas pu être vérifié dans cette session (pas de Flutter dans l'environnement d'exécution). Corriger toute erreur avant de poursuivre.
Ensuite, au choix du PO :
1. **S5 — Stocks & lots + scan GS1** : mouvements de stock, fournisseurs, seuils, réception, capture GS1 (lot/péremption/GTIN). Gratuit, enchaîne bien sur le catalogue.
2. **Provisionner Supabase + PowerSync** (coût) → appliquer 0001→0006, instance PowerSync, `env.json`, puis valider en live (auth + MFA + CRUD rôles + vente offline→synchro + catalogue partagé).

> Reco Claude : **vérifier S4** (analyze/test) en tout premier ; puis **1** (S5) pour garder l'élan.

Outillage machine : git, Node/npm, Flutter/Dart (`C:\flutter`), VS Code ✓ · Supabase CLI, Docker ✗.
Lancer l'app configurée : `flutter run --dart-define-from-file=env.json` (modèle : `app/.env.example`).
