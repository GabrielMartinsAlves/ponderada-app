import { NextRequest, NextResponse } from 'next/server';
import { feriadosDoAno } from '@/lib/booking/holidays';
import { jsonError } from '@/lib/booking/http';

// GET /api/booking/feriados?ano=YYYY — feriados nacionais do ano.
// Consome a BrasilAPI com cache em memória + fail-safe (lib/booking/holidays).
// Público (dado não específico de usuário).
export async function GET(req: NextRequest) {
  try {
    const raw = parseInt(new URL(req.url).searchParams.get('ano') ?? '', 10);
    const ano = Number.isFinite(raw) ? raw : new Date().getFullYear();
    const set = await feriadosDoAno(ano);
    return NextResponse.json({ ano, feriados: Array.from(set) });
  } catch (e) {
    console.error('[feriados]', (e as Error).message);
    return jsonError('Erro ao carregar feriados', 500);
  }
}
