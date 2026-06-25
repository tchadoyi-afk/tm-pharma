-- ============================================================================
-- TM Pharma — Bootstrap d'un compte administrateur pilote.
-- À exécuter manuellement une seule fois sur la base self-hébergée, APRÈS
-- les migrations (supabase/migrations/) :
--   psql -v admin_password="'<mot-de-passe-ici>'" -f seed_admin.sql
-- (mot de passe passé en variable psql, jamais en dur dans ce fichier ni
-- dans git — choisir une valeur respectant la politique GOTRUE_PASSWORD_*.)
-- Insertion directe dans auth.users : pas d'appel à GoTrue ici, donc cette
-- politique n'est pas vérifiée automatiquement par ce script. À changer
-- dès la première connexion (cf. consigne initiale).
-- ============================================================================

do $$
declare
  v_tenant_id uuid;
  v_user_id   uuid := gen_random_uuid();
  v_role_id   uuid;
  v_password  text := :admin_password;
begin
  insert into public.tenants (name, slug, status)
  values ('Pharmacie pilote', 'pharmacie-pilote', 'TRIAL')
  returning id into v_tenant_id;

  insert into auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data
  ) values (
    v_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    'rexxio@gmx.fr', crypt(v_password, gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}'
  );

  insert into public.users (id, tenant_id, full_name, email, status)
  values (v_user_id, v_tenant_id, 'Admin', 'rexxio@gmx.fr', 'ACTIVE');

  insert into public.roles (tenant_id, name, description, is_system)
  values (v_tenant_id, 'Admin', 'Rôle administrateur — toutes permissions', true)
  returning id into v_role_id;

  insert into public.role_permissions (role_id, permission_code, tenant_id)
  select v_role_id, code, v_tenant_id from public.permissions;

  insert into public.user_roles (user_id, role_id, tenant_id)
  values (v_user_id, v_role_id, v_tenant_id);
end $$;
