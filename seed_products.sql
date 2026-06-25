-- ============================================================
-- Baratito — Seed data: categories + sample second-hand products
-- ============================================================
-- HOW TO RUN:
-- 1. Go to Supabase → SQL Editor
-- 2. Replace 'YOUR_USER_ID_HERE' below with your user ID
--    (find it in Authentication → Users → copy your UUID)
-- 3. Run the whole script
-- ============================================================

-- Step 0: Make sure the is_negotiable column exists
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS is_negotiable boolean NOT NULL DEFAULT false;

-- Step 1: Seed categories (skip if already exist)
INSERT INTO public.categories (id, name, icon_name, is_active)
VALUES
  ('11111111-0001-0001-0001-000000000001', 'Ropa y Accesorios', 'checkroom',        true),
  ('11111111-0001-0001-0001-000000000002', 'Electrónica',       'devices',           true),
  ('11111111-0001-0001-0001-000000000003', 'Deportes',          'sports_soccer',     true),
  ('11111111-0001-0001-0001-000000000004', 'Hogar y Muebles',   'chair',             true),
  ('11111111-0001-0001-0001-000000000005', 'Libros y Juegos',   'menu_book',         true),
  ('11111111-0001-0001-0001-000000000006', 'Juguetes',          'toys',              true)
ON CONFLICT (id) DO NOTHING;

-- Step 2: Seed products
-- ⚠️  Replace the value below with YOUR user ID from Supabase Auth
DO $$
DECLARE
  v_seller uuid := 'YOUR_USER_ID_HERE';  -- ← CHANGE THIS

  -- category ids
  cat_ropa       uuid := '11111111-0001-0001-0001-000000000001';
  cat_electro    uuid := '11111111-0001-0001-0001-000000000002';
  cat_deportes   uuid := '11111111-0001-0001-0001-000000000003';
  cat_hogar      uuid := '11111111-0001-0001-0001-000000000004';
  cat_libros     uuid := '11111111-0001-0001-0001-000000000005';
  cat_juguetes   uuid := '11111111-0001-0001-0001-000000000006';

  pid uuid;
BEGIN

  -- 1. iPhone 13
  pid := gen_random_uuid();
  INSERT INTO public.products
    (id, seller_id, category_id, title, description, price, condition, status, is_negotiable, brand)
  VALUES (
    pid, v_seller, cat_electro,
    'iPhone 13 Pro 128GB — Grafito',
    'iPhone en excelente estado. Sin rayones visibles, batería al 94%. Incluye cargador original y caja. Desbloqueado para cualquier operadora.',
    380.00, 'como_nuevo', 'active', true, 'Apple'
  );

  -- 2. Bicicleta de montaña
  pid := gen_random_uuid();
  INSERT INTO public.products
    (id, seller_id, category_id, title, description, price, condition, status, is_negotiable, brand)
  VALUES (
    pid, v_seller, cat_deportes,
    'Bicicleta de montaña Trek 21 velocidades',
    'Bicicleta Trek en buen estado. Cambios funcionando bien, llantas en buen estado. Ideal para rutas de ciudad y montaña. Aro 26.',
    150.00, 'buen_estado', 'active', true, 'Trek'
  );

  -- 3. Chaqueta North Face
  pid := gen_random_uuid();
  INSERT INTO public.products
    (id, seller_id, category_id, title, description, price, condition, status, is_negotiable, brand)
  VALUES (
    pid, v_seller, cat_ropa,
    'Chaqueta North Face — talla M',
    'Chaqueta impermeable North Face talla M. Usada 3 veces, prácticamente nueva. Color negro. Perfecta para clima frío.',
    85.00, 'como_nuevo', 'active', false, 'The North Face'
  );

  -- 4. PS5 con juegos
  pid := gen_random_uuid();
  INSERT INTO public.products
    (id, seller_id, category_id, title, description, price, condition, status, is_negotiable, brand)
  VALUES (
    pid, v_seller, cat_electro,
    'PlayStation 5 + 2 controles + 4 juegos',
    'PS5 en perfecto estado. Incluye 2 controles DualSense, God of War Ragnarok, Spider-Man 2, FIFA 24 y Horizon Forbidden West.',
    520.00, 'buen_estado', 'active', true, 'Sony'
  );

  -- 5. Mesa de madera
  pid := gen_random_uuid();
  INSERT INTO public.products
    (id, seller_id, category_id, title, description, price, condition, status, is_negotiable, brand)
  VALUES (
    pid, v_seller, cat_hogar,
    'Mesa comedor madera 6 puestos',
    'Mesa de madera maciza 6 puestos, 160x90 cm. Muy buen estado, pequeños detalles de uso en la superficie. Sin sillas.',
    200.00, 'buen_estado', 'active', true, NULL
  );

  -- 6. Air Jordan 1
  pid := gen_random_uuid();
  INSERT INTO public.products
    (id, seller_id, category_id, title, description, price, condition, status, is_negotiable, brand)
  VALUES (
    pid, v_seller, cat_ropa,
    'Nike Air Jordan 1 Retro High — talla 42',
    'Jordan 1 Chicago colorway, talla 42. Usados 5 veces con mucho cuidado. Incluye caja original. 100% auténticos.',
    170.00, 'buen_estado', 'active', false, 'Nike'
  );

  -- 7. MacBook Air M1
  pid := gen_random_uuid();
  INSERT INTO public.products
    (id, seller_id, category_id, title, description, price, condition, status, is_negotiable, brand)
  VALUES (
    pid, v_seller, cat_electro,
    'MacBook Air M1 8GB / 256GB — Space Gray',
    'MacBook Air M1 en muy buen estado. Batería al 88%. Sin daños físicos, pequeña marca invisible en la cubierta. MacOS Sonoma.',
    650.00, 'buen_estado', 'active', true, 'Apple'
  );

  -- 8. Libro Harry Potter colección
  pid := gen_random_uuid();
  INSERT INTO public.products
    (id, seller_id, category_id, title, description, price, condition, status, is_negotiable, brand)
  VALUES (
    pid, v_seller, cat_libros,
    'Colección completa Harry Potter — 7 tomos',
    'Los 7 libros de Harry Potter en español, edición de pasta dura. En buen estado, algunos con pequeñas marcas de lectura.',
    45.00, 'buen_estado', 'active', true, NULL
  );

  -- 9. Set de pesas
  pid := gen_random_uuid();
  INSERT INTO public.products
    (id, seller_id, category_id, title, description, price, condition, status, is_negotiable, brand)
  VALUES (
    pid, v_seller, cat_deportes,
    'Set de pesas ajustables 2-24kg',
    'Pesas ajustables de 2 a 24kg cada una. Sistema de dial para ajustar el peso en segundos. Perfectas para gym en casa.',
    180.00, 'como_nuevo', 'active', false, 'Bowflex'
  );

  -- 10. Cámara Sony mirrorless
  pid := gen_random_uuid();
  INSERT INTO public.products
    (id, seller_id, category_id, title, description, price, condition, status, is_negotiable, brand)
  VALUES (
    pid, v_seller, cat_electro,
    'Cámara Sony a6400 + lente 16-50mm',
    'Sony a6400 en perfecto estado. Solo 8000 disparos. Incluye lente kit 16-50mm, batería extra, cargador y correa original.',
    750.00, 'buen_estado', 'active', true, 'Sony'
  );

  RAISE NOTICE 'Seed completado: 10 productos insertados para el usuario %', v_seller;
END $$;
