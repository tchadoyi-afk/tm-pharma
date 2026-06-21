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
- Phase : **S1 + S2 + S2b livrés (sauf test live cloud).** Repo git `C:\Claude\TM_Projects\TM_Pharma`, branche `main`. Commits : `7c7ddd3` (S1), `4218b36` (S2), `34be20d` (démo+CI), `5f5e131` (Drift).
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
- ⏳ **Pas encore branché au cloud** : Supabase CLI/Docker absents. Migrations = fichiers, jamais appliquées. Projet Supabase + instance PowerSync = **coût → feu vert PO requis**. C'est ce qui manque pour clore officiellement le **jalon S2** (test live : vente offline → synchro sans perte).
- ⚠️ Incident 21/06 : disque `E:` déconnecté → tout sur `C:` (repo git = sauvegarde).

## ▶ POINT DE REPRISE (prochaine session)
Au choix du PO :
1. **Provisionner Supabase + PowerSync** (coût) → appliquer 0001/0002/0003, créer l'instance PowerSync avec `sync_rules.yaml`, configurer `env.json` (modèle `app/.env.example`), puis **test live** : vente hors-ligne → synchro sans perte (= clôture jalon S2). + valider la couche Drift sur un vrai run device/web.
2. **Avancer S3 — Auth, RBAC fin & habilitations** : login + MFA Supabase, écran d'auth, création des rôles par tenant à partir du catalogue de permissions, validation hiérarchique. (Peut se faire sans cloud pour l'UI, mais l'auth réelle a besoin de Supabase.)
3. **Pousser le repo sur GitHub** (déclenche la CI) — repo encore local uniquement.

> Reco Claude : **1** (provisioning + test live) pour clore proprement S2 avant d'avancer ; sinon **3** (push GitHub) pour activer la CI tout de suite (gratuit).

Outillage machine : git, Node/npm, Flutter/Dart (`C:\flutter`), VS Code ✓ · Supabase CLI, Docker ✗.
Lancer l'app configurée : `flutter run --dart-define-from-file=env.json` (modèle : `app/.env.example`).
