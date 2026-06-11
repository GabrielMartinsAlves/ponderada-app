// Configuração de negócio do booking (horário comercial, unidades, utilitários).

// Horário comercial: salão aberto Ter–Sáb, 09:00–19:00, slots de 30 min
// (fechado Dom/Seg).
export const BUSINESS = {
  openDays: [2, 3, 4, 5, 6], // 0=Dom .. 6=Sáb
  openMin: 9 * 60, // 09:00
  closeMin: 19 * 60, // 19:00 (último término permitido)
  slotMin: 30,
};

// Status que OCUPAM o slot. Os demais (Cancelado / Cliente não compareceu) liberam.
const STATUS_LIVRES = new Set(['Cancelado', 'Cliente não compareceu']);
export const ocupaSlot = (status: string): boolean => !STATUS_LIVRES.has((status ?? '').trim());

// Coordenadas reais das unidades (usadas pela feature de GPS/rota).
// Granja Viana: coordenada do endereço da unidade.
// Alphaville: geocodificada via Nominatim/OpenStreetMap (Calçada das Anêmonas).
export const UNIDADE_GEO: Record<string, { endereco: string; lat: number; lng: number }> = {
  'Espaço Lumma — Granja Viana': {
    endereco: 'Praça Dr. Niso Viana, 51 — Granja Viana, Cotia/SP, 06709-047',
    lat: -23.593864,
    lng: -46.83979,
  },
  'Espaço Lumma — Alphaville': {
    endereco: 'Calçada das Anêmonas, 152 — Alphaville, Barueri/SP, 06453-005',
    lat: -23.497179,
    lng: -46.851487,
  },
};

// ---- utilitários de horário ------------------------------------------------
export function hhmmToMin(hhmm: string): number {
  const [h, m] = (hhmm ?? '').split(':').map((x) => parseInt(x, 10));
  return (Number.isFinite(h) ? h : 0) * 60 + (Number.isFinite(m) ? m : 0);
}
export function minToHHMM(min: number): string {
  const h = Math.floor(min / 60);
  const m = min % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

// dia da semana (0=Dom..6=Sáb) de 'YYYY-MM-DD' sem ruído de fuso.
export function weekdayOf(dateStr: string): number {
  const [y, m, d] = dateStr.split('-').map((x) => parseInt(x, 10));
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay();
}

// "agora" no fuso do salão (America/Sao_Paulo): data e minutos do dia.
export function nowSaoPaulo(): { dateStr: string; minutes: number } {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Sao_Paulo',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).formatToParts(new Date());
  const get = (t: string) => parts.find((p) => p.type === t)?.value ?? '00';
  return {
    dateStr: `${get('year')}-${get('month')}-${get('day')}`,
    minutes: (parseInt(get('hour'), 10) % 24) * 60 + parseInt(get('minute'), 10),
  };
}
