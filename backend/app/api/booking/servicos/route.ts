import { NextRequest, NextResponse } from 'next/server';
import { getBookingUser, createServiceClient } from '@/lib/supabase/service';
import { jsonError } from '@/lib/booking/http';

// GET /api/booking/servicos — catálogo de serviços (DISTINCT servico via view).
export async function GET(req: NextRequest) {
  const user = await getBookingUser(req);
  if (!user) return jsonError('Não autenticado', 401);
  try {
    const supabase = createServiceClient();
    const { data, error } = await supabase
      .from('booking_servicos')
      .select('servico, duracao_minutos, valor, total')
      .order('total', { ascending: false });
    if (error) throw error;
    return NextResponse.json({ servicos: data ?? [] });
  } catch (e) {
    console.error('[servicos]', (e as Error).message);
    return jsonError('Erro ao carregar serviços', 500);
  }
}
