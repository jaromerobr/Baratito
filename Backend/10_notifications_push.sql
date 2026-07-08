-- ============================================================
-- Baratito — Notificaciones automáticas (in-app + push FCM)
-- Ejecuta TODO en Supabase → SQL Editor → Run. Idempotente.
--
-- Arquitectura:
--   evento de negocio (trigger) ──> fila en public.notifications (historial)
--   trigger en notifications ──(pg_net)──> Edge Function `send-push`
--   Edge Function ──> FCM HTTP v1 ──> dispositivos del usuario (push_tokens)
--
-- Tipos de evento:
--   nuevo_mensaje            → destinatario de un mensaje de chat
--   venta_realizada          → vendedor: compraron su producto / pago listo
--   pago_confirmado          → comprador: Baratito confirmó su pago
--   pedido_enviado           → comprador: su pedido va en camino
--   verificacion_aprobada    → usuario: identidad aprobada
--   verificacion_rechazada   → usuario: identidad rechazada
--   nueva_verificacion       → admins: hay una verificación por revisar
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 0. (Informativo) tipo enum real de notifications.type
-- ────────────────────────────────────────────────────────
select udt_name as notifications_type_enum,
       (select string_agg(e.enumlabel, ', ' order by e.enumsortorder)
          from pg_enum e join pg_type t on t.oid = e.enumtypid
         where t.typname = c.udt_name) as valores_actuales
from information_schema.columns c
where table_schema='public' and table_name='notifications' and column_name='type';

-- ────────────────────────────────────────────────────────
-- 1. Agregar nuestras etiquetas al enum (sea cual sea su nombre)
-- ────────────────────────────────────────────────────────
do $$
declare
  _t text;
  _lbl text;
begin
  select udt_name into _t
    from information_schema.columns
   where table_schema='public' and table_name='notifications' and column_name='type';
  if _t is null then
    raise exception 'No existe public.notifications.type';
  end if;

  foreach _lbl in array array[
    'nuevo_mensaje','venta_realizada','pago_confirmado','pedido_enviado',
    'verificacion_aprobada','verificacion_rechazada','nueva_verificacion'
  ] loop
    execute format('alter type public.%I add value if not exists %L', _t, _lbl);
  end loop;
end $$;

-- ────────────────────────────────────────────────────────
-- 2. RLS de notifications (cada quien ve/lee las suyas)
-- ────────────────────────────────────────────────────────
grant all on public.notifications to anon, authenticated, service_role;
alter table public.notifications enable row level security;

drop policy if exists "Notificaciones propias visibles" on public.notifications;
create policy "Notificaciones propias visibles"
  on public.notifications for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Marcar notificación leída" on public.notifications;
create policy "Marcar notificación leída"
  on public.notifications for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────
-- 3. Helper: crear una notificación (cast dinámico al enum real).
--    Nunca lanza error: una notificación jamás debe romper la
--    operación de negocio que la originó.
-- ────────────────────────────────────────────────────────
do $$
declare _t text;
begin
  select udt_name into _t
    from information_schema.columns
   where table_schema='public' and table_name='notifications' and column_name='type';

  execute format($f$
    create or replace function public.notify_user(
      p_user uuid, p_tipo text, p_title text, p_body text, p_meta jsonb default '{}'::jsonb
    ) returns void
    language plpgsql security definer set search_path = public
    as $fn$
    begin
      insert into public.notifications (user_id, type, title, body, metadata)
      values (p_user, p_tipo::public.%I, p_title, p_body,
              coalesce(p_meta, '{}'::jsonb) || jsonb_build_object('tipo', p_tipo));
    exception when others then
      raise notice 'notify_user falló: %%', sqlerrm;
    end $fn$;
  $f$, _t);
end $$;

-- ────────────────────────────────────────────────────────
-- 4. TRIGGERS de negocio
-- ────────────────────────────────────────────────────────

-- 4a. Nuevo mensaje de chat → notificar al otro participante
create or replace function public.trg_notify_new_message()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  _conv record;
  _dest uuid;
  _sender text;
