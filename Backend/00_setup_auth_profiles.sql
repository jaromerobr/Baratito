-- ============================================================
-- Baratito — Setup de Autenticación sobre public.profiles
-- Esquema oficial (reemplaza a 01_trigger_new_user.sql y 02_rls_policies.sql)
--
-- Ejecuta TODO este archivo en: Supabase → SQL Editor → New query → Run
-- Es idempotente: puedes correrlo varias veces sin problema.
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 1. Función que crea el perfil al registrarse un usuario
--    Se dispara automáticamente al insertarse en auth.users.
--    SECURITY DEFINER = corre con permisos elevados (ignora RLS).
-- ────────────────────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  _full_name text;
  _role      public.user_role;
begin
  -- Nombre: viene de los metadatos del signup; si no, usa la parte
  -- antes del @ del correo como fallback (full_name es NOT NULL).
  _full_name := coalesce(
    nullif(new.raw_user_meta_data ->> 'full_name', ''),
    nullif(new.raw_user_meta_data ->> 'name', ''),
    split_part(new.email, '@', 1)
  );

  -- Rol: por defecto 'both' (puede comprar y vender).
  begin
    _role := coalesce(new.raw_user_meta_data ->> 'role', 'both')::public.user_role;
  exception when others then
    _role := 'both';
  end;

  insert into public.profiles (id, email, full_name, role)
  values (new.id, new.email, _full_name, _role)
  on conflict (id) do nothing;

  return new;
end;
$$;

-- ────────────────────────────────────────────────────────
-- 2. (Re)crear el trigger sobre auth.users
-- ────────────────────────────────────────────────────────
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- ────────────────────────────────────────────────────────
-- 3. RLS en public.profiles
-- ────────────────────────────────────────────────────────
alter table public.profiles enable row level security;

-- Lectura pública: necesaria para mostrar datos del vendedor en los
-- productos (nombre, avatar, trust_score) incluso en modo invitado.
drop policy if exists "Profiles son visibles para todos" on public.profiles;
create policy "Profiles son visibles para todos"
  on public.profiles
  for select
  using (true);

-- Cada usuario puede actualizar SU propio perfil.
drop policy if exists "Usuario actualiza su propio perfil" on public.profiles;
create policy "Usuario actualiza su propio perfil"
  on public.profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Insert propio (respaldo; normalmente lo hace el trigger).
drop policy if exists "Usuario inserta su propio perfil" on public.profiles;
create policy "Usuario inserta su propio perfil"
  on public.profiles
  for insert
  with check (auth.uid() = id);

-- ────────────────────────────────────────────────────────
-- 4. Backfill: crea perfiles para usuarios de auth que ya existan
--    pero que no tengan fila en profiles (por el trigger roto anterior).
-- ────────────────────────────────────────────────────────
insert into public.profiles (id, email, full_name, role)
select
  u.id,
  u.email,
  coalesce(
    nullif(u.raw_user_meta_data ->> 'full_name', ''),
    split_part(u.email, '@', 1)
  ),
  'both'::public.user_role
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null
on conflict (id) do nothing;

-- ============================================================
-- LISTO. Verifica con:
--   select id, email, full_name, role from public.profiles;
--
-- NOTA: La tabla public.users del trigger anterior queda obsoleta.
-- Si confirmaste que NO la usas para nada, puedes borrarla (opcional):
--   -- drop table if exists public.users cascade;
-- ============================================================
