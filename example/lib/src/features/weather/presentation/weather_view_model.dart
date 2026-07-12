import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/weather_errors.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_view_model.freezed.dart';

class WeatherViewModel extends ViewModel {
  WeatherViewModel(this._repository);

  final WeatherRepository _repository;
  late final _state = mutableStateOf(const WeatherState());

  StateValue<WeatherState> get state => _state;

  Future<void> search(String query) => execute.restartable(key: #searchWeather, (task) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      _state.update(
        (state) => state.copyWith(suggestions: const [], searchStatus: WeatherSearchStatus.idle),
      );
      return;
    }

    _state.update((state) => state.copyWith(searchStatus: WeatherSearchStatus.loading));

    try {
      final suggestions = await _repository.search(normalizedQuery, cancellationToken: task);
      _state.update(
        (state) => state.copyWith(suggestions: suggestions, searchStatus: WeatherSearchStatus.idle),
      );
    } on WeatherNotFoundException {
      _state.update(
        (state) => state.copyWith(suggestions: const [], searchStatus: WeatherSearchStatus.idle),
      );
    } on WeatherServiceException {
      _state.update(
        (state) => state.copyWith(suggestions: const [], searchStatus: WeatherSearchStatus.failed),
      );
    }
  });

  Future<void> load(String city) => execute.restartable(key: #loadWeather, (task) async {
    final normalizedCity = city.trim();
    if (normalizedCity.isEmpty) {
      _state.update(
        (state) => state.copyWith(requestedCity: '', loadStatus: WeatherLoadStatus.emptyInput),
      );
      return;
    }
    _state.update(
      (state) =>
          state.copyWith(requestedCity: normalizedCity, loadStatus: WeatherLoadStatus.loading),
    );

    try {
      final weather = await _repository.load(normalizedCity, cancellationToken: task);
      _state.update(
        (state) => state.copyWith(weather: weather, loadStatus: WeatherLoadStatus.ready),
      );
    } on WeatherNotFoundException {
      _state.update((state) => state.copyWith(loadStatus: WeatherLoadStatus.notFound));
    } on WeatherServiceException {
      _state.update((state) => state.copyWith(loadStatus: WeatherLoadStatus.serviceUnavailable));
    }
  });
}

@freezed
abstract class WeatherState with _$WeatherState {
  const factory WeatherState({
    @Default([]) List<String> suggestions,
    Weather? weather,
    @Default(WeatherSearchStatus.idle) WeatherSearchStatus searchStatus,
    @Default(WeatherLoadStatus.idle) WeatherLoadStatus loadStatus,
    @Default('') String requestedCity,
  }) = _WeatherState;
}

enum WeatherSearchStatus { idle, loading, failed }

enum WeatherLoadStatus { idle, loading, ready, emptyInput, notFound, serviceUnavailable }
