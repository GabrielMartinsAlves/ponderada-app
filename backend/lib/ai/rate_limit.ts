import { nowSaoPaulo } from '@/lib/booking/config';

// Rate limit diário da IA, em memória. Protege o orçamento da chave (compartilhada)
// limitando o total de chamadas ao LLM por dia, no fuso do salão. O contador zera
// sozinho quando a data muda. Em memória basta para esta entrega; em produção com
// múltiplas instâncias migraria para um store compartilhado (Redis/Postgres).
let diaAtual = '';
let contador = 0;

// Consome uma chamada do orçamento do dia. Retorna false se o teto já foi atingido
// (o endpoint responde 429 e o app cai no fluxo manual).
export function consumirChamada(maxPorDia: number): boolean {
  const { dateStr } = nowSaoPaulo();
  if (dateStr !== diaAtual) {
    diaAtual = dateStr;
    contador = 0;
  }
  if (contador >= maxPorDia) return false;
  contador += 1;
  return true;
}

// Exposto para teste/observabilidade: quantas chamadas já foram feitas hoje.
export function chamadasHoje(): number {
  const { dateStr } = nowSaoPaulo();
  return dateStr === diaAtual ? contador : 0;
}
