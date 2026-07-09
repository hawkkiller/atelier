class GeocodingResultDto {
  const GeocodingResultDto({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  factory GeocodingResultDto.fromJson(Map<String, Object?> json) {
    return GeocodingResultDto(
      name: json['name'] as String,
      country: json['country'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  final String name;
  final String country;
  final double latitude;
  final double longitude;
}
