-- ============================================================
-- Baratito — Datos de entrega del pedido
--
-- Tras subir el comprobante ("estamos verificando tu pago"), el comprador
-- ingresa su dirección de entrega. Se guarda en el checkout (pedido) y, como
-- predeterminada, en su perfil para precargarla en la próxima compra.
--
-- Depende de: 08_commission_payments.sql (checkouts), 00 (profiles).
-- Correr TODO en Supabase → SQL Editor. Es idempotente.
-- ============================================================

-- Datos de entrega en el pedido (snapshot del checkout).
alter table public.checkouts
  add column if not exists delivery_recipient text;
alter table public.checkouts
  add column if not exists delivery_phone text;
alter table public.checkouts
  add column if not exists delivery_address text;
alter table public.checkouts
  add column if not exists delivery_reference text;  -- descripción de la casa
alter table public.checkouts
  add column if not exists delivery_city text;

-- Dirección predeterminada del usuario (para reusar). `phone` ya existe.
alter table public.profiles
  add column if not exists address text;
alter table public.profiles
  add column if not exists address_reference text;
alter table public.profiles
  add column if not exists address_city text;
