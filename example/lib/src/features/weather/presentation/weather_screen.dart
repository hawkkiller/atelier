import 'dart:async';

import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/data/repositories/open_meteo_weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_view_model.dart';
import 'package:flutter/material.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key, this.repository});

  final WeatherRepository? repository;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with AtelierVmStateMixin<WeatherViewModel, WeatherScreen> {
  late final cityController = textController(text: 'Warsaw');
  late final WeatherRepository _repository =
      widget.repository ??
      disposeWith(
        OpenMeteoWeatherRepository(),
        (repository) => repository.close(),
      );

  @override
  WeatherViewModel createViewModel(BuildContext context) {
    return WeatherViewModel(_repository);
  }

  @override
  void initState() {
    super.initState();
    listen(viewModel.effects, (effect) {
      final message = switch (effect) {
        WeatherEmptyCity() => 'Enter a city name.',
        WeatherLocationNotFound(:final city) =>
          'No location found for “$city”.',
        WeatherServiceFailed(:final message) => message,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });
    unawaited(viewModel.load(cityController.text));
  }

  @override
  Widget build(BuildContext context) {
    final state = watch(viewModel.state);

    return Scaffold(
      appBar: AppBar(title: const Text('Atelier Weather')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'City',
                  ),
                  onChanged: (value) => unawaited(viewModel.search(value)),
                  onSubmitted: viewModel.load,
                ),
                if (state.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final suggestion in state.suggestions)
                          ListTile(
                            dense: true,
                            title: Text(suggestion),
                            onTap: () {
                              cityController.text = suggestion;
                              viewModel.load(suggestion);
                            },
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: state.isLoading
                      ? null
                      : () => viewModel.load(cityController.text),
                  child: const Text('Load weather'),
                ),
                const SizedBox(height: 32),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _WeatherContent(state: state),
                ),
                const SizedBox(height: 16),
                Text(
                  'Weather data by Open-Meteo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherContent extends StatelessWidget {
  const _WeatherContent({required this.state});

  final WeatherState state;

  @override
  Widget build(BuildContext context) {
    final weather = state.weather;
    if (state.isLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (weather == null) {
      return const SizedBox.shrink(key: ValueKey('empty'));
    }

    return Card(
      key: ValueKey(weather.city),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(weather.icon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text(
              weather.city,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${weather.temperature.round()}° C',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            Text(weather.description),
          ],
        ),
      ),
    );
  }
}
