import { NextRequest, NextResponse } from 'next/server';
import { getBookingUser, createServiceClient } from '@/lib/supabase/service';
import { BUSINESS, weekdayOf, nowSaoPaulo } from '@/lib/booking/config';
import { ehFeriado } from '@/lib/booking/holidays';
import { jsonError, isYMD, isHHMM, str } from '@/lib/booking/http';

// POST /api/booking/agendamentos — cria via RPC fn_criar_agendamento (advisory lock).
export async function POST(req: NextRequest) {
  const user = await getBookingUser(req);
  if (!user) return jsonError('Não autenticado', 401);
  try {
    const body = await req.json().catch(() => null);
    if (!body) return jsonError('JSON inválido', 400);

    const servico = str(body.servico, 200);
    const profissional = str(body.profissional, 150);
    const unidadeId = str(body.unidade_id, 64) || null;
    const data = str(body.data, 10);
    const hora = str(body.hora, 10);
    const observacoes = str(body.observacoes, 1000);

    if (!servico || !profissional || !isYMD(data) || !isHHMM(hora))
      return jsonError('Campos obrigatórios: servico, profissional, data (YYYY-MM-DD), hora (HH:MM)', 422);

    const { dateStr: hoje } = nowSaoPaulo();
    if (data < hoje) return jsonError('Não é possível agendar em data passada', 422);
    if (!BUSINESS.openDays.includes(weekdayOf(data))) return jsonError('Salão fechado neste dia da semana', 422);
    if (await ehFeriado(data)) return jsonError('Feriado nacional — salão fechado', 422);

    const supabase = createServiceClient();

    // deriva duração/valor do catálogo (nunca do input do cliente)
    const { data: sv } = await supabase
      .from('booking_servicos').select('duracao_minutos, valor').eq('servico', servico).maybeSingle();
    const duracao = (sv?.duracao_minutos as number) ?? BUSINESS.slotMin;
    const valor = (sv?.valor as number) ?? 0;

    const { data: rpc, error } = await supabase.rpc('fn_criar_agendamento', {
      p_unidade_id: unidadeId,
      p_data: data,
      p_hora: hora,
      p_profissional: profissional,
      p_servico: servico,
      p_duracao: duracao,
      p_valor: valor,
      p_cliente: user.nome || user.email,
      p_telefone: user.telefone,
      p_email: user.email,
      p_obs: observacoes,
    });

    if (error) {
      const msg = error.message ?? '';
      // distingue SLOT_TAKEN (corrida) de outros 23505 (unique de deduplicação)
      if (msg.includes('SLOT_TAKEN')) return jsonError('Horário já reservado', 409);
      if (error.code === '23505') return jsonError('Conflito de registro (duplicado)', 422);
      console.error('[agendamentos POST]', error.code, msg);
      return jsonError('Erro ao criar agendamento', 500);
    }

    const agendamento = Array.isArray(rpc) ? rpc[0] : rpc;
    return NextResponse.json({ agendamento }, { status: 201 });
  } catch (e) {
    console.error('[agendamentos POST]', (e as Error).message);
    return jsonError('Erro ao criar agendamento', 500);
  }
}

// GET /api/booking/agendamentos?escopo=futuros|passados — só do usuário (email exato).
export async function GET(req: NextRequest) {
  const user = await getBookingUser(req);
  if (!user) return jsonError('Não autenticado', 401);
  try {
    const { searchParams } = new URL(req.url);
    const escopo = (searchParams.get('escopo') ?? '').trim();
    const { dateStr: hoje } = nowSaoPaulo();

    const supabase = createServiceClient();
    let q = supabase
      .from('agendamentos')
      .select('id, data_agendamento, hora, profissional, servico, duracao_minutos, valor, status, unidade_id, observacoes')
      .eq('email', user.email); // match ESTRITO por email exato (sem OR telefone)
    if (escopo === 'futuros') q = q.gte('data_agendamento', hoje);
    else if (escopo === 'passados') q = q.lt('data_agendamento', hoje);
    q = q.order('data_agendamento', { ascending: false }).order('hora', { ascending: true });

    const { data, error } = await q;
    if (error) throw error;
    return NextResponse.json({ agendamentos: data ?? [] });
  } catch (e) {
    console.error('[agendamentos GET]', (e as Error).message);
    return jsonError('Erro ao carregar agendamentos', 500);
  }
}
