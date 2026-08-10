// Sending a family invitation as an actual letter.
//
// The invitation is a Firestore document written by the app, and that
// document is what grants the access. This only tells the other person it
// exists — which until now was nobody's job: the app said «отправлено» and
// nothing was ever sent.
//
// Two things make this safe to expose on a public URL. The caller has to
// present a Firebase ID token, which is traded for a uid; and the invitation
// named in the request has to already exist in Firestore with that uid as its
// owner. So the only address anyone can write to is one they have already been
// given the right to share a child's record with. It cannot be used as a relay.

import { getAccessToken, firestoreBase, plain } from './notifications.js';

const LOOKUP_URL =
  'https://identitytoolkit.googleapis.com/v1/accounts:lookup';

/// Brevo's transactional endpoint. Chosen because its free tier sends 300
/// letters a day from a single verified address — no domain to buy, no DNS to
/// configure, which is the whole difference between this shipping and not.
const BREVO_URL = 'https://api.brevo.com/v3/smtp/email';

/// GREEN-API's default host. Each instance is also given one of its own
/// (`https://7103.api.greenapi.com`), so this is overridable — the default is
/// only what works when nobody has been told otherwise.
const GREEN_API_URL = 'https://api.green-api.com';

/// Who the token belongs to, or null.
///
/// Verified by asking Google rather than by checking the signature here: the
/// public keys rotate, caching them correctly is its own bug, and this runs
/// once per invitation rather than once per request.
async function uidFor(idToken, apiKey) {
  const response = await fetch(`${LOOKUP_URL}?key=${apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ idToken }),
  });
  if (!response.ok) return null;
  const body = await response.json();
  const user = (body.users || [])[0];
  return user ? user.localId : null;
}

/// The invitation this request claims, as Firestore has it.
async function invitationFor(token, projectId, childId, email) {
  const path =
    `${firestoreBase(projectId)}/children/${childId}` +
    `/family_members/${encodeURIComponent(email)}`;
  const response = await fetch(path, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!response.ok) return null;
  const doc = await response.json();
  return Object.fromEntries(
    Object.entries(doc.fields || {}).map(([k, v]) => [k, plain(v)]),
  );
}

export function escapeHtml(text) {
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/// The letter itself.
///
/// Plain and short on purpose. It is read on a phone by somebody who was told
/// to expect it, and everything it has to do is name the child, name the
/// address to sign in with, and carry one link.
export function letter({ childName, email, link, fromName }) {
  const child = escapeHtml(childName);
  const who = escapeHtml(fromName || '');
  const address = escapeHtml(email);
  const url = escapeHtml(link);
  const opening = who
    ? `${who} открывает вам доступ к дневнику ребёнка`
    : 'Вам открыли доступ к дневнику ребёнка';

  return {
    subject: `Доступ к дневнику: ${childName}`,
    html: `<!doctype html><html lang="ru"><body style="margin:0;background:#FAF7F4;
  font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;
  color:#1E1A18">
<div style="max-width:520px;margin:0 auto;padding:32px 20px">
  <div style="background:#fff;border-radius:20px;padding:28px 24px;
    box-shadow:0 12px 28px rgba(30,26,24,.08)">
    <p style="margin:0 0 6px;font-size:12px;font-weight:700;letter-spacing:.1em;
      text-transform:uppercase;color:#A8570B">Приглашение</p>
    <h1 style="margin:0 0 14px;font-size:24px;line-height:1.2">${opening} — ${child}</h1>
    <p style="margin:0 0 18px;font-size:16px;line-height:1.5;color:#6E645F">
      Вы сможете видеть кормления, сон, рост и записи. Только смотреть —
      изменить или удалить что-либо нельзя.
    </p>
    <p style="margin:0 0 24px;font-size:16px;line-height:1.5">
      Войдите почтой <b>${address}</b> — именно на этот адрес открыт доступ.
    </p>
    <a href="${url}" style="display:block;text-align:center;background:#A8570B;
      color:#fff;text-decoration:none;font-weight:700;font-size:17px;
      padding:16px 20px;border-radius:14px">Открыть дневник</a>
    <p style="margin:16px 0 0;font-size:13px;color:#6E645F;word-break:break-all">
      ${url}
    </p>
  </div>
  <p style="margin:18px 4px 0;font-size:12px;line-height:1.5;color:#6E645F">
    Если вы не ждали этого письма — просто не открывайте ссылку, доступ без
    входа не работает.
  </p>
</div></body></html>`,
    text:
      `${opening} — ${childName}.\n\n` +
      `Войдите почтой ${email} по ссылке: ${link}\n\n` +
      'Доступ только на чтение. Если вы не ждали этого письма — ' +
      'просто не открывайте ссылку.',
  };
}

/// The same invitation as a WhatsApp message.
///
/// Which is the one that actually gets read here: in Kazakhstan a link sent
/// to WhatsApp arrives on the phone the person is already holding, and an
/// email lands in a tab they open on Tuesdays.
async function sendWhatsApp(env, phone, text) {
  const base = env.GREEN_API_URL || GREEN_API_URL;
  const url =
    `${base}/waInstance${env.GREEN_API_ID}` +
    `/sendMessage/${env.GREEN_API_TOKEN}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    // Digits only, country code first — the client normalises «+7 700…» and
    // «8 700…» to this before it ever gets here.
    body: JSON.stringify({ chatId: `${phone}@c.us`, message: text }),
  });

  if (!response.ok) {
    console.error('whatsapp failed', response.status, await response.text());
    return false;
  }
  // A 200 with no idMessage is GREEN-API refusing quietly — an instance that
  // is not authorised answers exactly like that.
  const body = await response.json().catch(() => ({}));
  return Boolean(body.idMessage);
}

