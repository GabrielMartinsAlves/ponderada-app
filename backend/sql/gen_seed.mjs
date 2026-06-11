// Gera seed.sql com dados de demonstração: catálogo de serviços, profissionais
// por unidade e agendamentos para o app ter conteúdo de exemplo. Nomes de
// profissionais e clientes são fictícios. Uso: node sql/gen_seed.mjs
import { writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const U1 = '11111111-1111-1111-1111-111111111111'; // Granja Viana
const U2 = '22222222-2222-2222-2222-222222222222'; // Alphaville

// [servico, duracao_minutos, valor] — catálogo de exemplo
const servicos = [
  ['Manicure', 50, 45],
  ['Pedicure', 60, 45],
  ['Manicure com esmaltação em gel', 90, 70],
  ['Pedicure com esmaltação em gel', 90, 70],
  ['Manutenção de alongamento em gel', 90, 155],
  ['Alongamento em gel com esmaltação', 120, 175],
  ['Blindagem de unhas com gel', 90, 90],
  ['Banho de gel', 100, 155],
  ['Alongamento em fibra de vidro', 120, 230],
  ['Remoção de gel', 60, 80],
  ['Design de sobrancelha', 40, 50],
  ['Design de sobrancelha com henna', 50, 65],
  ['Manutenção de cílios', 90, 120],
  ['Extensão de cílios volume', 90, 160],
  ['Massagem relaxante', 80, 175],
];

// Profissionais fictícios, 7 por unidade.
const profsU1 = ['Bianca', 'Camila', 'Renata', 'Patrícia', 'Fernanda', 'Aline', 'Juliana'];
const profsU2 = ['Beatriz', 'Carolina', 'Larissa', 'Priscila', 'Gabriela', 'Sabrina', 'Eduarda'];

// datas Ter–Sáb de maio/2026; horas dentro de 09–19
const datas = [
  '2026-05-05', '2026-05-06', '2026-05-07', '2026-05-08', '2026-05-09',
  '2026-05-12', '2026-05-13', '2026-05-14', '2026-05-15', '2026-05-16',
  '2026-05-19', '2026-05-20', '2026-05-21', '2026-05-22', '2026-05-23',
];
const horas = ['09:00', '10:30', '13:00', '14:30', '16:00', '17:30'];

const TOTAL = 200;
const esc = (s) => String(s).replace(/'/g, "''");

const profsAll = [];
profsU1.forEach((p) => profsAll.push([p, U1]));
profsU2.forEach((p) => profsAll.push([p, U2]));

const per = {}; // contador por profissional -> garante (data,hora) distintos
const rows = [];
for (let i = 0; i < TOTAL; i++) {
  const [prof, U] = profsAll[i % profsAll.length];
  const key = prof + U;
  const j = per[key] ?? 0;
  per[key] = j + 1;
  const s = servicos[i % servicos.length]; // cobre todos os serviços
  const data = datas[j % datas.length];
  const hora = horas[Math.floor(j / datas.length) % horas.length];
  const n = i + 1;
  const cliente = `Cliente Exemplo ${n}`;
  const tel = `1199${String(800000 + n).padStart(6, '0')}`;
  const email = `cliente${n}@exemplo.com`;
  rows.push(
    `  ('${data}','${hora}','${esc(prof)}','${esc(s[0])}',${s[1]},${s[2]},` +
    `'${esc(cliente)}','${tel}','${email}','Finalizado','normal','${U}')`
  );
}

const out = `-- ============================================================================
-- seed.sql — dados de demonstração (gerado por gen_seed.mjs).
-- ${rows.length} agendamentos (status Finalizado) + 2 unidades.
-- Emails cliente*@exemplo.com são fictícios e não casam com usuários do app
-- (Meus Agendamentos nasce vazio para um usuário novo — match estrito por email).
-- ============================================================================
INSERT INTO public.unidades (id, nome) VALUES
  ('${U1}','Espaço Lumma — Granja Viana'),
  ('${U2}','Espaço Lumma — Alphaville')
ON CONFLICT (nome) DO NOTHING;

INSERT INTO public.agendamentos
  (data_agendamento,hora,profissional,servico,duracao_minutos,valor,cliente,telefone,email,status,categoria_atendimento,unidade_id) VALUES
${rows.join(',\n')};
`;

const dir = path.dirname(fileURLToPath(import.meta.url));
writeFileSync(path.join(dir, 'seed.sql'), out, 'utf8');
console.log(`seed.sql gerado: ${rows.length} agendamentos, 2 unidades.`);
