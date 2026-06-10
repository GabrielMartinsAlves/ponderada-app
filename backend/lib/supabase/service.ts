import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { type NextRequest } from 'next/server';

// ---- env helpers -----------------------------------------------------------
function url(): string {
  const u = process.env.NEXT_PUBLIC_SUPABASE_URL;
  if (!u) throw new Error('NEXT_PUBLIC_SUPABASE_URL ausente');
  return u;
}
function anonKey(): string {
  const k = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!k) throw new Error('NEXT_PUBLIC_SUPABASE_ANON_KEY ausente');
  return k;
}
function serviceKey(): string {
  const k = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!k) throw new Error('SUPABASE_SERVICE_ROLE_KEY ausente');
  return k;
}

// ---- clients ---------------------------------------------------------------
// Cliente SERVICE ROLE (server-only). Ignora RLS — usado por /api/booking/*
// APÓS validar a sessão do usuário. NUNCA importar em código client-side.
let _service: SupabaseClient | null = null;
export function createServiceClient(): SupabaseClient {
  if (!_service) {
    _service = createClient(url(), serviceKey(), {
      auth: { autoRefreshToken: false, persistSession: false },
    });
  }
  return _service;
}

// Cliente anônimo (server-side) só para operações de auth (login/refresh).
export function createAuthClient(): SupabaseClient {
  return createClient(url(), anonKey(), {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

// ---- sessão do cliente mobile (Bearer) -------------------------------------
export type BookingUser = {
  id: string;
  email: string;
  nome: string;
  telefone: string;
};

// Valida o Authorization: Bearer <jwt> e retorna o usuário autenticado.
export async function getBookingUser(req: NextRequest): Promise<BookingUser | null> {
  const header = req.headers.get('authorization') ?? '';
  const token = header.toLowerCase().startsWith('bearer ') ? header.slice(7).trim() : '';
  if (!token) return null;

  const supabase = createClient(url(), anonKey(), {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) return null;

  const u = data.user;
  const meta = (u.user_metadata ?? {}) as Record<string, unknown>;
  return {
    id: u.id,
    email: (u.email ?? '').toLowerCase().trim(),
    nome: typeof meta.nome === 'string' ? meta.nome : '',
    telefone: typeof meta.telefone === 'string' ? meta.telefone : '',
  };
}
