import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/weather_errors.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_search_view_model.freezed.dart';

class WeatherSearchViewModel extends ViewModel<WeatherSearchState> {
  WeatherSearchViewModel(this._repository) : super(const WeatherSearchState());

  final WeatherRepository _repository;

  late final search = restartable((String query, task) async {
    final q = query.trim();
    if (q.isEmpty) {
      task.state = const WeatherSearchState();
      return;
    }

    task.state = task.state.copyWith(loading: true, failed: false);
    try {
      final suggestions = await _repository.search(q, cancellationToken: task);
      task.state = WeatherSearchState(suggestions: suggestions);
    } on WeatherNotFoundException {
      task.state = const WeatherSearchState();
    } on WeatherServiceException {
      task.state = const WeatherSearchState(failed: true);
    }
  });

  /// Clears the spinner when a search fails unexpectedly, then rethrows.
  @override
  void onTaskError(TaskContext<WeatherSearchState> task, Object error, StackTrace stackTrace) {
    task.state = task.state.copyWith(loading: false);
    super.onTaskError(task, error, stackTrace);
  }
}

@freezed
abstract class WeatherSearchState with _$WeatherSearchState {
  const factory WeatherSearchState({
    @Default([]) List<String> suggestions,
    @Default(false) bool loading,
    @Default(false) bool failed,
  }) = _WeatherSearchState;
}