/// Handles POST /invite.
///
/// Returns 501 rather than 500 when there is no mail key: that is the Worker
/// saying it was never set up to send, which the app turns into a different
/// sentence from a refusal.
export async function handleInvite(request, env, cors, json) {
  if (!env.FIREBASE_SERVICE_ACCOUNT) {
    return json({ error: 'FIREBASE_SERVICE_ACCOUNT is not configured' }, 501, cors);
  }
  const canMail = Boolean(env.BREVO_API_KEY && env.MAIL_FROM);
  const canWhatsApp = Boolean(env.GREEN_API_ID && env.GREEN_API_TOKEN);
  if (!canMail && !canWhatsApp) {
    return json({ error: 'no channel is configured' }, 501, cors);
  }

  const auth = request.headers.get('Authorization') || '';
  const idToken = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  if (!idToken) return json({ error: 'unauthorized' }, 401, cors);

  let body;
  try {
    body = await request.json();
  } catch {
    return json({ error: 'bad request' }, 400, cors);
  }

  const childId = String(body.child_id || '');
  const email = String(body.email || '').trim().toLowerCase();
  const childName = String(body.child_name || '').slice(0, 80);
  const link = String(body.link || '');
  const fromName = String(body.from_name || '').slice(0, 80);
  // Optional, and already digits by the time it arrives.
  const phone = String(body.phone || '').replace(/\D/g, '');

  if (!childId || !email || !link.startsWith('https://')) {
    return json({ error: 'bad request' }, 400, cors);
  }

  const apiKey = env.FIREBASE_API_KEY;
  if (!apiKey) {
    return json({ error: 'FIREBASE_API_KEY is not configured' }, 501, cors);
  }

  const uid = await uidFor(idToken, apiKey);
  if (!uid) return json({ error: 'unauthorized' }, 401, cors);

  const serviceAccount = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
  const token = await getAccessToken(serviceAccount);
  const invitation = await invitationFor(
    token,
    serviceAccount.project_id,
    childId,
    email,
  );

  // The gate. Not "is this a valid user" but "has this user already been
  // granted the right to share this particular record with this particular
  // address" — which only the owner's own client could have written.
  if (!invitation || invitation.owner_uid !== uid) {
    return json({ error: 'forbidden' }, 403, cors);
  }

  const mail = letter({ childName, email, link, fromName });
  const channels = [];

  // Whether anything was even tried. Without a mail key an invitation with no
  // phone number reaches this point with nothing to attempt, and reporting
  // that as a failed send made the app say «письмо не ушло» about a letter it
  // was never going to write.
  let attempted = false;

  // WhatsApp first: it is the one that gets read, and if it lands there is
  // no reason to make anyone check an inbox as well.
  if (canWhatsApp && phone) {
    attempted = true;
    if (await sendWhatsApp(env, phone, mail.text)) channels.push('whatsapp');
  }

  if (canMail && channels.length === 0) {
    attempted = true;
    const response = await fetch(BREVO_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-key': env.BREVO_API_KEY,
      },
      body: JSON.stringify({
        sender: {
          email: env.MAIL_FROM,
          name: env.MAIL_FROM_NAME || 'Дневник ребёнка',
        },
        to: [{ email }],
        subject: mail.subject,
        htmlContent: mail.html,
        textContent: mail.text,
      }),
    });
    if (response.ok) {
      channels.push('email');
    } else {
      console.error('invite mail failed', response.status, await response.text());
    }
  }

  if (channels.length === 0) {
    // 501 and 502 are different sentences on the screen: one is "there was no
    // way to deliver this", which is the ordinary state of an install with no
    // mail key and no phone number typed, and the other is "a provider we do
    // have refused us", which is worth the word «не удалось».
    return attempted
      ? json({ error: 'send failed' }, 502, cors)
      : json({ error: 'no channel for this invitation' }, 501, cors);
  }
  return json({ sent: true, channels }, 200, cors);
}
