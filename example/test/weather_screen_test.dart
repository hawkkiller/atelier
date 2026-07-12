import 'package:atelier_weather_example/src/features/weather/presentation/weather_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('weather screen provides a safe, textured background', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WeatherScreen()));

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(SafeArea), findsOneWidget);
    expect(find.byKey(const Key('weather-background-grain')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('background expands around reusable child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WeatherBackground(child: Center(child: Text('Weather content'))),
      ),
    );

    expect(find.text('Weather content'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
