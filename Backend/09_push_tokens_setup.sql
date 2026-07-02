-- ============================================================
-- Baratito — Semana 9: Tokens FCM (push_tokens) + RLS
-- Ejecuta TODO en Supabase → SQL Editor → Run. Idempotente.
--
-- La tabla public.push_tokens YA existe en el esquema
-- (id, user_id, token UNIQUE, platform, is_active, created_at, updated_at).
-- Aquí solo habilitamos RLS para que cada usuario gestione SUS tokens.
-- Modelo multi-dispositivo: una fila por token (cada dispositivo tiene su
-- propio token FCM). Al cerrar sesión, el token queda is_active = false.
-- ============================================================

grant all on public.push_tokens to anon, authenticated, service_role;

alter table public.push_tokens enable row level security;

-- Ver sus propios tokens
drop policy if exists "Tokens propios visibles" on public.push_tokens;
create policy "Tokens propios visibles"
  on public.push_tokens for select to authenticated
  using (auth.uid() = user_id);

-- Registrar un token propio
drop policy if exists "Registra token propio" on public.push_tokens;
create policy "Registra token propio"
  on public.push_tokens for insert to authenticated
  with check (auth.uid() = user_id);

-- Actualizar su token (upsert / activar / desactivar / refresh)
drop policy if exists "Actualiza token propio" on public.push_tokens;
create policy "Actualiza token propio"
  on public.push_tokens for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Borrar su token
drop policy if exists "Borra token propio" on public.push_tokens;
create policy "Borra token propio"
  on public.push_tokens for delete to authenticated
  using (auth.uid() = user_id);

-- ============================================================
-- LISTO. La app hace upsert (onConflict = token) al iniciar sesión y
-- pone is_active = false al cerrar sesión.
-- Verifica:  select user_id, platform, is_active, updated_at from public.push_tokens;
-- ============================================================
