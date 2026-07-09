import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';

abstract interface class WeatherRepository {
  Future<List<String>> search(
    String query, {
    required CancellationToken cancellationToken,
  });

  Future<Weather> load(
    String city, {
    required CancellationToken cancellationToken,
  });

  void close();
}
