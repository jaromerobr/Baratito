-- ============================================================
-- Baratito — Ofertas / negociación de precio
--
-- Solo los productos marcados como negociables (is_negotiable) admiten
-- ofertas. El COMPRADOR propone un precio desde el chat; el VENDEDOR lo
-- acepta o rechaza (el admin NO decide, solo lo ve). Al aceptarse, ese
-- precio queda reservado para ese comprador y es el que cobra el checkout.
--
-- Depende de:
--   00_setup_auth_profiles.sql (profiles), 01_catalog_setup.sql (products),
--   06_profile_chat_setup.sql (conversations), 08/11 (checkout_cart).
-- Correr TODO en Supabase → SQL Editor. Es idempotente.
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 1. Tabla de ofertas
-- ────────────────────────────────────────────────────────
create table if not exists public.product_offers (
  id              uuid primary key default gen_random_uuid(),
  product_id      uuid not null references public.products(id) on delete cascade,
  conversation_id uuid references public.conversations(id) on delete set null,
  buyer_id        uuid not null references public.profiles(id) on delete cascade,
  seller_id       uuid not null references public.profiles(id) on delete cascade,
  amount          numeric not null check (amount > 0),
  status          text not null default 'pending'
                  check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at      timestamptz not null default now(),
  responded_at    timestamptz
);

create index if not exists product_offers_lookup
  on public.product_offers (product_id, buyer_id, status);

grant all on public.product_offers to anon, authenticated, service_role;
alter table public.product_offers enable row level security;

-- Solo las partes (comprador/vendedor) o un admin ven la oferta.
drop policy if exists "Oferta visible a partes o admin" on public.product_offers;
create policy "Oferta visible a partes o admin"
  on public.product_offers for select to authenticated
  using (buyer_id = auth.uid() or seller_id = auth.uid() or public.is_admin());

-- ────────────────────────────────────────────────────────
-- 2. El comprador hace una oferta (solo productos negociables)
-- ────────────────────────────────────────────────────────
create or replace function public.make_offer(
  p_product uuid,
  p_amount  numeric,
  p_conversation uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  _p  record;
  _id uuid;
begin
  select id, seller_id, is_negotiable into _p
    from public.products where id = p_product;
  if _p.id is null then raise exception 'El producto no existe'; end if;
  if not coalesce(_p.is_negotiable, false) then
    raise exception 'Este producto no acepta ofertas';
  end if;
  if _p.seller_id = auth.uid() then
    raise exception 'No puedes ofertar por tu propio producto';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Monto inválido';
  end if;

  -- Anula ofertas pendientes previas del mismo comprador para este producto.
  update public.product_offers
     set status = 'cancelled', responded_at = now()
   where product_id = p_product and buyer_id = auth.uid() and status = 'pending';

  insert into public.product_offers
    (product_id, conversation_id, buyer_id, seller_id, amount)
  values (p_product, p_conversation, auth.uid(), _p.seller_id, p_amount)
  returning id into _id;

  return _id;
end;
$$;

grant execute on function public.make_offer(uuid, numeric, uuid) to authenticated;

-- ────────────────────────────────────────────────────────
-- 3. El vendedor acepta o rechaza la oferta
-- ────────────────────────────────────────────────────────
create or replace function public.respond_offer(
  p_offer  uuid,
  p_accept boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  _o record;
begin
  select * into _o from public.product_offers where id = p_offer;
  if _o.id is null then raise exception 'La oferta no existe'; end if;
  if _o.seller_id <> auth.uid() then
    raise exception 'Solo el vendedor puede responder la oferta';
  end if;
  if _o.status <> 'pending' then
    raise exception 'La oferta ya fue respondida';
  end if;

  update public.product_offers
     set status = case when p_accept then 'accepted' else 'rejected' end,
         responded_at = now()
   where id = p_offer;

  -- Al aceptar, deja una sola oferta aceptada por comprador+producto.
  if p_accept then
    update public.product_offers
       set status = 'cancelled', responded_at = now()
     where product_id = _o.product_id and buyer_id = _o.buyer_id
       and id <> p_offer and status = 'accepted';
  end if;
end;
$$;

grant execute on function public.respond_offer(uuid, boolean) to authenticated;

-- ────────────────────────────────────────────────────────
-- 4. Precio efectivo para un comprador: la última oferta aceptada
--    para (producto, comprador) o, si no hay, el precio de lista.
-- ────────────────────────────────────────────────────────
create or replace function public.effective_price(p_product uuid, p_buyer uuid)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select amount from public.product_offers
      where product_id = p_product and buyer_id = p_buyer and status = 'accepted'
      order by responded_at desc nulls last, created_at desc
      limit 1),
    (select price from public.products where id = p_product)
  );
$$;

grant execute on function public.effective_price(uuid, uuid) to authenticated;

-- ────────────────────────────────────────────────────────
-- 5. checkout_cart() ahora cobra el precio efectivo (oferta aceptada
--    o precio de lista) por producto y comprador.
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
  _subtotal  numeric;
  _fee_total numeric;
  _sellers   int;
  _shipping  numeric;
  _orders    int;
begin
  if _uid is null then raise exception 'Sin sesión'; end if;
  if not exists (select 1 from cart_items where user_id = _uid) then
    raise exception 'El carrito está vacío';
  end if;

  select commission_percent into _pct from platform_settings where id = 1;
  _pct := coalesce(_pct, 8);

  select
    coalesce(sum(public.effective_price(p.id, _uid)), 0),
    coalesce(sum(round(public.effective_price(p.id, _uid) * _pct / 100.0, 2)), 0),
    count(distinct p.seller_id)
  into _subtotal, _fee_total, _sellers
  from cart_items ci join products p on p.id = ci.product_id
  where ci.user_id = _uid;

  -- Envío: $2 con un vendedor; $1 por vendedor si son 2 o más.
  _shipping := case when _sellers <= 1 then 2 else _sellers * 1 end;

  insert into checkouts (buyer_id, total_amount, commission_percent,
                         platform_fee_total, shipping_fee)
  values (_uid, _subtotal + _shipping, _pct, _fee_total, _shipping)
  returning id into _checkout;

  insert into orders
    (buyer_id, product_id, seller_id, agreed_price, status, checkout_id,
     commission_percent, platform_fee, seller_payout)
  select
    _uid, p.id, p.seller_id, public.effective_price(p.id, _uid), 'pending', _checkout,
    _pct,
    round(public.effective_price(p.id, _uid) * _pct / 100.0, 2),
    public.effective_price(p.id, _uid)
      - round(public.effective_price(p.id, _uid) * _pct / 100.0, 2)
  from cart_items ci join products p on p.id = ci.product_id
  where ci.user_id = _uid;

  get diagnostics _orders = row_count;

  delete from cart_items where user_id = _uid;

  return jsonb_build_object(
    'checkout_id', _checkout,
    'orders', _orders,
    'sellers', _sellers,
    'subtotal', _subtotal,
    'shipping', _shipping,
    'total', _subtotal + _shipping,
    'platform_fee', _fee_total
  );
end;
$$;

grant execute on function public.checkout_cart() to authenticated;
