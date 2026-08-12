import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'place.dart';
import 'weather.dart';
import 'where.dart';

/// Open-Meteo. No key, no account, and it allows browser requests — which is
/// the whole reason this ships at all, the same reason the knowledge base is
/// compiled in rather than hosted.
const _endpoint = 'https://api.open-meteo.com/v1/forecast';

/// How long a reading stands.
///
/// Fifteen minutes. The weather does not turn in less, and a parent who asks
/// twice while dressing a child should not send two requests.
const weatherTtl = Duration(minutes: 15);

/// Long enough for a slow morning network, short enough that an answer is
/// never held up by it: the question is answered without figures rather than
/// late.
const weatherTimeout = Duration(seconds: 8);

/// The reading, fetched when a question is about going outside.
class WeatherService {
  WeatherService({
    http.Client? client,
    Future<Place?> Function()? locate,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _locate = locate ?? currentPlace;

  final http.Client _client;

  /// Closed on dispose only when this made it: a client handed in by a test
  /// belongs to the test.
  final bool _ownsClient;
  final Future<Place?> Function() _locate;

  Weather? _cached;
  DateTime? _at;

  /// Null on anything at all going wrong — refused location, no network, a
  /// shape we did not expect. Never throws: the answer matters more than the
  /// figures, and a question about a walk must survive a weather service
  /// being down.
  Future<Weather?> current({DateTime? now}) async {
    final moment = now ?? DateTime.now();
    final at = _at;
    if (_cached != null && at != null && moment.difference(at) < weatherTtl) {
      return _cached;
    }

    final place = await _locate();
    if (place == null) return null;

    try {
      final uri = Uri.parse(_endpoint).replace(
        queryParameters: {
          'latitude': place.latitude.toString(),
          'longitude': place.longitude.toString(),
          'current':
              'temperature_2m,apparent_temperature,wind_speed_10m,weather_code',
          'daily': 'temperature_2m_max,temperature_2m_min',
          'wind_speed_unit': 'ms',
          'timezone': 'auto',
          'forecast_days': '1',
        },
      );

      final response = await _client.get(uri).timeout(weatherTimeout);
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;

      final weather = weatherFromJson(decoded);
      if (weather != null) {
        _cached = weather;
        _at = moment;
      }
      return weather;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}

final weatherServiceProvider = Provider<WeatherService>((ref) {
  final service = WeatherService();
  ref.onDispose(service.dispose);
  return service;
});
