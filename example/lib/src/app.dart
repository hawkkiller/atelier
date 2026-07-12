import 'package:atelier_weather_example/src/features/weather/presentation/weather_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(textTheme: GoogleFonts.archivoBlackTextTheme()),
      home: WeatherScreen(),
    );
  }
}
