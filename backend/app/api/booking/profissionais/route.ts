import { NextRequest, NextResponse } from 'next/server';
import { getBookingUser, createServiceClient } from '@/lib/supabase/service';
import { jsonError } from '@/lib/booking/http';

// GET /api/booking/profissionais?unidade_id=&servico= — DISTINCT profissional.
export async function GET(req: NextRequest) {
  const user = await getBookingUser(req);
  if (!user) return jsonError('Não autenticado', 401);
  try {
    const { searchParams } = new URL(req.url);
    const unidadeId = (searchParams.get('unidade_id') ?? '').trim();
    const servico = (searchParams.get('servico') ?? '').trim();

    const supabase = createServiceClient();
    let q = supabase.from('booking_profissionais').select('profissional, unidade_id, servico');
    if (unidadeId) q = q.eq('unidade_id', unidadeId);
    if (servico) q = q.eq('servico', servico);
    const { data, error } = await q;
    if (error) throw error;

    const nomes = Array.from(new Set((data ?? []).map((r) => r.profissional as string).filter(Boolean)))
      .sort((a, b) => a.localeCompare(b, 'pt-BR'));
    return NextResponse.json({ profissionais: nomes.map((p) => ({ profissional: p })) });
  } catch (e) {
    console.error('[profissionais]', (e as Error).message);
    return jsonError('Erro ao carregar profissionais', 500);
  }
}
