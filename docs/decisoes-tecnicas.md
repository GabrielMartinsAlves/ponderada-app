# Decisões técnicas do Lumma Agendamentos

Registro das decisões que moldaram o projeto, em formato curto de contexto, decisão e consequência. A
narrativa completa dos problemas está no [README, seção _Problemas que enfrentei e como resolvi_](../README.md#problemas-que-enfrentei-e-como-resolvi);
aqui é a lista de referência.

---

## Anti-overbooking no banco, com advisory lock + overlap

- **Contexto.** Duas requisições simultâneas para o mesmo profissional/horário poderiam passar pela checagem de
  disponibilidade antes de qualquer uma gravar (condição de corrida). Travar a tabela toda mataria a concorrência.
- **Decisão.** Criação via `fn_criar_agendamento` (plpgsql): `pg_advisory_xact_lock` por `profissional|data|unidade`
  com re-check de `OVERLAPS` sob o lock, na mesma transação.
- **Consequência.** Invariante garantida no nível certo (o banco), com serialização mínima (por profissional/dia,
  não global). A criação deixa de ser um `INSERT` e vira uma RPC, com complexidade aceitável.

## Distinguir SLOT_TAKEN (409) de duplicado (422)

- **Contexto.** Tanto o overbooking quanto a violação da constraint de deduplicação chegam como `23505`.
- **Decisão.** A função levanta `SLOT_TAKEN` como mensagem; o route handler devolve **409** quando a mensagem é
  `SLOT_TAKEN` e **422** para os demais `23505`.
- **Consequência.** O app mostra "Horário já reservado" só quando é de fato concorrência; duplicado idêntico vira
  422 "Conflito de registro (duplicado)". Os dois casos ficam separados e testáveis.

## Catálogo derivado dos dados, via views

- **Contexto.** Base desnormalizada, sem tabelas de catálogo; eu precisava de listas de serviços e profissionais.
- **Decisão.** Views `booking_servicos` (moda da duração, mediana do valor) e `booking_profissionais` (`DISTINCT`).
- **Consequência.** O catálogo reflete os dados reais e é robusto a outliers; é uma fotografia estatística, não
  uma tabela curada, mas suficiente para o objetivo.

## Horário comercial como configuração inferida

- **Contexto.** Não havia configuração formal de funcionamento.
- **Decisão.** `BUSINESS` fixo: de terça a sábado, das 09:00 às 19:00, em janelas de 30 min, inferido da
  distribuição dos agendamentos.
- **Consequência.** Simples e previsível; não é parametrizável por unidade (evolução futura: tabela de horários).

## App fino, regra no backend

- **Contexto.** Duração, valor e regras (feriado, dia fechado, slot livre) não podem depender do cliente.
- **Decisão.** O backend deriva duração/valor do catálogo e aplica todas as regras; o app só envia a escolha.
- **Consequência.** O cliente não consegue forjar valor nem furar regra por um JSON diferente.

## Bearer + refresh num interceptor único (dio)

- **Contexto.** Toda chamada autenticada precisa do token; o token expira.
- **Decisão.** `ApiClient` com interceptors do dio: injeta `Bearer`, tenta `refresh` uma vez em 401, converte erro
  em `ApiException`.
- **Consequência.** Autenticação e tratamento de erro num só lugar; as telas só lidam com `ApiException`.

## Estado com Riverpod + AsyncValue

- **Contexto.** Todo consumo de API tem três estados: carregando, erro, dado (às vezes vazio).
- **Decisão.** `AsyncValue.when` + componentes de estado (`state_views.dart`); `FutureProvider.family` para
  chamadas parametrizadas (disponibilidade por data/profissional/serviço).
- **Consequência.** Loading/erro/vazio tratados de forma uniforme em todas as telas, sem tela branca nem exceção
  crua.

## Base URL por `--dart-define`

- **Contexto.** Emulador, dispositivo físico e iOS enxergam o `localhost` de formas diferentes.
- **Decisão.** `API_BASE_URL` injetada em build time (`--dart-define`), default `http://10.0.2.2:3000`.
- **Consequência.** Trocar de alvo é um parâmetro de build, sem mexer no código.

## GPS: forçar o location manager no Android

- **Contexto.** No emulador, o provedor *fused* devolvia cache e a precisão `medium` ia para o provedor de rede.
- **Decisão.** `AndroidSettings(accuracy: high, forceLocationManager: true, timeLimit: ...)` + fallback para a
  última posição conhecida; mexer na posição pela GUI Extended Controls do emulador.
- **Consequência.** Distâncias confiáveis e a prova de "distância muda". Em aparelho real o fluxo é direto; a
  ginástica é só do emulador.

## Lembrete via timer no emulador, zonedSchedule em produção

- **Contexto.** A notificação agendada (`zonedSchedule`) não renderiza no emulador (alarme dispara, notificação
  não aparece), nas versões 22 e 17 do plugin.
- **Decisão.** Modo de teste com timer interno + `show` (renderiza) para a demo; `zonedSchedule` (2h e 24h antes)
  mantido para produção.
- **Consequência.** A feature é demonstrável; o gatilho muda só no ambiente de teste. Decisão documentada
  abertamente.

## Etar para abrir o `.ics`

- **Contexto.** O Google Calendar do emulador exige conta Google; o emulador não tinha conta.
- **Decisão.** Instalar o Etar (calendário offline, código aberto), que aparece no seletor "Abrir com" e abre o
  evento sem conta. O `.ics` gerado usa `TZID=America/Sao_Paulo`, fim igual ao início mais a duração, local e
  descrição reais.
- **Consequência.** O "Salvar na agenda" é demonstrável no emulador; em aparelho real abre no calendário do
  usuário.

## "Meus Agendamentos" por e-mail exato

- **Contexto.** A base tem e-mail e telefone com qualidade variável; a listagem não pode vazar o horário de outra
  pessoa.
- **Decisão.** Filtrar por **e-mail exato** do usuário autenticado.
- **Consequência.** Previsível e seguro; **limitação conhecida**: agendamento antigo sem e-mail (ou com e-mail
  diferente) não aparece. Errar para o lado de não mostrar demais. Evolução: reconciliar por telefone verificado.

## Notificação local agora, push depois

- **Contexto.** O escopo pedia notificações; push real (FCM) exige infraestrutura extra.
- **Decisão.** Notificações **locais** (confirmação + lembrete) nesta entrega.
- **Consequência.** Cobre o requisito; o lembrete não chega com o app fechado por dias; o próximo passo é FCM.
