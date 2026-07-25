/**
 * Cloudflare Worker: proxy between the web app and the Gemini API.
 *
 * Why this exists: a Flutter web bundle is public. An API key compiled into it
 * is an API key given away, and Google bills whoever finds it. The key lives
 * here as a Worker secret and never leaves the edge.
 *
 * Free tier as of 2026: 100,000 requests/day on Cloudflare Workers, and the
 * Gemini Developer API has its own free quota. No credit card, no Blaze plan.
 *
 * Deploy:
 *   npx wrangler secret put GEMINI_API_KEY
 *   npx wrangler deploy
 */

const DEFAULT_MODEL = 'gemini-2.5-flash';
const MAX_PROMPT_CHARS = 24000;
const MAX_QUESTION_CHARS = 500;

export default {
  async fetch(request, env) {
    const cors = corsHeaders(env);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors });
    }
    if (request.method !== 'POST') {
      return json({ error: 'Only POST is accepted' }, 405, cors);
    }
    if (!env.GEMINI_API_KEY) {
      return json({ error: 'GEMINI_API_KEY is not configured' }, 500, cors);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return json({ error: 'Malformed JSON' }, 400, cors);
    }

    const system = typeof body.system === 'string' ? body.system : '';
    const prompt = typeof body.prompt === 'string' ? body.prompt : '';

    if (!prompt.trim()) {
      return json({ error: 'Empty prompt' }, 400, cors);
    }
    // Bound the payload so a scripted caller cannot burn the daily quota with
    // one enormous request.
    if (prompt.length > MAX_PROMPT_CHARS) {
      return json({ error: 'Prompt too long' }, 413, cors);
    }

    const model = env.GEMINI_MODEL || DEFAULT_MODEL;
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

    const payload = {
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.2, // factual recall, not creativity
        maxOutputTokens: 700,
        topP: 0.9,
      },
    };
    if (system) {
      payload.system_instruction = { parts: [{ text: system }] };
    }

    let upstream;
    try {
      upstream = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': env.GEMINI_API_KEY,
        },
        body: JSON.stringify(payload),
      });
    } catch (e) {
      return json({ error: `Upstream unreachable: ${e}` }, 502, cors);
    }

    if (upstream.status === 429) {
      return json({ error: 'Quota exceeded' }, 429, cors);
    }
    if (!upstream.ok) {
      const detail = await upstream.text();
      // Never echo the upstream body verbatim — it can contain the key.
      console.error('Gemini error', upstream.status, detail.slice(0, 500));
      return json({ error: 'Upstream error' }, 502, cors);
    }

    const data = await upstream.json();
    const candidate = data.candidates && data.candidates[0];

    // A safety block returns no parts. Say so plainly instead of returning an
    // empty bubble the parent cannot interpret.
    if (!candidate || candidate.finishReason === 'SAFETY') {
      return json(
        {
          text:
            'Не могу ответить на этот вопрос. Обратитесь к педиатру — ' +
            'при тревожных признаках звоните 103.',
        },
        200,
        cors,
      );
    }

    const text = (candidate.content?.parts || [])
      .map((p) => p.text || '')
      .join('')
      .trim();

    return json({ text }, 200, cors);
  },
};

function corsHeaders(env) {
  // Set ALLOWED_ORIGIN to the hosting domain in production so the quota
  // cannot be spent by someone else's page.
  const origin = env.ALLOWED_ORIGIN || '*';
  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
  };
}

function json(payload, status, cors) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { 'Content-Type': 'application/json; charset=utf-8', ...cors },
  });
}

export { MAX_QUESTION_CHARS };
