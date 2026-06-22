-- ============================================================================
-- TM Pharma — Migration 0012 : gating des modules sous licence (palier)
-- Décision actée : MVP (gestion d'officine), V2 (+ emploi du temps) et V3
-- (+ RH/paie élargie) sont des paliers de licence distincts. Le tronc commun
-- ne doit jamais coder en dur l'accès à un module V2/V3 : il consulte
-- `tenants.licensed_modules`. Aucun module V2/V3 n'est implémenté ici — ce
-- n'est que le point d'accroche posé dès le MVP pour éviter une rustine
-- plus tard.
-- ============================================================================

alter table public.tenants
  add column if not exists licensed_modules text[] not null default array[]::text[];

comment on column public.tenants.licensed_modules is
  'Codes des modules sous licence activés pour ce tenant '
  '(ex. ''scheduling'' pour l''emploi du temps V2, ''hr_payroll'' pour la RH/paie élargie V3). '
  'Vide par défaut : le MVP ne dépend d''aucun module sous licence.';

-- RPC pratique côté app pour vérifier l'accès à un module sans dupliquer la
-- logique de lecture du tenant courant à chaque écran.
create or replace function public.has_licensed_module(p_module text)
returns boolean
language sql
security definer
set search_path = ''
stable
as $$
  select coalesce(
    (select p_module = any(t.licensed_modules)
     from public.tenants t
     where t.id = private.current_tenant_id()),
    false
  );
$$;
