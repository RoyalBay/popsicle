#!/usr/bin/env node
// ============================================================
// sync-products.js
// Run: node sync-products.js
// Reads products.txt and upserts into your Supabase products table.
// ============================================================

const fs = require('fs');
const https = require('https');

// ---- CONFIG ----
const SUPABASE_URL = 'https://plrhgzsjbvpygjjysxot.supabase.co';      // e.g. https://xyz.supabase.co
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBscmhnenNqYnZweWdqanlzeG90Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NjY0MDAsImV4cCI6MjA5MzI0MjQwMH0.V_t1Dq-ap69n5IscjFauyMzT3-x-I46UpZP_mXTL9PY'; // Use service_role key for upsert
// ----------------

const raw = fs.readFileSync('products.txt', 'utf8');
const lines = raw.split('\n');
const products = [];

for (const line of lines) {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith('#')) continue;
  const parts = trimmed.split(',').map(s => s.trim());
  if (parts.length < 3) { console.warn('Skipping malformed line:', line); continue; }
  const [name, priceStr, id] = parts;
  const price = parseFloat(priceStr);
  if (!name || isNaN(price) || !id) { console.warn('Skipping invalid line:', line); continue; }
  products.push({ id, name, price });
}

if (!products.length) { console.log('No valid products found in products.txt'); process.exit(0); }

console.log(`Syncing ${products.length} product(s)...`);
products.forEach(p => console.log(`  ${p.id} | ${p.name} | $${p.price.toFixed(2)}`));

const body = JSON.stringify(products);
const url = new URL(`${SUPABASE_URL}/rest/v1/products`);

const opts = {
  hostname: url.hostname,
  path: url.pathname + '?on_conflict=id',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(body),
    'apikey': SUPABASE_SERVICE_KEY,
    'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
    'Prefer': 'resolution=merge-duplicates',
  },
};

const req = https.request(opts, res => {
  let data = '';
  res.on('data', d => data += d);
  res.on('end', () => {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      console.log(`\n✓ Synced successfully (HTTP ${res.statusCode})`);
    } else {
      console.error(`\n✗ Error (HTTP ${res.statusCode}):`, data);
    }
  });
});
req.on('error', e => console.error('Request error:', e));
req.write(body);
req.end();
