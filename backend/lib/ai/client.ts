import { aiConfig, type AiConfig } from './config';

export type LlmMessage = { role: 'system' | 'user' | 'assistant'; content: string };

// Cliente de LLM agnóstico de provedor. callLLM monta a requisição do provedor
// configurado, faz a chamada por HTTP (fetch, sem SDK — igual ao resto do backend)
// e normaliza a resposta para uma única string. Trocar OpenAI <-> Anthropic é só
// AI_PROVIDER no ambiente; o resto do código não muda.
export async function callLLM(messages: LlmMessage[]): Promise<string> {
  const cfg = aiConfig();
  return cfg.provider === 'anthropic' ? callAnthropic(cfg, messages) : callOpenAI(cfg, messages);
}

// OpenAI: POST /v1/chat/completions, Bearer no header, resposta em
// choices[0].message.content. response_format json_object reforça a saída JSON.
async function callOpenAI(cfg: AiConfig, messages: LlmMessage[]): Promise<string> {
  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${cfg.apiKey}`,
    },
    body: JSON.stringify({
      model: cfg.model,
      messages,
      temperature: 0,
      max_tokens: 400,
      response_format: { type: 'json_object' },
    }),
  });
  if (!res.ok) throw new Error(`OpenAI ${res.status}`);
  const data = (await res.json()) as { choices?: Array<{ message?: { content?: unknown } }> };
  const text = data?.choices?.[0]?.message?.content;
  if (typeof text !== 'string') throw new Error('Resposta da OpenAI sem conteúdo de texto');
  return text;
}

// Anthropic: POST /v1/messages, headers x-api-key + anthropic-version, resposta em
// content[0].text. O system prompt é campo próprio (não entra em messages, que só
// aceita user/assistant), então separamos as mensagens system aqui.
async function callAnthropic(cfg: AiConfig, messages: LlmMessage[]): Promise<string> {
  const system = messages.filter((m) => m.role === 'system').map((m) => m.content).join('\n\n');
  const turns = messages
    .filter((m) => m.role !== 'system')
    .map((m) => ({ role: m.role, content: m.content }));

  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-api-key': cfg.apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: cfg.model,
      max_tokens: 400,
      ...(system ? { system } : {}),
      messages: turns,
    }),
  });
  if (!res.ok) throw new Error(`Anthropic ${res.status}`);
  const data = (await res.json()) as { content?: Array<{ text?: unknown }> };
  const text = data?.content?.[0]?.text;
  if (typeof text !== 'string') throw new Error('Resposta da Anthropic sem conteúdo de texto');
  return text;
}
