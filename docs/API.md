# API.md — Afri_BMS API Contracts & Edge Functions

> Defines all Supabase Edge Functions, API contracts, and webhook specifications.

---

## 1. Supabase Edge Functions

### 1.1 `create-staff-account`

Creates a new user account and assigns a role (admin-only action).

**Method**: POST  
**Auth**: Required (admin JWT)

```typescript
// Request
{
  "email": "staff@example.com",
  "password": "TempPassword123!",  // optional — auto-generated if omitted
  "full_name": "John Doe",
  "phone": "+2348012345678",
  "business_id": "uuid",
  "branch_id": "uuid",           // optional — null = all branches
  "role": "salesperson",          // admin | branch_manager | salesperson | cashier | custom
  "custom_permissions": {}        // only if role = "custom"
}

// Response — 201
{
  "user_id": "uuid",
  "email": "staff@example.com",
  "role": "salesperson",
  "temp_password": "auto-generated-password",  // returned so admin can share with staff
  "message": "Staff account created successfully"
}

// Error — 400/403/500
{
  "error": "Insufficient permissions",
  "code": "FORBIDDEN"
}
```

### 1.2 `send-receipt-sms`

Sends a compact SMS receipt to a customer's phone.

**Method**: POST  
**Auth**: Required

```typescript
// Request
{
  "sale_id": "uuid",
  "phone_number": "+2348012345678",
  "business_name": "Ade's Store",
  "receipt_number": "INV-2026-0042",
  "total_amount": 1668938,         // minor units
  "currency": "NGN",
  "items_count": 3
}

// Response — 200
{
  "message_id": "sms-uuid",
  "status": "sent",
  "provider": "africas_talking"
}
```

### 1.3 `process-payment`

Initiates a Paystack mobile money / card payment.

**Method**: POST  
**Auth**: Required

```typescript
// Request
{
  "sale_id": "uuid",
  "amount": 1668938,
  "currency": "NGN",
  "payment_method": "mobile_money",
  "provider": "mtn",              // mtn | vodafone | airtel
  "phone_number": "+2348012345678",
  "customer_email": "customer@example.com",
  "business_name": "Ade's Store",
  "tx_ref": "AFRI-1696800000000"
}

// Response — 200
{
  "transaction_id": "PAYSTACK-uuid",
  "status": "pending",
  "access_code": "code_xyz123",
  "payment_link": "https://checkout.paystack.com/...",
  "message": "Payment initiated."
}
```

### 1.4 `verify-payment`

Verifies payment status from Paystack.

**Method**: POST  
**Auth**: Required

```typescript
// Request
{
  "reference": "AFRI-1696800000000"
}

// Response — 200
{
  "status": "successful",        // successful | failed | pending
  "amount": 1668938,
  "currency": "NGN",
  "payment_method": "mobile_money",
  "provider": "mtn",
  "transaction_reference": "PAYSTACK-ref-123"
}
```

### 1.5 `sync-batch`

Processes a batch of offline-created records.

**Method**: POST  
**Auth**: Required

```typescript
// Request
{
  "business_id": "uuid",
  "operations": [
    {
      "table": "products",
      "operation": "insert",
      "record_id": "local-uuid-1",
      "data": { /* product fields */ },
      "local_timestamp": "2026-10-09T12:00:00Z"
    },
    {
      "table": "sales",
      "operation": "insert",
      "record_id": "local-uuid-2",
      "data": { /* sale fields */ },
      "local_timestamp": "2026-10-09T12:01:00Z"
    },
    {
      "table": "stock",
      "operation": "update",
      "record_id": "existing-uuid-3",
      "data": { "quantity": 45 },
      "local_timestamp": "2026-10-09T12:01:00Z"
    }
  ]
}

// Response — 200
{
  "processed": 3,
  "succeeded": 2,
  "failed": 1,
  "results": [
    { "record_id": "local-uuid-1", "status": "success", "server_id": "server-uuid-1" },
    { "record_id": "local-uuid-2", "status": "success", "server_id": "server-uuid-2" },
    { "record_id": "existing-uuid-3", "status": "conflict", "resolution": "server_wins", "server_data": {...} }
  ],
  "server_timestamp": "2026-10-09T12:05:00Z"
}
```

### 1.6 `generate-report`

Generates complex reports server-side (for large datasets).

**Method**: POST  
**Auth**: Required (admin / branch_manager)

```typescript
// Request
{
  "business_id": "uuid",
  "branch_id": "uuid",          // optional — null = all branches
  "report_type": "profit_loss", // sales_summary | profit_loss | inventory_valuation | aging
  "date_from": "2026-10-01",
  "date_to": "2026-10-09",
  "currency": "NGN",
  "format": "json"              // json | csv | pdf
}

// Response — 200
{
  "report_type": "profit_loss",
  "period": "2026-10-01 to 2026-10-09",
  "data": {
    "total_revenue": 12500000,
    "cost_of_goods": 7500000,
    "gross_profit": 5000000,
    "total_expenses": 2000000,
    "net_profit": 3000000,
    "margin_percentage": 24.0,
    "breakdown": {
      "revenue_by_category": [...],
      "expenses_by_category": [...],
      "daily_breakdown": [...]
    }
  },
  "generated_at": "2026-10-09T12:10:00Z"
}
```

### 1.7 `check-subscription`

Validates and returns current subscription tier.

