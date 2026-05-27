-- ============================================================
-- Baratito — Row Level Security (RLS) Policies
-- Run this in Supabase SQL Editor AFTER 01_trigger_new_user.sql
-- ============================================================

-- ────────────────────────────────────
-- TABLE: public.users
-- Policy: Users can only read/edit their own profile
-- ────────────────────────────────────

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile"
  ON public.users
  FOR SELECT
  USING (auth.uid() = id);

-- Allow users to update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile"
  ON public.users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Allow the trigger (service_role) to insert new profiles
DROP POLICY IF EXISTS "Service role can insert profiles" ON public.users;
CREATE POLICY "Service role can insert profiles"
  ON public.users
  FOR INSERT
  WITH CHECK (TRUE);
  -- Note: The trigger runs with SECURITY DEFINER so it bypasses RLS.
  -- This policy is a fallback for service_role key usage.

-- ────────────────────────────────────
-- TABLE: public.admins
-- Policy: Only admin users can read
-- ────────────────────────────────────

-- Ensure admins table exists
CREATE TABLE IF NOT EXISTS public.admins (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  permission_level  TEXT DEFAULT 'basic',
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;

-- Only users who are in the admins table can read admin records
DROP POLICY IF EXISTS "Only admins can view admin records" ON public.admins;
CREATE POLICY "Only admins can view admin records"
  ON public.admins
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admins a
      WHERE a.user_id = auth.uid()
    )
  );

-- No insert/update/delete for regular users — only service_role
DROP POLICY IF EXISTS "No public write on admins" ON public.admins;
CREATE POLICY "No public write on admins"
  ON public.admins
  FOR ALL
  USING (FALSE)
  WITH CHECK (FALSE);

-- ────────────────────────────────────
-- TABLE: public.seller_stats
-- Policy: Public read, system-only write
-- ────────────────────────────────────

ALTER TABLE public.seller_stats ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can read seller stats (public marketplace data)
DROP POLICY IF EXISTS "Anyone can view seller stats" ON public.seller_stats;
CREATE POLICY "Anyone can view seller stats"
  ON public.seller_stats
  FOR SELECT
  USING (TRUE);

-- Only service_role (system) can insert/update/delete
-- The trigger function uses SECURITY DEFINER so it bypasses RLS
DROP POLICY IF EXISTS "No public write on seller_stats" ON public.seller_stats;
CREATE POLICY "No public write on seller_stats"
  ON public.seller_stats
  FOR INSERT
  WITH CHECK (FALSE);

DROP POLICY IF EXISTS "No public update on seller_stats" ON public.seller_stats;
CREATE POLICY "No public update on seller_stats"
  ON public.seller_stats
  FOR UPDATE
  USING (FALSE)
  WITH CHECK (FALSE);

DROP POLICY IF EXISTS "No public delete on seller_stats" ON public.seller_stats;
CREATE POLICY "No public delete on seller_stats"
  ON public.seller_stats
  FOR DELETE
  USING (FALSE);

-- ────────────────────────────────────
-- TABLE: public.inventory
-- Policy: Users can manage their own inventory
-- ────────────────────────────────────

ALTER TABLE public.inventory ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own inventory" ON public.inventory;
CREATE POLICY "Users can view own inventory"
  ON public.inventory
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own inventory" ON public.inventory;
CREATE POLICY "Users can update own inventory"
  ON public.inventory
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role can insert inventory" ON public.inventory;
CREATE POLICY "Service role can insert inventory"
  ON public.inventory
  FOR INSERT
  WITH CHECK (TRUE);

-- ============================================================
-- Done! All RLS policies applied.
-- ============================================================
