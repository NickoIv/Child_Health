import 'package:child_health_tracker/core/family/invite_mail.dart';
import 'package:child_health_tracker/core/family/phone.dart';
import 'package:flutter_test/flutter_test.dart';

/// The number a parent types, and the one WhatsApp needs.
///
/// GREEN-API addresses a chat as `77001234567@c.us` — digits only, country
/// code first. Nobody writes a number that way. What they write is «+7 700
/// 123-45-67» or «8 (700) 1234567» or something pasted out of a contact card
/// with a non-breaking space in it, and all of them mean the same person, so
/// all of them have to work.
void main() {
  group('the number', () {
    test('loses everything that is not a digit', () {
      expect(normalizePhone('+7 700 123-45-67'), '77001234567');
      expect(normalizePhone('7 (700) 123 45 67'), '77001234567');
      expect(normalizePhone('+7 700 1234567'), '77001234567');
    });

    test('turns the domestic 8 into the international 7', () {
      // The same number, written the way it is written on a fridge.
      expect(normalizePhone('8 700 123 45 67'), '77001234567');
      expect(normalizePhone('87001234567'), '77001234567');
    });

    test('adds the country code when it was left off', () {
      expect(normalizePhone('7001234567'), '77001234567');
    });

    test('leaves a foreign number alone', () {
      // Twelve digits starting with 4 is not a Kazakh number missing its
      // code, and rewriting it would be the app guessing at a country.
      expect(normalizePhone('+49 151 23456789'), '4915123456789');
    });

    test('is nothing when there is nothing', () {
      expect(normalizePhone(''), '');
      expect(normalizePhone('   '), '');
      expect(normalizePhone('—'), '');
    });
  });

  group('whether it could be dialled', () {
    test('accepts what people actually type', () {
      for (final raw in const [
        '+7 700 123-45-67',
        '87001234567',
        '7001234567',
        '+49 151 23456789',
      ]) {
        expect(looksLikePhone(raw), isTrue, reason: raw);
      }
    });

    test('refuses what cannot be a number', () {
      for (final raw in const ['', '123', '700123', 'не помню']) {
        expect(looksLikePhone(raw), isFalse, reason: raw);
      }
    });

    test('and does not pretend to know more than the parent does', () {
      // Ten to fifteen digits covers every numbering plan there is. An app
      // that refuses her husband's number over a format rule is an app that
      // refuses to send the invitation.
      expect(looksLikePhone('12345678901234'), isTrue);
      expect(looksLikePhone('1234567890123456'), isFalse);
    });
  });

  group('the WhatsApp handoff', () {
    // The delivery that does not depend on anything staying configured. The
    // Worker's own send needs a GREEN-API account that can lapse and a mail
    // key this build does not have; this needs a phone with WhatsApp on it.
    test('addresses the chat with the normalised number', () {
      final link = whatsAppLink(phone: '8 700 123 45 67', message: 'привет');
      expect(link, startsWith('https://wa.me/77001234567?text='));
    });

    test('opens WhatsApp with no recipient when there is no number', () {
      // She invited by email only. WhatsApp opens on the chat list with the
      // message ready, and she picks who it goes to.
      final link = whatsAppLink(phone: '', message: 'привет');
      expect(link, startsWith('https://wa.me/?text='));
    });

    test('carries the message intact, spaces and Cyrillic and all', () {
      const message =
          'Я открыл доступ к дневнику ребёнка (Маус). Войди почтой a@b.kz: '
          'https://child-health-tracker-7aad1.web.app';
      final link = whatsAppLink(phone: '77001234567', message: message);

      // A space written as `+` is a space only to something that knows it is
      // reading a query parameter. WhatsApp shows this to a person.
      expect(link, isNot(contains('+')));
      expect(link, contains('%20'));
      expect(
        Uri.decodeComponent(link.split('?text=').last),
        message,
        reason: 'what she sends is what was written',
      );
    });
  });

  group('the link the invitation carries', () {
    test('never throws off the web, where Uri.base is a file path', () {
      // `Uri.base.origin` throws for any scheme that is not http, and in a
      // test Uri.base is file:///. It threw once and the invitation reported
      // a failure it had not had.
      final link = appLink();
      expect(link, startsWith('https://'));
      expect(link, isNot(contains('file:')));
    });
  });
}
