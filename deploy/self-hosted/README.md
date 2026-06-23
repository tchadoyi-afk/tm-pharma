# Self-hosting TM Pharma (pilote, coût minimal)

Stack prête à déployer sur un petit VPS (ex. Hetzner/DigitalOcean, ~10-25 $/mois),
pour la **phase pilote**, avant une bascule éventuelle vers Supabase Cloud /
PowerSync Cloud managés avant la mise en production réelle (voir décision dans
`PROGRAMME_DEVELOPPEMENT.md` §0 et `CONTEXTE_RAPIDE.md`).

⚠️ **Non testé en conditions réelles dans le développement de ce projet** (pas
de Docker disponible dans l'environnement de dev utilisé jusqu'ici). À valider
pas à pas sur un vrai VPS avant d'y mettre des données de pharmacie réelles.

## Contenu

- `docker-compose.yml` : Postgres (image `supabase/postgres`, fournit le
  schéma `auth`/`auth.uid()` dont dépendent nos migrations et policies RLS)
  + GoTrue (Auth) + PostgREST (API REST, utilisée par `supabase_flutter`
  pour envoyer les écritures locales — voir `supabase_connector.dart`) +
  Kong (passerelle unique qui route `/rest/v1` et `/auth/v1`, exactement
  comme Supabase Cloud, pour que `supabase_flutter` fonctionne sans
  modification) + service PowerSync Open Edition (sync, self-hébergé,
  gratuit).
- `kong.yml` : config déclarative de la passerelle (routes `/rest/v1` →
  PostgREST, `/auth/v1` → GoTrue).
- `powersync.yaml` : config du service PowerSync (réplication, stockage des
  buckets sur Postgres, règles de sync = `supabase/sync_rules.yaml` existant).
- `.env.example` : variables à copier en `.env` (secrets réels, jamais commités).
- `apply_migrations.sh` : applique `supabase/migrations/*.sql` dans l'ordre,
  de façon idempotente (suivi dans `public.schema_migrations`).

## Étapes de déploiement (résumé)

1. Provisionner un VPS (Ubuntu/Debian récent), installer Docker + Docker Compose.
2. Copier ce dossier `deploy/self-hosted/` sur le VPS.
3. `cp .env.example .env` puis remplir des secrets réels forts (mot de passe
   Postgres, `JWT_SECRET` aléatoire ≥32 caractères).
4. `docker compose up -d` pour démarrer les 5 services : Postgres, Auth
   (GoTrue), PostgREST, Kong (passerelle, port 8000) et PowerSync.
5. Appliquer les migrations existantes (`supabase/migrations/0001` → la
   dernière) : `./apply_migrations.sh` (nécessite `psql` installé sur la
   machine qui lance le script, et le service `postgres` démarré et
   joignable). Le script est idempotent (table `public.schema_migrations`,
   relancer ne rejoue pas ce qui est déjà appliqué) — toujours faire un
   `pg_dump` de sauvegarde avant de l'exécuter sur une base avec des
   données réelles.
6. Vérifier que la réplication logique fonctionne : le service PowerSync doit
   démarrer sans erreur et exposer son port (8080 par défaut).
7. Pointer l'app Flutter vers ce serveur, via `app/.env.example` / `env.json`
   (ou `--dart-define`) :
   - `SUPABASE_URL` = l'URL de Kong (passerelle unique), ex.
     `http://<host-vps>:8000` — **pas** l'URL directe de GoTrue ou PostgREST.
   - `SUPABASE_KEY` = un JWT signé avec le même `JWT_SECRET` que dans `.env`,
     avec le claim `role: anon` (rôle utilisé par `supabase_flutter` pour les
     requêtes non authentifiées initiales). Sur Supabase Cloud ce JWT est
     généré et affiché automatiquement dans le dashboard ; en self-hosting il
     n'y a pas de dashboard, il faut le générer soi-même, par ex. via
     https://jwt.io (algorithme HS256, secret = `JWT_SECRET`, payload
     `{"role": "anon", "iss": "supabase"}`, sans expiration ou avec une
     expiration longue) ou un script `jwt` en ligne de commande. Ne jamais
     committer ce JWT généré (comme pour `.env`).
   - `POWERSYNC_URL` = l'URL du service PowerSync self-hébergé (port 8080).
8. Tester un scénario complet : créer un tenant + utilisateur, se connecter
   depuis l'app, faire une vente hors-ligne, vérifier la synchro.

## Ce qui reste à valider avant le pilote réel

- Le schéma exact de `powersync.yaml` (champs `client_auth`, `storage`,
  `replication`) doit être revérifié contre la documentation PowerSync au
  moment du déploiement — le format a pu évoluer depuis la rédaction de ce
  fichier (juin 2026). Référence : https://docs.powersync.com/intro/self-hosting
- Sauvegardes automatiques de Postgres (pas incluses ici — à ajouter, ex.
  `pg_dump` planifié + copie hors du VPS).
- Renouvellement TLS/HTTPS (certificat) si le VPS expose ces services
  publiquement plutôt qu'en interne derrière l'app.
- Migration GoTrue : MFA, templates d'emails (réinitialisation mot de passe)
  — à configurer (SMTP) avant un usage pilote réel avec de vrais utilisateurs.

## Bascule ultérieure vers du managé (avant la mise en prod réelle)

Comme la base est du Postgres standard avec le même schéma, la bascule vers
Supabase Cloud se fait par `pg_dump`/`pg_restore` puis changement d'URL de
connexion côté app — pas de réécriture de code (voir décision documentée dans
`PROGRAMME_DEVELOPPEMENT.md`). Idem pour repasser de PowerSync self-hébergé à
PowerSync Cloud managé : seule l'URL du service change côté app.