**Method**: GET  
**Auth**: Required

```typescript
// Response — 200
{
  "business_id": "uuid",
  "tier": "pro",
  "status": "active",
  "expires_at": "2026-11-09T00:00:00Z",
  "limits": {
    "max_products": 1000,
    "max_transactions": 5000,
    "max_staff": 10,
    "max_branches": 5
  },
  "usage": {
    "products": 247,
    "transactions_this_month": 1523,
    "staff": 4,
    "branches": 2
  }
}
```

---

## 2. Webhook Endpoints

### 2.1 Paystack Payment Webhook

**URL**: `https://<project>.supabase.co/functions/v1/payment-webhook`  
**Method**: POST  
**Auth**: Paystack signature verification

```typescript
// Incoming payload (from Paystack)
{
  "event": "charge.success",
  "data": {
    "id": 123456,
    "reference": "AFRI-1696800000000",
    "amount": 1668938,
    "currency": "NGN",
    "status": "success",
    "channel": "mobile_money",
    "customer": {
      "email": "customer@example.com",
      "phone": "08012345678"
    }
  }
}

// Action
// 1. Verify signature with Paystack secret
// 2. Look up sale by reference
// 3. Update payment status
// 4. Notify client via Supabase Realtime
```

---

## 3. Supabase Database Functions (SQL)

### 3.1 Auto-generate Sale Number

```sql
CREATE OR REPLACE FUNCTION generate_sale_number(p_business_id UUID)
RETURNS TEXT AS $$
DECLARE
  v_count INT;
  v_year TEXT;
BEGIN
  v_year := to_char(now(), 'YYYY');

  SELECT COUNT(*) + 1 INTO v_count
  FROM sales
  WHERE business_id = p_business_id
    AND date_part('year', created_at) = date_part('year', now());

  RETURN 'INV-' || v_year || '-' || lpad(v_count::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;
```

### 3.2 Update Stock on Sale

```sql
CREATE OR REPLACE FUNCTION update_stock_on_sale()
RETURNS TRIGGER AS $$
BEGIN
  -- Decrement stock
  UPDATE stock
  SET quantity = quantity - NEW.quantity,
      updated_at = now()
  WHERE product_id = NEW.product_id
    AND (variant_id = NEW.variant_id OR (NEW.variant_id IS NULL AND variant_id IS NULL))
    AND branch_id = (SELECT branch_id FROM sales WHERE id = NEW.sale_id);

  -- Log stock movement
  INSERT INTO stock_movements (product_id, variant_id, branch_id, movement_type, quantity, reference_type, reference_id)
  VALUES (
    NEW.product_id,
    NEW.variant_id,
    (SELECT branch_id FROM sales WHERE id = NEW.sale_id),
    'out',
    NEW.quantity,
    'sale',
    NEW.sale_id
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_stock_on_sale_item
AFTER INSERT ON sale_items
FOR EACH ROW EXECUTE FUNCTION update_stock_on_sale();
```

### 3.3 Update Customer Totals

```sql
CREATE OR REPLACE FUNCTION update_customer_totals()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.customer_id IS NOT NULL THEN
    UPDATE customers
    SET total_purchases = (
          SELECT COALESCE(SUM(total_amount), 0)
          FROM sales
          WHERE customer_id = NEW.customer_id AND deleted_at IS NULL
        ),
        total_debt = (
          SELECT COALESCE(SUM(outstanding_amount), 0)
          FROM debts
          WHERE customer_id = NEW.customer_id AND status != 'paid' AND deleted_at IS NULL
        ),
        updated_at = now()
    WHERE id = NEW.customer_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 3.4 Auto-update Debt Status

```sql
CREATE OR REPLACE FUNCTION check_overdue_debts()
RETURNS void AS $$
BEGIN
  UPDATE debts
  SET status = 'overdue', updated_at = now()
  WHERE status = 'active'
    AND due_date < CURRENT_DATE
    AND deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql;

-- Run daily via pg_cron
SELECT cron.schedule('check-overdue', '0 1 * * *', 'SELECT check_overdue_debts()');
```

---

## 4. Realtime Subscriptions

| Channel | Table | Filter | Purpose |
|---|---|---|---|
| `sales:{business_id}` | `sales` | `business_id=eq.{id}` | Real-time sale notifications to admin dashboard |
| `stock:{branch_id}` | `stock` | `branch_id=eq.{id}` | Low stock alerts |
| `debts:{business_id}` | `debts` | `business_id=eq.{id}` | Debt status changes |
| `user_roles:{user_id}` | `user_roles` | `user_id=eq.{id}` | Role/permission changes (force refresh) |

---

## 5. Error Codes

| Code | HTTP Status | Description |
|---|---|---|
| `AUTH_REQUIRED` | 401 | No valid JWT provided |
| `FORBIDDEN` | 403 | User lacks required role/permission |
| `NOT_FOUND` | 404 | Resource not found |
| `VALIDATION_ERROR` | 400 | Invalid input data |
| `DUPLICATE_ENTRY` | 409 | Unique constraint violation |
| `TIER_LIMIT` | 402 | Subscription tier limit reached |
| `SYNC_CONFLICT` | 409 | Conflicting data during sync |
| `PAYMENT_FAILED` | 402 | Payment processing failed |
| `RATE_LIMITED` | 429 | Too many requests |
| `SERVER_ERROR` | 500 | Internal server error |
