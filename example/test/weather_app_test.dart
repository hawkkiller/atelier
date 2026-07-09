import 'package:atelier/atelier.dart';
import 'package:atelier_weather_example/src/app.dart';
import 'package:atelier_weather_example/src/features/weather/domain/entities/weather.dart';
import 'package:atelier_weather_example/src/features/weather/domain/repositories/weather_repository.dart';
import 'package:atelier_weather_example/src/features/weather/presentation/weather_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads the default Warsaw weather', (tester) async {
    await tester.pumpWidget(WeatherApp(repository: _WeatherRepositoryStub()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.descendant(of: find.byType(Card), matching: find.text('Warsaw')),
      findsOneWidget,
    );
    expect(find.text('22° C'), findsOneWidget);
    expect(find.text('Partly cloudy'), findsOneWidget);
  });

  testWidgets('shows state-driven search suggestions', (tester) async {
    await tester.pumpWidget(WeatherApp(repository: _WeatherRepositoryStub()));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'War');
    await tester.pump();

    expect(find.text('Warka'), findsOneWidget);
  });

  test('load preserves search suggestions', () async {
    final repository = _WeatherRepositoryStub();
    final viewModel = WeatherViewModel(repository);

    await viewModel.search('War');
    await viewModel.load('Warsaw');

    expect(viewModel.state.value.suggestions, ['Warka']);
    viewModel.dispose();
  });
}

final class _WeatherRepositoryStub implements WeatherRepository {
  @override
  Future<List<String>> search(
    String query, {
    required CancellationToken cancellationToken,
  }) async {
    return const ['Warka'];
  }

  @override
  Future<Weather> load(
    String city, {
    required CancellationToken cancellationToken,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    cancellationToken.throwIfCancelled();
    return const Weather(
      city: 'Warsaw',
      temperature: 22,
      description: 'Partly cloudy',
      icon: '⛅',
    );
  }

  @override
  void close() {}
}
