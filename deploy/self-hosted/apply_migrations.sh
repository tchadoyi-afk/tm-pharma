#!/usr/bin/env bash
# ============================================================================
# TM Pharma — Applique les migrations supabase/migrations/*.sql, dans l'ordre
# numérique, contre le Postgres self-hébergé (deploy/self-hosted/).
#
# Usage :
#   cd deploy/self-hosted
#   cp .env.example .env   # puis remplir des secrets réels
#   docker compose up -d postgres
#   ./apply_migrations.sh
#
# Idempotent : garde la trace des migrations déjà appliquées dans une table
# `public.schema_migrations`, comme le ferait `supabase db push` côté cloud —
# relancer le script ne rejoue pas une migration déjà passée.
#
# ⚠️ Non exécuté en conditions réelles dans cet environnement (pas de Docker
# ici). À tester sur un vrai VPS avant le pilote. Toujours faire un
# `pg_dump` de sauvegarde avant de lancer ce script sur une base contenant
# déjà des données réelles (règle du projet : migration prod = feu vert
# explicite + sauvegarde/rollback préparés).
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR/../../supabase/migrations"

if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/.env"
  set +a
fi

POSTGRES_DB="${POSTGRES_DB:-tm_pharma}"
POSTGRES_USER="${POSTGRES_USER:-tm_pharma}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-changeme}"
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

export PGPASSWORD="$POSTGRES_PASSWORD"
PSQL=(psql -v ON_ERROR_STOP=1 -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB")

echo "→ Cible : $POSTGRES_USER@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB"

"${PSQL[@]}" -c "
  create table if not exists public.schema_migrations (
    filename    text primary key,
    applied_at  timestamptz not null default now()
  );
" >/dev/null

shopt -s nullglob
for file in "$MIGRATIONS_DIR"/*.sql; do
  name="$(basename "$file")"
  already_applied="$("${PSQL[@]}" -tAc "select 1 from public.schema_migrations where filename = '$name'")"
  if [ "$already_applied" = "1" ]; then
    echo "  ⏭  $name (déjà appliquée)"
    continue
  fi
  echo "  ▶  $name"
  "${PSQL[@]}" -f "$file"
  "${PSQL[@]}" -c "insert into public.schema_migrations (filename) values ('$name');" >/dev/null
done

echo "✓ Migrations à jour."
