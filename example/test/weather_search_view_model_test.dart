import 'dart:async';

import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_search_view_model.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';
import 'package:atelier_weather_example/src/features/weather/domain/weather_errors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search covers loading, success, empty, not found and failure', () async {
    final completer = Completer<List<String>>();
    final repository = _ControlledRepository(searchResult: () => completer.future);
    final viewModel = WeatherSearchViewModel(repository);
    final future = viewModel.search(' War ');
    expect(viewModel.state.value.searchStatus, WeatherSearchStatus.loading);
    completer.complete(['Warsaw']);
    await future;
    expect(viewModel.state.value.suggestions, ['Warsaw']);
    await viewModel.search(' ');
    expect(viewModel.state.value.searchStatus, WeatherSearchStatus.idle);
    expect(viewModel.state.value.suggestions, isEmpty);
    repository.searchError = const WeatherNotFoundException();
    await viewModel.search('none');
    expect(viewModel.state.value.searchStatus, WeatherSearchStatus.idle);
    repository.searchError = const WeatherServiceException('raw');
    await viewModel.search('fail');
    expect(viewModel.state.value.searchStatus, WeatherSearchStatus.failed);
  });

  test('replacement cancels stale search and suppresses its result', () async {
    final repository = _ControlledRepository();
    final viewModel = WeatherSearchViewModel(repository);
    final first = viewModel.search('first');
    final firstToken = repository.searchTokens.single;
    final second = viewModel.search('second');
    expect(firstToken.isCancelled, isTrue);
    repository.completeSearch(1, ['Second']);
    await second;
    repository.completeSearch(0, ['First']);
    await first;
    expect(viewModel.state.value.suggestions, ['Second']);
  });

  test('unexpected search errors propagate', () async {
    final repository = _ControlledRepository()..searchError = StateError('bug');
    final viewModel = WeatherSearchViewModel(repository);
    await expectLater(viewModel.search('War'), throwsStateError);
  });
}

final class _ControlledRepository implements WeatherRepository {
  _ControlledRepository({this.searchResult});
  final Future<List<String>> Function()? searchResult;
  Object? searchError;
  final searchTokens = <CancellationToken>[];
  final _searches = <Completer<List<String>>>[];

  @override
  Future<List<String>> search(String query, {required CancellationToken cancellationToken}) {
    searchTokens.add(cancellationToken);
    if (searchError case final error?) return Future.error(error);
    final result = searchResult?.call();
    if (result != null) return result;
    final completer = Completer<List<String>>();
    _searches.add(completer);
    return completer.future;
  }

  void completeSearch(int index, List<String> suggestions) => _searches[index].complete(suggestions);

  @override
  Future<Weather> load(String city, {required CancellationToken cancellationToken}) => throw UnimplementedError();

  @override
  void close() {}
}
