-- 20261009000002_staff_management.sql
-- ========================================================
-- DIRECT STAFF ACCOUNT CREATION (NO PRIOR SIGN-UP NEEDED)
-- ========================================================

-- Enable pgcrypto in extensions schema if not already enabled
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- 1. Fix NULL token fields in auth.users for existing accounts to prevent GoTrue 500 errors
UPDATE auth.users
SET 
  confirmation_token = COALESCE(confirmation_token, ''),
  email_change = COALESCE(email_change, ''),
  email_change_token_new = COALESCE(email_change_token_new, ''),
  recovery_token = COALESCE(recovery_token, '')
WHERE confirmation_token IS NULL 
   OR email_change IS NULL 
   OR email_change_token_new IS NULL 
   OR recovery_token IS NULL;

-- 2. Ensure auth.identities exists for any existing users
INSERT INTO auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  provider_id,
  last_sign_in_at,
  created_at,
  updated_at
)
SELECT 
  gen_random_uuid(),
  u.id,
  jsonb_build_object('sub', u.id::text, 'email', u.email),
  'email',
  u.id::text,
  now(),
  now(),
  now()
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM auth.identities i WHERE i.user_id = u.id
);

-- 3. Stored Procedure to create staff account directly and assign role
CREATE OR REPLACE FUNCTION public.create_staff_user(
  p_email TEXT,
  p_password TEXT,
  p_full_name TEXT,
  p_phone TEXT DEFAULT NULL,
  p_business_id UUID DEFAULT NULL,
  p_branch_id UUID DEFAULT NULL,
  p_role TEXT DEFAULT 'salesperson'
)
RETURNS UUID AS $$
DECLARE
  v_user_id UUID;
  v_caller_id UUID;
  v_instance_id UUID;
BEGIN
  v_caller_id := auth.uid();
  
  -- 1. Security Check: Verify caller is owner or admin of this business
  IF NOT (
    public.is_business_owner(p_business_id, v_caller_id) OR 
    public.has_business_role(p_business_id, v_caller_id)
  ) THEN
    RAISE EXCEPTION 'Only business owners and admins can create staff accounts.';
  END IF;

  -- 2. Check if user already exists in auth.users
  SELECT id INTO v_user_id FROM auth.users WHERE email = lower(trim(p_email));

  -- 3. If user does not exist, create in auth.users directly
  IF v_user_id IS NULL THEN
    v_user_id := gen_random_uuid();
    
    -- Dynamically resolve instance_id from current Supabase instance
    SELECT instance_id INTO v_instance_id FROM auth.users WHERE instance_id IS NOT NULL LIMIT 1;
    IF v_instance_id IS NULL THEN
      v_instance_id := '00000000-0000-00-00-00-000000000000'::uuid;
    END IF;
    
    INSERT INTO auth.users (
      id,
      instance_id,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      role,
      aud,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) VALUES (
      v_user_id,
      v_instance_id,
      lower(trim(p_email)),
      extensions.crypt(p_password, extensions.gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('full_name', p_full_name, 'phone', p_phone),
      now(),
      now(),
      'authenticated',
      'authenticated',
      '',
      '',
      '',
      ''
    );

    -- Insert corresponding identity record so Supabase GoTrue can authenticate user
    INSERT INTO auth.identities (
      id,
      user_id,
      identity_data,
      provider,
      provider_id,
      last_sign_in_at,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_user_id,
      jsonb_build_object('sub', v_user_id::text, 'email', lower(trim(p_email))),
      'email',
      v_user_id::text,
      now(),
      now(),
      now()
    );
  ELSE
    -- If user already exists, update their password if provided
    IF p_password IS NOT NULL AND length(p_password) >= 6 THEN
      UPDATE auth.users
      SET encrypted_password = extensions.crypt(p_password, extensions.gen_salt('bf')),
          confirmation_token = COALESCE(confirmation_token, ''),
          email_change = COALESCE(email_change, ''),
          email_change_token_new = COALESCE(email_change_token_new, ''),
          recovery_token = COALESCE(recovery_token, ''),
          updated_at = now()
      WHERE id = v_user_id;

      -- Ensure identity exists
      INSERT INTO auth.identities (
        id,
        user_id,
        identity_data,
        provider,
        provider_id,
        last_sign_in_at,
        created_at,
        updated_at
      )
      SELECT 
        gen_random_uuid(),
        v_user_id,
        jsonb_build_object('sub', v_user_id::text, 'email', lower(trim(p_email))),
        'email',
        v_user_id::text,
        now(),
        now(),
        now()
      WHERE NOT EXISTS (
        SELECT 1 FROM auth.identities WHERE user_id = v_user_id
      );
    END IF;
  END IF;

  -- 4. Ensure profile exists in public.profiles
  INSERT INTO public.profiles (id, email, full_name, phone)
  VALUES (v_user_id, lower(trim(p_email)), p_full_name, p_phone)
  ON CONFLICT (id) DO UPDATE
  SET full_name = EXCLUDED.full_name,
      phone = COALESCE(EXCLUDED.phone, profiles.phone);

  -- 5. Assign user role
  INSERT INTO public.user_roles (user_id, business_id, branch_id, role, is_active)
  VALUES (v_user_id, p_business_id, p_branch_id, p_role, true)
  ON CONFLICT (user_id, business_id, branch_id) DO UPDATE
  SET role = EXCLUDED.role,
      is_active = true;

  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
