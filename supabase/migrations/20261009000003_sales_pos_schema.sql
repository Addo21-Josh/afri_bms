-- 20261009000003_sales_pos_schema.sql
-- ========================================================
-- STOCK MOVEMENTS, SALES & POS ENGINE SCHEMA
-- ========================================================

-- 1. Stock Movements (Audit trail for all stock adjustments, sales, restocks)
CREATE TABLE IF NOT EXISTS public.stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    variant_id UUID REFERENCES public.product_variants(id) ON DELETE SET NULL,
    quantity INT NOT NULL, -- Positive for additions, negative for deductions
    type TEXT NOT NULL CHECK (type IN ('sale', 'restock', 'adjustment', 'damaged', 'expired', 'transfer', 'return')),
    reason TEXT,
    batch_number TEXT,
    expiry_date DATE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Sales Table
CREATE TABLE IF NOT EXISTS public.sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    cashier_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
    sale_number TEXT NOT NULL,
    subtotal BIGINT NOT NULL DEFAULT 0, -- Minor units (kobo/pesewas)
    discount_amount BIGINT NOT NULL DEFAULT 0,
    tax_amount BIGINT NOT NULL DEFAULT 0,
    total_amount BIGINT NOT NULL DEFAULT 0,
    payment_method TEXT NOT NULL DEFAULT 'cash' CHECK (payment_method IN ('cash', 'mobile_money', 'card', 'split', 'credit')),
    payment_status TEXT NOT NULL DEFAULT 'paid' CHECK (payment_status IN ('paid', 'pending', 'partial', 'refunded')),
    amount_tendered BIGINT DEFAULT 0,
    change_given BIGINT DEFAULT 0,
    payment_reference TEXT,
    customer_name TEXT,
    customer_phone TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    deleted_at TIMESTAMPTZ
);

