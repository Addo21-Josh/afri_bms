-- 20261015000008_harden_sales_sync_rls.sql
-- ========================================================
-- HARDEN SALES & SALE_ITEMS RLS POLICIES FOR OFFLINE SYNC
-- ========================================================

-- 1. Ensure sales can be inserted by business owner, staff with active role, OR the recording cashier
DROP POLICY IF EXISTS "Users create sales" ON public.sales;
CREATE POLICY "Users create sales" ON public.sales
    FOR INSERT WITH CHECK (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid()) OR
        cashier_id = auth.uid()
    );

-- 2. Ensure sales can be viewed by business owner, role holder, or recording cashier
DROP POLICY IF EXISTS "Users view sales" ON public.sales;
CREATE POLICY "Users view sales" ON public.sales
    FOR SELECT USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid()) OR
        cashier_id = auth.uid()
    );

-- 3. Ensure sale_items can be inserted if parent sale belongs to user's business or recording cashier
DROP POLICY IF EXISTS "Users create sale_items" ON public.sale_items;
CREATE POLICY "Users create sale_items" ON public.sale_items
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.sales s
            WHERE s.id = sale_id AND (
                public.is_business_owner(s.business_id, auth.uid()) OR
                public.has_business_role(s.business_id, auth.uid()) OR
                s.cashier_id = auth.uid()
            )
        )
    );

-- 4. Ensure sale_items can be viewed by business owner, role holder, or recording cashier
DROP POLICY IF EXISTS "Users view sale_items" ON public.sale_items;
CREATE POLICY "Users view sale_items" ON public.sale_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.sales s
            WHERE s.id = sale_id AND (
                public.is_business_owner(s.business_id, auth.uid()) OR
                public.has_business_role(s.business_id, auth.uid()) OR
                s.cashier_id = auth.uid()
            )
        )
    );
