-- ============================================================
-- Baratito — Reseñas MUTUAS entre usuarios (vendedor ↔ comprador)
--
-- Al entregarse un pedido, tanto el comprador como el vendedor pueden
-- calificarse (1-5 estrellas + comentario opcional). Generaliza el antiguo
-- `seller_reviews` (solo comprador→vendedor) a `user_reviews` (cualquiera
-- califica a cualquiera con quien tuvo un pedido ENTREGADO). El promedio y el
-- conteo siguen en `profiles.rating_avg` / `rating_count`.
--
-- Depende de: 14_seller_reviews.sql (columnas rating en profiles + datos a
-- migrar), 15_order_fulfillment.sql (checkouts.fulfillment_status + FK orders).
-- Correr TODO en Supabase → SQL Editor. Es idempotente.
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 1. Tabla general de reseñas (una por par calificador→calificado)
-- ────────────────────────────────────────────────────────
create table if not exists public.user_reviews (
  id           uuid primary key default gen_random_uuid(),
  reviewee_id  uuid not null references public.profiles(id) on delete cascade, -- el calificado
  reviewer_id  uuid not null references public.profiles(id) on delete cascade, -- el que califica
  order_id     uuid references public.orders(id) on delete set null,
  role         text not null default 'seller' check (role in ('seller', 'buyer')), -- rol del calificado
  rating       smallint not null check (rating between 1 and 5),
  comment      text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (reviewee_id, reviewer_id)
);

create index if not exists user_reviews_reviewee_idx
  on public.user_reviews (reviewee_id);

grant all on public.user_reviews to anon, authenticated, service_role;

-- ────────────────────────────────────────────────────────
-- 2. Migrar las reseñas antiguas (comprador→vendedor) si existen
-- ────────────────────────────────────────────────────────
do $$
begin
  if exists (select 1 from information_schema.tables
             where table_schema = 'public' and table_name = 'seller_reviews') then
    insert into public.user_reviews
      (reviewee_id, reviewer_id, order_id, role, rating, comment, created_at)
    select seller_id, reviewer_id, order_id, 'seller', rating, comment, created_at
      from public.seller_reviews
    on conflict (reviewee_id, reviewer_id) do nothing;
  end if;
end $$;

