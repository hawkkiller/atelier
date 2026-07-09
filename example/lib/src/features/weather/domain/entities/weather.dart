class Weather {
  const Weather({
    required this.city,
    required this.temperature,
    required this.description,
    required this.icon,
  });

  final String city;
  final double temperature;
  final String description;
  final String icon;
}
