// Smoke-test E2E de /api/booking/* + TESTE DE CORRIDA (overbooking).
// Requer: dev server rodando (npm run dev) e banco aplicado (schema+functions+seed).
// Uso: node scripts/smoke.mjs
const BASE = process.env.BASE ?? 'http://127.0.0.1:3000/api/booking';
let pass = 0;
let fail = 0;
const ok = (cond, label, extra = '') => {
  if (cond) { pass++; console.log(`  PASS  ${label} ${extra}`); }
  else { fail++; console.log(`  FAIL  ${label} ${extra}`); }
};

async function api(path, { method = 'GET', token, body } = {}) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body) headers['Content-Type'] = 'application/json';
  const res = await fetch(BASE + path, { method, headers, body: body ? JSON.stringify(body) : undefined });
  let json = null;
  try { json = await res.json(); } catch { /* sem corpo */ }
  return { status: res.status, json };
}

async function signup(tag) {
  const email = `qa_${tag}_${Date.now()}_${Math.floor(Math.random() * 1e6)}@exemplo.com`;
  const r = await api('/auth/signup', {
    method: 'POST',
    body: { nome: `QA ${tag}`, email, telefone: '11999990000', senha: 'Senha123!' },
  });
  return { email, token: r.json?.access_token, status: r.status };
}

// Encontra uma data Ter–Sáb (e não-feriado, validado pelo servidor) com slots livres.
async function findOpen(token, profissional, unidadeId, servico) {
  const base = new Date();
  for (let i = 1; i <= 21; i++) {
    const c = new Date(base.getFullYear(), base.getMonth(), base.getDate() + i);
    const data = `${c.getFullYear()}-${String(c.getMonth() + 1).padStart(2, '0')}-${String(c.getDate()).padStart(2, '0')}`;
    const qs = `data=${data}&profissional=${encodeURIComponent(profissional)}&unidade_id=${unidadeId}&servico=${encodeURIComponent(servico)}`;
    const d = await api(`/disponibilidade?${qs}`, { token });
    const livres = (d.json?.slots ?? []).filter((s) => s.disponivel);
    if (d.json?.aberto && livres.length >= 2) return { data, livres, disp: d };
  }
  return null;
}

async function main() {
  console.log(`# Smoke E2E -> ${BASE}\n`);

  const a = await signup('A');
  ok(a.status === 201 && !!a.token, '1  signup A', `status=${a.status}`);

  const sv = await api('/servicos', { token: a.token });
  ok(sv.status === 200 && (sv.json?.servicos?.length ?? 0) > 0, '2  GET servicos', `n=${sv.json?.servicos?.length}`);
  const un = await api('/unidades', { token: a.token });
  ok(un.status === 200 && (un.json?.unidades?.length ?? 0) > 0, '3  GET unidades', `n=${un.json?.unidades?.length}`);

  const unidade = un.json.unidades[0];
  const servico = sv.json.servicos[0].servico;
  const pr = await api(`/profissionais?unidade_id=${unidade.id}&servico=${encodeURIComponent(servico)}`, { token: a.token });
  ok(pr.status === 200 && (pr.json?.profissionais?.length ?? 0) > 0, '4  GET profissionais', `n=${pr.json?.profissionais?.length}`);
  const profissional = pr.json.profissionais[0].profissional;

  const open = await findOpen(a.token, profissional, unidade.id, servico);
  ok(!!open, '5  GET disponibilidade (dia aberto c/ slots)', open ? `data=${open.data} livres=${open.livres.length}` : 'nenhum dia aberto');
  if (!open) { console.log(`\n# Resultado: ${pass} PASS / ${fail} FAIL`); process.exit(1); }

  const hora = open.livres[0].hora;
  const cr = await api('/agendamentos', {
    method: 'POST', token: a.token,
    body: { servico, profissional, unidade_id: unidade.id, data: open.data, hora, observacoes: 'smoke' },
  });
  ok(cr.status === 201 && !!cr.json?.agendamento?.id, '6  POST agendamento', `status=${cr.status} ${open.data} ${hora}`);
  const agId = cr.json?.agendamento?.id;

  const li = await api('/agendamentos?escopo=futuros', { token: a.token });
  ok(li.status === 200 && (li.json?.agendamentos ?? []).some((x) => x.id === agId), '7  GET meus agendamentos', `n=${li.json?.agendamentos?.length}`);

  const ca = await api(`/agendamentos/${agId}/cancelar`, { method: 'PATCH', token: a.token });
  ok(ca.status === 200 && ca.json?.agendamento?.status === 'Cancelado', '8  PATCH cancelar', `status=${ca.status}`);

  const c = await signup('C');
  const liC = await api('/agendamentos', { token: c.token });
  ok(liC.status === 200 && (liC.json?.agendamentos ?? []).length === 0, '9  match estrito: usuário novo vê lista vazia', `n=${liC.json?.agendamentos?.length}`);

  // ---- TESTE DE CORRIDA: 2 clientes diferentes, MESMO profissional/data/hora ----
  const ra = await signup('RaceA');
  const rb = await signup('RaceB');
  const open2 = await findOpen(ra.token, profissional, unidade.id, servico);
  const horaRace = open2?.livres?.[0]?.hora;
  const payload = { servico, profissional, unidade_id: unidade.id, data: open2.data, hora: horaRace, observacoes: 'corrida' };
  const [r1, r2] = await Promise.all([
    api('/agendamentos', { method: 'POST', token: ra.token, body: payload }),
    api('/agendamentos', { method: 'POST', token: rb.token, body: payload }),
  ]);
  const um201 = [r1.status, r2.status].filter((s) => s === 201).length === 1;
  const um409 = [r1.status, r2.status].filter((s) => s === 409).length === 1;
  ok(um201 && um409, '10 TESTE DE CORRIDA (2 clientes, mesmo slot)', `=> ${r1.status} & ${r2.status} (esperado 201 & 409)`);

  console.log(`\n# Resultado: ${pass} PASS / ${fail} FAIL`);
  process.exit(fail > 0 ? 1 : 0);
}

main().catch((e) => { console.error('ERRO smoke:', e); process.exit(2); });
