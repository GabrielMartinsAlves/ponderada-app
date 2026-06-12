import { NextRequest, NextResponse } from 'next/server';
import { createAuthClient } from '@/lib/supabase/service';
import { jsonError } from '@/lib/booking/http';

// POST /api/booking/auth/refresh — renova a sessão a partir do refresh_token.
export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => null);
    const refresh_token = body && typeof body.refresh_token === 'string' ? body.refresh_token : '';
    if (!refresh_token) return jsonError('refresh_token é obrigatório', 422);

    const auth = createAuthClient();
    const { data, error } = await auth.auth.refreshSession({ refresh_token });
    if (error || !data.session) return jsonError('Sessão inválida', 401);

    return NextResponse.json({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
    });
  } catch (e) {
    console.error('[refresh]', (e as Error).message);
    return jsonError('Erro ao renovar sessão', 500);
  }
}
