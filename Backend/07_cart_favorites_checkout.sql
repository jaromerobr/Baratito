-- ============================================================
-- Baratito — Favoritos + Carrito + Checkout (dividido por vendedor)
-- Ejecuta TODO en Supabase → SQL Editor → Run. Idempotente.
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 1. FAVORITES — cada quien gestiona los suyos
-- ────────────────────────────────────────────────────────
-- Evita duplicados (un usuario guarda un producto una sola vez).
create unique index if not exists favorites_user_product_uidx
  on public.favorites (user_id, product_id);

alter table public.favorites enable row level security;

drop policy if exists "Favoritos propios visibles" on public.favorites;
create policy "Favoritos propios visibles"
  on public.favorites for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Agrega favorito propio" on public.favorites;
create policy "Agrega favorito propio"
  on public.favorites for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Quita favorito propio" on public.favorites;
create policy "Quita favorito propio"
  on public.favorites for delete to authenticated
  using (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────
-- 2. CART_ITEMS — carrito persistente por usuario
-- ────────────────────────────────────────────────────────
create table if not exists public.cart_items (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  added_at   timestamptz not null default now(),
  unique (user_id, product_id)
);

grant all on public.cart_items to anon, authenticated, service_role;

alter table public.cart_items enable row level security;

drop policy if exists "Carrito propio visible" on public.cart_items;
create policy "Carrito propio visible"
  on public.cart_items for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Agrega al carrito propio" on public.cart_items;
create policy "Agrega al carrito propio"
  on public.cart_items for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Quita del carrito propio" on public.cart_items;
create policy "Quita del carrito propio"
  on public.cart_items for delete to authenticated
  using (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────
-- 3. ORDERS — columna para agrupar el checkout (un "pedido")
--    Todas las órdenes de un mismo checkout comparten checkout_id;
--    cada orden conserva su seller_id => queda dividido por vendedor.
-- ────────────────────────────────────────────────────────
alter table public.orders
  add column if not exists checkout_id uuid;

-- ────────────────────────────────────────────────────────
-- 4. RPC: checkout del carrito (atómico, en el backend)
--    Crea una orden por producto (estado pending), agrupadas por
--    checkout_id; cada vendedor recibe sus órdenes por separado.
--    Vacía el carrito al final. Devuelve el resumen.
-- ────────────────────────────────────────────────────────
create or replace function public.checkout_cart()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  _uid      uuid := auth.uid();
  _checkout uuid := gen_random_uuid();
  _orders   int;
  _sellers  int;
begin
  if _uid is null then
    raise exception 'Sin sesión';
  end if;

  if not exists (select 1 from public.cart_items where user_id = _uid) then
    raise exception 'El carrito está vacío';
  end if;

  -- Una orden por producto del carrito.
  insert into public.orders
    (buyer_id, product_id, seller_id, agreed_price, status, checkout_id)
  select
    _uid, p.id, p.seller_id, p.price, 'pending', _checkout
  from public.cart_items ci
  join public.products p on p.id = ci.product_id
  where ci.user_id = _uid;

  get diagnostics _orders = row_count;

  select count(distinct p.seller_id) into _sellers
  from public.cart_items ci
  join public.products p on p.id = ci.product_id
  where ci.user_id = _uid;

  -- Vaciar el carrito.
  delete from public.cart_items where user_id = _uid;

  return jsonb_build_object(
    'checkout_id', _checkout,
    'orders', _orders,
    'sellers', _sellers
  );
end;
$$;

grant execute on function public.checkout_cart() to authenticated;

-- ============================================================
-- LISTO. Favoritos, carrito persistente y checkout dividido por
-- vendedor activos. El pago se conectará después (ver payments /
-- seller_payment_methods cuando decidas la pasarela).
-- ============================================================
