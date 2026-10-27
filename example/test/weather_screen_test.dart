import 'dart:async';

import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/weather_errors.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads the default city once and renders it', (tester) async {
    final repository = _ControlledWeatherRepository();
    await tester.pumpWidget(_app(repository));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.completeLoad(0, _weather('Kraków, Poland', 21.2, 'Clear sky'));
    await tester.pump();
    await tester.pumpWidget(_app(repository));

    expect(find.text('Kraków, Poland'), findsOneWidget);
    expect(find.text('21° · Clear sky'), findsOneWidget);
    expect(repository.loadedCities, ['Kraków']);
  });

  testWidgets('searching shows progress, then suggestions; selecting loads the city', (tester) async {
    final repository = await _pumpReady(tester);

    await tester.enterText(find.byType(TextField), 'Lon');
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    repository.completeSearch(0, ['London, United Kingdom']);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.tap(find.text('London, United Kingdom'));
    await tester.pump();
    expect(repository.loadedCities.last, 'London, United Kingdom');
    expect(find.widgetWithText(ListTile, 'London, United Kingdom'), findsNothing);

    repository.completeLoad(1, _weather('London, United Kingdom', 12, 'Rain'));
    await tester.pump();
    expect(find.text('12° · Rain'), findsOneWidget);
  });

  testWidgets('rapid typing never shows stale suggestions', (tester) async {
    final repository = await _pumpReady(tester);

    await tester.enterText(find.byType(TextField), 'First');
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Second');
    await tester.pump();
    repository.completeSearch(0, ['First City']);
    repository.completeSearch(1, ['Second City']);
    await tester.pump();

    expect(repository.searchTokens.first.isCancelled, isTrue);
    expect(find.text('First City'), findsNothing);
    expect(find.text('Second City'), findsOneWidget);
  });

  testWidgets('search failure offers retry', (tester) async {
    final repository = await _pumpReady(tester);

    await tester.enterText(find.byType(TextField), 'city');
    await tester.pump();
    repository.completeSearchError(0, const WeatherServiceException('down'));
    await tester.pump();
    expect(find.text('Search is unavailable'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(repository.searchQueries, ['city', 'city']);
  });

  testWidgets('load failure keeps the last weather and offers retry', (tester) async {
    final repository = await _pumpReady(tester);

    await tester.enterText(find.byType(TextField), 'Atl');
    await tester.pump();
    repository.completeSearch(0, ['Atlantis']);
    await tester.pump();
    await tester.tap(find.text('Atlantis'));
    await tester.pump();
    repository.completeLoadError(1, const WeatherNotFoundException());
    await tester.pump();

    expect(find.text('Kraków, Poland'), findsOneWidget);
    expect(find.text('Couldn’t find Atlantis.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(repository.loadedCities.last, 'Atlantis');
  });

  testWidgets('unexpected load errors show a snackbar', (tester) async {
    final repository = await _pumpReady(tester);

    await tester.enterText(find.byType(TextField), 'x');
    await tester.pump();
    repository.completeSearch(0, ['Bug City']);
    await tester.pump();
    await tester.tap(find.text('Bug City'));
    await tester.pump();
    repository.completeLoadError(1, StateError('bug'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
  });

  testWidgets('disposing the screen does not close the shared repository', (tester) async {
    final repository = await _pumpReady(tester);
    await tester.pumpWidget(const SizedBox());
    expect(repository.closeCount, 0);
  });
}

Future<_ControlledWeatherRepository> _pumpReady(WidgetTester tester) async {
  final repository = _ControlledWeatherRepository();
  await tester.pumpWidget(_app(repository));
  repository.completeLoad(0, _weather('Kraków, Poland', 21.2, 'Clear sky'));
  await tester.pump();
  return repository;
}

Widget _app(_ControlledWeatherRepository repository) {
  return MaterialApp(home: WeatherScreen(repository: repository));
}

Weather _weather(String city, double temperature, String description, {bool isDay = true}) {
  return Weather(
    city: city,
    temperature: temperature,
    description: description,
    condition: description == 'Rain' ? WeatherCondition.rain : WeatherCondition.clear,
    isDay: isDay,
  );
}

class _ControlledWeatherRepository implements WeatherRepository {
  final loadedCities = <String>[];
  final searchQueries = <String>[];
  final searchTokens = <CancellationToken>[];
  final _loads = <Completer<Weather>>[];
  final _searches = <Completer<List<String>>>[];
  int closeCount = 0;

  @override
  Future<Weather> load(String city, {required CancellationToken cancellationToken}) {
    loadedCities.add(city);
    final completer = Completer<Weather>();
    _loads.add(completer);
    return completer.future;
  }

  @override
  Future<List<String>> search(String query, {required CancellationToken cancellationToken}) {
    searchQueries.add(query);
    searchTokens.add(cancellationToken);
    final completer = Completer<List<String>>();
    _searches.add(completer);
    return completer.future;
  }

  void completeLoad(int index, Weather weather) => _loads[index].complete(weather);

  void completeLoadError(int index, Object error) => _loads[index].completeError(error);

  void completeSearch(int index, List<String> suggestions) => _searches[index].complete(suggestions);

  void completeSearchError(int index, Object error) => _searches[index].completeError(error);

  @override
  void close() => closeCount++;
}