-- 3. Sale Items Table
CREATE TABLE IF NOT EXISTS public.sale_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id UUID NOT NULL REFERENCES public.sales(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
    variant_id UUID REFERENCES public.product_variants(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    variant_name TEXT,
    unit_cost_price BIGINT NOT NULL DEFAULT 0,
    unit_price BIGINT NOT NULL DEFAULT 0,
    quantity INT NOT NULL DEFAULT 1,
    discount_amount BIGINT NOT NULL DEFAULT 0,
    total_price BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_stock_movements_business_branch ON public.stock_movements(business_id, branch_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_product ON public.stock_movements(product_id);
CREATE INDEX IF NOT EXISTS idx_sales_business_branch ON public.sales(business_id, branch_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sales_cashier ON public.sales(cashier_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON public.sale_items(sale_id);

-- Enable RLS
ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;

-- Policies for stock_movements
DROP POLICY IF EXISTS "Users view stock_movements" ON public.stock_movements;
CREATE POLICY "Users view stock_movements" ON public.stock_movements
    FOR SELECT USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

DROP POLICY IF EXISTS "Users insert stock_movements" ON public.stock_movements;
CREATE POLICY "Users insert stock_movements" ON public.stock_movements
    FOR INSERT WITH CHECK (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

-- Policies for sales
DROP POLICY IF EXISTS "Users view sales" ON public.sales;
CREATE POLICY "Users view sales" ON public.sales
    FOR SELECT USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

DROP POLICY IF EXISTS "Users create sales" ON public.sales;
CREATE POLICY "Users create sales" ON public.sales
    FOR INSERT WITH CHECK (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

-- Policies for sale_items
DROP POLICY IF EXISTS "Users view sale_items" ON public.sale_items;
CREATE POLICY "Users view sale_items" ON public.sale_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.sales s
            WHERE s.id = sale_id AND (
                public.is_business_owner(s.business_id, auth.uid()) OR
                public.has_business_role(s.business_id, auth.uid())
            )
        )
    );

DROP POLICY IF EXISTS "Users create sale_items" ON public.sale_items;
CREATE POLICY "Users create sale_items" ON public.sale_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.sales s
            WHERE s.id = sale_id AND (
                public.is_business_owner(s.business_id, auth.uid()) OR
                public.has_business_role(s.business_id, auth.uid())
            )
        )
    );

-- ========================================================
-- ATOMIC STORED PROCEDURE: process_sale
-- ========================================================
CREATE OR REPLACE FUNCTION public.process_sale(
    p_business_id UUID,
    p_branch_id UUID,
    p_cashier_id UUID,
    p_sale_number TEXT,
    p_subtotal BIGINT,
    p_discount_amount BIGINT,
    p_tax_amount BIGINT,
    p_total_amount BIGINT,
    p_payment_method TEXT,
    p_amount_tendered BIGINT,
    p_change_given BIGINT,
    p_payment_reference TEXT,
    p_customer_name TEXT,
    p_customer_phone TEXT,
    p_notes TEXT,
    p_items JSONB -- Array of item objects
)
RETURNS UUID AS $$
DECLARE
    v_sale_id UUID;
    v_item JSONB;
    v_product_id UUID;
    v_variant_id UUID;
    v_qty INT;
    v_cost_price BIGINT;
    v_unit_price BIGINT;
    v_discount BIGINT;
    v_total_price BIGINT;
    v_prod_name TEXT;
    v_var_name TEXT;
BEGIN
    -- 1. Insert into sales
    INSERT INTO public.sales (
        business_id,
        branch_id,
        cashier_id,
        sale_number,
        subtotal,
        discount_amount,
        tax_amount,
        total_amount,
        payment_method,
        payment_status,
        amount_tendered,
        change_given,
        payment_reference,
        customer_name,
        customer_phone,
        notes
    ) VALUES (
        p_business_id,
        p_branch_id,
        p_cashier_id,
        p_sale_number,
        p_subtotal,
        p_discount_amount,
        p_tax_amount,
        p_total_amount,
        p_payment_method,
        'paid',
        p_amount_tendered,
        p_change_given,
        p_payment_reference,
        p_customer_name,
        p_customer_phone,
        p_notes
    ) RETURNING id INTO v_sale_id;

    -- 2. Process each sale item
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::UUID;
        v_variant_id := (v_item->>'variant_id')::UUID;
        v_qty := (v_item->>'quantity')::INT;
        v_cost_price := COALESCE((v_item->>'unit_cost_price')::BIGINT, 0);
        v_unit_price := (v_item->>'unit_price')::BIGINT;
        v_discount := COALESCE((v_item->>'discount_amount')::BIGINT, 0);
        v_total_price := (v_item->>'total_price')::BIGINT;
        v_prod_name := v_item->>'product_name';
        v_var_name := v_item->>'variant_name';

        -- Insert sale item
        INSERT INTO public.sale_items (
            sale_id,
            product_id,
            variant_id,
            product_name,
            variant_name,
            unit_cost_price,
            unit_price,
            quantity,
            discount_amount,
            total_price
        ) VALUES (
            v_sale_id,
            v_product_id,
            v_variant_id,
            v_prod_name,
            v_var_name,
            v_cost_price,
            v_unit_price,
            v_qty,
            v_discount,
            v_total_price
        );

        -- Decrement physical branch stock
        IF v_variant_id IS NOT NULL THEN
            UPDATE public.stock
            SET quantity = quantity - v_qty,
                updated_at = now()
            WHERE branch_id = p_branch_id AND variant_id = v_variant_id;
        ELSE
            UPDATE public.stock
            SET quantity = quantity - v_qty,
                updated_at = now()
            WHERE branch_id = p_branch_id AND product_id = v_product_id AND variant_id IS NULL;
        END IF;

        -- Record stock movement audit
        INSERT INTO public.stock_movements (
            business_id,
            branch_id,
            product_id,
            variant_id,
            quantity,
            type,
            reason,
            user_id
        ) VALUES (
            p_business_id,
            p_branch_id,
            v_product_id,
            v_variant_id,
            -v_qty,
            'sale',
            'Sale: ' || p_sale_number,
            p_cashier_id
        );
    END LOOP;

    RETURN v_sale_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
