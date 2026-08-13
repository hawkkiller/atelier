import 'dart:async';

import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/weather_errors.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads the default city once across rebuild and search navigation', (tester) async {
    final repository = _ControlledWeatherRepository();
    await _pumpScreen(tester, repository);
    repository.completeLoad(0, _weather('Kraków, Poland', 21.2, 'Clear sky'));
    await tester.pump();

    await tester.pumpWidget(_app(repository));
    await tester.tap(find.byTooltip('Choose a city'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pumpWidget(_app(repository));

    expect(repository.loadedCities, ['Kraków']);
  });

  testWidgets('renders live weather data and condition', (tester) async {
    final repository = _ControlledWeatherRepository();
    await _pumpScreen(tester, repository);
    repository.completeLoad(0, _weather('Reykjavík, Iceland', 3.7, 'Snow'));
    await tester.pump();

    expect(find.text('4°'), findsOneWidget);
    expect(find.text('Reykjavík, Iceland'), findsOneWidget);
    expect(find.text('It’s snow now.'), findsOneWidget);
  });

  testWidgets('background repaint follows palette changes, not load status alone', (tester) async {
    final repository = _ControlledWeatherRepository();
    await _pumpReadyScreen(tester, repository);
    await tester.pump(const Duration(milliseconds: 100));
    final initialPainter = _backgroundPainter(tester);

    await _openSearch(tester);
    await _searchFor(tester, repository, 'Clear City', ['Clear City']);
    await tester.tap(find.byKey(const Key('weather-search-suggestion-Clear City')));
    await tester.pumpAndSettle();
    final loadingPainter = _backgroundPainter(tester);
    expect(_shouldRepaint(loadingPainter, initialPainter), isFalse);

    repository.completeLoad(1, _weather('Clear City', 20, 'Clear sky'));
    await tester.pump();
    await _openSearch(tester);
    await _searchFor(tester, repository, 'Rain City', ['Rain City']);
    await tester.tap(find.byKey(const Key('weather-search-suggestion-Rain City')));
    await tester.pumpAndSettle();
    repository.completeLoad(2, _weather('Rain City', 11, 'Rain'));
    await tester.pump();
    await tester.pump();
    final conditionPainter = _backgroundPainter(tester);
    expect(_shouldRepaint(conditionPainter, loadingPainter), isTrue);

    await _openSearch(tester);
    await _searchFor(tester, repository, 'Night City', ['Night City']);
    await tester.tap(find.byKey(const Key('weather-search-suggestion-Night City')));
    await tester.pumpAndSettle();
    repository.completeLoad(3, _weather('Night City', 11, 'Rain', isDay: false));
    await tester.pump();
    await tester.pump();
    final nightPainter = _backgroundPainter(tester);
    expect(_shouldRepaint(nightPainter, conditionPainter), isTrue);
  });

  testWidgets('opens an opaque search route with an autofocus field and prompt', (tester) async {
    final repository = _ControlledWeatherRepository();
    await _pumpReadyScreen(tester, repository);
    await _openSearch(tester);

    final routeContext = tester.element(find.byKey(const Key('weather-search-field')));
    expect(ModalRoute.of(routeContext)!.opaque, isTrue);
    expect(find.byKey(const Key('weather-search-prompt')), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('weather-search-field'))).autofocus, isTrue);
    final fieldBox = tester.renderObject<RenderBox>(find.byKey(const Key('weather-search-field')));
    final routeBox = tester.renderObject<RenderBox>(find.byKey(const Key('weather-search-route')));
    expect(fieldBox.localToGlobal(Offset.zero).dy, greaterThan(routeBox.size.height * .65));
  });

  testWidgets('search states show loading precedence, suggestions, no results, and retry', (tester) async {
    final repository = _ControlledWeatherRepository();
    await _pumpReadyScreen(tester, repository);
    await _openSearch(tester);
    final field = find.byKey(const Key('weather-search-field'));

    await tester.enterText(field, 'old');
    await tester.pump();
    repository.completeSearch(0, ['Old Town']);
    await tester.pump();
    expect(find.byKey(const Key('weather-search-suggestion-Old Town')), findsOneWidget);

    await tester.enterText(field, 'new');
    await tester.pump();
    expect(find.byKey(const Key('weather-search-loading')), findsOneWidget);
    expect(find.byKey(const Key('weather-search-suggestion-Old Town')), findsNothing);
    expect(find.byKey(const Key('weather-search-results')), findsNothing);

    repository.completeSearch(1, const []);
    await tester.pump();
    expect(find.byKey(const Key('weather-search-no-results')), findsOneWidget);

    await tester.enterText(field, 'broken');
    await tester.pump();
    repository.completeSearchError(2, const WeatherServiceException('offline'));
    await tester.pump();
    expect(find.byKey(const Key('weather-search-error')), findsOneWidget);

    await tester.tap(find.byKey(const Key('weather-search-retry')));
    await tester.pump();
    expect(repository.searchQueries, ['old', 'new', 'broken', 'broken']);
  });

  testWidgets('rapid query replacement never exposes stale tappable results', (tester) async {
    final repository = _ControlledWeatherRepository();
    await _pumpReadyScreen(tester, repository);
    await _openSearch(tester);
    final field = find.byKey(const Key('weather-search-field'));

    await tester.enterText(field, 'first');
    await tester.enterText(field, 'second');
    await tester.pump();
    repository.completeSearch(0, ['First City']);
    await tester.pump();
    expect(find.byKey(const Key('weather-search-suggestion-First City')), findsNothing);

    repository.completeSearch(1, ['Second City']);
    await tester.pump();
    expect(find.byKey(const Key('weather-search-suggestion-Second City')), findsOneWidget);
  });

  testWidgets('selection starts one load, pops, retains stale weather, then renders new weather', (tester) async {
    final repository = _ControlledWeatherRepository();
    await _pumpReadyScreen(tester, repository);
    await _openSearch(tester);
    await _searchFor(tester, repository, 'London', ['London']);

    await tester.tap(find.byKey(const Key('weather-search-suggestion-London')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weather-search-route')), findsNothing);
    expect(repository.loadedCities, ['Kraków', 'London']);
    expect(find.text('Kraków, Poland'), findsOneWidget);
    expect(find.text('Updating weather…'), findsOneWidget);

    repository.completeLoad(1, _weather('London, UK', 12.1, 'Rain'));
    await tester.pump();
    await tester.pump();
    expect(find.text('London, UK'), findsOneWidget);
    expect(find.text('12°'), findsOneWidget);
  });

  testWidgets('selection failure keeps old weather and shows restrained error', (tester) async {
    final repository = _ControlledWeatherRepository();
    await _pumpReadyScreen(tester, repository);
    await _openSearch(tester);
    await _searchFor(tester, repository, 'Atlantis', ['Atlantis']);

    await tester.tap(find.byKey(const Key('weather-search-suggestion-Atlantis')));
    await tester.pumpAndSettle();
    repository.completeLoadError(1, const WeatherNotFoundException());
    await tester.pump();
    await tester.pump();

    expect(find.text('Kraków, Poland'), findsOneWidget);
    expect(find.text('Couldn’t update Atlantis. Showing the last report.'), findsOneWidget);
  });

  testWidgets('close and system back clear search without loading a city', (tester) async {
    final repository = _ControlledWeatherRepository();
    await _pumpReadyScreen(tester, repository);
    await _openSearch(tester);
    await tester.enterText(find.byKey(const Key('weather-search-field')), 'city');
    await tester.pump();
    final closeToken = repository.searchTokens.single;
    await tester.tap(find.byKey(const Key('weather-search-close')));
    await tester.pumpAndSettle();
    expect(closeToken.isCancelled, isTrue);
    repository.completeSearch(0, ['Stale City']);
    await tester.pump();
    expect(repository.loadedCities, ['Kraków']);
    expect(repository.searchQueries.last, 'city');
    expect(find.byKey(const Key('weather-search-suggestion-Stale City')), findsNothing);

    await _openSearch(tester);
    await tester.enterText(find.byKey(const Key('weather-search-field')), 'back');
    await tester.pump();
    final backToken = repository.searchTokens[1];
    tester.testTextInput.hide();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    final didPop = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(didPop, isTrue);
    expect(backToken.isCancelled, isTrue);
    repository.completeSearch(1, ['Back Stale City']);
    await tester.pump();
    expect(repository.loadedCities, ['Kraków']);
    expect(find.byKey(const Key('weather-search-route')), findsNothing);
    expect(find.byKey(const Key('weather-search-suggestion-Back Stale City')), findsNothing);
  });

  testWidgets('rapid close and selection activation does not double pop or load', (tester) async {
    final repository = _ControlledWeatherRepository();
    await _pumpReadyScreen(tester, repository);
    await _openSearch(tester);
    await _searchFor(tester, repository, 'Paris', ['Paris']);

    final close = find.byKey(const Key('weather-search-close'));
    final suggestion = find.byKey(const Key('weather-search-suggestion-Paris'));
    tester.widget<IconButton>(close).onPressed!();
    tester.widget<ListTile>(suggestion).onTap!();
    await tester.pumpAndSettle();

    expect(repository.loadedCities, ['Kraków']);
    expect(find.byKey(const Key('weather-search-route')), findsNothing);
    expect(find.text('Kraków, Poland'), findsOneWidget);
  });

  testWidgets('system back wins a selection race without popping the parent', (tester) async {
    final repository = _ControlledWeatherRepository();
    await _pumpReadyScreen(tester, repository);
    await _openSearch(tester);
    await _searchFor(tester, repository, 'Paris', ['Paris']);

    final select = tester.widget<ListTile>(find.byKey(const Key('weather-search-suggestion-Paris'))).onTap!;
    final didPop = await tester.binding.handlePopRoute();
    select();
    await tester.pumpAndSettle();

    expect(didPop, isTrue);
    expect(find.byKey(const Key('weather-search-route')), findsNothing);
    expect(repository.loadedCities, ['Kraków']);
    expect(find.text('Kraków, Poland'), findsOneWidget);
  });

  testWidgets('screen and search route do not close shared repository', (tester) async {
    final repository = _ControlledWeatherRepository();
    await _pumpReadyScreen(tester, repository);
    await _openSearch(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(repository.closeCount, 0);

    await _openSearch(tester);
    await _searchFor(tester, repository, 'Paris', ['Paris']);
    await tester.tap(find.byKey(const Key('weather-search-suggestion-Paris')));
    await tester.pumpAndSettle();
    repository.completeLoad(1, _weather('Paris, France', 18.4, 'Clear sky'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Paris, France'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(repository.closeCount, 0);
    await tester.pumpWidget(const SizedBox());
    expect(repository.closeCount, 0);
  });

  testWidgets('constrained viewport and increased text scale do not throw', (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
    });
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.3;

    final repository = _ControlledWeatherRepository();
    await _pumpReadyScreen(tester, repository);
    expect(tester.takeException(), isNull);
    await _openSearch(tester);
    expect(find.byKey(const Key('weather-search-route')), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byKey(const Key('weather-search-field'))).focusNode!.hasFocus,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpScreen(WidgetTester tester, _ControlledWeatherRepository repository) async {
  await tester.pumpWidget(_app(repository));
  await tester.pump();
}

Future<void> _pumpReadyScreen(WidgetTester tester, _ControlledWeatherRepository repository) async {
  await _pumpScreen(tester, repository);
  repository.completeLoad(0, _weather('Kraków, Poland', 21.2, 'Clear sky'));
  await tester.pump();
}

Future<void> _openSearch(WidgetTester tester) async {
  await tester.ensureVisible(find.byTooltip('Choose a city'));
  await tester.tap(find.byTooltip('Choose a city'));
  await tester.pumpAndSettle();
}

Future<void> _searchFor(
  WidgetTester tester,
  _ControlledWeatherRepository repository,
  String query,
  List<String> suggestions,
) async {
  await tester.enterText(find.byKey(const Key('weather-search-field')), query);
  await tester.pump();
  repository.completeSearch(repository.searchQueries.length - 1, suggestions);
  await tester.pump();
}

Widget _app(_ControlledWeatherRepository repository) {
  return MaterialApp(home: WeatherScreen(repository: repository));
}

CustomPainter _backgroundPainter(WidgetTester tester) {
  return tester.renderObject<RenderCustomPaint>(find.byKey(const Key('weather-background-grain'))).painter!;
}

bool _shouldRepaint(CustomPainter current, CustomPainter previous) {
  return (current as dynamic).shouldRepaint(previous as dynamic) as bool;
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
