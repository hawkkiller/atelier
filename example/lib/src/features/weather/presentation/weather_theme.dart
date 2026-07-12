import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';
import 'package:flutter/material.dart';

abstract final class WeatherColors {
  static const ink = Color(0xff0b1220);
  static const paper = Color(0xfff4f1e9);
  static const muted = Color(0xffaeb9ca);

  static List<Color> gradient(Weather? weather) {
    if (weather == null) return const [Color(0xff17243d), ink];
    return switch ((weather.condition, weather.isDay)) {
      (WeatherCondition.clear, true) => const [
        Color(0xff2764a8),
        Color(0xff87cde4),
      ],
      (WeatherCondition.clear, false) => const [
        Color(0xff121a39),
        Color(0xff45376f),
      ],
      (WeatherCondition.partlyCloudy, true) => const [
        Color(0xff315d87),
        Color(0xff91afbd),
      ],
      (WeatherCondition.partlyCloudy, false) => const [
        Color(0xff18233c),
        Color(0xff44506a),
      ],
      (WeatherCondition.fog, _) => const [Color(0xff526576), Color(0xff9ba8aa)],
      (
        WeatherCondition.drizzle ||
            WeatherCondition.rain ||
            WeatherCondition.rainShowers,
        _,
      ) =>
        const [Color(0xff17354a), Color(0xff42758a)],
      (WeatherCondition.snow || WeatherCondition.snowShowers, _) => const [
        Color(0xff50758d),
        Color(0xffc9e1e5),
      ],
      (WeatherCondition.thunderstorm, _) => const [
        Color(0xff211f35),
        Color(0xff594d79),
      ],
      (WeatherCondition.overcast, _) => const [
        Color(0xff34465b),
        Color(0xff718191),
      ],
      (WeatherCondition.unknown, _) => const [
        Color(0xff26364b),
        Color(0xff596778),
      ],
    };
  }
}

ThemeData weatherTheme() {
  const scheme = ColorScheme.dark(
    primary: Color(0xffffca68),
    surface: Color(0xff142035),
    onSurface: WeatherColors.paper,
    error: Color(0xffff9b91),
  );
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: WeatherColors.ink,
    textTheme: Typography.material2021(platform: TargetPlatform.macOS).white
        .apply(
          bodyColor: WeatherColors.paper,
          displayColor: WeatherColors.paper,
        ),
    focusColor: scheme.primary.withValues(alpha: .22),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: .08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .14)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xffffca68), width: 2),
      ),
    ),
  );
}
