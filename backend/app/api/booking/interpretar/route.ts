import { NextRequest, NextResponse } from 'next/server';
import { getBookingUser, createServiceClient } from '@/lib/supabase/service';
import { calcularDisponibilidade } from '@/lib/booking/disponibilidade';
import { nowSaoPaulo, hhmmToMin } from '@/lib/booking/config';
import { jsonError, str } from '@/lib/booking/http';
import { aiConfigurado, maxChamadasPorDia } from '@/lib/ai/config';
import { consumirChamada } from '@/lib/ai/rate_limit';
import { extrairIntencao, type Catalogo, type Intencao } from '@/lib/ai/intent';

// Intenção totalmente vazia (todas as decisões caem para o usuário no fluxo manual).
const INTENCAO_VAZIA: Intencao = {
  servico: null,
  profissional: null,
  unidade: null,
  data: null,
  periodo: null,
  hora: null,
};

// Campos do agendamento que ainda faltam a partir da intenção (hora vem da escolha
// de um horário sugerido, então não entra aqui).
function camposFaltantes(i: Intencao): string[] {
  const faltam: string[] = [];
  if (!i.servico) faltam.push('servico');
  if (!i.profissional) faltam.push('profissional');
  if (!i.unidade) faltam.push('unidade');
  if (!i.data) faltam.push('data');
  return faltam;
}

// Resposta de fallback: o app desce para o passo a passo manual sem quebrar.
function fallback(motivo: string, intencao: Intencao = INTENCAO_VAZIA) {
  return NextResponse.json({
    intencao,
    sugestoes_de_horario: [],
    campos_faltantes: camposFaltantes(intencao),
    fallback: true,
    motivo,
  });
}

// Carrega o catálogo real (serviços, profissionais, unidades) para injetar no prompt
// e validar a saída do modelo. O modelo só pode escolher o que existe aqui.
async function carregarCatalogo(): Promise<Catalogo> {
  const supabase = createServiceClient();
  const [sv, pr, un] = await Promise.all([
    supabase.from('booking_servicos').select('servico').order('total', { ascending: false }),
    supabase.from('booking_profissionais').select('profissional'),
    supabase.from('unidades').select('id, nome').order('nome', { ascending: true }),
  ]);
  const servicos = Array.from(
    new Set((sv.data ?? []).map((r) => r.servico as string).filter(Boolean)),
  );
  const profissionais = Array.from(
    new Set((pr.data ?? []).map((r) => r.profissional as string).filter(Boolean)),
  ).sort((a, b) => a.localeCompare(b, 'pt-BR'));
  const unidades = (un.data ?? []).map((u) => ({ id: u.id as string, nome: u.nome as string }));
  return { servicos, profissionais, unidades };
}

// Escolhe a unidade da profissional quando o texto não a menciona. Considera as
// unidades onde ela atende (no serviço pedido, ou no geral). Com mais de uma, desempata
// pela que tem mais horários livres no dia; sem data, fica com a primeira candidata.
async function escolherUnidade(
  profissional: string,
  servico: string | null,
  data: string | null,
): Promise<string | null> {
  const supabase = createServiceClient();
  const distintas = async (comServico: boolean): Promise<string[]> => {
    let q = supabase.from('booking_profissionais').select('unidade_id').eq('profissional', profissional);
    if (comServico && servico) q = q.eq('servico', servico);
    const { data: rows } = await q;
    return Array.from(new Set((rows ?? []).map((r) => r.unidade_id as string).filter(Boolean)));
  };
  let candidatas = await distintas(true);
  if (candidatas.length === 0) candidatas = await distintas(false);
  if (candidatas.length <= 1) return candidatas[0] ?? null;
  if (!data) return candidatas[0];

  let melhor = candidatas[0];
  let melhorVagas = -1;
  for (const u of candidatas) {
    const disp = await calcularDisponibilidade({
      data,
      profissional,
      unidadeId: u,
      servico: servico ?? undefined,
    });
    const vagas = disp.aberto ? disp.slots.filter((s) => s.disponivel).length : 0;
    if (vagas > melhorVagas) {
      melhorVagas = vagas;
      melhor = u;
    }
  }
  return melhor;
}

