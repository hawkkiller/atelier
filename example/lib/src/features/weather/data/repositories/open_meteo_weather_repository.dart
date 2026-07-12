import 'dart:convert';

import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/data/models/current_weather_dto.dart';
import 'package:atelier_weather_example/src/features/weather/data/models/geocoding_result_dto.dart';
import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/weather_errors.dart';
import 'package:http/http.dart' as http;

class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<String>> search(
    String query, {
    required CancellationToken cancellationToken,
  }) async {
    final locations = await _findLocations(query, 5, cancellationToken);
    return [for (final location in locations) _placeName(location)];
  }

  @override
  Future<Weather> load(
    String city, {
    required CancellationToken cancellationToken,
  }) async {
    final location = await _findLocations(
      city,
      1,
      cancellationToken,
    ).then((locations) => locations.first);
    cancellationToken.throwIfCancelled();

    final current = await _loadCurrentWeather(location, cancellationToken);
    final condition = _conditionFor(current.weatherCode);

    return Weather(
      city: _placeName(location),
      temperature: current.temperature,
      description: condition.description,
      condition: condition.condition,
      isDay: current.isDay,
    );
  }

  Future<List<GeocodingResultDto>> _findLocations(
    String query,
    int count,
    CancellationToken cancellationToken,
  ) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query,
      'count': '$count',
      'language': 'en',
      'format': 'json',
    });
    final json = await _getJson(uri, cancellationToken);
    final results = json['results'];
    if (results is! List<Object?> || results.isEmpty) {
      throw const WeatherNotFoundException();
    }

    try {
      return [
        for (final result in results)
          GeocodingResultDto.fromJson(
            Map<String, Object?>.from(result! as Map),
          ),
      ];
    } on Object catch (error) {
      throw WeatherServiceException(
        'The geocoding response was invalid: $error',
      );
    }
  }

  Future<CurrentWeatherDto> _loadCurrentWeather(
    GeocodingResultDto location,
    CancellationToken cancellationToken,
  ) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': location.latitude.toString(),
      'longitude': location.longitude.toString(),
      'current': 'temperature_2m,weather_code,is_day',
      'timezone': 'auto',
    });
    final json = await _getJson(uri, cancellationToken);

    try {
      return CurrentWeatherDto.fromJson(
        Map<String, Object?>.from(json['current']! as Map),
      );
    } on Object catch (error) {
      throw WeatherServiceException('The weather response was invalid: $error');
    }
  }

  Future<Map<String, Object?>> _getJson(
    Uri uri,
    CancellationToken cancellationToken,
  ) async {
    cancellationToken.throwIfCancelled();

    try {
      final request = http.AbortableRequest(
        'GET',
        uri,
        abortTrigger: cancellationToken.cancelled,
      );
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      cancellationToken.throwIfCancelled();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw WeatherServiceException(
          'Open-Meteo returned HTTP ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw const WeatherServiceException(
          'Open-Meteo returned an invalid JSON document.',
        );
      }
      return Map<String, Object?>.from(decoded);
    } on http.RequestAbortedException {
      cancellationToken.throwIfCancelled();
      rethrow;
    } on WeatherServiceException {
      rethrow;
    } on Object catch (error) {
      cancellationToken.throwIfCancelled();
      throw WeatherServiceException('Could not reach Open-Meteo: $error');
    }
  }

  String _placeName(GeocodingResultDto location) {
    return location.country.isEmpty
        ? location.name
        : '${location.name}, ${location.country}';
  }

  _WeatherConditionMapping _conditionFor(int code) {
    return switch (code) {
      0 => const _WeatherConditionMapping(WeatherCondition.clear, 'Clear sky'),
      1 || 2 => const _WeatherConditionMapping(
        WeatherCondition.partlyCloudy,
        'Partly cloudy',
      ),
      3 => const _WeatherConditionMapping(
        WeatherCondition.overcast,
        'Overcast',
      ),
      45 || 48 => const _WeatherConditionMapping(WeatherCondition.fog, 'Foggy'),
      >= 51 && <= 57 => const _WeatherConditionMapping(
        WeatherCondition.drizzle,
        'Drizzle',
      ),
      >= 61 && <= 67 => const _WeatherConditionMapping(
        WeatherCondition.rain,
        'Rain',
      ),
      >= 71 && <= 77 => const _WeatherConditionMapping(
        WeatherCondition.snow,
        'Snow',
      ),
      >= 80 && <= 82 => const _WeatherConditionMapping(
        WeatherCondition.rainShowers,
        'Rain showers',
      ),
      85 || 86 => const _WeatherConditionMapping(
        WeatherCondition.snowShowers,
        'Snow showers',
      ),
      >= 95 => const _WeatherConditionMapping(
        WeatherCondition.thunderstorm,
        'Thunderstorm',
      ),
      _ => const _WeatherConditionMapping(
        WeatherCondition.unknown,
        'Unknown conditions',
      ),
    };
  }

  @override
  void close() {
    _client.close();
  }
}

class _WeatherConditionMapping {
  const _WeatherConditionMapping(this.condition, this.description);

  final WeatherCondition condition;
  final String description;
}
