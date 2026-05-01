-- ============================================================
-- POPSICLE PROPAGANDA — Supabase SQL Setup
-- Run this in the Supabase SQL editor
-- ============================================================

-- PRODUCTS table (populated from products.txt via app)
CREATE TABLE IF NOT EXISTS products (
  id TEXT PRIMARY KEY,           -- e.g. PP001
  name TEXT NOT NULL,
  price NUMERIC(10, 2) NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- LOYALTY MEMBERS
CREATE TABLE IF NOT EXISTS loyalty_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name TEXT NOT NULL,
  pin_hash TEXT NOT NULL,         -- Store hashed 4-digit PIN
  points INTEGER DEFAULT 0,
  total_spent NUMERIC(10, 2) DEFAULT 0,
  tier TEXT DEFAULT 'Rookie',     -- Rookie / Regular / VIP
  joined_at TIMESTAMPTZ DEFAULT NOW()
);

-- PROMOTIONS (managed in Supabase)
CREATE TABLE IF NOT EXISTS promotions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  description TEXT,
  discount_type TEXT NOT NULL CHECK (discount_type IN ('percent', 'fixed')),
  discount_value NUMERIC(10, 2) NOT NULL,
  min_purchase NUMERIC(10, 2) DEFAULT 0,
  active BOOLEAN DEFAULT TRUE,
  uses_remaining INTEGER DEFAULT NULL,  -- NULL = unlimited
  expires_at TIMESTAMPTZ DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- SALES
CREATE TABLE IF NOT EXISTS sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_number SERIAL,            -- auto-incrementing friendly number
  items JSONB NOT NULL,          -- [{prod_id, name, price, qty}]
  subtotal NUMERIC(10, 2) NOT NULL,
  tax_breakdown JSONB,           -- {gst: x, pst: x, total_tax: x}
  promo_code TEXT REFERENCES promotions(code) ON DELETE SET NULL,
  discount_amount NUMERIC(10, 2) DEFAULT 0,
  total NUMERIC(10, 2) NOT NULL,
  loyalty_member_id UUID REFERENCES loyalty_members(id) ON DELETE SET NULL,
  points_earned INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add serial sale_number via sequence
CREATE SEQUENCE IF NOT EXISTS sale_number_seq START 1000;
ALTER TABLE sales ALTER COLUMN sale_number SET DEFAULT nextval('sale_number_seq');

-- LOYALTY TRANSACTIONS (each sale tied to loyalty)
CREATE TABLE IF NOT EXISTS loyalty_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id UUID REFERENCES loyalty_members(id) ON DELETE CASCADE,
  sale_id UUID REFERENCES sales(id) ON DELETE CASCADE,
  points_change INTEGER NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- SEED DATA — Example Promotions
-- ============================================================

INSERT INTO promotions (code, description, discount_type, discount_value, min_purchase, active, uses_remaining)
VALUES
  ('SUMMER10', '10% off your order', 'percent', 10, 0, TRUE, NULL),
  ('WELCOME2', '$2 off first purchase', 'fixed', 2, 5, TRUE, 1),
  ('POPGANG', '15% off $10+ orders', 'percent', 15, 10, TRUE, NULL);

-- ============================================================
-- SEED DATA — Example Products (matches products.txt)
-- ============================================================

INSERT INTO products (id, name, price)
VALUES
  ('PP001', 'Strawberry Cream Pop', 4.50),
  ('PP002', 'Mango Chili Fusion', 5.25)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- HELPER FUNCTION — Update loyalty tier
-- ============================================================

CREATE OR REPLACE FUNCTION update_loyalty_tier()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.total_spent >= 100 THEN
    NEW.tier := 'VIP';
  ELSIF NEW.total_spent >= 40 THEN
    NEW.tier := 'Regular';
  ELSE
    NEW.tier := 'Rookie';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER loyalty_tier_trigger
BEFORE UPDATE ON loyalty_members
FOR EACH ROW EXECUTE FUNCTION update_loyalty_tier();

-- ============================================================
-- VIEW — Sales with loyalty name for dashboard
-- ============================================================

CREATE OR REPLACE VIEW sales_view AS
SELECT
  s.sale_number,
  s.id,
  s.items,
  s.subtotal,
  s.tax_breakdown,
  s.promo_code,
  s.discount_amount,
  s.total,
  s.points_earned,
  s.created_at,
  lm.full_name AS loyalty_name,
  lm.tier AS loyalty_tier
FROM sales s
LEFT JOIN loyalty_members lm ON lm.id = s.loyalty_member_id
ORDER BY s.created_at DESC;
