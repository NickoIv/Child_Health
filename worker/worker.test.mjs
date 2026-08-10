import assert from 'node:assert/strict';
import { test, describe } from 'node:test';

import { plain, pushOutcome, settledAfter, titleFor } from './notifications.js';
import { escapeHtml, letter } from './invites.js';

// The Worker had no tests at all, and it is the least forgiving code in the
// project: it holds the one real secret, it bypasses the Firestore rules by
// design, and everything it does happens while nobody is watching. What
// follows covers the pure decisions — the parts where a mistake is silent.

describe('whether a push is worth trying again', () => {
  test('a delivered push is done', () => {
    assert.equal(pushOutcome(200), 'ok');
    assert.equal(pushOutcome(204), 'ok');
  });

  test('a dropped subscription is done too, differently', () => {
    // The browser threw the subscription away. Another hour changes nothing.
    for (const status of [400, 403, 404]) {
      assert.equal(pushOutcome(status), 'dead', `status ${status}`);
    }
  });

  test('anything transient is worth another hour', () => {
    for (const status of [429, 500, 502, 503]) {
      assert.equal(pushOutcome(status), 'retry', `status ${status}`);
    }
  });
});

describe('whether the reminder is finished with', () => {
  test('nothing to send to is finished', () => {
    // No devices registered. Marked so it does not queue up and arrive in a
    // burst the day notifications are switched on.
    assert.equal(settledAfter([]), true);
  });

  test('one delivery is enough, whatever the other phones did', () => {
    assert.equal(settledAfter(['retry', 'ok']), true);
    assert.equal(settledAfter(['dead', 'ok']), true);
  });

  test('all subscriptions dead is finished', () => {
    assert.equal(settledAfter(['dead', 'dead']), true);
  });

  test('one transient failure keeps it for the next sweep', () => {
    // The bug this whole pair of functions was written for: marking it here
    // meant a single five-hundred from FCM lost a vaccination reminder
    // permanently, and silently.
    assert.equal(settledAfter(['retry']), false);
    assert.equal(settledAfter(['dead', 'retry']), false);
  });
});

describe('what the lock screen says', () => {
  test('names the child', () => {
    assert.equal(titleFor('vaccination', 'Миша'), 'Миша: сегодня прививка');
    assert.equal(titleFor('medication', 'Миша'), 'Миша: лекарство по времени');
  });

  test('never bends the name into a case', () => {
    // The first version of this said «Сегодня прививка у Миша» — the genitive
    // that Russian wants and that no rule gets right for «Айжан», «Нурлан» or
    // anything a parent types in. The sentence is built so the question never
    // comes up, and every name appears exactly as she wrote it.
    for (const name of ['Миша', 'Айжан', 'Нурлан', 'Miguel', 'Гүлнұр']) {
      const title = titleFor('vaccination', name);
      assert.ok(title.startsWith(`${name}:`), title);
    }
  });

  test('still says something useful without a name', () => {
    // The name lookup is allowed to fail; the reminder still goes out.
    assert.equal(titleFor('vaccination', null), 'Сегодня прививка');
    assert.equal(titleFor('medication', null), 'Лекарство по времени');
    assert.equal(titleFor('appointment', null), 'Сегодня визит к врачу');
  });

  test('never gives an order', () => {
    // «Пора» tells a mother she is late for something the app cannot know
    // she is late for.
    for (const type of ['vaccination', 'medication', 'appointment']) {
      assert.ok(!titleFor(type, 'Миша').includes('Пора'), type);
    }
  });
});

describe('Firestore values', () => {
  test('unwrap to the plain thing', () => {
    assert.equal(plain({ stringValue: 'Миша' }), 'Миша');
    assert.equal(plain({ integerValue: '42' }), 42);
    assert.equal(plain({ booleanValue: false }), false);
  });

  test('are null when the field is absent', () => {
    // getChildName reads doc.fields?.name on a document that may have none.
    assert.equal(plain(undefined), null);
    assert.equal(plain(null), null);
  });

  test('come back out of arrays and maps', () => {
    assert.deepEqual(
      plain({ arrayValue: { values: [{ stringValue: 'a' }] } }),
      ['a'],
    );
    assert.deepEqual(
      plain({ mapValue: { fields: { on: { booleanValue: true } } } }),
      { on: true },
    );
  });
});

describe('the invitation letter', () => {
  test('carries the address to sign in with and the link', () => {
    const mail = letter({
      childName: 'Миша',
      email: 'dad@example.com',
      link: 'https://example.app',
      fromName: 'Аня',
    });

    assert.ok(mail.html.includes('dad@example.com'));
    assert.ok(mail.html.includes('https://example.app'));
    assert.ok(mail.text.includes('https://example.app'));
    assert.ok(mail.subject.includes('Миша'));
  });

  test('works when nobody filled in a name to send it from', () => {
    const mail = letter({
      childName: 'Миша',
      email: 'dad@example.com',
      link: 'https://example.app',
      fromName: '',
    });
    assert.ok(mail.text.startsWith('Вам открыли доступ'));
    assert.ok(!mail.html.includes('undefined'));
  });

  test('cannot be made to carry markup through a child\'s name', () => {
    // The name is whatever she typed into a profile field, and it lands in
    // an HTML document sent to somebody else's inbox.
    const mail = letter({
      childName: '<script>alert(1)</script>',
      email: 'dad@example.com',
      link: 'https://example.app',
      fromName: '"><b>',
    });

    assert.ok(!mail.html.includes('<script>'));
    assert.ok(mail.html.includes('&lt;script&gt;'));
    assert.ok(!mail.html.includes('"><b>'));
  });

  test('escapes the four characters that matter', () => {
    assert.equal(escapeHtml('<&>"'), '&lt;&amp;&gt;&quot;');
  });
});
