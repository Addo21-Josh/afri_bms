import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

console.log("create-staff-account function is up and running!")

serve(async (req) => {
  try {
    const { email, password, full_name, phone, business_id, branch_id, role } = await req.json()

    // 1. Initialize Supabase client with Service Role key (to bypass RLS and create users)
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 2. Validate the requester is an admin for this business
    // TODO: Verify the JWT token of the caller here

    // 3. Create the user in Auth
    const { data: userData, error: authError } = await supabaseClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name, phone }
    })

    if (authError) throw authError

    const userId = userData.user.id

    // 4. Create public.profiles entry
    await supabaseClient.from('profiles').insert({
      id: userId,
      email,
      full_name,
      phone
    })

    // 5. Create user_roles entry
    await supabaseClient.from('user_roles').insert({
      user_id: userId,
      business_id,
      branch_id,
      role
    })

    return new Response(
      JSON.stringify({ 
        message: "Staff account created successfully",
        user_id: userId
      }),
      { headers: { "Content-Type": "application/json" }, status: 201 },
    )
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 400,
    })
  }
})
