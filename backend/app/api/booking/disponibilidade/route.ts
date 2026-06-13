import { NextRequest, NextResponse } from 'next/server';
import { createServiceClient } from '@/lib/supabase/service';
import { BUSINESS, ocupaSlot, hhmmToMin, minToHHMM, weekdayOf, nowSaoPaulo } from '@/lib/booking/config';
import { ehFeriado } from '@/lib/booking/holidays';
import { jsonError, isYMD } from '@/lib/booking/http';

// GET /api/booking/disponibilidade?data=&profissional=&unidade_id=&servico=
// Horário comercial − slots ocupados (sobreposição) − feriados/dia fechado.
// Disponibilidade é dado público do salão (não específico de usuário) — sem auth.
export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const data = (searchParams.get('data') ?? '').trim();
    const profissional = (searchParams.get('profissional') ?? '').trim();
    const unidadeId = (searchParams.get('unidade_id') ?? '').trim();
    const servico = (searchParams.get('servico') ?? '').trim();

    if (!isYMD(data)) return jsonError('Parâmetro "data" inválido (use YYYY-MM-DD)', 422);
    if (!profissional) return jsonError('Parâmetro "profissional" é obrigatório', 422);

    const { dateStr: hoje, minutes: agoraMin } = nowSaoPaulo();
    if (data < hoje) return NextResponse.json({ data, aberto: false, motivo: 'Data no passado', slots: [] });
    if (!BUSINESS.openDays.includes(weekdayOf(data)))
      return NextResponse.json({ data, aberto: false, motivo: 'Salão fechado neste dia da semana', slots: [] });
    if (await ehFeriado(data))
      return NextResponse.json({ data, aberto: false, motivo: 'Feriado nacional', slots: [] });

    const supabase = createServiceClient();

    // duração do serviço escolhido define o encaixe e a checagem de sobreposição
    let dur = BUSINESS.slotMin;
    if (servico) {
      const { data: sv } = await supabase
        .from('booking_servicos').select('duracao_minutos').eq('servico', servico).maybeSingle();
      if (sv?.duracao_minutos) dur = sv.duracao_minutos as number;
    }

    // intervalos ocupados do profissional no dia
    let oq = supabase.from('agendamentos')
      .select('hora, duracao_minutos, status')
      .eq('data_agendamento', data).eq('profissional', profissional);
    if (unidadeId) oq = oq.eq('unidade_id', unidadeId);
    const { data: ocup, error } = await oq;
    if (error) throw error;

    const intervalos = (ocup ?? [])
      .filter((r) => r.hora && ocupaSlot((r.status as string) ?? ''))
      .map((r) => {
        const s = hhmmToMin(r.hora as string);
        return [s, s + ((r.duracao_minutos as number) ?? 0)] as [number, number];
      });

    const slots: Array<{ hora: string; disponivel: boolean }> = [];
    for (let start = BUSINESS.openMin; start + dur <= BUSINESS.closeMin; start += BUSINESS.slotMin) {
      const end = start + dur;
      const futuro = data > hoje || start >= agoraMin; // hoje: só horários ainda por vir
      const livre = !intervalos.some(([s, e]) => start < e && s < end);
      slots.push({ hora: minToHHMM(start), disponivel: futuro && livre });
    }

    return NextResponse.json({ data, aberto: true, duracao_minutos: dur, slots });
  } catch (e) {
    console.error('[disponibilidade]', (e as Error).message);
    return jsonError('Erro ao calcular disponibilidade', 500);
  }
}
