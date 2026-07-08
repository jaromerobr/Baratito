-- ============================================================
-- Baratito — Pagos: comisión 8%, envío, QR y validación por OCR
-- Ejecuta TODO en Supabase → SQL Editor → Run. Idempotente.
-- Requiere: 08_commission_payments.sql ya ejecutado.
--
-- Reglas de negocio (definidas por el equipo):
--   • Comisión Baratito: 8% del precio de los productos.
--   • Envío (lo cobra Baratito): $2 si el pedido es de UN vendedor;
--     si es de 2+ vendedores, $1 por vendedor (Baratito consolida).
--   • El vendedor recibe: precio de sus productos − 8%.
--   • El comprador paga: productos + envío, por transferencia/QR
--     al Banco de Loja de Baratito, y sube el comprobante.
--   • La app lee el comprobante con OCR: si el monto coincide,
--     el pago se CONFIRMA AUTOMÁTICAMENTE (payouts + notificaciones);
--     si no, queda en revisión manual del admin.
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 1. Comisión al 8%
-- ────────────────────────────────────────────────────────
update public.platform_settings set commission_percent = 8, updated_at = now()
 where id = 1;

-- ────────────────────────────────────────────────────────
-- 2. Columnas nuevas en checkouts (envío + OCR)
-- ────────────────────────────────────────────────────────
alter table public.checkouts add column if not exists shipping_fee   numeric not null default 0;
alter table public.checkouts add column if not exists ocr_amount     numeric;
alter table public.checkouts add column if not exists ocr_reference  text;
alter table public.checkouts add column if not exists auto_confirmed boolean not null default false;

-- ────────────────────────────────────────────────────────
-- 3. checkout_cart() — ahora suma el envío al total
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
    coalesce(sum(p.price), 0),
    coalesce(sum(round(p.price * _pct / 100.0, 2)), 0),
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
    _uid, p.id, p.seller_id, p.price, 'pending', _checkout,
    _pct,
    round(p.price * _pct / 100.0, 2),
    p.price - round(p.price * _pct / 100.0, 2)
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

-- ────────────────────────────────────────────────────────
-- 4. submit_payment_proof() — el comprador envía comprobante + OCR.
--    Si el monto leído cubre el total → CONFIRMACIÓN AUTOMÁTICA
--    (genera payouts; los triggers de notificación avisan solos).
--    Si no → queda en revisión manual (awaiting_confirmation).
-- ────────────────────────────────────────────────────────
create or replace function public.submit_payment_proof(
  p_checkout   uuid,
  p_proof_path text,
  p_ocr_amount numeric default null,
  p_ocr_ref    text    default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  _c record;
begin
  select * into _c from checkouts where id = p_checkout;
  if _c is null then raise exception 'Checkout no existe'; end if;
  if _c.buyer_id <> auth.uid() then raise exception 'No es tu pedido'; end if;
  if _c.status = 'paid' then
    return jsonb_build_object('status', 'paid', 'already', true);
  end if;

  -- OCR válido si cubre el total (tolerancia de 1 centavo).
  if p_ocr_amount is not null and p_ocr_amount >= _c.total_amount - 0.01 then
    update checkouts
       set proof_path = p_proof_path,
           ocr_amount = p_ocr_amount,
           ocr_reference = p_ocr_ref,
           status = 'paid',
           auto_confirmed = true,
           paid_at = now()
     where id = p_checkout;

    -- Un payout por vendedor (precio de sus productos − 8%; el envío es de Baratito).
    insert into payouts (seller_id, checkout_id, amount)
    select o.seller_id, o.checkout_id, sum(o.seller_payout)
      from orders o
     where o.checkout_id = p_checkout
     group by o.seller_id, o.checkout_id;

    return jsonb_build_object('status', 'paid', 'auto', true,
                              'ocr_amount', p_ocr_amount);
  end if;

  -- OCR no coincide o no se pudo leer → revisión manual.
  update checkouts
     set proof_path = p_proof_path,
         ocr_amount = p_ocr_amount,
         ocr_reference = p_ocr_ref,
         status = 'awaiting_confirmation'
   where id = p_checkout;

  return jsonb_build_object('status', 'awaiting_confirmation',
                            'ocr_amount', p_ocr_amount);
end;
$$;

grant execute on function public.submit_payment_proof(uuid, text, numeric, text) to authenticated;

-- ────────────────────────────────────────────────────────
-- 5. Bucket público para el QR de cobro de Baratito
--    (nota: el bucket, el QR y los datos de la cuenta ya fueron
--    configurados por API; esta sección es idempotente y no daña)
-- ────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('platform-assets', 'platform-assets', true)
on conflict (id) do update set public = true;

drop policy if exists "Assets plataforma lectura pública" on storage.objects;
create policy "Assets plataforma lectura pública"
  on storage.objects for select
  using (bucket_id = 'platform-assets');

drop policy if exists "Assets plataforma escribe admin" on storage.objects;
create policy "Assets plataforma escribe admin"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'platform-assets' and public.is_admin());

-- ────────────────────────────────────────────────────────
-- 6. Nadie puede agregar SU PROPIO producto al carrito
--    (refuerzo en el backend; la app ya lo oculta en la UI)
-- ────────────────────────────────────────────────────────
drop policy if exists "Agrega al carrito propio" on public.cart_items;
create policy "Agrega al carrito propio"
  on public.cart_items for insert to authenticated
  with check (
    auth.uid() = user_id
    and not exists (
      select 1 from public.products p
      where p.id = product_id and p.seller_id = auth.uid()
    )
  );

-- ────────────────────────────────────────────────────────
-- 7. Verificación final: debe devolver 2 filas
-- ────────────────────────────────────────────────────────
select column_name from information_schema.columns
 where table_name = 'checkouts' and column_name in ('shipping_fee','ocr_amount');