begin
  select buyer_id, seller_id into _conv from conversations where id = new.conversation_id;
  if _conv is null then return new; end if;
  _dest := case when new.sender_id = _conv.buyer_id then _conv.seller_id else _conv.buyer_id end;
  select coalesce(full_name, 'Alguien') into _sender from profiles where id = new.sender_id;

  perform notify_user(
    _dest, 'nuevo_mensaje',
    _sender || ' te escribió',
    left(new.content, 120),
    jsonb_build_object('conversation_id', new.conversation_id)
  );
  return new;
end $$;

drop trigger if exists notify_new_message on public.messages;
create trigger notify_new_message
  after insert on public.messages
  for each row execute function public.trg_notify_new_message();

-- 4b. Nueva orden (checkout) → notificar al vendedor: ¡venta!
create or replace function public.trg_notify_new_order()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  _title text;
  _buyer text;
begin
  select title into _title from products where id = new.product_id;
  select coalesce(full_name, 'Un comprador') into _buyer from profiles where id = new.buyer_id;

  perform notify_user(
    new.seller_id, 'venta_realizada',
    '¡Vendiste un producto! 🎉',
    _buyer || ' compró "' || coalesce(_title, 'tu producto') || '". Te avisaremos cuando el pago esté confirmado.',
    jsonb_build_object('order_id', new.id, 'product_id', new.product_id)
  );
  return new;
end $$;

drop trigger if exists notify_new_order on public.orders;
create trigger notify_new_order
  after insert on public.orders
  for each row execute function public.trg_notify_new_order();

-- 4c. Pago del checkout confirmado → comprador (y aviso a vendedores)
create or replace function public.trg_notify_checkout_paid()
returns trigger language plpgsql security definer set search_path = public as $$
declare _s record;
begin
  if new.status = 'paid' and old.status is distinct from 'paid' then
    perform notify_user(
      new.buyer_id, 'pago_confirmado',
      'Pago confirmado ✅',
      'Recibimos tu pago de $' || to_char(new.total_amount, 'FM999990.00') ||
      '. Coordinaremos la entrega de tu pedido.',
      jsonb_build_object('checkout_id', new.id)
    );
    -- a cada vendedor involucrado: prepara la entrega
    for _s in
      select distinct o.seller_id from orders o where o.checkout_id = new.id
    loop
      perform notify_user(
        _s.seller_id, 'venta_realizada',
        'Pago confirmado: prepara la entrega 📦',
        'El pago de una venta tuya fue confirmado por Baratito.',
        jsonb_build_object('checkout_id', new.id)
      );
    end loop;
  end if;
  return new;
end $$;

drop trigger if exists notify_checkout_paid on public.checkouts;
create trigger notify_checkout_paid
  after update on public.checkouts
  for each row execute function public.trg_notify_checkout_paid();

-- 4d. Pedido enviado → comprador (se activa cuando exista flujo de envío;
--     cubre varias etiquetas posibles del enum de estado)
create or replace function public.trg_notify_order_shipped()
returns trigger language plpgsql security definer set search_path = public as $$
declare _title text;
begin
  if new.status::text in ('shipped','enviado','in_transit','delivering')
     and old.status is distinct from new.status then
    select title into _title from products where id = new.product_id;
    perform notify_user(
      new.buyer_id, 'pedido_enviado',
      'Tu pedido va en camino 🚚',
      '"' || coalesce(_title, 'Tu pedido') || '" fue enviado.',
      jsonb_build_object('order_id', new.id)
    );
  end if;
  return new;
end $$;

drop trigger if exists notify_order_shipped on public.orders;
create trigger notify_order_shipped
  after update on public.orders
  for each row execute function public.trg_notify_order_shipped();

-- 4e. Verificación de identidad: resultado → usuario; nueva → admins
create or replace function public.trg_notify_verification()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    -- avisar a todos los admins que hay una verificación por revisar
    perform notify_user(
      a.user_id, 'nueva_verificacion',
      'Nueva verificación por revisar 🪪',
      'Un usuario envió su cédula y selfie. Recuerda el plazo de revisión.',
      jsonb_build_object('verification_id', new.id)
    ) from admins a;
    return new;
  end if;

  if new.status is distinct from old.status then
    if new.status::text = 'approved' then
      perform notify_user(
        new.user_id, 'verificacion_aprobada',
        '¡Identidad verificada! ✅',
        'Tu cuenta fue verificada. Ya puedes publicar y comprar en Baratito.',
        jsonb_build_object('verification_id', new.id)
      );
    elsif new.status::text = 'rejected' then
      perform notify_user(
        new.user_id, 'verificacion_rechazada',
        'Verificación rechazada',
        coalesce('Motivo: ' || nullif(new.rejection_reason, ''),
                 'Revisa tus fotos e inténtalo de nuevo.'),
        jsonb_build_object('verification_id', new.id)
      );
    end if;
  end if;
  return new;
