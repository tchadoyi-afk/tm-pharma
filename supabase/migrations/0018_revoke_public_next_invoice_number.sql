-- ============================================================================
-- TM Pharma — Migration 0018 : durcissement next_invoice_number()
-- La migration 0016 recrée next_invoice_number() avec un grant explicite
-- vers authenticated, mais ne révoque pas le grant EXECUTE par défaut
-- accordé à public par PostgreSQL sur toute nouvelle fonction. La
-- fonction reste donc appelable de manière anonyme via
-- /rest/v1/rpc/next_invoice_number (le contrôle interne sur invoice.issue
-- bloque l'opération, mais l'accès anonyme à la fonction n'est pas censé
-- être possible).
-- ============================================================================

revoke execute on function public.next_invoice_number() from public;
