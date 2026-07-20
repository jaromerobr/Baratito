-- ============================================================
-- Baratito — Chats de soporte / reportes
--
-- Los usuarios pueden "Reportar un problema" (con la app o con otro
-- usuario) y el equipo admin lo atiende desde la pestaña Chats.
-- Reusa la tabla `conversations` con kind='support' (sin producto ni
-- vendedor). El usuario que reporta es el `buyer_id`.
--
-- Depende de:
--   05_admin_setup.sql   → función public.is_admin()
--   06_profile_chat_setup.sql → tablas conversations / messages + RLS base
--
-- Correr TODO en Supabase → SQL Editor. Es idempotente.
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 1. Columna `kind` + campos nulos para conversaciones de soporte
-- ────────────────────────────────────────────────────────
alter table public.conversations
  add column if not exists kind text not null default 'product';

alter table public.conversations
  drop constraint if exists conversations_kind_check;
alter table public.conversations
  add constraint conversations_kind_check check (kind in ('product', 'support'));

-- En soporte no hay producto ni vendedor.
alter table public.conversations alter column product_id drop not null;
alter table public.conversations alter column seller_id drop not null;

-- ────────────────────────────────────────────────────────
-- 2. RLS conversations: los admins ven y responden las de soporte
--    (las políticas son permisivas/OR, no restringen a los usuarios).
-- ────────────────────────────────────────────────────────
drop policy if exists "Admin ve soporte" on public.conversations;
create policy "Admin ve soporte"
  on public.conversations for select to authenticated
  using (kind = 'support' and public.is_admin());

drop policy if exists "Admin actualiza soporte" on public.conversations;
create policy "Admin actualiza soporte"
  on public.conversations for update to authenticated
  using (kind = 'support' and public.is_admin())
  with check (kind = 'support' and public.is_admin());

-- ────────────────────────────────────────────────────────
-- 3. RLS messages: los admins leen / escriben / marcan leídos en soporte.
--    El usuario que reporta ya puede por ser buyer_id (políticas base de 06).
-- ────────────────────────────────────────────────────────
drop policy if exists "Admin lee msgs soporte" on public.messages;
create policy "Admin lee msgs soporte"
  on public.messages for select to authenticated
  using (
    public.is_admin() and exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id and c.kind = 'support'
    )
  );

drop policy if exists "Admin envía msgs soporte" on public.messages;
create policy "Admin envía msgs soporte"
  on public.messages for insert to authenticated
  with check (
    sender_id = auth.uid() and public.is_admin() and exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id and c.kind = 'support'
    )
  );

drop policy if exists "Admin marca msgs soporte" on public.messages;
create policy "Admin marca msgs soporte"
  on public.messages for update to authenticated
  using (
    public.is_admin() and exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id and c.kind = 'support'
    )
  );

