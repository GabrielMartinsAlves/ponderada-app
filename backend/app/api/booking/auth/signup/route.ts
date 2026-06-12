import { NextRequest, NextResponse } from 'next/server';
import { createServiceClient, createAuthClient } from '@/lib/supabase/service';
import { jsonError, str, isEmail } from '@/lib/booking/http';

// POST /api/booking/auth/signup — cria usuário via Admin API (service role) e
// já devolve tokens. O app nunca fala direto com o Supabase.
export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => null);
    if (!body) return jsonError('JSON inválido', 400);

    const nome = str(body.nome, 200);
    const email = str(body.email, 254).toLowerCase();
    const telefone = str(body.telefone, 30);
    const senha = typeof body.senha === 'string' ? body.senha : '';
    if (!nome || !isEmail(email) || senha.length < 6)
      return jsonError('Informe nome, email válido e senha (mín. 6 caracteres)', 422);

    const admin = createServiceClient();
    const { error: e1 } = await admin.auth.admin.createUser({
      email,
      password: senha,
      email_confirm: true,
      user_metadata: { nome, telefone },
    });
    if (e1) {
      const m = (e1.message ?? '').toLowerCase();
      if (m.includes('already') || m.includes('registered') || m.includes('exist'))
        return jsonError('E-mail já cadastrado', 409);
      console.error('[signup]', e1.message);
      return jsonError('Erro ao cadastrar', 500);
    }

    // login imediato para devolver tokens
    const auth = createAuthClient();
    const { data: sess, error: e2 } = await auth.auth.signInWithPassword({ email, password: senha });
    if (e2 || !sess.session) {
      return NextResponse.json(
        { user: { email, nome, telefone }, message: 'Cadastro criado. Faça login.' },
        { status: 201 },
      );
    }
    return NextResponse.json(
      {
        access_token: sess.session.access_token,
        refresh_token: sess.session.refresh_token,
        user: { email, nome, telefone },
      },
      { status: 201 },
    );
  } catch (e) {
    console.error('[signup]', (e as Error).message);
    return jsonError('Erro ao cadastrar', 500);
  }
}
