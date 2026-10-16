import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts"

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 })
  }

  try {
    const paystackSignature = req.headers.get("x-paystack-signature")
    const paystackSecretKey = Deno.env.get("PAYSTACK_SECRET_KEY")

    if (!paystackSignature || !paystackSecretKey) {
      return new Response("Unauthorized signature", { status: 401 })
    }

    const rawBody = await req.text()

    // Verify HMAC SHA512 signature
    const keyBuffer = new TextEncoder().encode(paystackSecretKey)
    const cryptoKey = await crypto.subtle.importKey(
      "raw",
      keyBuffer,
      { name: "HMAC", hash: "SHA-512" },
      false,
      ["sign"]
    )
    const signatureBuffer = await crypto.subtle.sign(
      "HMAC",
      cryptoKey,
      new TextEncoder().encode(rawBody)
    )
    const computedSignature = Array.from(new Uint8Array(signatureBuffer))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("")

    if (computedSignature !== paystackSignature) {
      console.error("Paystack webhook signature mismatch!")
      return new Response("Invalid signature", { status: 400 })
    }

    const event = JSON.parse(rawBody)

    // Handle charge.success
    if (event.event === "charge.success") {
      const data = event.data
      const metadata = data.metadata || {}
      const businessId = metadata.business_id
      const targetTier = metadata.tier
      const billingCycle = metadata.billing_cycle || "monthly"
      const amountPaid = (data.amount || 0) / 100
      const currency = data.currency || "GHS"
      const channel = data.channel || "mobile_money"

      if (businessId && targetTier) {
        const supabaseAdmin = createClient(
          Deno.env.get("SUPABASE_URL") ?? "",
          Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
        )

        // Upgrade business subscription tier
        await supabaseAdmin
          .from("businesses")
          .update({
            subscription_tier: targetTier,
            updated_at: new Date().toISOString(),
          })
          .eq("id", businessId)

        // Insert audit payment
        await supabaseAdmin.from("subscription_payments").upsert({
          business_id: businessId,
          reference: data.reference,
          amount: amountPaid,
          currency,
          tier: targetTier,
          billing_cycle: billingCycle,
          channel,
          paid_at: data.paid_at || new Date().toISOString(),
          verified_by: "paystack_webhook",
          metadata: data,
        }, { onConflict: "reference" })

        console.log(`Successfully upgraded business ${businessId} to ${targetTier} via webhook`)
      }
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    })
  } catch (error) {
    console.error("Webhook processing error:", error)
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    })
  }
})
