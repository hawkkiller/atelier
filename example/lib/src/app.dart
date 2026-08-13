import 'package:atelier_weather_example/src/features/weather/presentation/weather_screen.dart';
import 'package:atelier_weather_example/src/features/weather/data/repositories/open_meteo_weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final WeatherRepository weatherRepository = OpenMeteoWeatherRepository();

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(textTheme: GoogleFonts.archivoBlackTextTheme()),
      home: WeatherScreen(repository: weatherRepository),
    );
  }
}
