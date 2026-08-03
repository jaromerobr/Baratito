-- ============================================================
-- Baratito — Reportar usuario, bloquear usuario (personal) y
-- bloqueo de cuenta (ban) con apelación.
--
-- 3 cosas DISTINTAS:
--   1) user_blocks   → bloqueo personal: A deja de ver el contenido de B.
--   2) user_reports  → A reporta a B; lo revisa el admin.
--   3) ban de cuenta → el admin banea (profiles.is_banned); el usuario apela.
--
-- Depende de: 00 (profiles), 05 (is_admin()).
-- Correr TODO en Supabase → SQL Editor. Es idempotente.
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 1. Bloqueo personal entre usuarios
-- ────────────────────────────────────────────────────────
create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

grant all on public.user_blocks to anon, authenticated, service_role;
alter table public.user_blocks enable row level security;

drop policy if exists "Veo mis bloqueos" on public.user_blocks;
create policy "Veo mis bloqueos"
  on public.user_blocks for select to authenticated
  using (blocker_id = auth.uid());

drop policy if exists "Bloqueo a alguien" on public.user_blocks;
create policy "Bloqueo a alguien"
  on public.user_blocks for insert to authenticated
  with check (blocker_id = auth.uid() and blocked_id <> auth.uid());

drop policy if exists "Desbloqueo" on public.user_blocks;
create policy "Desbloqueo"
  on public.user_blocks for delete to authenticated
  using (blocker_id = auth.uid());

-- ────────────────────────────────────────────────────────
-- 2. Reportes de usuario (los revisa el admin)
-- ────────────────────────────────────────────────────────
create table if not exists public.user_reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_id uuid not null references public.profiles(id) on delete cascade,
  reason      text not null,
  details     text,
  status      text not null default 'open'
              check (status in ('open', 'reviewed', 'dismissed')),
  created_at  timestamptz not null default now()
);

create index if not exists user_reports_status_idx
  on public.user_reports (status, created_at desc);

grant all on public.user_reports to anon, authenticated, service_role;
alter table public.user_reports enable row level security;

drop policy if exists "Creo un reporte" on public.user_reports;
create policy "Creo un reporte"
  on public.user_reports for insert to authenticated
  with check (reporter_id = auth.uid() and reported_id <> auth.uid());

drop policy if exists "Veo mis reportes o admin" on public.user_reports;
create policy "Veo mis reportes o admin"
  on public.user_reports for select to authenticated
  using (reporter_id = auth.uid() or public.is_admin());

drop policy if exists "Admin gestiona reportes" on public.user_reports;
create policy "Admin gestiona reportes"
  on public.user_reports for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- ────────────────────────────────────────────────────────
-- 3. Bloqueo de cuenta (ban) en profiles + RPC admin
-- ────────────────────────────────────────────────────────
alter table public.profiles
  add column if not exists is_banned boolean not null default false;
alter table public.profiles
  add column if not exists ban_reason text;
alter table public.profiles
  add column if not exists banned_at timestamptz;

create or replace function public.set_user_banned(
  p_user   uuid,
  p_banned boolean,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Solo un administrador puede banear cuentas';
  end if;
  update public.profiles
     set is_banned  = p_banned,
         ban_reason = case when p_banned then p_reason else null end,
         banned_at  = case when p_banned then now() else null end
   where id = p_user;
end;
$$;

grant execute on function public.set_user_banned(uuid, boolean, text) to authenticated;

-- ────────────────────────────────────────────────────────
-- 4. Apelaciones de cuenta bloqueada
-- ────────────────────────────────────────────────────────
create table if not exists public.account_appeals (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  message     text not null,
  status      text not null default 'pending'
              check (status in ('pending', 'accepted', 'rejected')),
  created_at  timestamptz not null default now(),
  resolved_at timestamptz
);

create index if not exists account_appeals_status_idx
  on public.account_appeals (status, created_at desc);

grant all on public.account_appeals to anon, authenticated, service_role;
alter table public.account_appeals enable row level security;

-- El usuario (aunque esté baneado) puede crear y ver sus apelaciones.
drop policy if exists "Creo mi apelación" on public.account_appeals;
create policy "Creo mi apelación"
  on public.account_appeals for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "Veo mi apelación o admin" on public.account_appeals;
create policy "Veo mi apelación o admin"
  on public.account_appeals for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

drop policy if exists "Admin gestiona apelaciones" on public.account_appeals;
create policy "Admin gestiona apelaciones"
  on public.account_appeals for update to authenticated
  using (public.is_admin()) with check (public.is_admin());
