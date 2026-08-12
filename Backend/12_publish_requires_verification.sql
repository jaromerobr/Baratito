-- ============================================================
-- Baratito — PE-S15: la publicación exige identidad verificada
-- Ejecuta TODO en Supabase → SQL Editor → Run. Idempotente.
--
-- PROBLEMA QUE CORRIGE
-- La regla "un vendedor debe tener su identidad verificada y aprobada antes
-- de poder publicar un artículo" solo estaba implementada en la UI
-- (main_shell._onPublishTap). La política de inserción de 01_catalog_setup.sql
-- solo comprobaba `auth.uid() = seller_id`, es decir, AUTENTICACIÓN, no
-- verificación de identidad. Cualquier ruta que evite el botón (deep link a
-- /publish, o una llamada directa a la API de Supabase) podía insertar un
-- producto sin KYC aprobado.
--
-- La corrección va en RLS porque es la única capa que ningún cliente puede
-- saltarse, y porque mantiene el monolito modular: el módulo de productos no
-- necesita consultar tablas del módulo de verificación.
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 0. Helper: ¿el usuario actual tiene la identidad aprobada?
--    SECURITY DEFINER para que la comprobación no dependa de
--    las políticas de lectura de `profiles`.
-- ────────────────────────────────────────────────────────
create or replace function public.is_identity_verified()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.is_verified = true
  );
$$;

-- ────────────────────────────────────────────────────────
-- 1. Reemplaza la política de inserción de PRODUCTS
--    Antes: with check (auth.uid() = seller_id)
--    Ahora: además exige identidad verificada (o ser admin,
--    exentos igual que en la app).
-- ────────────────────────────────────────────────────────
drop policy if exists "Vendedor crea productos" on public.products;
create policy "Vendedor crea productos"
  on public.products
  for insert
  to authenticated
  with check (
    auth.uid() = seller_id
    and (public.is_admin() or public.is_identity_verified())
  );

-- ============================================================
-- LISTO. Un usuario autenticado pero sin verificación aprobada
-- recibe ahora un error 42501 (row-level security) al intentar
-- insertar en public.products.
-- ============================================================
