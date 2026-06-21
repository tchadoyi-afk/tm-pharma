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
- Phase : **S1 livré (socle).** Repo git initialisé (`C:\Claude\TM_Projects\TM_Pharma`, branche `main`, 1er commit `7c7ddd3`).
- **Code en place** :
  - `supabase/migrations/0001_core.sql` : tenants, users (liés `auth.users`), RBAC (roles/permissions/role_permissions/user_roles), `pharmacy_settings` (logo/identité/devise XOF-Togo·XAF-Gabon), `audit_log` immuable **chaîné par hash**, **RLS** stricte par `tenant_id` + habilitation.
  - `supabase/migrations/0002_seed_permissions.sql` : catalogue global des permissions.
  - `app/` : Flutter (Riverpod Notifier, go_router, i18n FR/EN, thème clair/sombre M3, écran d'accueil). `flutter analyze` OK, test OK.
- ⏳ **Pas encore appliqué au cloud** : Supabase CLI/Docker absents ; migrations = fichiers. Le projet Supabase cloud (coût) attend le **feu vert PO**.
- ⚠️ Incident 21/06 : disque `E:` déconnecté → tout est sur `C:`. (Repo git = sauvegarde désormais.)

## ▶ POINT DE REPRISE (prochaine session)
Au choix du PO :
1. **Provisionner Supabase** (a un coût) → appliquer 0001 + 0002, générer les types, tester la RLS d'isolation. *(via MCP Supabase ou installer la CLI)*
2. **CI/CD** (reste de S1) : GitHub Actions `flutter analyze`+`test`, lint SQL.
3. **Démarrer S2 — moteur de sync offline** (PowerSync + Drift) : le risque technique n°1.

> Reco Claude : enchaîner **S2 (sync)** pour lever le risque archi tôt ; le provisioning Supabase peut se faire juste avant (S2 a besoin d'une base réelle pour tester la synchro).

Outillage machine : git, Node/npm, Flutter/Dart (`C:\flutter`), VS Code ✓ · Supabase CLI, Docker ✗.
