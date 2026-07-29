// Scheduled reminder delivery.
//
// Cloud Functions would be the obvious home for this, but they require the
// paid Blaze plan. A Cloudflare cron trigger is free, so the job lives here:
// wake up hourly, find reminders that have come due, push them to whichever
// devices the parent registered, and mark them so they are never sent twice.
//
// This is the one place in the project holding a real secret. The service
// account bypasses the Firestore rules entirely — it has to, since it acts
// for every user and on behalf of none. It exists only as a Worker secret.

const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const SCOPES = [
  'https://www.googleapis.com/auth/datastore',
  'https://www.googleapis.com/auth/firebase.messaging',
].join(' ');

/// How far ahead to look. An hourly cron with an hourly horizon means a
/// reminder arrives within an hour of its time — close enough for a
/// vaccination, and far better than a notification at 03:00 sharp.
const HORIZON_MS = 60 * 60 * 1000;

/// Nothing older than this is sent at all. A parent returning from a week
/// offline should not be buried in stale reminders for appointments already
/// missed; those are visible in the app, where they belong.
const STALE_AFTER_MS = 24 * 60 * 60 * 1000;

// --- Authentication -------------------------------------------------------

function base64UrlEncode(bytes) {
  let binary = '';
  for (const byte of new Uint8Array(bytes)) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function pemToArrayBuffer(pem) {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '');
  const binary = atob(body);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

/// Signs a JWT with the service account key and trades it for an access
/// token. Done per invocation: the cron runs hourly and tokens last an hour,
/// so caching would buy nothing and add a staleness bug.
async function getAccessToken(serviceAccount) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claims = {
    iss: serviceAccount.client_email,
    scope: SCOPES,
    aud: TOKEN_URL,
    iat: now,
    exp: now + 3600,
  };

  const encoder = new TextEncoder();
  const unsigned =
    `${base64UrlEncode(encoder.encode(JSON.stringify(header)))}.` +
    `${base64UrlEncode(encoder.encode(JSON.stringify(claims)))}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(serviceAccount.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    encoder.encode(unsigned),
  );

  const assertion = `${unsigned}.${base64UrlEncode(signature)}`;
  const response = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  if (!response.ok) {
    throw new Error(`token exchange failed: ${response.status}`);
  }
  const data = await response.json();
  return data.access_token;
}

// --- Firestore ------------------------------------------------------------

function firestoreBase(projectId) {
  return `https://firestore.googleapis.com/v1/projects/${projectId}` +
    '/databases/(default)/documents';
}

/// Firestore returns typed values; this pulls out the plain one.
function plain(value) {
  if (!value) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('timestampValue' in value) return value.timestampValue;
  if ('arrayValue' in value) {
    return (value.arrayValue.values || []).map(plain);
  }
  if ('mapValue' in value) {
    const out = {};
    for (const [k, v] of Object.entries(value.mapValue.fields || {})) {
      out[k] = plain(v);
    }
    return out;
  }
  return null;
}

/// Reminders that are due, not completed and not already announced.
///
/// Dates are stored as ISO-8601 strings, which sort lexicographically in the
/// same order as chronologically — so a plain string range filter is a
/// correct date range filter here.
async function dueReminders(token, projectId, now) {
  const horizon = new Date(now.getTime() + HORIZON_MS).toISOString();
  const floor = new Date(now.getTime() - STALE_AFTER_MS).toISOString();

  const response = await fetch(`${firestoreBase(projectId)}:runQuery`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      structuredQuery: {
        from: [{ collectionId: 'reminders' }],
        where: {
          compositeFilter: {
            op: 'AND',
            filters: [
              {
                fieldFilter: {
                  field: { fieldPath: 'is_completed' },
                  op: 'EQUAL',
                  value: { booleanValue: false },
                },
              },
              {
                fieldFilter: {
                  field: { fieldPath: 'scheduled_time' },
                  op: 'LESS_THAN_OR_EQUAL',
                  value: { stringValue: horizon },
                },
              },
              {
                fieldFilter: {
                  field: { fieldPath: 'scheduled_time' },
                  op: 'GREATER_THAN',
                  value: { stringValue: floor },
                },
              },
            ],
          },
        },
        orderBy: [{ field: { fieldPath: 'scheduled_time' } }],
        limit: 200,
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`firestore query failed: ${response.status}`);
  }

  const rows = await response.json();
  return rows
    .filter((row) => row.document)
    .map((row) => ({
      name: row.document.name,
      id: row.document.name.split('/').pop(),
      fields: Object.fromEntries(
        Object.entries(row.document.fields || {}).map(([k, v]) => [k, plain(v)]),
      ),
    }))
    // Already announced. Filtered here rather than in the query: Firestore
    // cannot test for a missing field, and adding the field to every
    // reminder up front would mean rewriting them all.
    .filter((doc) => !doc.fields.notified_at);
}