-- ────────────────────────────────────────────────────────
-- 3. Agregado de rating por usuario (en profiles)
-- ────────────────────────────────────────────────────────
create or replace function public.refresh_user_rating(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles p
     set rating_count = sub.cnt,
         rating_avg   = coalesce(sub.avg, 0)
    from (
      select count(*)::int as cnt,
             round(avg(rating)::numeric, 2) as avg
        from public.user_reviews
       where reviewee_id = p_user
    ) sub
   where p.id = p_user;
end;
$$;

create or replace function public.tg_user_reviews_aggr()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'DELETE' then
    perform public.refresh_user_rating(old.reviewee_id);
    return old;
  end if;
  new.updated_at := now();
  perform public.refresh_user_rating(new.reviewee_id);
  if tg_op = 'UPDATE' and new.reviewee_id <> old.reviewee_id then
    perform public.refresh_user_rating(old.reviewee_id);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_user_reviews_aggr on public.user_reviews;
create trigger trg_user_reviews_aggr
  after insert or update or delete on public.user_reviews
  for each row execute function public.tg_user_reviews_aggr();

-- El trigger viejo de seller_reviews queda obsoleto (ya no se escribe ahí).
drop trigger if exists trg_seller_reviews_aggr on public.seller_reviews;

-- ────────────────────────────────────────────────────────
-- 4. RLS: cualquiera lee las reseñas (para mostrarlas en el perfil).
--    La escritura se hace SOLO por el RPC submit_review (valida entrega).
-- ────────────────────────────────────────────────────────
alter table public.user_reviews enable row level security;

drop policy if exists "Reseñas visibles para todos" on public.user_reviews;
create policy "Reseñas visibles para todos"
  on public.user_reviews for select
  using (true);

-- ────────────────────────────────────────────────────────
-- 5. Crear/actualizar reseña: solo si hubo un pedido ENTREGADO entre ambos.
--    El rol del calificado se deduce (si el que califica fue el comprador,
--    el calificado es el vendedor, y viceversa).
-- ────────────────────────────────────────────────────────
create or replace function public.submit_review(
  p_reviewee uuid,
  p_rating   int,
  p_comment  text default null,
  p_order    uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  _reviewer uuid := auth.uid();
  _role     text;
begin
  if _reviewer is null then raise exception 'Sin sesión'; end if;
  if _reviewer = p_reviewee then raise exception 'No puedes calificarte a ti mismo'; end if;
  if p_rating < 1 or p_rating > 5 then raise exception 'Calificación inválida'; end if;

  -- Debe existir un pedido ENTREGADO entre ambos (en cualquier dirección).
  select case when o.buyer_id = _reviewer then 'seller' else 'buyer' end
    into _role
  from public.orders o
  join public.checkouts c on c.id = o.checkout_id
  where c.fulfillment_status = 'delivered'
    and ((o.buyer_id = _reviewer and o.seller_id = p_reviewee)
      or (o.seller_id = _reviewer and o.buyer_id = p_reviewee))
  limit 1;

  if _role is null then
    raise exception 'Solo puedes calificar tras un pedido entregado';
  end if;

  insert into public.user_reviews
    (reviewee_id, reviewer_id, order_id, role, rating, comment)
  values (p_reviewee, _reviewer, p_order, _role, p_rating,
          nullif(btrim(coalesce(p_comment, '')), ''))
  on conflict (reviewee_id, reviewer_id) do update
    set rating   = excluded.rating,
        comment  = excluded.comment,
        role     = excluded.role,
        order_id = coalesce(excluded.order_id, public.user_reviews.order_id),
        updated_at = now();
end;
$$;

grant execute on function public.submit_review(uuid, int, text, uuid) to authenticated;

-- ────────────────────────────────────────────────────────
-- 5b. Reseñas PENDIENTES del usuario: contrapartes de pedidos entregados
--     a las que aún no ha calificado (para el aviso automático en la app).
-- ────────────────────────────────────────────────────────
create or replace function public.pending_reviews()
returns table (reviewee_id uuid, reviewee_name text, role text)
language sql
stable
security definer
set search_path = public
as $$
  select t.counterpart, coalesce(p.full_name, 'Usuario'), t.role
  from (
    -- Como comprador: debo calificar a los vendedores.
    select distinct o.seller_id as counterpart, 'seller'::text as role
      from public.orders o
      join public.checkouts c on c.id = o.checkout_id
     where c.fulfillment_status = 'delivered' and o.buyer_id = auth.uid()
    union
    -- Como vendedor: debo calificar a los compradores.
    select distinct o.buyer_id, 'buyer'::text
      from public.orders o
      join public.checkouts c on c.id = o.checkout_id
     where c.fulfillment_status = 'delivered' and o.seller_id = auth.uid()
  ) t
  join public.profiles p on p.id = t.counterpart
  where t.counterpart <> auth.uid()
    and not exists (
      select 1 from public.user_reviews r
       where r.reviewer_id = auth.uid() and r.reviewee_id = t.counterpart
    );
$$;

grant execute on function public.pending_reviews() to authenticated;

-- ────────────────────────────────────────────────────────
-- 6. Recalcular los agregados desde user_reviews
-- ────────────────────────────────────────────────────────
update public.profiles p
   set rating_count = sub.cnt,
       rating_avg   = coalesce(sub.avg, 0)
  from (
    select reviewee_id,
           count(*)::int as cnt,
           round(avg(rating)::numeric, 2) as avg
      from public.user_reviews
     group by reviewee_id
  ) sub
 where p.id = sub.reviewee_id;
