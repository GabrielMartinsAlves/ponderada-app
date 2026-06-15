import { NextRequest, NextResponse } from 'next/server';
import { getBookingUser, createServiceClient } from '@/lib/supabase/service';
import { jsonError, str } from '@/lib/booking/http';

// GET /api/booking/perfil — dados do usuário logado.
export async function GET(req: NextRequest) {
  const user = await getBookingUser(req);
  if (!user) return jsonError('Não autenticado', 401);
  return NextResponse.json({ perfil: { email: user.email, nome: user.nome, telefone: user.telefone } });
}

// PATCH /api/booking/perfil — atualiza nome/telefone (user_metadata) via service role.
export async function PATCH(req: NextRequest) {
  const user = await getBookingUser(req);
  if (!user) return jsonError('Não autenticado', 401);
  try {
    const body = await req.json().catch(() => null);
    if (!body) return jsonError('JSON inválido', 400);
    const nome = str(body.nome, 200);
    const telefone = str(body.telefone, 30);

    const meta: Record<string, string> = { nome: nome || user.nome, telefone: telefone || user.telefone };
    const supabase = createServiceClient();
    const { data, error } = await supabase.auth.admin.updateUserById(user.id, { user_metadata: meta });
    if (error) throw error;

    const m = (data.user?.user_metadata ?? {}) as Record<string, unknown>;
    return NextResponse.json({
      perfil: { email: user.email, nome: (m.nome as string) ?? '', telefone: (m.telefone as string) ?? '' },
    });
  } catch (e) {
    console.error('[perfil PATCH]', (e as Error).message);
    return jsonError('Erro ao atualizar perfil', 500);
  }
}
