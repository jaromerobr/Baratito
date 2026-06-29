-- ============================================================
-- Baratito — Verificación de identidad (KYC) con cédula + selfie
-- Ejecuta TODO en Supabase → SQL Editor → Run. Es idempotente.
--
-- Seguridad: las fotos de cédula/selfie son datos sensibles, así que
-- van a un bucket PRIVADO. Solo el dueño (y el service_role del servicio
-- Python) pueden leerlas.
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 0. (Informativo) Valores del enum verify_status
-- ────────────────────────────────────────────────────────
select unnest(enum_range(null::public.verify_status))::text as verify_status_values;

-- ────────────────────────────────────────────────────────
-- 1. STORAGE — bucket privado para documentos de verificación
-- ────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('verification-docs', 'verification-docs', false)
on conflict (id) do update set public = false;

-- Cada usuario sube/lee SOLO en su carpeta {user_id}/...
drop policy if exists "Verif subir propio" on storage.objects;
create policy "Verif subir propio"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'verification-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Verif leer propio" on storage.objects;
create policy "Verif leer propio"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'verification-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "Verif actualizar propio" on storage.objects;
create policy "Verif actualizar propio"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'verification-docs'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ────────────────────────────────────────────────────────
-- 2. RLS en identity_verifications
-- ────────────────────────────────────────────────────────
alter table public.identity_verifications enable row level security;

-- El usuario crea su propia solicitud (siempre en pending).
drop policy if exists "Crea su verificación" on public.identity_verifications;
create policy "Crea su verificación"
  on public.identity_verifications for insert to authenticated
  with check (auth.uid() = user_id);

-- El usuario lee SUS propias verificaciones.
drop policy if exists "Lee su verificación" on public.identity_verifications;
create policy "Lee su verificación"
  on public.identity_verifications for select to authenticated
  using (auth.uid() = user_id);

-- Los admins leen y actualizan todas (revisión manual del flujo híbrido).
drop policy if exists "Admin lee verificaciones" on public.identity_verifications;
create policy "Admin lee verificaciones"
  on public.identity_verifications for select to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()));

drop policy if exists "Admin actualiza verificaciones" on public.identity_verifications;
create policy "Admin actualiza verificaciones"
  on public.identity_verifications for update to authenticated
  using (exists (select 1 from public.admins a where a.user_id = auth.uid()))
  with check (exists (select 1 from public.admins a where a.user_id = auth.uid()));

-- ────────────────────────────────────────────────────────
-- 3. Sincronizar profiles.is_verified con el resultado
--    (lo dispara tanto el servicio Python como la revisión admin)
-- ────────────────────────────────────────────────────────
create or replace function public.sync_profile_verified()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is distinct from old.status then
    if new.status::text = 'approved' then
      update public.profiles
        set is_verified = true, updated_at = now()
        where id = new.user_id;
    elsif new.status::text = 'rejected' then
      update public.profiles
        set is_verified = false, updated_at = now()
        where id = new.user_id;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists on_verification_status_change on public.identity_verifications;
create trigger on_verification_status_change
  after update on public.identity_verifications
  for each row
  execute function public.sync_profile_verified();

-- ============================================================
-- LISTO. profiles.is_verified = true cuando una verificación
-- pasa a 'approved'. La app usa ese campo para permitir publicar/comprar.
-- ============================================================
