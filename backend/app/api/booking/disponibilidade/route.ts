import { NextRequest, NextResponse } from 'next/server';
import { calcularDisponibilidade } from '@/lib/booking/disponibilidade';
import { jsonError, isYMD } from '@/lib/booking/http';

// GET /api/booking/disponibilidade?data=&profissional=&unidade_id=&servico=
// Horário comercial − slots ocupados (sobreposição) − feriados/dia fechado.
// Disponibilidade é dado público do salão (não específico de usuário) — sem auth.
// A lógica vive em lib/booking/disponibilidade.ts (reusada pelo endpoint de IA).
export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const data = (searchParams.get('data') ?? '').trim();
    const profissional = (searchParams.get('profissional') ?? '').trim();
    const unidadeId = (searchParams.get('unidade_id') ?? '').trim();
    const servico = (searchParams.get('servico') ?? '').trim();

    if (!isYMD(data)) return jsonError('Parâmetro "data" inválido (use YYYY-MM-DD)', 422);
    if (!profissional) return jsonError('Parâmetro "profissional" é obrigatório', 422);

    const resultado = await calcularDisponibilidade({ data, profissional, unidadeId, servico });
    return NextResponse.json(resultado);
  } catch (e) {
    console.error('[disponibilidade]', (e as Error).message);
    return jsonError('Erro ao calcular disponibilidade', 500);
  }
}
