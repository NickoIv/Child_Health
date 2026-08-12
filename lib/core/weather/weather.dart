/// What it is like outside, for the one question the app could not answer.
///
/// «Можно ли сегодня гулять» is asked more often than almost anything else
/// here, and until now the assistant answered it out of general knowledge
/// about a city it did not know, on a day it could not see. It is also the
/// question where being wrong is expensive in both directions: a walk skipped
/// on a mild day, or a newborn taken out at minus twenty.
///
/// Three decisions hold this to the rest of the app:
///
/// **Nothing is fetched unless the question is about it.** [asksAboutWeather]
/// runs on the device against her own words, and only then is a location
/// asked for. A parent who never asks about a walk is never prompted for
/// permission and her coordinates never leave the phone.
///
/// **The provider needs no key and no account.** Open-Meteo is free for
/// non-commercial use, has no sign-up and permits browser requests, which is
/// what makes this shippable at all — the same reason the knowledge base is
/// compiled in rather than hosted.
///
/// **It is a fact, not advice.** What reaches the model is the temperature,
/// what it feels like, the wind and the sky. Whether to go out is the
/// parent's, and the prompt says so.
library;

/// A reading, as the prompt will state it.
class Weather {
  const Weather({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.windMs,
    required this.code,
    this.minC,
    this.maxC,
  });

  final double temperatureC;

  /// What it feels like with the wind and the humidity in it — the number
  /// that decides how a child is dressed, and the one nobody reads off a
  /// thermometer.
  final double feelsLikeC;

  final double windMs;

  /// WMO code, as Open-Meteo reports it.
  final int code;

  final double? minC;
  final double? maxC;

  /// The sky in one word.
  String get sky => switch (code) {
    0 => 'ясно',
    1 || 2 => 'переменная облачность',
    3 => 'пасмурно',
    45 || 48 => 'туман',
    51 || 53 || 55 || 56 || 57 => 'морось',
    61 || 63 || 80 || 81 => 'дождь',
    65 || 82 => 'сильный дождь',
    66 || 67 => 'ледяной дождь',
    71 || 73 || 85 => 'снег',
    75 || 86 => 'сильный снег',
    77 => 'снежная крупа',
    95 || 96 || 99 => 'гроза',
    _ => 'без осадков',
  };
}

/// The reading, written for the prompt.
///
/// The apparent temperature is named as such rather than folded into the
/// first number: «-8, ощущается как -14» is the difference between a coat and
/// a coat with a blanket over it, and a model given one figure will use it for
/// both.
String weatherContext(Weather w) {
  final parts = <String>[
    'сейчас ${_round(w.temperatureC)} °C',
    'ощущается как ${_round(w.feelsLikeC)} °C',
    w.sky,
    'ветер ${w.windMs.toStringAsFixed(0)} м/с',
  ];

  final range = w.minC != null && w.maxC != null
      ? ', за день от ${_round(w.minC!)} до ${_round(w.maxC!)} °C'
      : '';

  return 'ПОГОДА НА УЛИЦЕ: ${parts.join(', ')}$range.';
}

String _round(double v) => v.round().toString();

/// Open-Meteo's answer, or null if it is not the shape we asked for.
///
/// Null rather than an exception on every branch: a question about a walk
/// must still be answered when the weather service is down, just without the
/// figures.
Weather? weatherFromJson(Map<String, dynamic> json) {
  final current = json['current'];
  if (current is! Map) return null;

  final temperature = _double(current['temperature_2m']);
  if (temperature == null) return null;

  final daily = json['daily'];
  final mins = daily is Map ? daily['temperature_2m_min'] : null;
  final maxs = daily is Map ? daily['temperature_2m_max'] : null;

  return Weather(
    temperatureC: temperature,
    // Falls back to the plain reading: a missing apparent temperature is
    // better stated as the real one than dropped, and on a still day they
    // are the same number anyway.
    feelsLikeC: _double(current['apparent_temperature']) ?? temperature,
    windMs: _double(current['wind_speed_10m']) ?? 0,
    code: _double(current['weather_code'])?.round() ?? -1,
    minC: mins is List && mins.isNotEmpty ? _double(mins.first) : null,
    maxC: maxs is List && maxs.isNotEmpty ? _double(maxs.first) : null,
  );
}

double? _double(Object? value) => switch (value) {
  final num v => v.toDouble(),
  final String v => double.tryParse(v),
  _ => null,
};

/// Whether her sentence is about going outside.
///
/// The gate on the whole feature. Matched on stems rather than whole words —
/// «гулять», «погуляем», «прогулка» and «выгуливать» are one question — and
/// deliberately generous: the cost of a false positive is one silent request
/// for a location she can refuse, and the cost of a false negative is the
/// answer she asked for arriving without the figures.
bool asksAboutWeather(String text) {
  final lower = text.toLowerCase().replaceAll('ё', 'е');
  return _outdoors.any(lower.contains);
}

const _outdoors = <String>[
  'гуля',
  'прогул',
  'погод',
  'на улиц',
  'на улице',
  'во двор',
  'одеть',
  'одевать',
  'одеваться',
  'холодно',
  'мороз',
  'жарко',
  'дожд',
  'ветер',
  'снег',
  'коляск',
  'weather',
  'walk',
  'outside',
];
