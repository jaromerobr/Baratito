-- ============================================================
-- Baratito — Catálogo: RLS + Storage + Categorías
-- Ejecuta TODO este archivo en Supabase → SQL Editor → Run.
-- Es idempotente (se puede correr varias veces).
--
-- Regla clave: un producto está "publicado/visible" cuando
-- published_at NO es null. Así no dependemos del valor exacto
-- del enum product_status.
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 0. (Informativo) Ver los valores reales de tus enums.
--    Mira el resultado: me sirve para afinar filtros/seed.
-- ────────────────────────────────────────────────────────
select 'product_status' as enum, unnest(enum_range(null::public.product_status))::text as valor
union all
select 'product_condition', unnest(enum_range(null::public.product_condition))::text;

-- ────────────────────────────────────────────────────────
-- 1. CATEGORIES — lectura pública
-- ────────────────────────────────────────────────────────
alter table public.categories enable row level security;

drop policy if exists "Categorías visibles para todos" on public.categories;
create policy "Categorías visibles para todos"
  on public.categories
  for select
  using (is_active = true);

-- ────────────────────────────────────────────────────────
-- 2. PRODUCTS
--    - Lectura pública SOLO de productos publicados.
--    - El vendedor administra (CRUD) sus propios productos.
-- ────────────────────────────────────────────────────────
alter table public.products enable row level security;

drop policy if exists "Productos publicados visibles" on public.products;
create policy "Productos publicados visibles"
  on public.products
  for select
  using (published_at is not null);

drop policy if exists "Vendedor ve sus propios productos" on public.products;
create policy "Vendedor ve sus propios productos"
  on public.products
  for select
  using (auth.uid() = seller_id);

drop policy if exists "Vendedor crea productos" on public.products;
create policy "Vendedor crea productos"
  on public.products
  for insert
  with check (auth.uid() = seller_id);

drop policy if exists "Vendedor edita sus productos" on public.products;
create policy "Vendedor edita sus productos"
  on public.products
  for update
  using (auth.uid() = seller_id)
  with check (auth.uid() = seller_id);

drop policy if exists "Vendedor borra sus productos" on public.products;
create policy "Vendedor borra sus productos"
  on public.products
  for delete
  using (auth.uid() = seller_id);

-- ────────────────────────────────────────────────────────
-- 3. PRODUCT_IMAGES
--    - Visibles si el producto está publicado.
--    - El vendedor administra las imágenes de sus productos.
-- ────────────────────────────────────────────────────────
alter table public.product_images enable row level security;

drop policy if exists "Imágenes de productos publicados" on public.product_images;
create policy "Imágenes de productos publicados"
  on public.product_images
  for select
  using (
    exists (
      select 1 from public.products p
      where p.id = product_id
        and (p.published_at is not null or p.seller_id = auth.uid())
    )
  );

drop policy if exists "Vendedor administra imágenes" on public.product_images;
create policy "Vendedor administra imágenes"
  on public.product_images
  for all
  using (
    exists (
      select 1 from public.products p
      where p.id = product_id and p.seller_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.products p
      where p.id = product_id and p.seller_id = auth.uid()
    )
  );

-- ────────────────────────────────────────────────────────
-- 4. STORAGE — bucket público para imágenes de productos
-- ────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do update set public = true;

-- Lectura pública del bucket
drop policy if exists "Imágenes producto lectura pública" on storage.objects;
create policy "Imágenes producto lectura pública"
  on storage.objects
  for select
  using (bucket_id = 'product-images');

-- Subida solo para usuarios autenticados
drop policy if exists "Imágenes producto subida auth" on storage.objects;
create policy "Imágenes producto subida auth"
  on storage.objects
  for insert
  to authenticated
  with check (bucket_id = 'product-images');

-- Borrado de los archivos que subió el propio usuario
drop policy if exists "Imágenes producto borrado propio" on storage.objects;
create policy "Imágenes producto borrado propio"
  on storage.objects
  for delete
  to authenticated
  using (bucket_id = 'product-images' and owner = auth.uid());

-- ────────────────────────────────────────────────────────
-- 5. Categorías base (matching el diseño)
-- ────────────────────────────────────────────────────────
insert into public.categories (name, slug, sort_order, is_active) values
  ('Electrónica', 'electronica', 1, true),
  ('Ropa',        'ropa',        2, true),
  ('Deportes',    'deportes',    3, true),
  ('Hogar',       'hogar',       4, true),
  ('Juguetes',    'juguetes',    5, true),
  ('Libros',      'libros',      6, true)
on conflict (slug) do nothing;

-- ============================================================
-- LISTO. Después corre 02_seed_products.sql para tener
-- productos de ejemplo visibles en la app.
-- ============================================================
