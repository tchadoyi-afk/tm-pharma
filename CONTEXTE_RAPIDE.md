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
- Phase : **Cadrage terminé.** Programme de dev rédigé et validé (archi, IA, RBAC, KPIs, traçabilité, facturation, roadmap).
- Dossier = docs uniquement (PDF CDC + modèle de données + `PROGRAMME_DEVELOPPEMENT.md` + ce fichier). **Pas encore de code, pas de repo git.**
- ⚠️ Incident 21/06 : le disque `E:` (où les docs avaient été écrits) s'est déconnecté/remonté ; docs recréés sur `C:`. Penser à un **repo git + sauvegarde**.

## ▶ POINT DE REPRISE (prochaine session)
**Démarrer S1 — Socle technique & sécurité.** Actions :
1. `git init` + sauvegarde (leçon incident disque E:).
2. Créer le projet **Supabase** (env dev/prod) + schéma multi-tenant + **RLS**.
3. Scaffold **Flutter** (Riverpod, routing, i18n FR/EN, thème) + `audit_log` chaîné de base + paramètres pharmacie (identité + logo).
4. Enchaîner **S2 = moteur de sync PowerSync + Drift** (risque n°1 à lever tôt).

> Note : si tu préfères dérisquer l'archi avant tout, on peut faire le **PoC sync (S2)** en parallèle de S1.
