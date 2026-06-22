-- ============================================================================
-- S8 — Facturation : factures liées aux ventes, numérotation séquentielle
-- par tenant (préfixe + compteur de pharmacy_settings).
-- ============================================================================
create table public.invoices (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references public.tenants(id),
  sale_id         uuid not null references public.sales(id),
  invoice_number  text not null,
  issued_at       timestamptz not null default now(),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz,
  unique (tenant_id, invoice_number),
  unique (sale_id)
);
create index idx_invoices_tenant on public.invoices(tenant_id, issued_at);
create trigger trg_invoices_updated before update on public.invoices
  for each row execute function public.set_updated_at();

-- ----------------------------------------------------------------------------
-- Génère le prochain numéro de facture du tenant en incrémentant de façon
-- atomique pharmacy_settings.invoice_next_number (verrou de ligne).
-- ----------------------------------------------------------------------------
create function public.next_invoice_number(p_tenant_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_prefix text;
  v_number bigint;
begin
  select coalesce(invoice_prefix, 'INV'), invoice_next_number
    into v_prefix, v_number
    from public.pharmacy_settings
   where tenant_id = p_tenant_id
     for update;

  if v_number is null then
    raise exception 'pharmacy_settings introuvable pour ce tenant';
  end if;

  update public.pharmacy_settings
     set invoice_next_number = invoice_next_number + 1
   where tenant_id = p_tenant_id;

  return v_prefix || '-' || lpad(v_number::text, 6, '0');
end;
$$;

alter table public.invoices enable row level security;

create policy invoices_read on public.invoices
  for select using (tenant_id = private.current_tenant_id());

create policy invoices_insert on public.invoices
  for insert with check (
    tenant_id = private.current_tenant_id()
    and private.has_permission('invoice.issue')
  );
