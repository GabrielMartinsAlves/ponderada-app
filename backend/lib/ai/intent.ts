import { callLLM, type LlmMessage } from './client';
import { isYMD, isHHMM } from '@/lib/booking/http';

// Período do dia inferido do texto (manhã < 12:00 <= tarde).
export type Periodo = 'manha' | 'tarde';

// Intenção extraída e JÁ VALIDADA: cada campo é um valor do catálogo real ou null.
// `unidade` é sempre o unidade_id (ou null), nunca o nome livre que o modelo cuspiu.
export type Intencao = {
  servico: string | null;
  profissional: string | null;
  unidade: string | null;
  data: string | null; // YYYY-MM-DD
  periodo: Periodo | null;
  hora: string | null; // HH:MM (horário específico pedido)
};

export type Catalogo = {
  servicos: string[];
  profissionais: string[];
  unidades: Array<{ id: string; nome: string }>;
};

// normaliza para comparação tolerante (sem acento, minúsculo, espaços colapsados)
const norm = (s: string): string =>
  (s ?? '')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();

// Monta as mensagens de extração. O catálogo real e a data de hoje (fuso do salão)
// entram no prompt para o modelo resolver datas relativas ("sexta", "amanhã") e
// só escolher valores que existem. Instrução explícita de JSON estrito.
export function montarMensagens(texto: string, catalogo: Catalogo, hoje: string): LlmMessage[] {
  const servicos = catalogo.servicos.join(' | ') || '(nenhum)';
  const profissionais = catalogo.profissionais.join(' | ') || '(nenhum)';
  const unidades = catalogo.unidades.map((u) => u.nome).join(' | ') || '(nenhuma)';

  const system = [
    'Você converte um pedido em português para um agendamento de salão de beleza.',
    'Responda APENAS com um objeto JSON, sem texto antes ou depois, sem markdown.',
    'O JSON tem exatamente estas chaves: servico, profissional, unidade, data, periodo, hora.',
    'Regras:',
    '- servico: copie exatamente um item da lista de serviços, ou null.',
    '- profissional: copie exatamente um nome da lista de profissionais, ou null.',
    '- unidade: copie exatamente um nome da lista de unidades, ou null.',
    '- data: no formato YYYY-MM-DD, resolvendo datas relativas a partir de HOJE; se não der para inferir, null.',
    '- periodo: "manha", "tarde" ou null.',
    '- hora: "HH:MM" em 24h quando a pessoa disser um horário específico (ex.: "às 14h" -> "14:00", "9 e meia" -> "09:30"); senão null.',
    'Nunca invente valores fora das listas. Em dúvida, use null.',
    '',
    `HOJE: ${hoje}`,
    `Serviços: ${servicos}`,
    `Profissionais: ${profissionais}`,
    `Unidades: ${unidades}`,
  ].join('\n');

  return [
    { role: 'system', content: system },
    { role: 'user', content: texto },
  ];
}

// Parse defensivo: remove cercas de código, isola o primeiro bloco { ... } e tenta
// JSON.parse. Qualquer falha vira objeto vazio (o validador devolve tudo null).
export function parseJsonDefensivo(bruto: string): Record<string, unknown> {
  const semCerca = (bruto ?? '').replace(/```(?:json)?/gi, '').trim();
  const ini = semCerca.indexOf('{');
  const fim = semCerca.lastIndexOf('}');
  if (ini === -1 || fim === -1 || fim < ini) return {};
  try {
    const obj = JSON.parse(semCerca.slice(ini, fim + 1));
    return obj && typeof obj === 'object' ? (obj as Record<string, unknown>) : {};
  } catch {
    return {};
  }
}

// Valida o JSON cru contra o catálogo: só passa valor que existe de fato. O modelo
// não é fonte de verdade — aqui é o portão. unidade vira id; data no passado vira null.
export function validarIntencao(
  cru: Record<string, unknown>,
  catalogo: Catalogo,
  hoje: string,
): Intencao {
  const txt = (v: unknown): string => (typeof v === 'string' ? v.trim() : '');

  // serviço/profissional: precisam bater EXATAMENTE (após normalizar) com o catálogo
  const acharExato = (valor: string, lista: string[]): string | null => {
    const alvo = norm(valor);
    if (!alvo) return null;
    return lista.find((x) => norm(x) === alvo) ?? null;
  };

  // unidade: o modelo pode devolver apelido ("Alphaville") ou nome completo;
  // casamos por inclusão normalizada e devolvemos o unidade_id.
  const acharUnidade = (valor: string): string | null => {
    const alvo = norm(valor);
    if (!alvo) return null;
    const u = catalogo.unidades.find((x) => {
      const n = norm(x.nome);
      return n === alvo || n.includes(alvo) || alvo.includes(n);
    });
    return u?.id ?? null;
  };

  const dataCrua = txt(cru.data);
  const data = isYMD(dataCrua) && dataCrua >= hoje ? dataCrua : null;

  const periodoCru = norm(txt(cru.periodo));
  const periodo: Periodo | null =
    periodoCru === 'manha' ? 'manha' : periodoCru === 'tarde' ? 'tarde' : null;

  // hora específica: aceita HH:MM (com tolerância para hora de 1 dígito, "9:30" -> "09:30")
  const horaCrua0 = txt(cru.hora);
  const horaCrua = /^\d:\d{2}$/.test(horaCrua0) ? `0${horaCrua0}` : horaCrua0;
  const hora = isHHMM(horaCrua) ? horaCrua : null;

  return {
    servico: acharExato(txt(cru.servico), catalogo.servicos),
    profissional: acharExato(txt(cru.profissional), catalogo.profissionais),
    unidade: acharUnidade(txt(cru.unidade)),
    data,
    periodo,
    hora,
  };
}

// Orquestra a extração: chama o LLM, parseia defensivo e valida contra o catálogo.
export async function extrairIntencao(
  texto: string,
  catalogo: Catalogo,
  hoje: string,
): Promise<Intencao> {
  const bruto = await callLLM(montarMensagens(texto, catalogo, hoje));
  return validarIntencao(parseJsonDefensivo(bruto), catalogo, hoje);
}
