import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_screen.dart';
import 'package:flutter/material.dart';

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key, this.repository});

  final WeatherRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atelier Weather',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: WeatherScreen(repository: repository),
    );
  }
}
