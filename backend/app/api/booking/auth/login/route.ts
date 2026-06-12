import { NextRequest, NextResponse } from 'next/server';
import { createAuthClient } from '@/lib/supabase/service';
import { jsonError, str, isEmail } from '@/lib/booking/http';

// POST /api/booking/auth/login — login server-side; devolve access/refresh token.
export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => null);
    if (!body) return jsonError('JSON inválido', 400);
    const email = str(body.email, 254).toLowerCase();
    const senha = typeof body.senha === 'string' ? body.senha : '';
    if (!isEmail(email) || !senha) return jsonError('Informe email e senha', 422);

    const auth = createAuthClient();
    const { data, error } = await auth.auth.signInWithPassword({ email, password: senha });
    if (error || !data.session) return jsonError('Credenciais inválidas', 401);

    const u = data.user;
    const m = (u?.user_metadata ?? {}) as Record<string, unknown>;
    return NextResponse.json({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      user: { email: u?.email ?? email, nome: (m.nome as string) ?? '', telefone: (m.telefone as string) ?? '' },
    });
  } catch (e) {
    console.error('[login]', (e as Error).message);
    return jsonError('Erro ao entrar', 500);
  }
}
