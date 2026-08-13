import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/weather_errors.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_search_view_model.freezed.dart';

class WeatherSearchViewModel extends ViewModel<WeatherSearchState> {
  WeatherSearchViewModel(this._repository) : super(const WeatherSearchState());

  final WeatherRepository _repository;

  Future<void> search(String query) => execute.restartable(key: #searchWeather, (task) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      task.updateState(
        (state) => state.copyWith(suggestions: const [], searchStatus: WeatherSearchStatus.idle),
      );
      return;
    }

    task.updateState((state) => state.copyWith(searchStatus: WeatherSearchStatus.loading));
    try {
      final suggestions = await _repository.search(normalizedQuery, cancellationToken: task);
      task.updateState(
        (state) => state.copyWith(suggestions: suggestions, searchStatus: WeatherSearchStatus.idle),
      );
    } on WeatherNotFoundException {
      task.updateState(
        (state) => state.copyWith(suggestions: const [], searchStatus: WeatherSearchStatus.idle),
      );
    } on WeatherServiceException {
      task.updateState(
        (state) => state.copyWith(suggestions: const [], searchStatus: WeatherSearchStatus.failed),
      );
    }
  });
}

@freezed
abstract class WeatherSearchState with _$WeatherSearchState {
  const factory WeatherSearchState({
    @Default([]) List<String> suggestions,
    @Default(WeatherSearchStatus.idle) WeatherSearchStatus searchStatus,
  }) = _WeatherSearchState;
}

enum WeatherSearchStatus { idle, loading, failed }
