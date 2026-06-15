import { NextRequest, NextResponse } from 'next/server';
import { getBookingUser, createServiceClient } from '@/lib/supabase/service';
import { jsonError } from '@/lib/booking/http';

// PATCH /api/booking/agendamentos/:id/cancelar — só o dono (email exato) cancela.
export async function PATCH(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const user = await getBookingUser(req);
  if (!user) return jsonError('Não autenticado', 401);
  try {
    const { id } = await params;
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id))
      return jsonError('ID inválido', 422);

    const supabase = createServiceClient();
    const { data: existing, error: e1 } = await supabase
      .from('agendamentos').select('id, email, status').eq('id', id).maybeSingle();
    if (e1) throw e1;
    if (!existing) return jsonError('Agendamento não encontrado', 404);
    if ((existing.email as string ?? '').toLowerCase() !== user.email) return jsonError('Sem permissão', 403);
    if (existing.status === 'Cancelado') return jsonError('Agendamento já cancelado', 409);

    const { data, error } = await supabase
      .from('agendamentos').update({ status: 'Cancelado' })
      .eq('id', id).eq('email', user.email).select().maybeSingle();
    if (error) throw error;
    return NextResponse.json({ agendamento: data });
  } catch (e) {
    console.error('[cancelar]', (e as Error).message);
    return jsonError('Erro ao cancelar agendamento', 500);
  }
}
