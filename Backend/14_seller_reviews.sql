-- ============================================================
-- Baratito — Reseñas / valoración de vendedores (estrellas)
--
-- Un comprador puede calificar (1-5 estrellas + comentario opcional) a un
-- vendedor del que compró. El promedio y el conteo se mantienen en
-- `profiles.rating_avg` / `profiles.rating_count` vía trigger, para poder
-- mostrar la valoración en la tarjeta del vendedor sin consultas extra.
--
-- Depende de:
--   00_setup_auth_profiles.sql → public.profiles
--   06_profile_chat_setup.sql / 07_cart_favorites_checkout.sql → public.orders
--
-- Correr TODO en Supabase → SQL Editor. Es idempotente.
-- ============================================================

-- ────────────────────────────────────────────────────────
-- 1. Agregados de valoración en profiles
-- ────────────────────────────────────────────────────────
alter table public.profiles
  add column if not exists rating_avg numeric(3, 2) not null default 0;
alter table public.profiles
  add column if not exists rating_count integer not null default 0;

-- ────────────────────────────────────────────────────────
-- 2. Tabla de reseñas (una por comprador → vendedor; se puede actualizar)
-- ────────────────────────────────────────────────────────
create table if not exists public.seller_reviews (
  id          uuid primary key default gen_random_uuid(),
  seller_id   uuid not null references public.profiles(id) on delete cascade,
  reviewer_id uuid not null references public.profiles(id) on delete cascade,
  order_id    uuid references public.orders(id) on delete set null,
  rating      smallint not null check (rating between 1 and 5),
  comment     text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (seller_id, reviewer_id)
);

create index if not exists seller_reviews_seller_idx
  on public.seller_reviews (seller_id);

-- ────────────────────────────────────────────────────────
-- 3. Recalcular promedio + conteo del vendedor y guardarlos en profiles
-- ────────────────────────────────────────────────────────
create or replace function public.refresh_seller_rating(p_seller uuid)
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
        from public.seller_reviews
       where seller_id = p_seller
    ) sub
   where p.id = p_seller;
end;
$$;

create or replace function public.tg_seller_reviews_aggr()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'DELETE' then
    perform public.refresh_seller_rating(old.seller_id);
    return old;
  end if;
  new.updated_at := now();
  perform public.refresh_seller_rating(new.seller_id);
  if tg_op = 'UPDATE' and new.seller_id <> old.seller_id then
    perform public.refresh_seller_rating(old.seller_id);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_seller_reviews_aggr on public.seller_reviews;
create trigger trg_seller_reviews_aggr
  after insert or update or delete on public.seller_reviews
  for each row execute function public.tg_seller_reviews_aggr();

-- ────────────────────────────────────────────────────────
-- 4. RLS
-- ────────────────────────────────────────────────────────
alter table public.seller_reviews enable row level security;

-- Cualquiera (incluido invitado) puede leer las reseñas para mostrar estrellas.
drop policy if exists "Reseñas visibles para todos" on public.seller_reviews;
create policy "Reseñas visibles para todos"
  on public.seller_reviews for select
  using (true);

-- El comprador crea su reseña: solo si compró a ese vendedor y no es él mismo.
drop policy if exists "Comprador crea reseña" on public.seller_reviews;
create policy "Comprador crea reseña"
  on public.seller_reviews for insert to authenticated
  with check (
    reviewer_id = auth.uid()
    and reviewer_id <> seller_id
    and exists (
      select 1 from public.orders o
      where o.buyer_id = auth.uid()
        and o.seller_id = seller_reviews.seller_id
    )
  );

-- El comprador edita su propia reseña.
drop policy if exists "Comprador edita reseña" on public.seller_reviews;
create policy "Comprador edita reseña"
  on public.seller_reviews for update to authenticated
  using (reviewer_id = auth.uid())
  with check (reviewer_id = auth.uid());

-- El comprador borra su propia reseña.
drop policy if exists "Comprador borra reseña" on public.seller_reviews;
create policy "Comprador borra reseña"
  on public.seller_reviews for delete to authenticated
  using (reviewer_id = auth.uid());

-- ────────────────────────────────────────────────────────
-- 5. Backfill: dejar los agregados coherentes por si ya hubiera reseñas.
-- ────────────────────────────────────────────────────────
update public.profiles p
   set rating_count = sub.cnt,
       rating_avg   = coalesce(sub.avg, 0)
  from (
    select seller_id,
           count(*)::int as cnt,
           round(avg(rating)::numeric, 2) as avg
      from public.seller_reviews
     group by seller_id
  ) sub
 where p.id = sub.seller_id;
