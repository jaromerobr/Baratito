-- ============================================================
-- Baratito — Trigger: Sync auth.users → public.users + stats
-- Run this in Supabase SQL Editor FIRST
-- ============================================================

-- 1. Create the user_role enum if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE public.user_role AS ENUM ('buyer', 'seller', 'both');
  END IF;
END
$$;

-- 2. Ensure public.users table exists with expected columns
CREATE TABLE IF NOT EXISTS public.users (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT NOT NULL,
  password_hash TEXT,
  full_name     TEXT,
  username      TEXT UNIQUE,
  phone         TEXT,
  avatar_url    TEXT,
  role          public.user_role DEFAULT 'buyer',
  is_active     BOOLEAN DEFAULT TRUE,
  is_verified   BOOLEAN DEFAULT FALSE,
  email_verified_at TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Ensure seller_stats table exists
CREATE TABLE IF NOT EXISTS public.seller_stats (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  total_sales     INTEGER DEFAULT 0,
  total_revenue   NUMERIC(12,2) DEFAULT 0.00,
  avg_rating      NUMERIC(3,2) DEFAULT 0.00,
  total_reviews   INTEGER DEFAULT 0,
  total_products  INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 4. Ensure inventory table exists (placeholder for future products)
CREATE TABLE IF NOT EXISTS public.inventory (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create the trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _full_name TEXT;
  _role      public.user_role;
  _role_text TEXT;
BEGIN
  -- Extract metadata from the signup request
  _full_name := COALESCE(
    NEW.raw_user_meta_data ->> 'full_name',
    NEW.raw_user_meta_data ->> 'name',
    ''
  );

  _role_text := COALESCE(
    NEW.raw_user_meta_data ->> 'role',
    'buyer'
  );

  -- Safely cast the role text to our enum
  BEGIN
    _role := _role_text::public.user_role;
  EXCEPTION WHEN OTHERS THEN
    _role := 'buyer';
  END;

  -- Insert into public.users (extended profile)
  INSERT INTO public.users (id, email, full_name, role, is_active, is_verified, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    _full_name,
    _role,
    TRUE,
    FALSE,
    NOW()
  );

  -- If the user is a seller or both, create seller_stats row
  IF _role IN ('seller', 'both') THEN
    INSERT INTO public.seller_stats (user_id)
    VALUES (NEW.id);
  END IF;

  -- Create a placeholder inventory row for future products
  INSERT INTO public.inventory (user_id)
  VALUES (NEW.id);

  RETURN NEW;
END;
$$;

-- 6. Drop existing trigger if any, then create
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- Done! Now run 02_rls_policies.sql
-- ============================================================
