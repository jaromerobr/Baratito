-- ============================================================
-- Baratito — Comisión (Modelo A: Baratito recaudador)
-- Comprador paga el TOTAL a Baratito → Baratito retiene su % y
-- paga a cada vendedor (precio - comisión).
-- Ejecuta TODO en Supabase → SQL Editor → Run. Idempotente.
-- Requiere haber corrido antes: 05 (is_admin) y 07 (checkout).
-- ============================================================

-- (Informativo) valores del enum order_status:
select unnest(enum_range(null::public.order_status))::text as order_status_values;

-- ────────────────────────────────────────────────────────
-- 1. Ajustes de plataforma (fila única): % de comisión + datos
--    de cobro de Baratito (a dónde paga el comprador).
-- ────────────────────────────────────────────────────────
create table if not exists public.platform_settings (
  id                    int primary key default 1,
  commission_percent    numeric not null default 10
                        check (commission_percent >= 0 and commission_percent <= 100),
  payout_bank           text default 'Banco de Loja',
  payout_account_name   text default 'Baratito',
  payout_account_number text,
  payout_qr_path        text,
  updated_at            timestamptz not null default now(),
  constraint platform_settings_single_row check (id = 1)
);

insert into public.platform_settings (id, commission_percent)
values (1, 10) on conflict (id) do nothing;

grant all on public.platform_settings to anon, authenticated, service_role;
alter table public.platform_settings enable row level security;

drop policy if exists "Ajustes legibles" on public.platform_settings;
create policy "Ajustes legibles"
  on public.platform_settings for select to authenticated using (true);

drop policy if exists "Admin edita ajustes" on public.platform_settings;
create policy "Admin edita ajustes"
  on public.platform_settings for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ────────────────────────────────────────────────────────
-- 2. CHECKOUTS — el "pedido" (pago único del comprador a Baratito)
-- ────────────────────────────────────────────────────────
create table if not exists public.checkouts (
  id                 uuid primary key default gen_random_uuid(),
  buyer_id           uuid not null references public.profiles(id) on delete cascade,
  total_amount       numeric not null,
  commission_percent numeric not null,
  platform_fee_total numeric not null,   -- lo que retiene Baratito
  status             text not null default 'pending_payment',
                     -- pending_payment | awaiting_confirmation | paid | cancelled
  proof_path         text,               -- comprobante que sube el comprador
  paid_at            timestamptz,
  confirmed_by       uuid references public.profiles(id),
  created_at         timestamptz not null default now()
);

grant all on public.checkouts to anon, authenticated, service_role;
alter table public.checkouts enable row level security;

drop policy if exists "Checkout propio o admin" on public.checkouts;
create policy "Checkout propio o admin"
  on public.checkouts for select to authenticated
  using (auth.uid() = buyer_id or public.is_admin());

drop policy if exists "Comprador actualiza su checkout" on public.checkouts;
create policy "Comprador actualiza su checkout"
  on public.checkouts for update to authenticated
  using (auth.uid() = buyer_id) with check (auth.uid() = buyer_id);

drop policy if exists "Admin actualiza checkouts" on public.checkouts;
create policy "Admin actualiza checkouts"
  on public.checkouts for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ────────────────────────────────────────────────────────
-- 3. ORDERS — desglose de comisión por orden
-- ────────────────────────────────────────────────────────
alter table public.orders add column if not exists commission_percent numeric;
alter table public.orders add column if not exists platform_fee numeric;   -- comisión Baratito
alter table public.orders add column if not exists seller_payout numeric;   -- lo que recibe el vendedor

-- ────────────────────────────────────────────────────────
-- 4. PAYOUTS — lo que Baratito debe pagar a cada vendedor
-- ────────────────────────────────────────────────────────
create table if not exists public.payouts (
  id          uuid primary key default gen_random_uuid(),
  seller_id   uuid not null references public.profiles(id) on delete cascade,
  checkout_id uuid references public.checkouts(id) on delete cascade,
  amount      numeric not null,
  status      text not null default 'pending',  -- pending | paid
  paid_at     timestamptz,
  created_at  timestamptz not null default now()
);

grant all on public.payouts to anon, authenticated, service_role;
alter table public.payouts enable row level security;

drop policy if exists "Payout propio o admin" on public.payouts;
create policy "Payout propio o admin"
  on public.payouts for select to authenticated
  using (auth.uid() = seller_id or public.is_admin());

drop policy if exists "Admin gestiona payouts" on public.payouts;
create policy "Admin gestiona payouts"
  on public.payouts for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ────────────────────────────────────────────────────────
-- 5. checkout_cart() — ahora calcula comisión y crea el checkout
-- ────────────────────────────────────────────────────────
create or replace function public.checkout_cart()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  _uid       uuid := auth.uid();
  _pct       numeric;
  _checkout  uuid;
  _total     numeric;
  _fee_total numeric;
  _orders    int;
  _sellers   int;
