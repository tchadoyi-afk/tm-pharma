# TM Pharma

SaaS B2B **multi-tenant, offline-first** de gestion de pharmacies africaines (🇹🇬 Togo · 🇬🇦 Gabon).
Éditeur : **T&M Logiciels**. Mini IA au cœur de l'app, habilitation fine, traçabilité et KPIs précis.

## Documents
- [`CDC_TM_Pharma_v1.md`](CDC_TM_Pharma_v1.md) — cahier des charges officiel (le « quoi »).
- [`PROGRAMME_DEVELOPPEMENT.md`](PROGRAMME_DEVELOPPEMENT.md) — plan d'exécution, 12 sprints (le « comment »).
- [`CONTEXTE_RAPIDE.md`](CONTEXTE_RAPIDE.md) — reprise de session.

## Stack
- **Frontend** : Flutter (Web back-office + Mobile/Tablette caisse) — Riverpod.
- **Backend** : Supabase (Postgres + RLS multi-tenant + Auth/MFA + Storage + Realtime + Edge Functions).
- **Offline-first** : PowerSync + Drift/SQLite (sync bidirectionnelle, UUID v4, LWW + règles).
- **IA** : moteur local (offline) + API Claude (assistant & prévisions, online).

## Structure du dépôt
```
app/                  application Flutter
supabase/
  migrations/         schéma SQL versionné (multi-tenant + RLS + audit)
  seed/               données de référence (permissions, rôles…)
docs/                 documentation technique additionnelle
```

## Avancement
**Sprint 1 — Socle technique & sécurité** (en cours).
Voir [`PROGRAMME_DEVELOPPEMENT.md` §8](PROGRAMME_DEVELOPPEMENT.md) pour le plan des 12 sprints.

## Conventions
- Migrations : `supabase/migrations/NNNN_description.sql` (numérotées, append-only).
- ⚠️ Toute migration appliquée en **prod** exige un **feu vert explicite** du PO.
- Toutes les tables métier : `id` UUID, `tenant_id`, `created_at`, `updated_at`, `deleted_at` (soft-delete), RLS activée.