// Filtra horários livres pelo período pedido (manhã < 12:00 <= tarde) e devolve até 6.
function sugerirHorarios(
  slots: Array<{ hora: string; disponivel: boolean }>,
  periodo: Intencao['periodo'],
): string[] {
  const meioDia = 12 * 60;
  return slots
    .filter((s) => s.disponivel)
    .filter((s) => {
      if (periodo === 'manha') return hhmmToMin(s.hora) < meioDia;
      if (periodo === 'tarde') return hhmmToMin(s.hora) >= meioDia;
      return true;
    })
    .map((s) => s.hora)
    .slice(0, 6);
}

// POST /api/booking/interpretar — agendamento por linguagem natural.
// Autenticado (Bearer). Body: { texto }. Extrai a intenção via LLM (provider-agnóstico),
// valida contra o catálogo real, sugere horários reais e devolve o que falta.
// NUNCA agenda sozinho: o app pré-preenche e o usuário confirma.
export async function POST(req: NextRequest) {
  const user = await getBookingUser(req);
  if (!user) return jsonError('Não autenticado', 401);

  try {
    const body = await req.json().catch(() => null);
    if (!body) return jsonError('JSON inválido', 400);
    const texto = str(body.texto, 500);
    if (!texto) return jsonError('Campo obrigatório: texto', 422);

    // IA não configurada: já devolve fallback (app segue no manual).
    if (!aiConfigurado()) return fallback('IA não configurada');

    // rate limit diário: protege o orçamento da chave compartilhada.
    if (!consumirChamada(maxChamadasPorDia()))
      return jsonError('Limite diário de interpretações atingido. Use o passo a passo.', 429);

    const catalogo = await carregarCatalogo();
    const { dateStr: hoje } = nowSaoPaulo();

    // chamada ao LLM isolada: qualquer falha vira fallback, não 500.
    let intencao: Intencao;
    try {
      intencao = await extrairIntencao(texto, catalogo, hoje);
    } catch (e) {
      console.error('[interpretar] LLM', (e as Error).message);
      return fallback('Não consegui interpretar agora');
    }

    // Se a profissional veio mas a unidade não, escolhemos a unidade dela (e é isso que
    // permite carregar a lista de profissionais e deixar tudo pré-selecionado no app).
    if (!intencao.unidade && intencao.profissional)
      intencao.unidade = await escolherUnidade(intencao.profissional, intencao.servico, intencao.data);

    // sugestões só quando dá para calcular disponibilidade (serviço + profissional + data).
    let sugestoes: string[] = [];
    let horaSelecionada: string | null = null;
    if (intencao.servico && intencao.profissional && intencao.data) {
      const disp = await calcularDisponibilidade({
        data: intencao.data,
        profissional: intencao.profissional,
        unidadeId: intencao.unidade ?? undefined,
        servico: intencao.servico,
      });
      if (disp.aberto) {
        const livres = new Set(disp.slots.filter((s) => s.disponivel).map((s) => s.hora));
        // horário específico pedido e disponível: já vem selecionado no app.
        if (intencao.hora && livres.has(intencao.hora)) horaSelecionada = intencao.hora;
        // período das sugestões: do horário pedido, ou do período dito, ou manhã por padrão.
        const periodoSug = intencao.hora
          ? hhmmToMin(intencao.hora) < 12 * 60 ? 'manha' : 'tarde'
          : intencao.periodo ?? 'manha';
        sugestoes = sugerirHorarios(disp.slots, periodoSug);
      }
    }

    return NextResponse.json({
      intencao,
      sugestoes_de_horario: sugestoes,
      hora_selecionada: horaSelecionada,
      campos_faltantes: camposFaltantes(intencao),
    });
  } catch (e) {
    console.error('[interpretar]', (e as Error).message);
    return jsonError('Erro ao interpretar o pedido', 500);
  }
}
