# 🧊 Popsicle Propaganda — POS & Loyalty System

## Quick Start

### 1. Supabase Setup
1. Create a project at supabase.com
2. Open the SQL editor and run **schema.sql** — this creates all tables, views, and seed promos
3. Copy your **Project URL** and **anon public key** from Settings → API

### 2. Configure index.html
Near the top of the `<script>` tag in `index.html`, replace:
```js
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

### 3. Add Products
Edit `products.txt` — one product per line in the format:
```
Product Name, Price, ProductID
```
Example:
```
Strawberry Cream Pop, 4.50, PP001
Mango Chili Fusion, 5.25, PP002
```

Then sync to Supabase: update `sync-products.js` with your URL + **service_role** key, then run:
```bash
node sync-products.js
```

### 4. Open index.html in your browser
That's it — no build step required. Works offline for the UI, requires internet for Supabase calls.

---

## Features

### 🛒 Sales (press SPACEBAR anywhere)
- Type product IDs to add items (Enter to confirm each)
- Real-time subtotal, GST/PST/MST tax breakdown
- Apply promo codes (pulled live from Supabase)
- Add to Loyalty Program: type name + 4-digit PIN
  - Auto-detects existing members and adds points
  - Creates new member if not found
- Each sale gets an auto-incrementing Sale Number + timestamp

### 💰 Tax Controls (top banner)
Toggle BC taxes on/off in real-time:
- **GST** — 5% (federal)
- **PST** — 7% (provincial)
- **MST** — ~1.5% (municipal, off by default)

### 📦 Products Page
- Live product catalog with ID, name, price
- After-tax price shown dynamically (updates with tax toggles)
- Sync button to reload from Supabase

### 📊 Sales Log
- Full history with sale number, time, items, tax breakdown, discounts
- Search by sale #, product name, promo code, or loyalty member
- Filter by date

### ⭐ Loyalty Program
- Members earn 1 point per $1 spent
- Tiers: **Rookie** (< $40) → **Regular** ($40+) → **VIP** ($100+)
- Tier upgrades happen automatically via Supabase trigger
- Dashboard shows total members, VIPs, points issued, loyalty spend

### 🎟 Promotions
- Managed directly in Supabase (or seeded via schema.sql)
- Supports: percent off, fixed dollar off
- Optional: minimum purchase, expiry date, limited uses
- Promo grid shows all active/inactive codes

---

## Database Tables
| Table | Purpose |
|-------|---------|
| `products` | Your menu — synced from products.txt |
| `sales` | Every transaction with full breakdown |
| `loyalty_members` | Loyalty program members |
| `loyalty_transactions` | Points history per member |
| `promotions` | Promo codes and rules |
| `sales_view` | JOIN of sales + loyalty name for display |

---

## Files
```
index.html          — Main app (open in browser)
schema.sql          — Run once in Supabase SQL editor
sync-products.js    — Sync products.txt → Supabase
products.txt        — Your product catalog
README.md           — This file
```
