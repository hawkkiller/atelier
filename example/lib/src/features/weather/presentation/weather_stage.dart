import 'package:atelier_weather_example/src/features/weather/presentation/weather_art.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_theme.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_view_model.dart';
import 'package:flutter/material.dart';

class WeatherStage extends StatelessWidget {
  const WeatherStage({required this.state, required this.onRetry, super.key});

  final WeatherState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final weather = state.weather;
    return AnimatedContainer(
      key: const Key('weather-stage'),
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 500),
      height: 440,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: WeatherColors.gradient(weather),
        ),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .32),
            blurRadius: 54,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Stack(
          children: [
            if (weather != null)
              Positioned(
                right: 20,
                top: 52,
                child: Opacity(
                  opacity: state.loadStatus == WeatherLoadStatus.loading
                      ? .45
                      : 1,
                  child: WeatherArt(weather: weather),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: SingleChildScrollView(
                child: weather == null
                    ? _WithoutWeather(state: state, onRetry: onRetry)
                    : _WeatherResult(state: state, onRetry: onRetry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WithoutWeather extends StatelessWidget {
  const _WithoutWeather({required this.state, required this.onRetry});

  final WeatherState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == WeatherLoadStatus.loading ||
        state.loadStatus == WeatherLoadStatus.idle) {
      return Semantics(
        liveRegion: true,
        label: state.requestedCity.isEmpty
            ? 'Loading weather'
            : 'Checking ${state.requestedCity}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CURRENT CONDITIONS',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 150),
            Container(width: 180, height: 18, decoration: _skeleton()),
            const SizedBox(height: 18),
            Container(width: 230, height: 92, decoration: _skeleton()),
            const SizedBox(height: 22),
            Text(
              state.requestedCity.isEmpty
                  ? 'Loading weather…'
                  : 'Checking ${state.requestedCity}…',
              style: const TextStyle(color: WeatherColors.muted),
            ),
          ],
        ),
      );
    }
    return _StatusMessage(status: state.loadStatus, onRetry: onRetry);
  }

  BoxDecoration _skeleton() => BoxDecoration(
    color: Colors.white.withValues(alpha: .13),
    borderRadius: BorderRadius.circular(12),
  );
}

class _WeatherResult extends StatelessWidget {
  const _WeatherResult({required this.state, required this.onRetry});

  final WeatherState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final weather = state.weather!;
    final temperature = weather.temperature.round();
    return Semantics(
      liveRegion: true,
      label:
          '${weather.city}, $temperature degrees Celsius, ${weather.description}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'CURRENT CONDITIONS',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (state.loadStatus == WeatherLoadStatus.loading) ...[
                const SizedBox(width: 12),
                Semantics(
                  label: 'Updating weather',
                  child: const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                const SizedBox(width: 7),
                const Text('Updating…', style: TextStyle(fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 150),
          Text(
            weather.city,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          ExcludeSemantics(
            child: Text(
              '$temperature°',
              key: const Key('temperature'),
              style: const TextStyle(
                fontSize: 112,
                height: .95,
                letterSpacing: -7,
                fontWeight: FontWeight.w200,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            weather.description,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w500),
          ),
          if (state.loadStatus == WeatherLoadStatus.notFound ||
              state.loadStatus == WeatherLoadStatus.serviceUnavailable) ...[
            const SizedBox(height: 22),
            _StatusMessage(status: state.loadStatus, onRetry: onRetry),
          ],
        ],
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.status, required this.onRetry});

  final WeatherLoadStatus status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (title, body, retry) = switch (status) {
      WeatherLoadStatus.emptyInput => (
        'Enter a city',
        'Enter a city to see current conditions.',
        false,
      ),
      WeatherLoadStatus.notFound => (
        'We couldn’t find that place.',
        'Check the spelling or try a nearby city.',
        true,
      ),
      _ => (
        'Weather is unavailable right now.',
        'Check your connection and try again.',
        true,
      ),
    };
    return Semantics(
      liveRegion: true,
      label: '$title $body',
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xff111a29).withValues(alpha: .72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: .14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(body, style: const TextStyle(color: WeatherColors.muted)),
            if (retry) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                key: const Key('retry-weather'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
