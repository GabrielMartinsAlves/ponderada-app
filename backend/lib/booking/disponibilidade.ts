import { createServiceClient } from '@/lib/supabase/service';
import { BUSINESS, ocupaSlot, hhmmToMin, minToHHMM, weekdayOf, nowSaoPaulo } from '@/lib/booking/config';
import { ehFeriado } from '@/lib/booking/holidays';

export type Slot = { hora: string; disponivel: boolean };
export type Disponibilidade =
  | { data: string; aberto: false; motivo: string; slots: [] }
  | { data: string; aberto: true; duracao_minutos: number; slots: Slot[] };

// Núcleo da disponibilidade: horário comercial − slots ocupados (sobreposição)
// − feriados/dia fechado/data passada. Compartilhado entre a rota pública
// /disponibilidade e o endpoint de IA /interpretar, para haver UMA fonte de verdade.
// Assume `data` já validada como YYYY-MM-DD e `profissional` não vazio.
export async function calcularDisponibilidade(params: {
  data: string;
  profissional: string;
  unidadeId?: string;
  servico?: string;
}): Promise<Disponibilidade> {
  const { data, profissional, unidadeId, servico } = params;

  const { dateStr: hoje, minutes: agoraMin } = nowSaoPaulo();
  if (data < hoje) return { data, aberto: false, motivo: 'Data no passado', slots: [] };
  if (!BUSINESS.openDays.includes(weekdayOf(data)))
    return { data, aberto: false, motivo: 'Salão fechado neste dia da semana', slots: [] };
  if (await ehFeriado(data)) return { data, aberto: false, motivo: 'Feriado nacional', slots: [] };

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

  const slots: Slot[] = [];
  for (let start = BUSINESS.openMin; start + dur <= BUSINESS.closeMin; start += BUSINESS.slotMin) {
    const end = start + dur;
    const futuro = data > hoje || start >= agoraMin; // hoje: só horários ainda por vir
    const livre = !intervalos.some(([s, e]) => start < e && s < end);
    slots.push({ hora: minToHHMM(start), disponivel: futuro && livre });
  }

  return { data, aberto: true, duracao_minutos: dur, slots };
}