end $$;

drop trigger if exists notify_verification on public.identity_verifications;
create trigger notify_verification
  after insert or update on public.identity_verifications
  for each row execute function public.trg_notify_verification();

-- ────────────────────────────────────────────────────────
-- 5. PUSH: al insertarse una notificación, llamar a la Edge
--    Function `send-push` vía pg_net (asíncrono, no bloquea).
-- ────────────────────────────────────────────────────────
create extension if not exists pg_net;

create or replace function public.trg_push_notification()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform net.http_post(
    url := 'https://ddygpqkuxgfrjdipdvek.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      -- anon key (pública; la Edge Function valida el JWT)
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkeWdwcWt1eGdmcmpkaXBkdmVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMjUwNjEsImV4cCI6MjA5NDkwMTA2MX0.63PViWP91iqrC2r4r6WX-SMcVehwRE-2IbZvwkNOVzY'
    ),
    body := jsonb_build_object(
      'user_id',  new.user_id,
      'title',    new.title,
      'body',     coalesce(new.body, ''),
      'metadata', coalesce(new.metadata, '{}'::jsonb)
    )
  );
  return new;
exception when others then
  raise notice 'push webhook falló: %', sqlerrm;
  return new;
end $$;

drop trigger if exists push_on_notification on public.notifications;
create trigger push_on_notification
  after insert on public.notifications
  for each row execute function public.trg_push_notification();

-- ============================================================
-- LISTO. Falta desplegar la Edge Function `send-push`
-- (ver supabase/functions/send-push/index.ts y la guía del chat).
-- Mientras la función no exista, las notificaciones in-app igual
-- se crean; solo no llega el push.
-- ============================================================
-- ============================================================
-- Baratito — Notificaciones automáticas (in-app + push FCM)
-- Ejecuta TODO en Supabase → SQL Editor → Run. Idempotente.
--
-- Arquitectura:
--   evento de negocio (trigger) ──> fila en public.notifications (historial)
--   trigger en notifications ──(pg_net)──> Edge Function `send-push`
--   Edge Function ──> FCM HTTP v1 ──> dispositivos del usuario (push_tokens)
--
-- Tipos de evento:
--   nuevo_mensaje            → destinatario de un mensaje de chat
--   venta_realizada          → vendedor: compraron su producto / pago listo
--   pago_confirmado          → comprador: Baratito confirmó su pago
--   pedido_enviado           → comprador: su pedido va en camino
--   verificacion_aprobada    → usuario: identidad aprobada
--   verificacion_rechazada   → usuario: identidad rechazada
--   nueva_verificacion       → admins: hay una verificación por revisar
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 0. (Informativo) tipo enum real de notifications.type
-- ────────────────────────────────────────────────────────
select udt_name as notifications_type_enum,
       (select string_agg(e.enumlabel, ', ' order by e.enumsortorder)
          from pg_enum e join pg_type t on t.oid = e.enumtypid
         where t.typname = c.udt_name) as valores_actuales
from information_schema.columns c
where table_schema='public' and table_name='notifications' and column_name='type';

-- ────────────────────────────────────────────────────────
-- 1. Agregar nuestras etiquetas al enum (sea cual sea su nombre)
-- ────────────────────────────────────────────────────────
do $$
declare
  _t text;
  _lbl text;
begin
  select udt_name into _t
    from information_schema.columns
   where table_schema='public' and table_name='notifications' and column_name='type';
  if _t is null then
    raise exception 'No existe public.notifications.type';
  end if;

  foreach _lbl in array array[
    'nuevo_mensaje','venta_realizada','pago_confirmado','pedido_enviado',
    'verificacion_aprobada','verificacion_rechazada','nueva_verificacion'
  ] loop
    execute format('alter type public.%I add value if not exists %L', _t, _lbl);
  end loop;
