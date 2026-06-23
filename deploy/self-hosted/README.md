# Self-hosting TM Pharma (pilote, coût minimal)

Stack prête à déployer sur un petit VPS (ex. Hetzner/DigitalOcean, ~10-25 $/mois),
pour la **phase pilote**, avant une bascule éventuelle vers Supabase Cloud /
PowerSync Cloud managés avant la mise en production réelle (voir décision dans
`PROGRAMME_DEVELOPPEMENT.md` §0 et `CONTEXTE_RAPIDE.md`).

⚠️ **Non testé en conditions réelles dans le développement de ce projet** (pas
de Docker disponible dans l'environnement de dev utilisé jusqu'ici). À valider
pas à pas sur un vrai VPS avant d'y mettre des données de pharmacie réelles.

## Contenu

- `docker-compose.yml` : Postgres (base applicative) + GoTrue (Auth Supabase
  open-source) + service PowerSync Open Edition (sync, self-hébergé, gratuit).
- `powersync.yaml` : config du service PowerSync (réplication, stockage des
  buckets sur Postgres, règles de sync = `supabase/sync_rules.yaml` existant).
- `.env.example` : variables à copier en `.env` (secrets réels, jamais commités).

## Étapes de déploiement (résumé)

1. Provisionner un VPS (Ubuntu/Debian récent), installer Docker + Docker Compose.
2. Copier ce dossier `deploy/self-hosted/` sur le VPS.
3. `cp .env.example .env` puis remplir des secrets réels forts (mot de passe
   Postgres, `JWT_SECRET` aléatoire ≥32 caractères).
4. `docker compose up -d` pour démarrer Postgres + Auth + PowerSync.
5. Appliquer les migrations existantes (`supabase/migrations/0001` → la
   dernière) sur ce Postgres — avec `psql` directement, dans l'ordre des
   numéros de fichiers (elles sont écrites pour Postgres standard, pas
   spécifiques à Supabase Cloud).
6. Vérifier que la réplication logique fonctionne : le service PowerSync doit
   démarrer sans erreur et exposer son port (8080 par défaut).
7. Pointer l'app Flutter vers ce serveur : adapter `app/.env.example` /
   `env.json` avec l'URL Postgres/Auth et l'URL du service PowerSync
   self-hébergé (au lieu des URLs Supabase Cloud + PowerSync Cloud).
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
