import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/weather_errors.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_view_model.freezed.dart';

class WeatherViewModel extends ViewModel<WeatherState> {
  WeatherViewModel(this._repository) : super(const WeatherState());

  final WeatherRepository _repository;
  late final MutableEffects<WeatherEffect> _effects = effectsOf();

  /// One-shot outcomes the screen presents, such as a snackbar.
  Effects<WeatherEffect> get effects => _effects;

  Future<void> load(String city) => execute.restartable(key: #loadWeather, (task) async {
    final normalizedCity = city.trim();
    if (normalizedCity.isEmpty) {
      task.updateState((state) => state.copyWith(requestedCity: '', loadStatus: .emptyInput));
      return;
    }

    task.updateState((state) => state.copyWith(requestedCity: normalizedCity, loadStatus: .loading));

    try {
      final weather = await _repository.load(normalizedCity, cancellationToken: task);
      task.updateState((state) => state.copyWith(weather: weather, loadStatus: .success));
    } on WeatherNotFoundException {
      task.updateState((state) => state.copyWith(loadStatus: .notFound));
    } on WeatherServiceException {
      task.updateState((state) => state.copyWith(loadStatus: .serviceUnavailable));
    }
  });

  /// Unexpected failures (bugs, malformed responses) end up here instead of
  /// escaping as uncaught errors from fire-and-forget UI calls.
  @override
  void onTaskError(TaskContext<WeatherState> task, Object error, StackTrace stackTrace) {
    task.updateState((state) => state.copyWith(loadStatus: .serviceUnavailable));
    _effects.emit(.unexpectedFailure);
  }
}

enum WeatherEffect { unexpectedFailure }

@freezed
abstract class WeatherState with _$WeatherState {
  const factory WeatherState({
    Weather? weather,
    @Default(WeatherLoadStatus.idle) WeatherLoadStatus loadStatus,
    @Default('') String requestedCity,
  }) = _WeatherState;
}

enum WeatherLoadStatus { idle, loading, success, emptyInput, notFound, serviceUnavailable }
