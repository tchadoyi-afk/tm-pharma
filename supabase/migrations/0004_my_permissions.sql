-- ============================================================================
-- TM Pharma — Migration 0004 : RPC des permissions de l'utilisateur courant (S3)
-- Renvoie les codes de permission de l'utilisateur connecté (via ses rôles).
-- Appelée par l'app au login pour piloter l'affichage et les actions (RBAC).
-- ============================================================================

create or replace function public.my_permissions()
returns setof text
language sql
stable
security definer
set search_path = ''
as $$
  select rp.permission_code
  from public.user_roles ur
  join public.role_permissions rp on rp.role_id = ur.role_id
  where ur.user_id = auth.uid()
$$;

-- Exécutable par les utilisateurs authentifiés.
grant execute on function public.my_permissions() to authenticated;
