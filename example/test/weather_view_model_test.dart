import 'dart:async';

import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/weather_errors.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const weather = Weather(
    city: 'Warsaw',
    temperature: 22,
    description: 'Clear sky',
    condition: WeatherCondition.clear,
    isDay: true,
  );

  test('empty load is normalized and never reaches repository', () async {
    final repository = _ControlledRepository();
    final viewModel = WeatherViewModel(repository);
    await viewModel.load('   ');
    expect(repository.loadCalls, isEmpty);
    expect(viewModel.state.value.loadStatus, WeatherLoadStatus.emptyInput);
    expect(viewModel.state.value.requestedCity, '');
  });

  test('load normalizes city and transitions loading to success', () async {
    final completer = Completer<Weather>();
    final repository = _ControlledRepository(
      loadResult: () => completer.future,
    );
    final viewModel = WeatherViewModel(repository);
    final future = viewModel.load('  Warsaw ');
    expect(viewModel.state.value.loadStatus, WeatherLoadStatus.loading);
    expect(viewModel.state.value.requestedCity, 'Warsaw');
    completer.complete(weather);
    await future;
    expect(viewModel.state.value.weather, weather);
    expect(viewModel.state.value.loadStatus, WeatherLoadStatus.success);
  });

  test('not found and service failure retain prior weather', () async {
    final repository = _ControlledRepository();
    final viewModel = WeatherViewModel(repository);
    await viewModel.load('Warsaw');
    repository.loadError = const WeatherNotFoundException();
    await viewModel.load('Missing');
    expect(viewModel.state.value.weather, weather);
    expect(viewModel.state.value.loadStatus, WeatherLoadStatus.notFound);
    repository.loadError = const WeatherServiceException('raw');
    await viewModel.load('Paris');
    expect(viewModel.state.value.weather, weather);
    expect(
      viewModel.state.value.loadStatus,
      WeatherLoadStatus.serviceUnavailable,
    );
  });

  test('unexpected repository errors propagate', () async {
    final repository = _ControlledRepository()..loadError = StateError('bug');
    final viewModel = WeatherViewModel(repository);
    await expectLater(viewModel.load('Warsaw'), throwsStateError);
  });
}

final class _ControlledRepository implements WeatherRepository {
  _ControlledRepository({this.loadResult});
  final Future<Weather> Function()? loadResult;
  Object? loadError;
  final loadCalls = <String>[];

  @override
  Future<Weather> load(
    String city, {
    required CancellationToken cancellationToken,
  }) async {
    loadCalls.add(city);
    if (loadError case final error?) throw error;
    return loadResult?.call() ??
        const Weather(
          city: 'Warsaw',
          temperature: 22,
          description: 'Clear sky',
          condition: WeatherCondition.clear,
          isDay: true,
        );
  }

  @override
  Future<List<String>> search(String query, {required CancellationToken cancellationToken}) async => const [];

  @override
  void close() {}
}