end $$;

-- ────────────────────────────────────────────────────────
-- 2. RLS de notifications (cada quien ve/lee las suyas)
-- ────────────────────────────────────────────────────────
grant all on public.notifications to anon, authenticated, service_role;
alter table public.notifications enable row level security;

drop policy if exists "Notificaciones propias visibles" on public.notifications;
create policy "Notificaciones propias visibles"
  on public.notifications for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists "Marcar notificación leída" on public.notifications;
create policy "Marcar notificación leída"
  on public.notifications for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ────────────────────────────────────────────────────────
-- 3. Helper: crear una notificación (cast dinámico al enum real).
--    Nunca lanza error: una notificación jamás debe romper la
--    operación de negocio que la originó.
-- ────────────────────────────────────────────────────────
do $$
declare _t text;
begin
  select udt_name into _t
    from information_schema.columns
   where table_schema='public' and table_name='notifications' and column_name='type';

  execute format($f$
    create or replace function public.notify_user(
      p_user uuid, p_tipo text, p_title text, p_body text, p_meta jsonb default '{}'::jsonb
    ) returns void
    language plpgsql security definer set search_path = public
    as $fn$
    begin
      insert into public.notifications (user_id, type, title, body, metadata)
      values (p_user, p_tipo::public.%I, p_title, p_body,
              coalesce(p_meta, '{}'::jsonb) || jsonb_build_object('tipo', p_tipo));
    exception when others then
      raise notice 'notify_user falló: %%', sqlerrm;
    end $fn$;
  $f$, _t);
end $$;

-- ────────────────────────────────────────────────────────
-- 4. TRIGGERS de negocio
-- ────────────────────────────────────────────────────────

-- 4a. Nuevo mensaje de chat → notificar al otro participante
create or replace function public.trg_notify_new_message()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  _conv record;
  _dest uuid;
  _sender text;
begin
  select buyer_id, seller_id into _conv from conversations where id = new.conversation_id;
  if _conv is null then return new; end if;
  _dest := case when new.sender_id = _conv.buyer_id then _conv.seller_id else _conv.buyer_id end;
  select coalesce(full_name, 'Alguien') into _sender from profiles where id = new.sender_id;

  perform notify_user(
    _dest, 'nuevo_mensaje',
    _sender || ' te escribió',
    left(new.content, 120),
    jsonb_build_object('conversation_id', new.conversation_id)
  );
  return new;
end $$;

drop trigger if exists notify_new_message on public.messages;
create trigger notify_new_message
  after insert on public.messages
  for each row execute function public.trg_notify_new_message();

-- 4b. Nueva orden (checkout) → notificar al vendedor: ¡venta!
create or replace function public.trg_notify_new_order()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  _title text;
  _buyer text;
begin
  select title into _title from products where id = new.product_id;
  select coalesce(full_name, 'Un comprador') into _buyer from profiles where id = new.buyer_id;

  perform notify_user(
    new.seller_id, 'venta_realizada',
    '¡Vendiste un producto! 🎉',
    _buyer || ' compró "' || coalesce(_title, 'tu producto') || '". Te avisaremos cuando el pago esté confirmado.',
    jsonb_build_object('order_id', new.id, 'product_id', new.product_id)
  );
  return new;
end $$;

drop trigger if exists notify_new_order on public.orders;
create trigger notify_new_order
  after insert on public.orders
  for each row execute function public.trg_notify_new_order();

-- 4c. Pago del checkout confirmado → comprador (y aviso a vendedores)
create or replace function public.trg_notify_checkout_paid()
returns trigger language plpgsql security definer set search_path = public as $$
declare _s record;
begin
  if new.status = 'paid' and old.status is distinct from 'paid' then
    perform notify_user(
      new.buyer_id, 'pago_confirmado',
      'Pago confirmado ✅',
      'Recibimos tu pago de $' || to_char(new.total_amount, 'FM999990.00') ||
      '. Coordinaremos la entrega de tu pedido.',
      jsonb_build_object('checkout_id', new.id)
    );
    -- a cada vendedor involucrado: prepara la entrega
    for _s in
      select distinct o.seller_id from orders o where o.checkout_id = new.id
    loop
      perform notify_user(
        _s.seller_id, 'venta_realizada',
        'Pago confirmado: prepara la entrega 📦',
        'El pago de una venta tuya fue confirmado por Baratito.',
        jsonb_build_object('checkout_id', new.id)
      );
    end loop;
  end if;
  return new;
