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
  late final _effects = effectsOf<WeatherEffect>();

  StateValue<WeatherState> get state => _state;
  Effects<WeatherEffect> get effects => _effects;

  Future<void> search(String query) => execute.restartable(key: #searchWeather, (task) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      _state.update((state) => state.copyWith(suggestions: const []));
      return;
    }

    try {
      final suggestions = await _repository.search(normalizedQuery, cancellationToken: task);
      _state.update((state) => state.copyWith(suggestions: suggestions));
    } on WeatherNotFoundException {
      _state.update((state) => state.copyWith(suggestions: const []));
    } on WeatherServiceException catch (error) {
      _state.update((state) => state.copyWith(suggestions: const []));
      _effects.emit(WeatherEffect.serviceFailed(error.message));
    }
  });

  Future<void> load(String city) => execute.restartable(key: #loadWeather, (task) async {
    final normalizedCity = city.trim();
    _state.update((state) => state.copyWith(weather: null, isLoading: true));

    try {
      final weather = await _repository.load(normalizedCity, cancellationToken: task);
      _state.update((state) => state.copyWith(weather: weather, isLoading: false));
    } on WeatherNotFoundException {
      _state.update((state) => state.copyWith(weather: null, isLoading: false));
      _effects.emit(WeatherEffect.locationNotFound(normalizedCity));
    } on WeatherServiceException catch (error) {
      _state.update((state) => state.copyWith(weather: null, isLoading: false));
      _effects.emit(WeatherEffect.serviceFailed(error.message));
    }
  });
}

@freezed
abstract class WeatherState with _$WeatherState {
  const factory WeatherState({
    @Default([]) List<String> suggestions,
    Weather? weather,
    @Default(false) bool isLoading,
  }) = _WeatherState;
}

@freezed
sealed class WeatherEffect with _$WeatherEffect {
  const factory WeatherEffect.emptyCity() = WeatherEmptyCity;

  const factory WeatherEffect.locationNotFound(String city) = WeatherLocationNotFound;

  const factory WeatherEffect.serviceFailed(String message) = WeatherServiceFailed;
}
