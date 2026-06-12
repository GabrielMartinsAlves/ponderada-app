// Consumo de API externa: feriados nacionais (BrasilAPI), com cache em memória
// por ano. Usado para bloquear agendamento em dia de salão fechado.
// Fail-safe: se a API cair, retorna vazio (não bloqueia o salão indevidamente).
const cache = new Map<number, Set<string>>();

export async function feriadosDoAno(ano: number): Promise<Set<string>> {
  const cached = cache.get(ano);
  if (cached) return cached;
  try {
    const res = await fetch(`https://brasilapi.com.br/api/feriados/v1/${ano}`);
    if (!res.ok) throw new Error(`BrasilAPI feriados ${res.status}`);
    const data = (await res.json()) as Array<{ date: string; name: string }>;
    const set = new Set(data.map((f) => f.date)); // 'YYYY-MM-DD'
    cache.set(ano, set);
    return set;
  } catch {
    return new Set();
  }
}

export async function ehFeriado(dateStr: string): Promise<boolean> {
  const ano = parseInt(dateStr.slice(0, 4), 10);
  const set = await feriadosDoAno(ano);
  return set.has(dateStr);
}
