-- ============================================================================
-- TM Pharma — Migration 0016 : durcissement des fonctions exposées en RPC
-- Constats de l'audit sécurité (get_advisors) sur la mise en prod initiale :
-- - Les fonctions trigger (set_updated_at, audit_log_chain,
--   audit_log_immutable) sont auto-exposées par PostgREST comme RPC
--   publiques alors qu'elles ne doivent être invoquées que par les
--   triggers (REVOKE EXECUTE ne change rien à leur déclenchement par
--   trigger, seulement à leur appel direct via /rest/v1/rpc/...).
-- - next_invoice_number(p_tenant_id) acceptait un tenant_id arbitraire en
--   paramètre au lieu de le dériver de private.current_tenant_id() : tout
--   utilisateur authentifié pouvait faire avancer le compteur de factures
--   d'un AUTRE tenant — fuite cross-tenant corrigée ici en supprimant le
--   paramètre et en vérifiant l'habilitation invoice.issue.
-- ============================================================================

revoke execute on function public.set_updated_at() from public;
revoke execute on function public.audit_log_chain() from public;
revoke execute on function public.audit_log_immutable() from public;

drop function public.next_invoice_number(uuid);

create function public.next_invoice_number()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := private.current_tenant_id();
  v_prefix text;
  v_number bigint;
begin
  if not private.has_permission('invoice.issue') then
    raise exception 'permission refusée : invoice.issue requis';
  end if;

  select coalesce(invoice_prefix, 'INV'), invoice_next_number
    into v_prefix, v_number
    from public.pharmacy_settings
   where tenant_id = v_tenant_id
     for update;

  if v_number is null then
    raise exception 'pharmacy_settings introuvable pour ce tenant';
  end if;

  update public.pharmacy_settings
     set invoice_next_number = invoice_next_number + 1
   where tenant_id = v_tenant_id;

  return v_prefix || '-' || lpad(v_number::text, 6, '0');
end;
$$;

grant execute on function public.next_invoice_number() to authenticated;
