-- 20261009000004_customers_suppliers_payments.sql
-- ========================================================
-- CUSTOMERS, SUPPLIERS & PAYMENTS SCHEMA
-- ========================================================

-- 1. Customers Table
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address TEXT,
    credit_limit BIGINT DEFAULT 0, -- In minor currency units (e.g. kobo/pesewas)
    outstanding_balance BIGINT DEFAULT 0, -- Outstanding unpaid balance (debt)
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Suppliers Table
CREATE TABLE IF NOT EXISTS public.suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    contact_person TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    outstanding_balance BIGINT DEFAULT 0, -- Amount owed to supplier
    notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Payments Table (Transaction logs for sales, debts, & supplier payouts)
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES public.branches(id) ON DELETE CASCADE,
    sale_id UUID REFERENCES public.sales(id) ON DELETE SET NULL,
    customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE SET NULL,
    amount BIGINT NOT NULL, -- Minor units
    payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'mobile_money', 'card', 'bank_transfer', 'credit')),
    provider TEXT, -- 'mtn_momo', 'telecel_cash', 'airteltigo_money', 'mpesa', 'paystack', etc.
    reference TEXT, -- MoMo txn id, POS reference, or bank slip
    phone_number TEXT, -- Sender phone number for MoMo
    status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'pending', 'failed', 'refunded')),
    notes TEXT,
    recorded_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Add customer_id reference to sales table if not already present
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'sales' AND column_name = 'customer_id'
    ) THEN
        ALTER TABLE public.sales ADD COLUMN customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 5. Indexes for fast search & filtering
CREATE INDEX IF NOT EXISTS idx_customers_business ON public.customers(business_id);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON public.customers(phone);
CREATE INDEX IF NOT EXISTS idx_suppliers_business ON public.suppliers(business_id);
CREATE INDEX IF NOT EXISTS idx_payments_business ON public.payments(business_id);
CREATE INDEX IF NOT EXISTS idx_payments_sale ON public.payments(sale_id);
CREATE INDEX IF NOT EXISTS idx_payments_customer ON public.payments(customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_customer ON public.sales(customer_id);

-- 6. Enable Row Level Security (RLS)
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- 7. Customers RLS Policies
DROP POLICY IF EXISTS "Users can view customers of their business" ON public.customers;
CREATE POLICY "Users can view customers of their business" ON public.customers
    FOR SELECT USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

DROP POLICY IF EXISTS "Users can insert customers for their business" ON public.customers;
CREATE POLICY "Users can insert customers for their business" ON public.customers
    FOR INSERT WITH CHECK (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

DROP POLICY IF EXISTS "Users can update customers for their business" ON public.customers;
CREATE POLICY "Users can update customers for their business" ON public.customers
    FOR UPDATE USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

DROP POLICY IF EXISTS "Owners can delete customers" ON public.customers;
CREATE POLICY "Owners can delete customers" ON public.customers
    FOR DELETE USING (
        public.is_business_owner(business_id, auth.uid())
    );

-- 8. Suppliers RLS Policies
DROP POLICY IF EXISTS "Users can view suppliers of their business" ON public.suppliers;
CREATE POLICY "Users can view suppliers of their business" ON public.suppliers
    FOR SELECT USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

DROP POLICY IF EXISTS "Users can insert suppliers for their business" ON public.suppliers;
CREATE POLICY "Users can insert suppliers for their business" ON public.suppliers
    FOR INSERT WITH CHECK (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

DROP POLICY IF EXISTS "Users can update suppliers for their business" ON public.suppliers;
CREATE POLICY "Users can update suppliers for their business" ON public.suppliers
    FOR UPDATE USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

DROP POLICY IF EXISTS "Owners can delete suppliers" ON public.suppliers;
CREATE POLICY "Owners can delete suppliers" ON public.suppliers
    FOR DELETE USING (
        public.is_business_owner(business_id, auth.uid())
    );

-- 9. Payments RLS Policies
DROP POLICY IF EXISTS "Users can view payments of their business" ON public.payments;
CREATE POLICY "Users can view payments of their business" ON public.payments
    FOR SELECT USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

DROP POLICY IF EXISTS "Users can insert payments for their business" ON public.payments;
CREATE POLICY "Users can insert payments for their business" ON public.payments
    FOR INSERT WITH CHECK (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );
