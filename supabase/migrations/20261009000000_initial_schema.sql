-- 20261009000000_initial_schema.sql
-- ==========================================
-- CORE TABLES
-- ==========================================

-- Users (extends Supabase Auth)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Businesses
CREATE TABLE public.businesses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id),
    name TEXT NOT NULL,
    description TEXT,
    logo_url TEXT,
    default_currency TEXT NOT NULL DEFAULT 'NGN',
    supported_currencies TEXT[] DEFAULT '{NGN}',
    tax_rate DECIMAL(5,2) DEFAULT 0.00,
    address TEXT,
    phone TEXT,
    email TEXT,
    is_active BOOLEAN DEFAULT true,
    subscription_tier TEXT DEFAULT 'free',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- Branches
CREATE TABLE public.branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id),
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    currency TEXT NOT NULL DEFAULT 'NGN',
    is_main BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- User Roles (many-to-many: users ↔ businesses/branches)
CREATE TABLE public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id),
    business_id UUID NOT NULL REFERENCES public.businesses(id),
    branch_id UUID REFERENCES public.branches(id),
    role TEXT NOT NULL CHECK (role IN ('admin', 'branch_manager', 'salesperson', 'cashier', 'custom')),
    custom_permissions JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    UNIQUE(user_id, business_id, branch_id)
);

-- Trigger for automatic profile creation on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, phone)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'phone'
  )
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email,
      full_name = EXCLUDED.full_name,
      phone = EXCLUDED.phone;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==========================================
-- SECURITY DEFINER HELPER FUNCTIONS (Prevent RLS recursion)
-- ==========================================

-- Check if user is the owner of a business without triggering RLS
CREATE OR REPLACE FUNCTION public.is_business_owner(biz_id UUID, uid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.businesses
    WHERE id = biz_id AND owner_id = uid
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Check if user has an active role in a business without triggering RLS
CREATE OR REPLACE FUNCTION public.has_business_role(biz_id UUID, uid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE business_id = biz_id AND user_id = uid AND is_active = true
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- RLS Policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Businesses Policies
DROP POLICY IF EXISTS "Users see own business data" ON public.businesses;
DROP POLICY IF EXISTS "Users can view businesses they own or belong to" ON public.businesses;
CREATE POLICY "Users can view businesses they own or belong to" ON public.businesses
    FOR SELECT USING (owner_id = auth.uid() OR public.has_business_role(id, auth.uid()));

DROP POLICY IF EXISTS "Owners can create businesses" ON public.businesses;
CREATE POLICY "Owners can create businesses" ON public.businesses
    FOR INSERT WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "Owners can update their businesses" ON public.businesses;
CREATE POLICY "Owners can update their businesses" ON public.businesses
    FOR UPDATE USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "Owners can delete their businesses" ON public.businesses;
CREATE POLICY "Owners can delete their businesses" ON public.businesses
    FOR DELETE USING (owner_id = auth.uid());

-- Branches Policies
DROP POLICY IF EXISTS "Users can view branches for their businesses" ON public.branches;
CREATE POLICY "Users can view branches for their businesses" ON public.branches
    FOR SELECT USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

DROP POLICY IF EXISTS "Owners can create branches" ON public.branches;
CREATE POLICY "Owners can create branches" ON public.branches
    FOR INSERT WITH CHECK (public.is_business_owner(business_id, auth.uid()));

DROP POLICY IF EXISTS "Owners can update branches" ON public.branches;
CREATE POLICY "Owners can update branches" ON public.branches
    FOR UPDATE USING (public.is_business_owner(business_id, auth.uid()));

DROP POLICY IF EXISTS "Owners can delete branches" ON public.branches;
CREATE POLICY "Owners can delete branches" ON public.branches
    FOR DELETE USING (public.is_business_owner(business_id, auth.uid()));

-- User Roles Policies
DROP POLICY IF EXISTS "Users can view user_roles" ON public.user_roles;
CREATE POLICY "Users can view user_roles" ON public.user_roles
    FOR SELECT USING (user_id = auth.uid() OR public.is_business_owner(business_id, auth.uid()));

DROP POLICY IF EXISTS "Owners and self can create user_roles" ON public.user_roles;
CREATE POLICY "Owners and self can create user_roles" ON public.user_roles
    FOR INSERT WITH CHECK (user_id = auth.uid() OR public.is_business_owner(business_id, auth.uid()));

DROP POLICY IF EXISTS "Owners can update user_roles" ON public.user_roles;
CREATE POLICY "Owners can update user_roles" ON public.user_roles
    FOR UPDATE USING (public.is_business_owner(business_id, auth.uid()));

DROP POLICY IF EXISTS "Owners can delete user_roles" ON public.user_roles;
CREATE POLICY "Owners can delete user_roles" ON public.user_roles
    FOR DELETE USING (public.is_business_owner(business_id, auth.uid()));

-- ==========================================
-- STORAGE BUCKETS & POLICIES
-- ==========================================

-- Create Avatars Bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Create Business Logos Bucket
INSERT INTO storage.buckets (id, name, public) VALUES ('logos', 'logos', true)
ON CONFLICT (id) DO NOTHING;

-- Avatars Policies (Public Read, Authenticated Upload)
CREATE POLICY "Avatar images are publicly accessible." ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Users can upload their own avatar." ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users can update their own avatar." ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Logos Policies (Public Read, Admin/Manager Upload)
CREATE POLICY "Logo images are publicly accessible." ON storage.objects FOR SELECT USING (bucket_id = 'logos');
CREATE POLICY "Authenticated users can upload logos." ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'logos' AND auth.role() = 'authenticated');
CREATE POLICY "Authenticated users can update logos." ON storage.objects FOR UPDATE USING (bucket_id = 'logos' AND auth.role() = 'authenticated');
