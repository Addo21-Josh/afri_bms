-- ========================================================
-- Allow UPDATE on sales and sale_items for business members
-- ========================================================

DROP POLICY IF EXISTS "Users update sales" ON public.sales;
CREATE POLICY "Users update sales" ON public.sales
    FOR UPDATE USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    )
    WITH CHECK (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

DROP POLICY IF EXISTS "Users update sale_items" ON public.sale_items;
CREATE POLICY "Users update sale_items" ON public.sale_items
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.sales s
            WHERE s.id = sale_id AND (
                public.is_business_owner(s.business_id, auth.uid()) OR
                public.has_business_role(s.business_id, auth.uid())
            )
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.sales s
            WHERE s.id = sale_id AND (
                public.is_business_owner(s.business_id, auth.uid()) OR
                public.has_business_role(s.business_id, auth.uid())
            )
        )
    );
