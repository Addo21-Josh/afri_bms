-- 20261014000007_protect_subscription_tier.sql
-- ==============================================================================
-- 1. SUBSCRIPTION PAYMENTS AUDIT TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.subscription_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    reference TEXT NOT NULL UNIQUE,
    amount DECIMAL(12, 2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'GHS',
    tier TEXT NOT NULL CHECK (tier IN ('free', 'starter', 'pro', 'enterprise')),
    billing_cycle TEXT NOT NULL CHECK (billing_cycle IN ('monthly', 'yearly')),
    channel TEXT,
    paid_at TIMESTAMPTZ DEFAULT now(),
    verified_by TEXT DEFAULT 'paystack_webhook',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on subscription payments
ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;

-- Business owners and staff can view their business subscription payment history
CREATE POLICY "Users can view subscription payments for their businesses"
    ON public.subscription_payments FOR SELECT
    USING (
        public.is_business_owner(business_id, auth.uid()) OR
        public.has_business_role(business_id, auth.uid())
    );

-- Only backend service_role can insert verified subscription payments
CREATE POLICY "Only service_role can insert subscription payments"
    ON public.subscription_payments FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

-- ==============================================================================
-- 2. SECURITY TRIGGER: PREVENT DIRECT SUBSCRIPTION_TIER PRIVILEGE ESCALATION
-- ==============================================================================
-- Prevents authenticated users or malicious clients from elevating their
-- subscription_tier directly through the Supabase REST/GraphQL API.
-- Only the backend Edge Functions / Webhooks running with 'service_role' can modify it.

CREATE OR REPLACE FUNCTION public.protect_business_subscription()
RETURNS TRIGGER AS $$
DECLARE
    current_role TEXT;
BEGIN
    -- Check the caller's JWT role
    BEGIN
        current_role := current_setting('request.jwt.claim.role', true);
    EXCEPTION WHEN OTHERS THEN
        current_role := NULL;
    END;

    -- If subscription_tier is being changed, ensure it's executed by service_role
    IF (NEW.subscription_tier IS DISTINCT FROM OLD.subscription_tier) THEN
        IF current_role IS NOT NULL AND current_role != 'service_role' THEN
            RAISE EXCEPTION 'Security Violation: subscription_tier cannot be updated directly from the client. Tier upgrades must be processed via authorized payment verification.'
                USING ERRCODE = '42501';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_protect_business_subscription ON public.businesses;
CREATE TRIGGER trg_protect_business_subscription
    BEFORE UPDATE ON public.businesses
    FOR EACH ROW
    EXECUTE FUNCTION public.protect_business_subscription();
