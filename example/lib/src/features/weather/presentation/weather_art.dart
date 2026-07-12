import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';
import 'package:flutter/material.dart';

class WeatherArt extends StatelessWidget {
  const WeatherArt({required this.weather, super.key});
  final Weather weather;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Text(
      key: const Key('weather-art'),
      _emoji,
      style: const TextStyle(fontSize: 112),
    ),
  );

  String get _emoji => switch (weather.condition) {
    WeatherCondition.clear => weather.isDay ? '☀️' : '🌙',
    WeatherCondition.partlyCloudy => weather.isDay ? '🌤️' : '☁️',
    WeatherCondition.overcast => '☁️',
    WeatherCondition.fog => '🌫️',
    WeatherCondition.drizzle || WeatherCondition.rainShowers => '🌦️',
    WeatherCondition.rain => '🌧️',
    WeatherCondition.snow || WeatherCondition.snowShowers => '🌨️',
    WeatherCondition.thunderstorm => '⛈️',
    WeatherCondition.unknown => '🌡️',
  };
}