end $$;

drop trigger if exists notify_checkout_paid on public.checkouts;
create trigger notify_checkout_paid
  after update on public.checkouts
  for each row execute function public.trg_notify_checkout_paid();

-- 4d. Pedido enviado → comprador (se activa cuando exista flujo de envío;
--     cubre varias etiquetas posibles del enum de estado)
create or replace function public.trg_notify_order_shipped()
returns trigger language plpgsql security definer set search_path = public as $$
declare _title text;
begin
  if new.status::text in ('shipped','enviado','in_transit','delivering')
     and old.status is distinct from new.status then
    select title into _title from products where id = new.product_id;
    perform notify_user(
      new.buyer_id, 'pedido_enviado',
      'Tu pedido va en camino 🚚',
      '"' || coalesce(_title, 'Tu pedido') || '" fue enviado.',
      jsonb_build_object('order_id', new.id)
    );
  end if;
  return new;
end $$;

drop trigger if exists notify_order_shipped on public.orders;
create trigger notify_order_shipped
  after update on public.orders
  for each row execute function public.trg_notify_order_shipped();

-- 4e. Verificación de identidad: resultado → usuario; nueva → admins
create or replace function public.trg_notify_verification()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    -- avisar a todos los admins que hay una verificación por revisar
    perform notify_user(
      a.user_id, 'nueva_verificacion',
      'Nueva verificación por revisar 🪪',
      'Un usuario envió su cédula y selfie. Recuerda el plazo de revisión.',
      jsonb_build_object('verification_id', new.id)
    ) from admins a;
    return new;
  end if;

  if new.status is distinct from old.status then
    if new.status::text = 'approved' then
      perform notify_user(
        new.user_id, 'verificacion_aprobada',
        '¡Identidad verificada! ✅',
        'Tu cuenta fue verificada. Ya puedes publicar y comprar en Baratito.',
        jsonb_build_object('verification_id', new.id)
      );
    elsif new.status::text = 'rejected' then
      perform notify_user(
        new.user_id, 'verificacion_rechazada',
        'Verificación rechazada',
        coalesce('Motivo: ' || nullif(new.rejection_reason, ''),
                 'Revisa tus fotos e inténtalo de nuevo.'),
        jsonb_build_object('verification_id', new.id)
      );
    end if;
  end if;
  return new;
end $$;

drop trigger if exists notify_verification on public.identity_verifications;
create trigger notify_verification
  after insert or update on public.identity_verifications
  for each row execute function public.trg_notify_verification();

-- ────────────────────────────────────────────────────────
-- 5. PUSH: al insertarse una notificación, llamar a la Edge
--    Function `send-push` vía pg_net (asíncrono, no bloquea).
-- ────────────────────────────────────────────────────────
create extension if not exists pg_net;

create or replace function public.trg_push_notification()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform net.http_post(
    url := 'https://ddygpqkuxgfrjdipdvek.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      -- anon key (pública; la Edge Function valida el JWT)
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkeWdwcWt1eGdmcmpkaXBkdmVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzMjUwNjEsImV4cCI6MjA5NDkwMTA2MX0.63PViWP91iqrC2r4r6WX-SMcVehwRE-2IbZvwkNOVzY'
    ),
    body := jsonb_build_object(
      'user_id',  new.user_id,
      'title',    new.title,
      'body',     coalesce(new.body, ''),
      'metadata', coalesce(new.metadata, '{}'::jsonb)
    )
  );
  return new;
exception when others then
  raise notice 'push webhook falló: %', sqlerrm;
  return new;
end $$;

drop trigger if exists push_on_notification on public.notifications;
create trigger push_on_notification
  after insert on public.notifications
  for each row execute function public.trg_push_notification();

-- ============================================================
-- LISTO. Falta desplegar la Edge Function `send-push`
-- (ver supabase/functions/send-push/index.ts y la guía del chat).
-- Mientras la función no exista, las notificaciones in-app igual
-- se crean; solo no llega el push.
-- ============================================================
