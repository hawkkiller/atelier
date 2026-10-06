import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_search_view_model.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_view_model.dart';
import 'package:flutter/material.dart';

/// Shows the current weather for a city, with a city search below it.
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key, required this.repository});

  final WeatherRepository repository;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with AtelierVmMixin<WeatherViewModel, WeatherScreen> {
  @override
  WeatherViewModel createViewModel(BuildContext context) => WeatherViewModel(widget.repository);

  @override
  void initState() {
    super.initState();
    listen(viewModel.effects, _onEffect);
    viewModel.load('Kraków');
  }

  void _onEffect(WeatherEffect effect) {
    final message = switch (effect) {
      WeatherEffect.unexpectedFailure => 'Something went wrong. Please try again.',
    };
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = watch(viewModel.state);
    final weather = state.weather;
    final error = switch (state.loadStatus) {
      WeatherLoadStatus.notFound => 'Couldn’t find ${state.requestedCity}.',
      WeatherLoadStatus.serviceUnavailable => 'Weather is unavailable right now.',
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Weather')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (weather != null) ...[
            Text(weather.city, style: Theme.of(context).textTheme.titleLarge),
            Text('${weather.temperature.round()}° · ${weather.description}'),
          ] else if (error == null)
            const Center(child: CircularProgressIndicator()),
          if (error != null)
            Row(
              children: [
                Expanded(child: Text(error)),
                TextButton(onPressed: () => viewModel.load(state.requestedCity), child: const Text('Retry')),
              ],
            ),
          const SizedBox(height: 24),
          CitySearch(repository: widget.repository, onSelected: viewModel.load.call),
        ],
      ),
    );
  }
}

/// A search field with city suggestions; owns its own ViewModel.
class CitySearch extends StatefulWidget {
  const CitySearch({super.key, required this.repository, required this.onSelected});

  final WeatherRepository repository;
  final ValueChanged<String> onSelected;

  @override
  State<CitySearch> createState() => _CitySearchState();
}

class _CitySearchState extends State<CitySearch> with AtelierVmMixin<WeatherSearchViewModel, CitySearch> {
  late final _query = own(TextEditingController());

  @override
  WeatherSearchViewModel createViewModel(BuildContext context) => WeatherSearchViewModel(widget.repository);

  void _select(String city) {
    _query.clear();
    viewModel.search('');
    widget.onSelected(city);
  }

  @override
  Widget build(BuildContext context) {
    final state = watch(viewModel.state);
    final searching = watch(viewModel.search.isRunning);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _query,
          decoration: const InputDecoration(hintText: 'Search for a city'),
          onChanged: viewModel.search.call,
        ),
        if (searching) const LinearProgressIndicator(),
        if (state.failed)
          ListTile(
            title: const Text('Search is unavailable'),
            trailing: TextButton(onPressed: () => viewModel.search(_query.text), child: const Text('Retry')),
          ),
        for (final city in state.suggestions) ListTile(title: Text(city), onTap: () => _select(city)),
      ],
    );
  }
}
