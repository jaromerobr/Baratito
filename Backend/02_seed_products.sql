-- ============================================================
-- Baratito — Productos de ejemplo (seed)
-- Ejecuta DESPUÉS de 00_setup_auth_profiles.sql y 01_catalog_setup.sql.
--
-- Requisito: debe existir al menos 1 perfil (regístrate en la app primero).
-- Usa imágenes públicas (Unsplash), así que se ven sin subir nada al storage.
-- Detecta automáticamente los valores válidos de los enums.
-- ============================================================

do $$
declare
  _seller   uuid;
  _cond     public.product_condition;
  _status   public.product_status;
  _cat_elec uuid;
  _cat_ropa uuid;
  _cat_hgr  uuid;
  _pid      uuid;
begin
  -- Vendedor = primer perfil existente
  select id into _seller from public.profiles order by created_at limit 1;
  if _seller is null then
    raise exception 'No hay perfiles. Regístrate en la app antes de correr este seed.';
  end if;

  -- Primer valor válido de condición
  _cond := (enum_range(null::public.product_condition))[1];

  -- Un status que NO sea draft (para que sea "publicado"); si no, el primero
  select s into _status
  from unnest(enum_range(null::public.product_status)) s
  where s::text <> 'draft'
  limit 1;
  if _status is null then
    _status := (enum_range(null::public.product_status))[1];
  end if;

  -- Categorías (si existen)
  select id into _cat_elec from public.categories where slug = 'electronica' limit 1;
  select id into _cat_ropa from public.categories where slug = 'ropa' limit 1;
  select id into _cat_hgr  from public.categories where slug = 'hogar' limit 1;

  -- ── Producto 1 ──
  insert into public.products
    (seller_id, category_id, title, description, price, condition, status, is_negotiable, location_city, published_at)
  values
    (_seller, _cat_elec, 'iPhone 13 Pro 128GB – Grafito',
     'En excelente estado, batería al 92%, incluye caja y cargador.',
     380.00, _cond, _status, true, 'Loja', now())
  returning id into _pid;
  insert into public.product_images (product_id, image_path, is_primary, sort_order)
  values (_pid, 'https://images.unsplash.com/photo-1632661674596-df8be070a5c5?w=600', true, 0);

  -- ── Producto 2 ──
  insert into public.products
    (seller_id, category_id, title, description, price, condition, status, is_negotiable, location_city, published_at)
  values
    (_seller, _cat_elec, 'PlayStation 5 + 2 controles + 4 juegos',
     'Consola PS5 edición con lectora, dos mandos y cuatro juegos físicos.',
     520.00, _cond, _status, true, 'Loja', now())
  returning id into _pid;
  insert into public.product_images (product_id, image_path, is_primary, sort_order)
  values (_pid, 'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=600', true, 0);

  -- ── Producto 3 ──
  insert into public.products
    (seller_id, category_id, title, description, price, condition, status, is_negotiable, location_city, published_at)
  values
    (_seller, _cat_ropa, 'Chaqueta de cuero talla M',
     'Chaqueta de cuero sintético, poco uso, color negro.',
     45.00, _cond, _status, false, 'Loja', now())
  returning id into _pid;
  insert into public.product_images (product_id, image_path, is_primary, sort_order)
  values (_pid, 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=600', true, 0);

  -- ── Producto 4 ──
  insert into public.products
    (seller_id, category_id, title, description, price, condition, status, is_negotiable, location_city, published_at)
  values
    (_seller, _cat_hgr, 'Lámpara de escritorio LED',
     'Lámpara LED regulable con brazo articulado, ideal para estudio.',
     18.50, _cond, _status, true, 'Loja', now())
  returning id into _pid;
  insert into public.product_images (product_id, image_path, is_primary, sort_order)
  values (_pid, 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=600', true, 0);

  raise notice 'Seed completado. Vendedor: %, condición: %, status: %', _seller, _cond, _status;
end $$;

-- Verifica:
select id, title, price, status, published_at from public.products order by created_at desc;
