-- ============================================================
-- Baratito — Restaurar permisos estándar de Supabase
--
-- Soluciona el error: 42501 "permission denied for schema public".
-- Devuelve a los roles anon/authenticated/service_role los permisos
-- que Supabase otorga por defecto sobre el esquema public.
--
-- IMPORTANTE: Esto NO debilita la seguridad. El control real lo siguen
-- haciendo las políticas RLS (que ya creaste). Los GRANT solo permiten
-- que los roles "vean" el esquema; RLS decide qué filas puede tocar cada uno.
--
-- Ejecuta TODO en Supabase → SQL Editor → Run.
-- ============================================================

-- 1. Acceso al esquema
grant usage on schema public to anon, authenticated, service_role;

-- 2. Permisos sobre las tablas/secuencias/funciones EXISTENTES
grant all on all tables    in schema public to anon, authenticated, service_role;
grant all on all sequences in schema public to anon, authenticated, service_role;
grant all on all routines  in schema public to anon, authenticated, service_role;

-- 3. Permisos por defecto para objetos FUTUROS (tablas que crees después)
alter default privileges in schema public
  grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on sequences to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on routines to anon, authenticated, service_role;

-- ============================================================
-- LISTO. Vuelve a intentar publicar un producto en la app.
-- ============================================================
