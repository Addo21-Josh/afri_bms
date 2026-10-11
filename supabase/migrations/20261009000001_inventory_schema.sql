-- 20261009000001_inventory_schema.sql
-- ==========================================
-- INVENTORY & PRODUCT SCHEMA
-- ==========================================

-- 1. Product Categories
CREATE TABLE IF NOT EXISTS public.product_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- 2. Products
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.product_categories(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    sku TEXT,
    barcode TEXT,
    cost_price BIGINT NOT NULL DEFAULT 0,
    selling_price BIGINT NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'NGN',
    unit TEXT DEFAULT 'pcs',
    reorder_level INT DEFAULT 10,
    is_active BOOLEAN DEFAULT true,
    image_urls TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- 3. Product Variants
CREATE TABLE IF NOT EXISTS public.product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    sku TEXT,
    barcode TEXT,
    cost_price BIGINT NOT NULL DEFAULT 0,
    selling_price BIGINT NOT NULL DEFAULT 0,
    attributes JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- 4. Stock (Per Branch)
CREATE TABLE IF NOT EXISTS public.stock (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES public.product_variants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    quantity INT NOT NULL DEFAULT 0,
    batch_number TEXT,
    expiry_date DATE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(product_id, variant_id, branch_id, batch_number)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_products_business ON public.products(business_id, name);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON public.products(barcode) WHERE barcode IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_sku ON public.products(sku) WHERE sku IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_categories_business ON public.product_categories(business_id);
CREATE INDEX IF NOT EXISTS idx_stock_product_branch ON public.stock(product_id, branch_id);

-- Enable RLS
ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock ENABLE ROW LEVEL SECURITY;

-- Product Categories Policies
DROP POLICY IF EXISTS "Users view categories" ON public.product_categories;
CREATE POLICY "Users view categories" ON public.product_categories
    FOR SELECT USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

DROP POLICY IF EXISTS "Users manage categories" ON public.product_categories;
CREATE POLICY "Users manage categories" ON public.product_categories
    FOR ALL USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

-- Products Policies
DROP POLICY IF EXISTS "Users view products" ON public.products;
CREATE POLICY "Users view products" ON public.products
    FOR SELECT USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

DROP POLICY IF EXISTS "Users manage products" ON public.products;
CREATE POLICY "Users manage products" ON public.products
    FOR ALL USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

-- Product Variants Policies
DROP POLICY IF EXISTS "Users view variants" ON public.product_variants;
CREATE POLICY "Users view variants" ON public.product_variants
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.products p
            WHERE p.id = product_id AND (
                public.is_business_owner(p.business_id, auth.uid()) OR
                public.has_business_role(p.business_id, auth.uid())
            )
        )
    );

DROP POLICY IF EXISTS "Users manage variants" ON public.product_variants;
CREATE POLICY "Users manage variants" ON public.product_variants
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.products p
            WHERE p.id = product_id AND (
                public.is_business_owner(p.business_id, auth.uid()) OR
                public.has_business_role(p.business_id, auth.uid())
            )
        )
    );

-- Stock Policies
DROP POLICY IF EXISTS "Users view stock" ON public.stock;
CREATE POLICY "Users view stock" ON public.stock
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.branches b
            WHERE b.id = branch_id AND (
                public.is_business_owner(b.business_id, auth.uid()) OR
                public.has_business_role(b.business_id, auth.uid())
            )
        )
    );

DROP POLICY IF EXISTS "Users manage stock" ON public.stock;
CREATE POLICY "Users manage stock" ON public.stock
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.branches b
            WHERE b.id = branch_id AND (
                public.is_business_owner(b.business_id, auth.uid()) OR
                public.has_business_role(b.business_id, auth.uid())
            )
        )
    );

-- Storage bucket for product images
INSERT INTO storage.buckets (id, name, public) VALUES ('product_images', 'product_images', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Product images publicly accessible" ON storage.objects 
  FOR SELECT USING (bucket_id = 'product_images');
CREATE POLICY "Authenticated users upload product images" ON storage.objects 
  FOR INSERT WITH CHECK (bucket_id = 'product_images' AND auth.role() = 'authenticated');
