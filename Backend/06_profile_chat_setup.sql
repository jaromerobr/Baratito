-- ============================================================
-- Baratito — Perfil (avatar) + Órdenes + Chat en tiempo real
-- Ejecuta TODO en Supabase → SQL Editor → Run. Idempotente.
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 1. STORAGE — bucket público de avatares
-- ────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

drop policy if exists "Avatars lectura pública" on storage.objects;
create policy "Avatars lectura pública"
  on storage.objects for select
  using (bucket_id = 'avatars');

drop policy if exists "Avatars subir propio" on storage.objects;
create policy "Avatars subir propio"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Avatars actualizar propio" on storage.objects;
create policy "Avatars actualizar propio"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Avatars borrar propio" on storage.objects;
create policy "Avatars borrar propio"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ────────────────────────────────────────────────────────
-- 2. ORDERS — comprador/vendedor ven sus propias órdenes
-- ────────────────────────────────────────────────────────
alter table public.orders enable row level security;

drop policy if exists "Órdenes propias visibles" on public.orders;
create policy "Órdenes propias visibles"
  on public.orders for select to authenticated
  using (auth.uid() = buyer_id or auth.uid() = seller_id);

drop policy if exists "Comprador crea orden" on public.orders;
create policy "Comprador crea orden"
  on public.orders for insert to authenticated
  with check (auth.uid() = buyer_id);

drop policy if exists "Participantes actualizan orden" on public.orders;
create policy "Participantes actualizan orden"
  on public.orders for update to authenticated
  using (auth.uid() = buyer_id or auth.uid() = seller_id)
  with check (auth.uid() = buyer_id or auth.uid() = seller_id);

-- ────────────────────────────────────────────────────────
-- 3. CONVERSATIONS — solo los dos participantes
-- ────────────────────────────────────────────────────────
alter table public.conversations enable row level security;

drop policy if exists "Conversaciones propias" on public.conversations;
create policy "Conversaciones propias"
  on public.conversations for select to authenticated
  using (auth.uid() = buyer_id or auth.uid() = seller_id);

drop policy if exists "Crea conversación como participante" on public.conversations;
create policy "Crea conversación como participante"
  on public.conversations for insert to authenticated
  with check (auth.uid() = buyer_id or auth.uid() = seller_id);

drop policy if exists "Actualiza conversación propia" on public.conversations;
create policy "Actualiza conversación propia"
  on public.conversations for update to authenticated
  using (auth.uid() = buyer_id or auth.uid() = seller_id)
  with check (auth.uid() = buyer_id or auth.uid() = seller_id);

-- ────────────────────────────────────────────────────────
-- 4. MESSAGES — visibles/insertables por los participantes
-- ────────────────────────────────────────────────────────
alter table public.messages enable row level security;

drop policy if exists "Mensajes de mis conversaciones" on public.messages;
create policy "Mensajes de mis conversaciones"
  on public.messages for select to authenticated
  using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id
        and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
    )
  );

drop policy if exists "Envío mensajes en mis conversaciones" on public.messages;
create policy "Envío mensajes en mis conversaciones"
  on public.messages for insert to authenticated
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversations c
      where c.id = conversation_id
        and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
    )
  );

drop policy if exists "Marco mensajes como leídos" on public.messages;
create policy "Marco mensajes como leídos"
  on public.messages for update to authenticated
  using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id
        and (c.buyer_id = auth.uid() or c.seller_id = auth.uid())
    )
  );

-- ────────────────────────────────────────────────────────
-- 5. Trigger: actualizar conversations.last_message_at
-- ────────────────────────────────────────────────────────
create or replace function public.bump_conversation_last_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversations
    set last_message_at = new.sent_at
    where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists on_message_insert on public.messages;
create trigger on_message_insert
  after insert on public.messages
  for each row
  execute function public.bump_conversation_last_message();

-- ────────────────────────────────────────────────────────
-- 6. Realtime: emitir cambios de messages y conversations
-- ────────────────────────────────────────────────────────
do $$
begin
  begin
    alter publication supabase_realtime add table public.messages;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.conversations;
  exception when duplicate_object then null;
  end;
end $$;

-- ============================================================
-- LISTO. Perfil con avatar, órdenes y chat en tiempo real activos.
-- ============================================================
