import 'dart:convert';

import 'package:child_health_tracker/core/weather/place.dart';
import 'package:child_health_tracker/core/weather/weather.dart';
import 'package:child_health_tracker/core/weather/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The one live fact the app fetches, and the gate that keeps it from
/// fetching it.
///
/// «Пойти на прогулку, а он даже про погоду сказать не может.» What matters
/// most below is not the parsing — it is that a location is never asked for
/// unless the question was about going outside, and that every failure costs
/// the figures and never the answer.
void main() {
  const body = '''
{
  "current": {
    "temperature_2m": -7.4,
    "apparent_temperature": -13.8,
    "wind_speed_10m": 4.2,
    "weather_code": 71
  },
  "daily": {
    "temperature_2m_max": [-4.1],
    "temperature_2m_min": [-11.6]
  }
}
''';

  group('the gate', () {
    test('opens on the ways a parent asks about going out', () {
      for (final question in const [
        'можно сегодня гулять?',
        'Погуляем во дворе или холодно',
        'как одеть на улицу',
        'какая погода',
        'на улице дождь?',
        'мороз, идти в коляске?',
      ]) {
        expect(asksAboutWeather(question), isTrue, reason: question);
      }
    });

    test('stays shut on everything else', () {
      // Every one of these must leave her coordinates on the phone.
      for (final question in const [
        'сколько раз кормить в три месяца',
        'он третью ночь плохо спит',
        'запиши температуру 37.8',
        'что делать при коликах',
      ]) {
        expect(asksAboutWeather(question), isFalse, reason: question);
      }
    });

    test('and reads «ё» the way people type it', () {
      expect(asksAboutWeather('сколько гулять в мороз'), isTrue);
    });
  });

  group('a place', () {
    test('is rounded before it can go anywhere', () {
      // About a kilometre. Enough for a temperature, not enough for an
      // address.
      const exact = Place(43.238293, 76.945465);
      expect(exact.coarse.latitude, 43.24);
      expect(exact.coarse.longitude, 76.95);
    });
  });

  group('the reading', () {
    test('keeps what it feels like apart from what it is', () {
      // «-7, ощущается как -14» is the difference between a coat and a coat
      // with a blanket over it, and a model given one figure uses it for both.
      final w = weatherFromJson(jsonDecode(body) as Map<String, dynamic>)!;
      expect(w.temperatureC, -7.4);
      expect(w.feelsLikeC, -13.8);
      expect(w.sky, 'снег');

      final line = weatherContext(w);
      expect(line, contains('-7'));
      expect(line, contains('ощущается как -14'));
      expect(line, contains('снег'));
      expect(line, contains('от -12 до -4'));
    });

    test('falls back to the real temperature when there is no apparent one', () {
      final w = weatherFromJson({
        'current': {'temperature_2m': 18.0},
      })!;
      expect(w.feelsLikeC, 18.0);
    });

    test('is nothing at all when the shape is not what we asked for', () {
      expect(weatherFromJson({'error': true}), isNull);
      expect(weatherFromJson({'current': 'sunny'}), isNull);
    });
  });

  group('fetching', () {
    Future<Weather?> fetch({
      required Place? place,
      required http.Client client,
      DateTime? now,
    }) => WeatherService(client: client, locate: () async => place)
        .current(now: now);

    test('asks for the point it was given and reads the answer', () async {
      Uri? asked;
      final client = MockClient((request) async {
        asked = request.url;
        return http.Response(body, 200, headers: const {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final w = await fetch(place: const Place(43.24, 76.95), client: client);
      expect(w?.temperatureC, -7.4);
      expect(asked!.queryParameters['latitude'], '43.24');
      expect(asked!.queryParameters['wind_speed_unit'], 'ms');
    });

    test('never asks at all when the location was refused', () async {
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });

      expect(await fetch(place: null, client: client), isNull);
      expect(called, isFalse, reason: 'a refusal must send nothing');
    });

    test('a failing service costs the figures and not the answer', () async {
      final down = MockClient((_) async => http.Response('nope', 503));
      expect(await fetch(place: const Place(1, 1), client: down), isNull);

      final broken = MockClient((_) async => http.Response('not json', 200));
      expect(await fetch(place: const Place(1, 1), client: broken), isNull);
    });

    test('a second question in the same quarter hour sends nothing', () async {
      // She asks twice while dressing a child; that is one request.
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response(body, 200, headers: const {
          'content-type': 'application/json; charset=utf-8',
        });
      });
      final service = WeatherService(
        client: client,
        locate: () async => const Place(43.24, 76.95),
      );

      final start = DateTime(2026, 1, 20, 9);
      await service.current(now: start);
      await service.current(now: start.add(const Duration(minutes: 5)));
      expect(requests, 1);

      await service.current(now: start.add(weatherTtl * 2));
      expect(requests, 2);
    });
  });
}
