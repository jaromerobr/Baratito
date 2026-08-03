-- ============================================================
-- Baratito — Seguimiento / entrega de pedidos (fulfillment)
--
-- Sobre el "pedido" (= checkout, el pago único del comprador) se añade un
-- estado de ENTREGA que el admin hace avanzar y el comprador ve como línea
-- de tiempo con animación:
--   (pago)  pending_payment → awaiting_confirmation → paid
--   (envío) pending → received → reviewing → delivering → delivered
--   rechazado = terminal (rejected)
--
-- El pago ya lo maneja checkouts.status + confirm_checkout_payment() (08/11).
-- Aquí se agrega checkouts.fulfillment_status para las etapas de entrega.
--
-- Depende de: 08_commission_payments.sql (checkouts, orders.checkout_id).
-- Correr TODO en Supabase → SQL Editor. Es idempotente.
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 1. Estado de entrega en el checkout
-- ────────────────────────────────────────────────────────
alter table public.checkouts
  add column if not exists fulfillment_status text not null default 'pending';

alter table public.checkouts drop constraint if exists checkouts_fulfillment_check;
alter table public.checkouts add constraint checkouts_fulfillment_check
  check (fulfillment_status in
    ('pending', 'received', 'reviewing', 'delivering', 'delivered', 'rejected'));

alter table public.checkouts add column if not exists rejected_reason text;
alter table public.checkouts
  add column if not exists fulfillment_updated_at timestamptz;

-- ────────────────────────────────────────────────────────
-- 2. FK orders.checkout_id → checkouts.id (permite embeber órdenes
--    del checkout en PostgREST). Se crea solo si no existe.
-- ────────────────────────────────────────────────────────
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'orders_checkout_id_fkey'
  ) then
    alter table public.orders
      add constraint orders_checkout_id_fkey
      foreign key (checkout_id) references public.checkouts(id) on delete set null;
  end if;
end $$;

-- ────────────────────────────────────────────────────────
-- 3. Avanzar / rechazar la entrega (solo admin).
--    p_status: received | reviewing | delivering | delivered | rejected
-- ────────────────────────────────────────────────────────
create or replace function public.set_order_fulfillment(
  p_checkout uuid,
  p_status   text,
  p_reason   text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Solo un administrador puede actualizar la entrega';
  end if;
  if p_status not in
     ('received', 'reviewing', 'delivering', 'delivered', 'rejected') then
    raise exception 'Estado de entrega inválido: %', p_status;
  end if;

  update public.checkouts
     set fulfillment_status    = p_status,
         rejected_reason       = case when p_status = 'rejected'
                                      then p_reason else rejected_reason end,
         -- Un pedido rechazado se marca como cancelado a nivel de pago.
         status                = case when p_status = 'rejected'
                                      then 'cancelled' else status end,
         fulfillment_updated_at = now()
   where id = p_checkout;
end;
$$;

grant execute on function public.set_order_fulfillment(uuid, text, text)
  to authenticated;
