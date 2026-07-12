class Weather {
  const Weather({
    required this.city,
    required this.temperature,
    required this.description,
    required this.condition,
    required this.isDay,
  });

  final String city;
  final double temperature;
  final String description;
  final WeatherCondition condition;
  final bool isDay;
}

enum WeatherCondition {
  clear,
  partlyCloudy,
  overcast,
  fog,
  drizzle,
  rain,
  snow,
  rainShowers,
  snowShowers,
  thunderstorm,
  unknown,
}