begin
  if _uid is null then raise exception 'Sin sesión'; end if;
  if not exists (select 1 from cart_items where user_id = _uid) then
    raise exception 'El carrito está vacío';
  end if;

  select commission_percent into _pct from platform_settings where id = 1;
  _pct := coalesce(_pct, 10);

  select
    coalesce(sum(p.price), 0),
    coalesce(sum(round(p.price * _pct / 100.0, 2)), 0)
  into _total, _fee_total
  from cart_items ci join products p on p.id = ci.product_id
  where ci.user_id = _uid;

  insert into checkouts (buyer_id, total_amount, commission_percent, platform_fee_total)
  values (_uid, _total, _pct, _fee_total)
  returning id into _checkout;

  insert into orders
    (buyer_id, product_id, seller_id, agreed_price, status, checkout_id,
     commission_percent, platform_fee, seller_payout)
  select
    _uid, p.id, p.seller_id, p.price, 'pending', _checkout,
    _pct,
    round(p.price * _pct / 100.0, 2),
    p.price - round(p.price * _pct / 100.0, 2)
  from cart_items ci join products p on p.id = ci.product_id
  where ci.user_id = _uid;

  get diagnostics _orders = row_count;

  select count(distinct p.seller_id) into _sellers
  from cart_items ci join products p on p.id = ci.product_id
  where ci.user_id = _uid;

  delete from cart_items where user_id = _uid;

  return jsonb_build_object(
    'checkout_id', _checkout,
    'orders', _orders,
    'sellers', _sellers,
    'total', _total,
    'platform_fee', _fee_total
  );
end;
$$;

grant execute on function public.checkout_cart() to authenticated;

-- ────────────────────────────────────────────────────────
-- 6. confirm_checkout_payment(checkout) — ADMIN confirma el pago
--    del comprador y genera los payouts a cada vendedor.
-- ────────────────────────────────────────────────────────
create or replace function public.confirm_checkout_payment(p_checkout uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  _status text;
begin
  if not public.is_admin() then raise exception 'forbidden: solo administradores'; end if;

  select status into _status from checkouts where id = p_checkout;
  if _status is null then raise exception 'Checkout no existe'; end if;
  if _status = 'paid' then
    return jsonb_build_object('ok', true, 'already', true);
  end if;

  update checkouts
    set status = 'paid', paid_at = now(), confirmed_by = auth.uid()
    where id = p_checkout;

  -- Un payout por vendedor (suma de seller_payout de sus órdenes).
  insert into payouts (seller_id, checkout_id, amount)
  select o.seller_id, o.checkout_id, sum(o.seller_payout)
  from orders o
  where o.checkout_id = p_checkout
  group by o.seller_id, o.checkout_id;

  return jsonb_build_object('ok', true);
end;
$$;

grant execute on function public.confirm_checkout_payment(uuid) to authenticated;

-- ────────────────────────────────────────────────────────
-- 6b. admin_commission_summary() — cuánto ha ganado Baratito
-- ────────────────────────────────────────────────────────
create or replace function public.admin_commission_summary()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'forbidden'; end if;
  return jsonb_build_object(
    'commission_earned',
      coalesce((select sum(platform_fee_total) from checkouts where status = 'paid'), 0),
    'gross_paid',
      coalesce((select sum(total_amount) from checkouts where status = 'paid'), 0),
    'checkouts_awaiting',
      (select count(*) from checkouts where status = 'awaiting_confirmation'),
    'payouts_pending',
      coalesce((select sum(amount) from payouts where status = 'pending'), 0),
    'payouts_paid',
      coalesce((select sum(amount) from payouts where status = 'paid'), 0)
  );
end;
$$;

grant execute on function public.admin_commission_summary() to authenticated;

-- ────────────────────────────────────────────────────────
-- 7. STORAGE — bucket privado para comprobantes de pago
-- ────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('payment-proofs', 'payment-proofs', false)
on conflict (id) do update set public = false;

drop policy if exists "Comprobante subir propio" on storage.objects;
create policy "Comprobante subir propio"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'payment-proofs'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "Comprobante leer propio o admin" on storage.objects;
create policy "Comprobante leer propio o admin"
  on storage.objects for select to authenticated
  using (bucket_id = 'payment-proofs'
         and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

-- ============================================================
-- LISTO. Comisión configurable en platform_settings.commission_percent.
-- Pon los datos de cobro de Baratito (a dónde paga el comprador):
--   update public.platform_settings
--     set payout_account_number = 'XXXX', payout_account_name = 'Baratito'
--     where id = 1;
-- ============================================================
