import 'dart:async';

import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/data/repositories/open_meteo_weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_search.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_stage.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_theme.dart';
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
  late final searchFocusNode = focusNode();
  late final WeatherRepository _repository =
      widget.repository ??
      disposeWith(
        OpenMeteoWeatherRepository(),
        (repository) => repository.close(),
      );

  @override
  WeatherViewModel createViewModel(BuildContext context) =>
      WeatherViewModel(_repository);

  @override
  void initState() {
    super.initState();
    unawaited(viewModel.load(cityController.text));
  }

  void _clear() {
    cityController.clear();
    unawaited(viewModel.search(''));
    searchFocusNode.requestFocus();
    setState(() {});
  }

  void _select(String city) {
    cityController.value = TextEditingValue(
      text: city,
      selection: TextSelection.collapsed(offset: city.length),
    );
    searchFocusNode.unfocus();
    unawaited(viewModel.load(city));
  }

  @override
  Widget build(BuildContext context) {
    final state = watch(viewModel.state);
    final search = WeatherSearch(
      controller: cityController,
      focusNode: searchFocusNode,
      state: state,
      onChanged: (value) async {
        setState(() {});
        await viewModel.search(value);
        return viewModel.state.value.suggestions;
      },
      onSubmitted: (value) {
        searchFocusNode.unfocus();
        unawaited(viewModel.load(value));
      },
      onSelected: _select,
      onClear: _clear,
    );
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(.75, -.65),
            radius: 1.35,
            colors: [Color(0xff243b60), WeatherColors.ink],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  key: const Key('mobile-layout'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Brand(),
                    const SizedBox(height: 24),
                    search,
                    const SizedBox(height: 24),
                    WeatherStage(
                      state: state,
                      onRetry: () => unawaited(
                        viewModel.load(
                          state.requestedCity.isEmpty
                              ? cityController.text
                              : state.requestedCity,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _Attribution(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Icon(Icons.wb_twilight_outlined, color: Color(0xffffca68)),
      SizedBox(width: 10),
      Flexible(
        child: Text(
          'ATELIER / WEATHER',
          style: TextStyle(
            fontSize: 13,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) => const Text(
    'Weather data by Open-Meteo',
    style: TextStyle(color: WeatherColors.muted, fontSize: 13),
  );
}
