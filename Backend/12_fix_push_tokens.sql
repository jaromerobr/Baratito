-- ============================================================
-- Baratito — Fix: registro de tokens push al cambiar de cuenta
-- Ejecuta TODO en Supabase → SQL Editor → Run. Idempotente.
--
-- Problema: si en un mismo dispositivo inicia sesión OTRO usuario,
-- el token FCM ya pertenece al usuario anterior y las políticas RLS
-- (correctamente) impiden que el nuevo usuario modifique esa fila.
-- El upsert fallaba en silencio → el nuevo usuario quedaba sin
-- dispositivos registrados y no recibía notificaciones.
--
-- Solución: dos RPC con SECURITY DEFINER que gestionan el token por
-- dispositivo de forma segura: el token SIEMPRE pasa a pertenecer a
-- quien está autenticado en el dispositivo (un token = un aparato).
-- ============================================================

-- Registrar/reclamar el token del dispositivo para el usuario actual.
create or replace function public.register_push_token(
  p_token    text,
  p_platform text default 'android'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Sin sesión';
  end if;

  insert into push_tokens (user_id, token, platform, is_active, updated_at)
  values (auth.uid(), p_token, p_platform, true, now())
  on conflict (token) do update
    set user_id    = auth.uid(),   -- reasigna el aparato al usuario actual
        platform   = excluded.platform,
        is_active  = true,
        updated_at = now();
end;
$$;

grant execute on function public.register_push_token(text, text) to authenticated;

-- Desactivar el token del dispositivo (al cerrar sesión),
-- sin importar a qué usuario pertenecía la fila.
create or replace function public.deactivate_push_token(p_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update push_tokens
     set is_active = false, updated_at = now()
   where token = p_token;
end;
$$;

grant execute on function public.deactivate_push_token(text) to authenticated;

-- Limpieza puntual: desactivar tokens actuales para que cada
-- dispositivo se re-registre con el usuario correcto al abrir la app.
update public.push_tokens set is_active = false, updated_at = now();

-- ============================================================
-- LISTO. La app ahora registra el token vía register_push_token()
-- en cada inicio de sesión / arranque.
-- ============================================================
