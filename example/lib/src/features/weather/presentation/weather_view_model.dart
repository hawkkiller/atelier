import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/weather_errors.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_view_model.freezed.dart';

class WeatherViewModel extends ViewModel<WeatherState> {
  WeatherViewModel(this._repository) : super(const WeatherState());

  final WeatherRepository _repository;

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
}

@freezed
abstract class WeatherState with _$WeatherState {
  const factory WeatherState({
    Weather? weather,
    @Default(WeatherLoadStatus.idle) WeatherLoadStatus loadStatus,
    @Default('') String requestedCity,
  }) = _WeatherState;
}

enum WeatherLoadStatus { idle, loading, success, emptyInput, notFound, serviceUnavailable }
