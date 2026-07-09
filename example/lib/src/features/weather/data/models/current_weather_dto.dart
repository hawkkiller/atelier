class CurrentWeatherDto {
  const CurrentWeatherDto({
    required this.temperature,
    required this.weatherCode,
    required this.isDay,
  });

  factory CurrentWeatherDto.fromJson(Map<String, Object?> json) {
    return CurrentWeatherDto(
      temperature: (json['temperature_2m'] as num).toDouble(),
      weatherCode: (json['weather_code'] as num).toInt(),
      isDay: (json['is_day'] as num).toInt() == 1,
    );
  }

  final double temperature;
  final int weatherCode;
  final bool isDay;
}
