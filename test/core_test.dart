import 'dart:async';

import 'package:atelier/atelier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StateValue', () {
    test('replays its current value and emits every assignment', () async {
      final viewModel = _TestViewModel();
      final first = <int>[];
      final second = <int>[];

      viewModel.state.listen(first.add);
      viewModel.setValue(1);
      viewModel.setValue(1);
      viewModel.state.listen(second.add);
      viewModel.increment();

      expect(first, isEmpty);
      expect(second, isEmpty);
      await Future<void>.delayed(Duration.zero);

      expect(first, [0, 1, 1, 2]);
      expect(second, [1, 2]);
    });

    test('is broadcast', () {
      expect(_TestViewModel().state.isBroadcast, isTrue);
    });

    test('closes and rejects mutations when ViewModel is disposed', () async {
      final viewModel = _TestViewModel();
      final done = Completer<void>();
      viewModel.state.listen((_) {}, onDone: done.complete);

      viewModel.dispose();

      await done.future;
      expect(
        () => viewModel.setValue(1),
        throwsA(isA<MutableStateDisposedError>()),
      );
    });
  });

  group('Effects', () {
    test('delivers only to current listeners without replay', () async {
      final viewModel = _TestViewModel();
      final first = <String>[];
      final second = <String>[];

      viewModel.emit('before');
      viewModel.effects.listen(first.add);
      viewModel.emit('one');
      viewModel.effects.listen(second.add);
      viewModel.emit('two');

      expect(first, isEmpty);
      expect(second, isEmpty);
      await Future<void>.delayed(Duration.zero);

      expect(first, ['one', 'two']);
      expect(second, ['two']);
    });

    test('is broadcast', () {
      expect(_TestViewModel().effects.isBroadcast, isTrue);
    });

    test('closes and rejects emissions when ViewModel is disposed', () async {
      final viewModel = _TestViewModel();
      final done = Completer<void>();
      viewModel.effects.listen((_) {}, onDone: done.complete);

      viewModel.dispose();

      await done.future;
      expect(
        () => viewModel.emit('late'),
        throwsA(isA<EffectsDisposedError>()),
      );
    });
  });

  group('ViewModel', () {
    test('disposal is idempotent', () {
      final viewModel = _TestViewModel();

      viewModel.dispose();
      viewModel.dispose();

      expect(viewModel.disposeCount, 1);
      expect(viewModel.isDisposed, isTrue);
    });

    test('still closes resources when onDispose throws', () async {
      final viewModel = _ThrowingDisposeViewModel();
      final done = Completer<void>();
      viewModel.state.listen((_) {}, onDone: done.complete);

      expect(viewModel.dispose, throwsA(isA<ArgumentError>()));
      await done.future;
      expect(
        () => viewModel.update(),
        throwsA(isA<MutableStateDisposedError>()),
      );
    });
  });

  group('TaskExecutor', () {
    test('concurrent tasks expose context and run independently', () async {
      final viewModel = _TestViewModel();
      final firstGate = Completer<void>();
      final secondGate = Completer<void>();
      late TaskContext firstContext;
      late TaskContext secondContext;

      final first = viewModel.execute.concurrent((task) async {
        firstContext = task;
        await firstGate.future;
      }, key: 'load');
      final second = viewModel.execute((task) async {
        secondContext = task;
        await secondGate.future;
      }, key: 'load');

      expect(firstContext.policy, TaskPolicy.concurrent);
      expect(firstContext.key, 'load');
      expect(secondContext.isActive, isTrue);

      secondGate.complete();
      firstGate.complete();
      await Future.wait([first, second]);
      expect(firstContext.isActive, isFalse);
      expect(secondContext.isActive, isFalse);
    });

    test('droppable shares the active invocation future', () async {
      final viewModel = _TestViewModel();
      final gate = Completer<void>();
      var invocationCount = 0;

      final first = viewModel.execute.droppable(key: 'login', (task) async {
        invocationCount++;
        await gate.future;
      });
      final second = viewModel.execute.droppable(key: 'login', (task) async {
        invocationCount++;
      });

      expect(identical(first, second), isTrue);
      expect(invocationCount, 1);
      gate.complete();
      await second;
    });

    test('restartable invalidates the previous invocation', () async {
      final viewModel = _TestViewModel();
      final firstGate = Completer<void>();
      late TaskContext firstContext;

      final first = viewModel.execute.restartable(key: 'search', (task) async {
        firstContext = task;
        await firstGate.future;
      });
      final firstResult = expectLater(first, completes);

      final second = viewModel.execute.restartable(
        key: 'search',
        (task) async {},
      );

      expect(firstContext.isCancelled, isTrue);
      await firstContext.cancelled;
      expect(
        firstContext.throwIfCancelled,
        throwsA(isA<TaskCancelledException>()),
      );
      await second;
      firstGate.complete();
      await firstResult;
    });

    test('stale restartable tasks cannot overwrite state', () async {
      final viewModel = _TestViewModel();
      final gate = Completer<void>();

      final first = viewModel.execute.restartable(key: 'load', (task) async {
        await gate.future;
        viewModel.setValue(1);
      });
      await viewModel.execute.restartable(key: 'load', (task) async {
        viewModel.setValue(2);
      });

      gate.complete();
      await first;
      expect(viewModel.state.value, 2);
    });

    test('stale restartable tasks cannot emit effects', () async {
      final viewModel = _TestViewModel();
      final gate = Completer<void>();
      final effects = <String>[];
      viewModel.effects.listen(effects.add);

      final first = viewModel.execute.restartable(key: 'load', (task) async {
        await gate.future;
        viewModel.emit('old');
      });
      await viewModel.execute.restartable(key: 'load', (task) async {
        viewModel.emit('new');
      });

      gate.complete();
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(effects, ['new']);
    });

    test('sequential runs invocations in order', () async {
      final viewModel = _TestViewModel();
      final firstGate = Completer<void>();
      final secondGate = Completer<void>();
      final events = <String>[];

      final first = viewModel.execute.sequential(key: 'save', (task) async {
        events.add('first:start');
        await firstGate.future;
        events.add('first:end');
      });
      final second = viewModel.execute.sequential(key: 'save', (task) async {
        events.add('second:start');
        await secondGate.future;
        events.add('second:end');
      });

      expect(events, ['first:start']);
      firstGate.complete();
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(events, ['first:start', 'first:end', 'second:start']);
      secondGate.complete();
      await second;
      expect(events, [
        'first:start',
        'first:end',
        'second:start',
        'second:end',
      ]);
    });

    test('sequential continues after an invocation fails', () async {
      final viewModel = _TestViewModel();
      final first = viewModel.execute.sequential(
        key: 'save',
        (task) async => throw ArgumentError('failed'),
      );
      final firstResult = expectLater(first, throwsArgumentError);

      final second = viewModel.execute.sequential(
        key: 'save',
        (task) async {},
      );

      await firstResult;
      await second;
    });

    test('disposal cancels active and queued tasks', () async {
      final viewModel = _TestViewModel();
      final gate = Completer<void>();
      late TaskContext activeContext;

      final active = viewModel.execute.sequential(key: 'save', (task) async {
        activeContext = task;
        await gate.future;
      });
      final queued = viewModel.execute.sequential(key: 'save', (task) async {});
      final activeResult = expectLater(active, completes);
      final queuedResult = expectLater(queued, completes);

      viewModel.dispose();

      expect(activeContext.isCancelled, isTrue);
      gate.complete();
      await activeResult;
      await queuedResult;
      await expectLater(viewModel.execute((task) async {}), completes);
    });

    test('rejects policy collisions on active keys', () async {
      final viewModel = _TestViewModel();
      final gate = Completer<void>();
      final active = viewModel.execute.droppable(key: 'operation', (
        task,
      ) async {
        await gate.future;
      });

      expect(
        () => viewModel.execute.restartable(key: 'operation', (task) async {}),
        throwsStateError,
      );

      gate.complete();
      await active;
    });
  });
}

final class _TestViewModel extends ViewModel {
  late final MutableState<int> _state = mutableStateOf(0);
  late final MutableEffects<String> _effects = effectsOf();

  StateValue<int> get state => _state;
  Effects<String> get effects => _effects;
  int disposeCount = 0;

  void setValue(int value) => _state.value = value;
  void increment() => _state.update((value) => value + 1);
  void emit(String effect) => _effects.emit(effect);

  @override
  void onDispose() {
    disposeCount++;
  }
}

final class _ThrowingDisposeViewModel extends ViewModel {
  late final MutableState<int> _state = mutableStateOf(0);

  StateValue<int> get state => _state;

  void update() => _state.value++;

  @override
  void onDispose() {
    throw ArgumentError('dispose failed');
  }
}
