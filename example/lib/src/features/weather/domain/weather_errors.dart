class WeatherNotFoundException implements Exception {
  const WeatherNotFoundException();
}

class WeatherServiceException implements Exception {
  const WeatherServiceException(this.message);

  final String message;

  @override
  String toString() => 'WeatherServiceException: $message';
}
