-- ==============================================================================
-- Migration: 20261009000005_expenses_and_debts.sql
-- Description: Expenses, Expense Categories, Debt/Credit Ledger & Repayments
-- ==============================================================================

-- 1. Expense Categories Table
CREATE TABLE IF NOT EXISTS public.expense_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT DEFAULT 'category',
    color TEXT DEFAULT '0xFF2196F3',
    is_system BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Index on business_id
CREATE INDEX IF NOT EXISTS idx_expense_categories_biz ON public.expense_categories(business_id);

-- 2. Expenses Table
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.expense_categories(id) ON DELETE SET NULL,
    amount BIGINT NOT NULL, -- in minor currency units (cents/pesewas)
    description TEXT NOT NULL,
    payment_method TEXT NOT NULL DEFAULT 'cash',
    payment_reference TEXT,
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    receipt_url TEXT,
    recorded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    recorded_by_name TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_expenses_biz ON public.expenses(business_id);
CREATE INDEX IF NOT EXISTS idx_expenses_branch ON public.expenses(branch_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses(expense_date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON public.expenses(category_id);

-- 3. Debts Table (Ledger for Customer Receivables & Supplier Payables)
CREATE TABLE IF NOT EXISTS public.debts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    debt_type TEXT NOT NULL CHECK (debt_type IN ('receivable', 'payable')),
    customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
    supplier_id UUID REFERENCES public.suppliers(id) ON DELETE SET NULL,
    sale_id UUID REFERENCES public.sales(id) ON DELETE SET NULL,
    person_name TEXT NOT NULL,
    person_phone TEXT,
    initial_amount BIGINT NOT NULL, -- in minor currency units
    remaining_balance BIGINT NOT NULL, -- in minor currency units
    due_date DATE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paid', 'bad_debt', 'cancelled')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_debts_biz ON public.debts(business_id);
CREATE INDEX IF NOT EXISTS idx_debts_branch ON public.debts(branch_id);
CREATE INDEX IF NOT EXISTS idx_debts_type_status ON public.debts(debt_type, status);
CREATE INDEX IF NOT EXISTS idx_debts_due_date ON public.debts(due_date);
CREATE INDEX IF NOT EXISTS idx_debts_customer ON public.debts(customer_id);
CREATE INDEX IF NOT EXISTS idx_debts_supplier ON public.debts(supplier_id);

-- 4. Debt Payments Table (Repayments towards a debt)
CREATE TABLE IF NOT EXISTS public.debt_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    debt_id UUID NOT NULL REFERENCES public.debts(id) ON DELETE CASCADE,
    amount BIGINT NOT NULL, -- in minor currency units
    payment_method TEXT NOT NULL DEFAULT 'cash',
    payment_reference TEXT,
    notes TEXT,
    recorded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_debt_payments_debt ON public.debt_payments(debt_id);
CREATE INDEX IF NOT EXISTS idx_debt_payments_biz ON public.debt_payments(business_id);

-- 5. Row Level Security (RLS)
ALTER TABLE public.expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debt_payments ENABLE ROW LEVEL SECURITY;

-- Expense Categories Policies
DROP POLICY IF EXISTS "Users can manage expense categories in their business" ON public.expense_categories;
CREATE POLICY "Users can manage expense categories in their business"
    ON public.expense_categories
    FOR ALL
    USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    )
    WITH CHECK (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

-- Expenses Policies
DROP POLICY IF EXISTS "Users can manage expenses in their business" ON public.expenses;
CREATE POLICY "Users can manage expenses in their business"
    ON public.expenses
    FOR ALL
    USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    )
    WITH CHECK (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

-- Debts Policies
DROP POLICY IF EXISTS "Users can manage debts in their business" ON public.debts;
CREATE POLICY "Users can manage debts in their business"
    ON public.debts
    FOR ALL
    USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    )
    WITH CHECK (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

-- Debt Payments Policies
DROP POLICY IF EXISTS "Users can manage debt payments in their business" ON public.debt_payments;
CREATE POLICY "Users can manage debt payments in their business"
    ON public.debt_payments
    FOR ALL
    USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    )
    WITH CHECK (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

