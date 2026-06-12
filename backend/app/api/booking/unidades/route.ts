import { NextRequest, NextResponse } from 'next/server';
import { getBookingUser, createServiceClient } from '@/lib/supabase/service';
import { UNIDADE_GEO } from '@/lib/booking/config';
import { jsonError } from '@/lib/booking/http';

// GET /api/booking/unidades — id+nome do banco enriquecidos com coords estáticas.
export async function GET(req: NextRequest) {
  const user = await getBookingUser(req);
  if (!user) return jsonError('Não autenticado', 401);
  try {
    const supabase = createServiceClient();
    const { data, error } = await supabase.from('unidades').select('id, nome').order('nome', { ascending: true });
    if (error) throw error;
    const unidades = (data ?? []).map((u) => {
      const geo = UNIDADE_GEO[u.nome as string] ?? null;
      return {
        id: u.id,
        nome: u.nome,
        endereco: geo?.endereco ?? null,
        lat: geo?.lat ?? null,
        lng: geo?.lng ?? null,
      };
    });
    return NextResponse.json({ unidades });
  } catch (e) {
    console.error('[unidades]', (e as Error).message);
    return jsonError('Erro ao carregar unidades', 500);
  }
}
