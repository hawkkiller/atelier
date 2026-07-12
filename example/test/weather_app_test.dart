import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/app.dart';
import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/domain/weather_errors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads Warsaw with mobile structure and weather semantics', (
    tester,
  ) async {
    await tester.pumpWidget(WeatherApp(repository: _StubRepository()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mobile-layout')), findsOneWidget);
    expect(find.text('Warsaw, Poland'), findsOneWidget);
    expect(find.text('22°'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('city-search-field'))).height,
      60,
    );
    expect(tester.getSize(find.byKey(const Key('weather-stage'))).height, 440);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Warsaw, Poland, 22 degrees Celsius, Partly cloudy',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('weather-art')), findsOneWidget);
  });

  testWidgets('preserves the mobile structure and input while resizing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(WeatherApp(repository: _StubRepository()));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('city-search-field')),
      'Lisbon',
    );
    expect(find.byKey(const Key('mobile-layout')), findsOneWidget);

    tester.view.physicalSize = const Size(500, 700);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mobile-layout')), findsOneWidget);
    expect(find.text('Lisbon'), findsOneWidget);
  });

  testWidgets('supports suggestions, Escape, selection and clear', (
    tester,
  ) async {
    await tester.pumpWidget(WeatherApp(repository: _StubRepository()));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('city-search-field'));
    await tester.tap(field);
    await tester.enterText(field, 'Warr');
    await tester.pumpAndSettle();
    expect(find.text('Warka, Poland'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byKey(const Key('suggestions-menu')), findsNothing);

    await tester.enterText(field, 'War');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Warka, Poland'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('suggestions-menu')), findsNothing);
    await tester.tap(find.byKey(const Key('clear-search')));
    await tester.pump();
    final textField = tester.widget<TextField>(field);
    expect(textField.controller!.text, isEmpty);
  });

  testWidgets('Enter submits and service error retries', (tester) async {
    final repository = _StubRepository(failAfterInitial: true);
    await tester.pumpWidget(WeatherApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('city-search-field')));
    await tester.enterText(find.byKey(const Key('city-search-field')), 'Oslo');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Weather is unavailable right now.'), findsOneWidget);
    expect(find.text('Warsaw, Poland'), findsOneWidget);
    repository.failAfterInitial = false;
    await tester.ensureVisible(find.byKey(const Key('retry-weather')));
    await tester.tap(find.byKey(const Key('retry-weather')));
    await tester.pumpAndSettle();
    expect(find.text('Weather is unavailable right now.'), findsNothing);
  });

  testWidgets('handles short height and large text', (tester) async {
    tester.view.physicalSize = const Size(400, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          textScaler: TextScaler.linear(2),
          disableAnimations: true,
        ),
        child: WeatherApp(repository: _StubRepository()),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final stage = tester.widget<AnimatedContainer>(
      find.byKey(const Key('weather-stage')),
    );
    expect(stage.duration, Duration.zero);
  });
}

final class _StubRepository implements WeatherRepository {
  _StubRepository({this.failAfterInitial = false});
  bool failAfterInitial;
  var loads = 0;

  @override
  Future<List<String>> search(
    String query, {
    required CancellationToken cancellationToken,
  }) async => const ['Warka, Poland'];

  @override
  Future<Weather> load(
    String city, {
    required CancellationToken cancellationToken,
  }) async {
    loads++;
    if (failAfterInitial && loads > 1) {
      throw const WeatherServiceException('technical detail');
    }
    return Weather(
      city: city == 'Warsaw' ? 'Warsaw, Poland' : city,
      temperature: 22,
      description: 'Partly cloudy',
      condition: WeatherCondition.partlyCloudy,
      isDay: true,
    );
  }

  @override
  void close() {}
}
