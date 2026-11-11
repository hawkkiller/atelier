import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/weather_errors.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_view_model.freezed.dart';

class WeatherViewModel extends ViewModel<WeatherState> with ViewModelEffects<WeatherState, WeatherEffect> {
  WeatherViewModel(this._repository) : super(const WeatherState());

  final WeatherRepository _repository;

  late final load = restartable((String city, task) async {
    final q = city.trim();
    if (q.isEmpty) {
      task.state = task.state.copyWith(requestedCity: '', loadStatus: .emptyInput);
      return;
    }

    task.state = task.state.copyWith(requestedCity: q, loadStatus: .loading);
    try {
      final weather = await _repository.load(q, cancellationToken: task);
      task.state = task.state.copyWith(weather: weather, loadStatus: .success);
    } on WeatherNotFoundException {
      task.state = task.state.copyWith(loadStatus: .notFound);
    } on WeatherServiceException {
      task.state = task.state.copyWith(loadStatus: .serviceUnavailable);
    }
  });

  /// Unexpected failures (bugs, malformed responses) end up here instead of
  /// escaping as uncaught errors from fire-and-forget UI calls.
  @override
  void onTaskError(TaskContext<WeatherState> task, Object error, StackTrace stackTrace) {
    task.state = task.state.copyWith(loadStatus: .serviceUnavailable);
    emit(.unexpectedFailure);
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
