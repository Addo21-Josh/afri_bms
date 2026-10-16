import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const { reference } = await req.json()

    if (!reference) {
      return new Response(JSON.stringify({ error: "Transaction reference is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    const paystackSecretKey = Deno.env.get("PAYSTACK_SECRET_KEY")
    if (!paystackSecretKey) {
      return new Response(JSON.stringify({ error: "Server misconfiguration: Paystack secret key not set" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    // Verify transaction with Paystack API
    const paystackResponse = await fetch(`https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`, {
      method: "GET",
      headers: {
        "Authorization": `Bearer ${paystackSecretKey}`,
      },
    })

    const result = await paystackResponse.json()

    if (!paystackResponse.ok || !result.status) {
      return new Response(JSON.stringify({ error: result.message || "Verification failed" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    const txData = result.data
    const isSuccess = txData.status === "success"

    if (!isSuccess) {
      return new Response(
        JSON.stringify({
          verified: false,
          status: txData.status,
          message: "Transaction is not marked as successful",
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        }
      )
    }

    // Extract business and plan details from metadata
    const metadata = txData.metadata || {}
    const businessId = metadata.business_id
    const targetTier = metadata.tier
    const billingCycle = metadata.billing_cycle || "monthly"
    const amountPaid = (txData.amount || 0) / 100 // convert pesewas to currency unit
    const currency = txData.currency || "GHS"
    const channel = txData.channel || "card"

    if (businessId && targetTier) {
      // Initialize Supabase admin client using SERVICE_ROLE_KEY to bypass RLS and trigger checks
      const supabaseAdmin = createClient(
        Deno.env.get("SUPABASE_URL") ?? "",
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
      )

      // 1. Update the business subscription tier
      const { error: updateError } = await supabaseAdmin
        .from("businesses")
        .update({
          subscription_tier: targetTier,
          updated_at: new Date().toISOString(),
        })
        .eq("id", businessId)

      if (updateError) {
        console.error("Failed to update business subscription_tier:", updateError)
        throw updateError
      }

      // 2. Audit log payment in public.subscription_payments
      await supabaseAdmin.from("subscription_payments").upsert({
        business_id: businessId,
        reference: txData.reference,
        amount: amountPaid,
        currency,
        tier: targetTier,
        billing_cycle: billingCycle,
        channel,
        paid_at: txData.paid_at || new Date().toISOString(),
        verified_by: "paystack_verify_edge_function",
        metadata: txData,
      }, { onConflict: "reference" })
    }

    return new Response(
      JSON.stringify({
        verified: true,
        tier: targetTier,
        reference: txData.reference,
        amount: amountPaid,
        currency,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }
})
