// Configuração da camada de IA (agendamento por linguagem natural).
// Provider-agnóstica: o provedor padrão é a OpenAI, mas trocar para a Anthropic
// é só mudar AI_PROVIDER no ambiente. A chave NUNCA vai para o app: fica só no
// backend, sem prefixo NEXT_PUBLIC, e o modelo nunca é fonte de verdade — toda
// saída passa por validação contra o catálogo real e a disponibilidade.

export type AiProvider = 'openai' | 'anthropic';

export type AiConfig = {
  provider: AiProvider;
  apiKey: string;
  model: string;
  maxCallsPerDay: number;
};

// Modelo padrão por provedor quando AI_MODEL não é informado.
// OpenAI: gpt-4o-mini (barato, suficiente para extração). Anthropic: claude-haiku-4-5.
const MODELO_PADRAO: Record<AiProvider, string> = {
  openai: 'gpt-4o-mini',
  anthropic: 'claude-haiku-4-5',
};

// Lê a configuração do ambiente. Lança se o provedor for inválido ou a chave faltar;
// o endpoint trata a ausência via aiConfigurado() e cai no fallback manual.
export function aiConfig(): AiConfig {
  const provider = (process.env.AI_PROVIDER ?? 'openai').trim().toLowerCase();
  if (provider !== 'openai' && provider !== 'anthropic')
    throw new Error(`AI_PROVIDER inválido: "${provider}" (use openai ou anthropic)`);

  const apiKey = (process.env.AI_API_KEY ?? '').trim();
  if (!apiKey) throw new Error('AI_API_KEY ausente');

  const model = (process.env.AI_MODEL ?? '').trim() || MODELO_PADRAO[provider];
  const maxCallsPerDay = Number.parseInt(process.env.AI_MAX_CALLS_PER_DAY ?? '', 10) || 200;

  return { provider, apiKey, model, maxCallsPerDay };
}

// Indica se a IA está configurada, sem lançar — o endpoint usa isto para decidir
// entre chamar o LLM ou já devolver o fallback manual.
export function aiConfigurado(): boolean {
  return !!(process.env.AI_API_KEY ?? '').trim();
}

// Teto diário de chamadas (lido à parte para o rate limit não depender da chave).
export function maxChamadasPorDia(): number {
  return Number.parseInt(process.env.AI_MAX_CALLS_PER_DAY ?? '', 10) || 200;
}
