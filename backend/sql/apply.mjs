// Aplica schema.sql + functions.sql + seed.sql no banco novo.
// Requer DATABASE_URL (Session pooler URI do Supabase) em backend/.env.
// Uso: npm run db:apply
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

const dir = path.dirname(fileURLToPath(import.meta.url));

function loadEnv() {
  if (process.env.DATABASE_URL) return process.env.DATABASE_URL;
  try {
    const envText = readFileSync(path.join(dir, '..', '.env'), 'utf8');
    for (const line of envText.split(/\r?\n/)) {
      const m = line.match(/^\s*DATABASE_URL\s*=\s*(.+)\s*$/);
      if (m) return m[1].trim().replace(/^["']|["']$/g, '');
    }
  } catch {}
  return null;
}

const url = loadEnv();
if (!url) {
  console.error('DATABASE_URL ausente. Adicione o Session pooler URI em backend/.env (ou rode os .sql no SQL Editor do Supabase).');
  process.exit(1);
}

const client = new pg.Client({ connectionString: url, ssl: { rejectUnauthorized: false } });
await client.connect();
for (const f of ['schema.sql', 'functions.sql', 'seed.sql']) {
  process.stdout.write(`Aplicando ${f} ... `);
  await client.query(readFileSync(path.join(dir, f), 'utf8'));
  console.log('ok');
}
await client.end();
console.log('Banco novo aplicado com sucesso.');