async function getUser(token, projectId, uid) {
  const response = await fetch(`${firestoreBase(projectId)}/users/${uid}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!response.ok) return null;
  const doc = await response.json();
  const fields = Object.fromEntries(
    Object.entries(doc.fields || {}).map(([k, v]) => [k, plain(v)]),
  );
  return fields;
}

async function markNotified(token, projectId, documentName, when) {
  await fetch(
    `https://firestore.googleapis.com/v1/${documentName}` +
      '?updateMask.fieldPaths=notified_at',
    {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        fields: { notified_at: { stringValue: when } },
      }),
    },
  );
}

// --- Sending --------------------------------------------------------------

async function sendPush(token, projectId, deviceToken, reminder) {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: deviceToken,
          notification: {
            title: titleFor(reminder.fields.type),
            body: reminder.fields.title || 'Напоминание',
          },
          data: {
            reminder_id: reminder.id,
            child_id: reminder.fields.child_id || '',
          },
          webpush: {
            fcmOptions: { link: '/reminders' },
          },
        },
      }),
    },
  );

  // 404 and 400 UNREGISTERED mean the browser dropped the subscription —
  // reported so the caller can prune it rather than retrying forever.
  return { ok: response.ok, status: response.status };
}

function titleFor(type) {
  switch (type) {
    case 'vaccination':
      return 'Пора на прививку';
    case 'medication':
      return 'Приём лекарства';
    default:
      return 'Визит к врачу';
  }
}

// --- Entry point ----------------------------------------------------------

export async function runReminderSweep(env, now = new Date()) {
  if (!env.FIREBASE_SERVICE_ACCOUNT) {
    console.error('FIREBASE_SERVICE_ACCOUNT is not configured');
    return { sent: 0, skipped: 0, error: 'not configured' };
  }

  const serviceAccount = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT);
  const projectId = serviceAccount.project_id;
  const token = await getAccessToken(serviceAccount);

  const reminders = await dueReminders(token, projectId, now);
  if (reminders.length === 0) return { sent: 0, skipped: 0 };

  // One profile read per parent, not per reminder: a newborn's schedule can
  // put several doses on the same morning.
  const profiles = new Map();
  let sent = 0;
  let skipped = 0;

  for (const reminder of reminders) {
    const uid = reminder.fields.parent_uid;
    if (!uid) {
      skipped++;
      continue;
    }

    if (!profiles.has(uid)) {
      profiles.set(uid, await getUser(token, projectId, uid));
    }
    const profile = profiles.get(uid);

    const enabled = profile?.settings?.notifications_enabled !== false;
    const deviceTokens = profile?.push_tokens || [];
    if (!profile || !enabled || deviceTokens.length === 0) {
      // Nothing to send to. Still marked, so the reminder does not queue up
      // and arrive in a burst the day notifications are switched on.
      await markNotified(token, projectId, reminder.name, now.toISOString());
      skipped++;
      continue;
    }

    let delivered = false;
    for (const deviceToken of deviceTokens) {
      const result = await sendPush(token, projectId, deviceToken, reminder);
      if (result.ok) delivered = true;
    }

    await markNotified(token, projectId, reminder.name, now.toISOString());
    if (delivered) sent++;
    else skipped++;
  }

  return { sent, skipped, considered: reminders.length };
}
