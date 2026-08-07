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

// An alias, not a pinned name, on purpose. Google retires model names without
// notice — gemini-2.5-flash started returning 404 "no longer available to new
// users" the same day this was wired up, and a pinned name means a dead
// assistant until someone notices. The alias always resolves to the current
// Flash model. Trade-off accepted: behaviour can shift under us, but the
// answers are tightly constrained by the system prompt and the retrieved
// articles, and a silently broken assistant is the worse failure.
const DEFAULT_MODEL = 'gemini-flash-latest';
const MAX_PROMPT_CHARS = 24000;
const MAX_QUESTION_CHARS = 500;

// Past messages travelling with a question. The app already trims to three
// exchanges; this is the bound that holds when the caller is not the app.
const MAX_HISTORY_TURNS = 8;
const MAX_HISTORY_TURN_CHARS = 2000;

import { runReminderSweep } from './notifications.js';

export default {
  /// Hourly cron. Sends reminders that have come due — see notifications.js.
  async scheduled(event, env, ctx) {
    ctx.waitUntil(
      runReminderSweep(env).then(
        (result) => console.log('reminder sweep', JSON.stringify(result)),
        (error) => console.error('reminder sweep failed', error),
      ),
    );
  },

  async fetch(request, env) {
    const cors = corsHeaders(env);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors });
    }
    if (!env.GEMINI_API_KEY) {
      return json({ error: 'GEMINI_API_KEY is not configured' }, 500, cors);
    }

    // Diagnostic: which models this key may actually call. Google retires
    // model names without warning — "no longer available to new users" is a
    // 404 that looks like a broken deployment. Keeping this makes the next
    // retirement a one-minute fix instead of an investigation.
    if (request.method === 'GET' && new URL(request.url).pathname === '/models') {
      const list = await fetch(
        'https://generativelanguage.googleapis.com/v1beta/models',
        { headers: { 'x-goog-api-key': env.GEMINI_API_KEY } },
      );
      if (!list.ok) {
        return json({ error: `List failed: ${list.status}` }, 502, cors);
      }
      const data = await list.json();
      const usable = (data.models || [])
        .filter((m) => (m.supportedGenerationMethods || []).includes('generateContent'))
        .map((m) => m.name.replace('models/', ''));
      return json({ configured: env.GEMINI_MODEL || DEFAULT_MODEL, usable }, 200, cors);
    }

    if (request.method !== 'POST') {
      return json({ error: 'Only POST is accepted' }, 405, cors);
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
      contents: [...historyContents(body.history, prompt.length),
                 { role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.2, // factual recall, not creativity
        // Generous on purpose. Current Flash models reason before answering
        // and those hidden tokens come out of the same budget — at 700 the
        // visible reply was being cut off mid-sentence.
        //
        // Turning reasoning off would be tidier, but thinkingConfig is
        // rejected with 400 INVALID_ARGUMENT by the model this alias resolves
        // to, and guessing at the replacement field name is how you get an
        // assistant that breaks again next quarter. A larger budget fixes the
        // truncation without depending on a parameter that keeps moving.
        maxOutputTokens: 2048,
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

/**
 * The thread so far, as Gemini `contents`.
 *
 * Real roles rather than text pasted into the question: the system prompt
 * forbids treating an earlier answer as a source, and it can only keep that
 * rule if its own words are distinguishable from the parent's.
 *
 * Everything here is defensive — the body is whatever a caller sent. Unknown
 * roles collapse to `user`, oversized messages are cut, and the oldest turns
 * are dropped until the whole request fits the same budget one prompt has.
 * The current question is never among them, so a long history degrades the
 * memory rather than the answer.
 */
function historyContents(raw, promptChars) {
  if (!Array.isArray(raw)) return [];

  const turns = raw
    .filter((t) => t && typeof t.text === 'string' && t.text.trim())
    .slice(-MAX_HISTORY_TURNS)
    .map((t) => ({
      role: t.role === 'model' ? 'model' : 'user',
      parts: [{ text: t.text.slice(0, MAX_HISTORY_TURN_CHARS) }],
    }));

  let total = turns.reduce((n, c) => n + c.parts[0].text.length, 0);
  while (turns.length && total + promptChars > MAX_PROMPT_CHARS) {
    total -= turns[0].parts[0].text.length;
    turns.shift();
  }

  // A conversation has to open with something the parent said; the API
  // rejects one that starts with a model turn.
  while (turns.length && turns[0].role !== 'user') turns.shift();

  return turns;
}

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
