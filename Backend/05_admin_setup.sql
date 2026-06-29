-- ============================================================
-- Baratito — Panel de administración: permisos + métricas
-- Ejecuta TODO en Supabase → SQL Editor → Run. Idempotente.
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 0. Helper: ¿el usuario actual es admin?
-- ────────────────────────────────────────────────────────
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.admins a where a.user_id = auth.uid());
$$;

-- ────────────────────────────────────────────────────────
-- 1. Permisos de moderación sobre PRODUCTS para admins
-- ────────────────────────────────────────────────────────
drop policy if exists "Admin ve todos los productos" on public.products;
create policy "Admin ve todos los productos"
  on public.products for select to authenticated
  using (public.is_admin());

drop policy if exists "Admin modera productos" on public.products;
create policy "Admin modera productos"
  on public.products for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admin elimina productos" on public.products;
create policy "Admin elimina productos"
  on public.products for delete to authenticated
  using (public.is_admin());

-- ────────────────────────────────────────────────────────
-- 2. Admins pueden LEER las imágenes de verificación
--    (bucket privado verification-docs) para revisarlas.
-- ────────────────────────────────────────────────────────
drop policy if exists "Verif leer admin" on storage.objects;
create policy "Verif leer admin"
  on storage.objects for select to authenticated
  using (bucket_id = 'verification-docs' and public.is_admin());

-- ────────────────────────────────────────────────────────
-- 3. RPC: resumen de métricas para el dashboard (admin-only)
-- ────────────────────────────────────────────────────────
create or replace function public.admin_overview()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result jsonb;
begin
  if not public.is_admin() then
    raise exception 'forbidden: solo administradores';
  end if;

  select jsonb_build_object(
    'users_total',     (select count(*) from profiles),
    'users_verified',  (select count(*) from profiles where is_verified = true),
    'users_new_7d',    (select count(*) from profiles where created_at > now() - interval '7 days'),
    'products_total',  (select count(*) from products),
    'products_active', (select count(*) from products where status = 'active'),
    'products_sold',   (select count(*) from products where status = 'sold'),
    'products_draft',  (select count(*) from products where status = 'draft'),
    'verif_pending',   (select count(*) from identity_verifications where status = 'pending'),
    'verif_approved',  (select count(*) from identity_verifications where status = 'approved'),
    'verif_rejected',  (select count(*) from identity_verifications where status = 'rejected'),
    'orders_total',    (select count(*) from orders),
    'by_category', coalesce((
      select jsonb_agg(t) from (
        select coalesce(c.name, 'Sin categoría') as name, count(*) as total
        from products p
        left join categories c on c.id = p.category_id
        group by c.name
        order by count(*) desc
      ) t), '[]'::jsonb),
    'top_sellers', coalesce((
      select jsonb_agg(t) from (
        select coalesce(pr.full_name, pr.email) as name, count(*) as total
        from products p
        join profiles pr on pr.id = p.seller_id
        group by pr.id, pr.full_name, pr.email
        order by count(*) desc
        limit 5
      ) t), '[]'::jsonb)
  ) into result;

  return result;
end;
$$;

grant execute on function public.admin_overview() to authenticated;

insert into public.admins (user_id)
select id from public.profiles where email = 'eg.pd2005@gmail.com'
on conflict (user_id) do nothing;

select * from public.admins;
