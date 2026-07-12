import 'dart:async';

import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/data/repositories/open_meteo_weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('searches city suggestions from Open-Meteo geocoding', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'geocoding-api.open-meteo.com');
      expect(request.url.queryParameters['name'], 'War');
      expect(request.url.queryParameters['count'], '5');
      return http.Response('''
        {
          "results": [
            {"name": "Warsaw", "country": "Poland", "latitude": 52.2, "longitude": 21.0},
            {"name": "War", "latitude": 1, "longitude": 2}
          ]
        }
        ''', 200);
    });
    final repository = OpenMeteoWeatherRepository(client: client);

    final suggestions = await repository.search(
      'War',
      cancellationToken: _NeverCancelledToken(),
    );

    expect(suggestions, ['Warsaw, Poland', 'War']);
    repository.close();
  });

  test('loads and maps current weather from Open-Meteo responses', () async {
    final requestedHosts = <String>[];
    final client = MockClient((request) async {
      requestedHosts.add(request.url.host);

      if (request.url.host == 'geocoding-api.open-meteo.com') {
        expect(request.url.queryParameters['name'], 'Warsaw');
        return http.Response('''
          {
            "results": [
              {
                "name": "Warsaw",
                "country": "Poland",
                "latitude": 52.2298,
                "longitude": 21.0118
              }
            ]
          }
          ''', 200);
      }

      expect(request.url.host, 'api.open-meteo.com');
      expect(
        request.url.queryParameters['current'],
        'temperature_2m,weather_code,is_day',
      );
      return http.Response('''
        {
          "current": {
            "temperature_2m": 22.4,
            "weather_code": 2,
            "is_day": 1
          }
        }
        ''', 200);
    });
    final repository = OpenMeteoWeatherRepository(client: client);

    final weather = await repository.load(
      'Warsaw',
      cancellationToken: _NeverCancelledToken(),
    );

    expect(requestedHosts, [
      'geocoding-api.open-meteo.com',
      'api.open-meteo.com',
    ]);
    expect(weather.city, 'Warsaw, Poland');
    expect(weather.temperature, 22.4);
    expect(weather.description, 'Partly cloudy');
    expect(weather.condition, WeatherCondition.partlyCloudy);
    expect(weather.isDay, isTrue);

    repository.close();
  });

  test('maps clear night without an emoji presentation dependency', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'geocoding-api.open-meteo.com') {
        return http.Response(
          '{"results":[{"name":"Reykjavik","country":"Iceland","latitude":64.1,"longitude":-21.9}]}',
          200,
        );
      }
      return http.Response(
        '{"current":{"temperature_2m":4,"weather_code":0,"is_day":0}}',
        200,
      );
    });
    final repository = OpenMeteoWeatherRepository(client: client);

    final weather = await repository.load(
      'Reykjavik',
      cancellationToken: _NeverCancelledToken(),
    );

    expect(weather.condition, WeatherCondition.clear);
    expect(weather.description, 'Clear sky');
    expect(weather.isDay, isFalse);
    repository.close();
  });
}

final class _NeverCancelledToken implements CancellationToken {
  final Completer<void> _cancelled = Completer<void>();

  @override
  bool get isCancelled => false;

  @override
  Future<void> get cancelled => _cancelled.future;

  @override
  void throwIfCancelled() {}
}
