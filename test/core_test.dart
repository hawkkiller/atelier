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
      final firstUpdate = viewModel.setValue(1);
      final equalUpdate = viewModel.setValue(1);
      viewModel.state.listen(second.add);
      final increment = viewModel.increment();

      expect(first, isEmpty);
      expect(second, isEmpty);
      await Future.wait([firstUpdate, equalUpdate, increment]);
      await Future<void>.delayed(Duration.zero);

      expect(first, [0, 1, 1, 2]);
      expect(second, [1, 2]);
    });

    test('is broadcast', () {
      expect(_TestViewModel().state.isBroadcast, isTrue);
    });

    test('closes and ignores mutation commands when disposed', () async {
      final viewModel = _TestViewModel();
      final done = Completer<void>();
      viewModel.state.listen((_) {}, onDone: done.complete);

      viewModel.dispose();

      await done.future;
      final before = viewModel.state.value;
      await viewModel.setValue(1);
      expect(viewModel.state.value, before);
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
    test('reduces FIFO updates against the latest state and emits equals', () async {
      final viewModel = _TestViewModel();
      final values = <int>[];
      viewModel.state.listen(values.add);
      await viewModel.tasks((task) async {
        task.updateState((value) => value + 1);
        task.updateState((value) => value);
      });
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.state.value, 1);
      expect(values, [0, 1, 1]);
    });

    test('state is synchronously visible before the first await', () async {
      final viewModel = _TestViewModel();
      final reachedAwait = Completer<void>();
      final task = viewModel.tasks((context) async {
        context.updateState((_) => 7);
        expect(viewModel.state.value, 7);
        reachedAwait.complete();
        await Future<void>.delayed(Duration.zero);
      });
      await reachedAwait.future;
      expect(viewModel.state.value, 7);
      await task;
    });

    test('concurrent contexts linearize updates in call order', () async {
      final viewModel = _TestViewModel();
      final firstGate = Completer<void>();
      final secondGate = Completer<void>();
      final order = <String>[];
      final first = viewModel.tasks((task) async {
        await firstGate.future;
        task.updateState((value) {
          order.add('first');
          return value + 1;
        });
      });
      final second = viewModel.tasks((task) async {
        await secondGate.future;
        task.updateState((value) {
          order.add('second');
          return value + 1;
        });
      });
      secondGate.complete();
      await Future<void>.delayed(Duration.zero);
      firstGate.complete();
      await Future.wait([first, second]);
      expect(order, ['second', 'first']);
      expect(viewModel.state.value, 2);
    });

    test('captured contexts silently no-op after completion, replacement, and disposal', () async {
      final completed = _TestViewModel();
      late TaskContext<int> completedContext;
      await completed.tasks((task) async {
        completedContext = task;
      });
      var evaluated = false;
      completedContext.updateState((value) {
        evaluated = true;
        return value + 1;
      });
      expect(evaluated, isFalse);

      final replaced = _TestViewModel();
      final gate = Completer<void>();
      late TaskContext<int> replacedContext;
      final first = replaced.tasks.restartable(key: 'x', (task) async {
        replacedContext = task;
        await gate.future;
      });
      await replaced.tasks.restartable(key: 'x', (task) async {});
      var replacedEvaluated = false;
      replacedContext.updateState((value) {
        replacedEvaluated = true;
        return value + 1;
      });
      expect(replacedEvaluated, isFalse);
      gate.complete();
      await first;

      final disposed = _TestViewModel();
      late TaskContext<int> disposedContext;
      final pending = disposed.tasks((task) async {
        disposedContext = task;
        await Future<void>.delayed(Duration.zero);
      });
      disposed.dispose();
      var disposedEvaluated = false;
      disposedContext.updateState((value) {
        disposedEvaluated = true;
        return value + 1;
      });
      expect(disposedEvaluated, isFalse);
      await pending;
    });

    test('reducer errors propagate and later updates recover', () async {
      final viewModel = _TestViewModel();
      await expectLater(
        viewModel.tasks((task) async {
          task.updateState((_) => throw StateError('reducer'));
        }),
        throwsStateError,
      );
      expect(viewModel.state.value, 0);
      await viewModel.tasks((task) async {
        task.updateState((_) => 3);
      });
      expect(viewModel.state.value, 3);
    });

    test('reducers reject nested updates, task starts, and disposal', () async {
      final nested = _TestViewModel();
      await expectLater(
        nested.tasks((task) async {
          task.updateState((value) {
            task.updateState((_) => 9);
            return value + 1;
          });
        }),
        throwsStateError,
      );
      expect(nested.state.value, 0);

      final starting = _TestViewModel();
      await expectLater(
        starting.tasks((task) async {
          task.updateState((value) {
            starting.tasks((_) async {});
            return value + 1;
          });
        }),
        throwsStateError,
      );
      expect(starting.state.value, 0);

      final restarting = _TestViewModel();
      await expectLater(
        restarting.tasks.restartable(key: 'owned', (task) async {
          task.updateState((value) {
            restarting.tasks.restartable(key: 'owned', (task) async {});
            return value + 1;
          });
        }),
        throwsStateError,
      );
      expect(restarting.state.value, 0);

      final disposing = _TestViewModel();
      await expectLater(
        disposing.tasks((task) async {
          task.updateState((value) {
            disposing.dispose();
            return value + 1;
          });
        }),
        throwsStateError,
      );
      expect(disposing.state.value, 0);
    });

    test('onDispose can read state and emit effects', () async {
      final viewModel = _LifecycleViewModel();
      final effects = <String>[];
      await viewModel.setValue(4);
      viewModel.effects.listen(effects.add);
      viewModel.dispose();
      expect(viewModel.stateDuringDispose, 4);
      await Future<void>.delayed(Duration.zero);
      expect(effects, ['during']);
    });

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
      await viewModel.update();
      expect(viewModel.state.value, 0);
    });

    test('cancels tasks before onDispose and closes channels afterward', () async {
      final viewModel = _LifecycleViewModel();
      final stateDone = Completer<void>();
      final effectsDone = Completer<void>();
      viewModel.state.listen((_) {}, onDone: stateDone.complete);
      viewModel.effects.listen((_) {}, onDone: effectsDone.complete);
      final taskGate = Completer<void>();
      late TaskContext taskContext;
      final task = viewModel.tasks((context) async {
        taskContext = context;
        viewModel.taskContext = context;
        await taskGate.future;
      });

      viewModel.dispose();

      expect(taskContext.isCancelled, isTrue);
      expect(viewModel.sawCancelledTask, isTrue);
      expect(viewModel.channelsUsableDuringDispose, isTrue);
      taskGate.complete();
      await task;
      await Future.wait([stateDone.future, effectsDone.future]);
      await viewModel.setValue(2);
      expect(viewModel.state.value, 0);
      expect(
        () => viewModel.emit('after'),
        throwsA(isA<EffectsDisposedError>()),
      );
    });

    test('channels close and a failed disposal remains idempotent', () async {
      final viewModel = _LifecycleViewModel(throwOnDispose: true);
      final stateDone = Completer<void>();
      final effectsDone = Completer<void>();
      viewModel.state.listen((_) {}, onDone: stateDone.complete);
      viewModel.effects.listen((_) {}, onDone: effectsDone.complete);

      expect(viewModel.dispose, throwsA(isA<ArgumentError>()));
      await Future.wait([stateDone.future, effectsDone.future]);
      expect(viewModel.channelsUsableDuringDispose, isTrue);
      await viewModel.setValue(2);
      expect(viewModel.state.value, 0);
      expect(
        () => viewModel.emit('after'),
        throwsA(isA<EffectsDisposedError>()),
      );

      expect(viewModel.dispose, returnsNormally);
      expect(viewModel.disposeCount, 1);
    });
  });

  group('TaskExecutor', () {
    test('concurrent tasks expose context and run independently', () async {
      final viewModel = _TestViewModel();
      final firstGate = Completer<void>();
      final secondGate = Completer<void>();
      late TaskContext firstContext;
      late TaskContext secondContext;

      final first = viewModel.tasks((task) async {
        firstContext = task;
        await firstGate.future;
      }, key: 'load');
      final second = viewModel.tasks((task) async {
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

      final first = viewModel.tasks.droppable(key: 'login', (task) async {
        invocationCount++;
        await gate.future;
      });
      final second = viewModel.tasks.droppable(key: 'login', (task) async {
        invocationCount++;
      });

      expect(identical(first, second), isTrue);
      expect(invocationCount, 1);
      gate.complete();
      await second;
    });

    test('reentrant droppable shares the future without invoking its block', () async {
      final viewModel = _TestViewModel();
      addTearDown(viewModel.dispose);
      final gate = Completer<void>();
      late Future<void> nested;
      var repeatedBlockRan = false;
      final first = viewModel.tasks.droppable(key: #login, (task) async {
        nested = viewModel.tasks.droppable(key: #login, (_) async {
          repeatedBlockRan = true;
        });
        await gate.future;
      });
      expect(identical(first, nested), isTrue);
      expect(repeatedBlockRan, isFalse);
      gate.complete();
      await first;
    });

    test('reentrant restartable cancels the outer task and keeps the newest active', () async {
      final viewModel = _TestViewModel();
      addTearDown(viewModel.dispose);
      final gate = Completer<void>();
      late Future<void> nested;
      late TaskContext<int> outerContext;
      late TaskContext<int> nestedContext;
      final first = viewModel.tasks.restartable(key: #search, (task) async {
        outerContext = task;
        nested = viewModel.tasks.restartable(key: #search, (next) async {
          nestedContext = next;
          await gate.future;
          next.updateState((_) => 2);
        });
        task.updateState((_) => 1);
      });
      expect(outerContext.isCancelled, isTrue);
      expect(viewModel.state.value, 0);
      await first;
      // Finishing the outer invocation must not release the nested task's lane.
      await viewModel.tasks.restartable(key: #search, (task) async {
        task.updateState((_) => 3);
      });
      expect(nestedContext.isCancelled, isTrue);
      gate.complete();
      await nested;
      expect(viewModel.state.value, 3);
    });

    test('reentrant sequential waits for the outer task before running', () async {
      final viewModel = _TestViewModel();
      addTearDown(viewModel.dispose);
      final gate = Completer<void>();
      final events = <String>[];
      late Future<void> nested;
      final first = viewModel.tasks.sequential(key: #save, (task) async {
        events.add('outer start');
        nested = viewModel.tasks.sequential(key: #save, (_) async {
          events.add('nested');
        });
        await gate.future;
        events.add('outer end');
      });
      expect(events, ['outer start']);
      gate.complete();
      await first;
      await nested;
      expect(events, ['outer start', 'outer end', 'nested']);
    });

    test('restartable invalidates the previous invocation', () async {
      final viewModel = _TestViewModel();
      final firstGate = Completer<void>();
      late TaskContext firstContext;

      final first = viewModel.tasks.restartable(key: 'search', (task) async {
        firstContext = task;
        await firstGate.future;
      });
      final firstResult = expectLater(first, completes);

      final second = viewModel.tasks.restartable(
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

    test('restartable cancellation does not hide unrelated errors', () async {
      final viewModel = _TestViewModel();
      final gate = Completer<void>();

      final first = viewModel.tasks.restartable(key: 'search', (task) async {
        await gate.future;
        throw StateError('failed after cancellation');
      });
      final firstResult = expectLater(first, throwsStateError);

      await viewModel.tasks.restartable(key: 'search', (task) async {});
      gate.complete();

      await firstResult;
    });

    test('stale restartable tasks cannot overwrite state', () async {
      final viewModel = _TestViewModel();
      final gate = Completer<void>();

      final first = viewModel.tasks.restartable(key: 'load', (task) async {
        await gate.future;
        task.updateState((_) => 1);
      });
      await viewModel.tasks.restartable(key: 'load', (task) async {
        task.updateState((_) => 2);
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

      final first = viewModel.tasks.restartable(key: 'load', (task) async {
        await gate.future;
        viewModel.emit('old');
      });
      await viewModel.tasks.restartable(key: 'load', (task) async {
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

      final first = viewModel.tasks.sequential(key: 'save', (task) async {
        events.add('first:start');
        await firstGate.future;
        events.add('first:end');
      });
      final second = viewModel.tasks.sequential(key: 'save', (task) async {
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
      final first = viewModel.tasks.sequential(
        key: 'save',
        (task) async => throw ArgumentError('failed'),
      );
      final firstResult = expectLater(first, throwsArgumentError);

      final second = viewModel.tasks.sequential(
        key: 'save',
        (task) async {},
      );

      await firstResult;
      await second;
    });

    test('genuine synchronous throws are captured by every policy', () async {
      final viewModel = _TestViewModel();
      Future<void> syncThrow(TaskContext _) => throw StateError('sync');

      final callable = viewModel.tasks(syncThrow, key: 'call');
      expect(callable, isA<Future<void>>());
      await expectLater(callable, throwsStateError);

      final sequential = viewModel.tasks.sequential(syncThrow, key: 's');
      expect(sequential, isA<Future<void>>());
      await expectLater(sequential, throwsStateError);

      final droppable = viewModel.tasks.droppable(syncThrow, key: 'd');
      expect(droppable, isA<Future<void>>());
      await expectLater(droppable, throwsStateError);

      final restartable = viewModel.tasks.restartable(syncThrow, key: 'r');
      expect(restartable, isA<Future<void>>());
      await expectLater(restartable, throwsStateError);
    });

    test('synchronous failures release sequential, droppable, and restartable lanes', () async {
      final viewModel = _TestViewModel();
      var ran = 0;
      await expectLater(
        viewModel.tasks.sequential(
          key: 's',
          (task) => throw StateError('sync'),
        ),
        throwsStateError,
      );
      await viewModel.tasks.sequential(key: 's', (task) async => ran++);
      await expectLater(
        viewModel.tasks.droppable(key: 'd', (task) => throw StateError('sync')),
        throwsStateError,
      );
      await viewModel.tasks.droppable(key: 'd', (task) async => ran++);
      await expectLater(
        viewModel.tasks.restartable(key: 'r', (task) => throw StateError('sync')),
        throwsStateError,
      );
      await viewModel.tasks.restartable(key: 'r', (task) async => ran++);
      expect(ran, 3);
    });

    test('disposal cancels active and queued tasks', () async {
      final viewModel = _TestViewModel();
      final gate = Completer<void>();
      late TaskContext activeContext;

      final active = viewModel.tasks.sequential(key: 'save', (task) async {
        activeContext = task;
        await gate.future;
      });
      final queued = viewModel.tasks.sequential(key: 'save', (task) async {});
      final activeResult = expectLater(active, completes);
      final queuedResult = expectLater(queued, completes);

      viewModel.dispose();

      expect(activeContext.isCancelled, isTrue);
      gate.complete();
      await activeResult;
      await queuedResult;
      await expectLater(viewModel.tasks((task) async {}), completes);
    });

    test('disposal skips multiple queued sequential blocks', () async {
      final viewModel = _TestViewModel();
      final gate = Completer<void>();
      var ran = 0;
      final active = viewModel.tasks.sequential(key: 'save', (task) async {
        await gate.future;
      });
      final queued = [
        viewModel.tasks.sequential(key: 'save', (task) async => ran++),
        viewModel.tasks.sequential(key: 'save', (task) async => ran++),
        viewModel.tasks.sequential(key: 'save', (task) async => ran++),
      ];
      viewModel.dispose();
      gate.complete();
      await active;
      await Future.wait(queued);
      expect(ran, 0);
    });

    test('active disposal is cooperative for every policy', () async {
      final viewModel = _TestViewModel();
      final gates = List.generate(4, (_) => Completer<void>());
      final contexts = <TaskContext>[];
      final futures = <Future<void>>[
        viewModel.tasks((task) async {
          contexts.add(task);
          await gates[0].future;
        }, key: 'c'),
        viewModel.tasks.sequential((task) async {
          contexts.add(task);
          await gates[1].future;
        }, key: 's'),
        viewModel.tasks.droppable((task) async {
          contexts.add(task);
          await gates[2].future;
        }, key: 'd'),
        viewModel.tasks.restartable((task) async {
          contexts.add(task);
          await gates[3].future;
        }, key: 'r'),
      ];
      expect(contexts, hasLength(4));
      viewModel.dispose();
      for (final context in contexts) {
        expect(context.isCancelled, isTrue);
        await context.cancelled;
      }
      for (final gate in gates) {
        gate.complete();
      }
      await Future.wait(futures);
    });

    test('noncooperative active task remains pending until released', () async {
      final viewModel = _TestViewModel();
      final gate = Completer<void>();
      late TaskContext context;
      final future = viewModel.tasks((task) async {
        context = task;
        await gate.future;
      });
      viewModel.dispose();
      expect(context.isCancelled, isTrue);
      var settled = false;
      future.whenComplete(() => settled = true);
      await context.cancelled;
      expect(settled, isFalse);
      gate.complete();
      await future;
      expect(settled, isTrue);
    });

    test('cancellation notification and cooperative cancellation settle normally', () async {
      final viewModel = _TestViewModel();
      final gate = Completer<void>();
      late TaskContext context;
      final first = viewModel.tasks.restartable(key: 'r', (task) async {
        context = task;
        await gate.future;
        task.throwIfCancelled();
      });
      final replacement = viewModel.tasks.restartable(key: 'r', (task) async {});
      await context.cancelled;
      await replacement;
      gate.complete();
      await first;
      expect(context.isCancelled, isTrue);
    });

    test('a task can await cancellation and then return normally', () async {
      final viewModel = _TestViewModel();
      late TaskContext context;
      var resumed = false;
      final first = viewModel.tasks.restartable(key: 'await-cancel', (task) async {
        context = task;
        await task.cancelled;
        resumed = true;
      });
      await viewModel.tasks.restartable(key: 'await-cancel', (task) async {});
      await context.cancelled;
      await first;
      expect(resumed, isTrue);
    });

    test('a separately constructed cancellation exception is swallowed after cancellation', () async {
      final viewModel = _TestViewModel();
      final release = Completer<void>();
      late TaskContext context;
      final first = viewModel.tasks.restartable(key: 'separate-cancel', (task) async {
        context = task;
        await release.future;
        throw const TaskCancelledException('constructed by the block');
      });
      await viewModel.tasks.restartable(key: 'separate-cancel', (task) async {});
      await context.cancelled;
      release.complete();
      await first;
    });

    test('uncancelled cancellation exception and post-disposal errors propagate', () async {
      final viewModel = _TestViewModel();
      await expectLater(
        viewModel.tasks(
          (task) async => throw const TaskCancelledException(),
        ),
        throwsA(isA<TaskCancelledException>()),
      );
      final gate = Completer<void>();
      final future = viewModel.tasks((task) async {
        await gate.future;
        throw StateError('after disposal');
      });
      viewModel.dispose();
      gate.complete();
      await expectLater(future, throwsStateError);
    });

    test('all executor entry points skip blocks after disposal', () async {
      final viewModel = _TestViewModel()..dispose();
      var ran = 0;
      final futures = [
        viewModel.tasks((task) async => ran++),
        viewModel.tasks.sequential(key: 's', (task) async => ran++),
        viewModel.tasks.droppable(key: 'd', (task) async => ran++),
        viewModel.tasks.restartable(key: 'r', (task) async => ran++),
      ];
      await Future.wait(futures);
      expect(ran, 0);
    });

    test('lane ownership collisions cover all pairs and concurrent coexistence', () async {
      final viewModel = _TestViewModel();
      for (final pair in [
        (TaskPolicy.sequential, TaskPolicy.droppable),
        (TaskPolicy.sequential, TaskPolicy.restartable),
        (TaskPolicy.droppable, TaskPolicy.sequential),
        (TaskPolicy.droppable, TaskPolicy.restartable),
        (TaskPolicy.restartable, TaskPolicy.sequential),
        (TaskPolicy.restartable, TaskPolicy.droppable),
      ]) {
        final gate = Completer<void>();
        late TaskContext ownerContext;
        final owner = _startPolicy(
          viewModel,
          pair.$1,
          'collision',
          gate,
          onContext: (context) => ownerContext = context,
        );
        expect(ownerContext.isActive, isTrue);
        expect(ownerContext.isCancelled, isFalse);
        var rejectedRan = false;
        expect(
          () => _startPolicy(viewModel, pair.$2, 'collision', gate, onRun: () => rejectedRan = true),
          throwsStateError,
        );
        expect(rejectedRan, isFalse);
        expect(ownerContext.isActive, isTrue);
        expect(ownerContext.isCancelled, isFalse);
        gate.complete();
        await owner;
      }

      final ownedGate = Completer<void>();
      final concurrentGate = Completer<void>();
      var ownedEntered = false;
      var concurrentEntered = false;
      final owned = viewModel.tasks.sequential(key: 'coexist', (task) async {
        ownedEntered = true;
        await ownedGate.future;
      });
      final concurrent = viewModel.tasks((task) async {
        concurrentEntered = true;
        await concurrentGate.future;
      }, key: 'coexist');
      expect(ownedEntered, isTrue);
      expect(concurrentEntered, isTrue);
      ownedGate.complete();
      concurrentGate.complete();
      await Future.wait([owned, concurrent]);

      final sequentialGate = Completer<void>();
      final droppableGate = Completer<void>();
      var sequentialEntered = false;
      var droppableEntered = false;
      final distinctSequential = viewModel.tasks.sequential(key: 'sequential-key', (task) async {
        sequentialEntered = true;
        await sequentialGate.future;
      });
      final distinctDroppable = viewModel.tasks.droppable(key: 'droppable-key', (task) async {
        droppableEntered = true;
        await droppableGate.future;
      });
      expect(sequentialEntered, isTrue);
      expect(droppableEntered, isTrue);
      sequentialGate.complete();
      droppableGate.complete();
      await Future.wait([distinctSequential, distinctDroppable]);
    });

    test('ensureActive immediately before external callback skips stale invocation', () async {
      final viewModel = _TestViewModel();
      final resume = Completer<void>();
      var callbackCount = 0;
      final first = viewModel.tasks.restartable(key: 'effect', (task) async {
        await resume.future;
        try {
          task.ensureActive();
          callbackCount++;
        } on TaskCancelledException {
          // The callback is deliberately after the activity check.
        }
      });
      await viewModel.tasks.restartable(key: 'effect', (task) async {});
      resume.complete();
      await first;
      expect(callbackCount, 0);
    });
  });
}

Future<void> _startPolicy(
  _TestViewModel viewModel,
  TaskPolicy policy,
  Object key,
  Completer<void> gate, {
  void Function()? onRun,
  void Function(TaskContext context)? onContext,
}) {
  Future<void> block(TaskContext task) async {
    onContext?.call(task);
    onRun?.call();
    await gate.future;
  }

  return switch (policy) {
    TaskPolicy.concurrent => viewModel.tasks(block, key: key),
    TaskPolicy.sequential => viewModel.tasks.sequential(block, key: key),
    TaskPolicy.droppable => viewModel.tasks.droppable(block, key: key),
    TaskPolicy.restartable => viewModel.tasks.restartable(block, key: key),
  };
}

final class _TestViewModel extends ViewModel<int> {
  _TestViewModel() : super(0);
  TaskExecutor<int> get tasks => execute;
  late final MutableEffects<String> _effects = effectsOf();

  Effects<String> get effects => _effects;
  int disposeCount = 0;

  Future<void> setValue(int value) => execute((task) async => task.updateState((_) => value));
  Future<void> increment() => execute((task) async => task.updateState((value) => value + 1));
  void emit(String effect) => _effects.emit(effect);

  @override
  void onDispose() {
    disposeCount++;
  }
}

final class _LifecycleViewModel extends ViewModel<int> {
  _LifecycleViewModel({this.throwOnDispose = false}) : super(0);
  TaskExecutor<int> get tasks => execute;

  final bool throwOnDispose;
  late final MutableEffects<String> _effects = effectsOf();
  TaskContext? taskContext;
  bool sawCancelledTask = false;
  bool channelsUsableDuringDispose = false;
  int? stateDuringDispose;
  int disposeCount = 0;

  Effects<String> get effects => _effects;

  Future<void> setValue(int value) => execute((task) async => task.updateState((_) => value));
  void emit(String effect) => _effects.emit(effect);

  @override
  void onDispose() {
    disposeCount++;
    sawCancelledTask = taskContext?.isCancelled ?? false;
    stateDuringDispose = state.value;
    _effects.emit('during');
    channelsUsableDuringDispose = true;
    if (throwOnDispose) {
      throw ArgumentError('dispose failed');
    }
  }
}

final class _ThrowingDisposeViewModel extends ViewModel<int> {
  _ThrowingDisposeViewModel() : super(0);

  Future<void> update() => execute((task) async => task.updateState((value) => value + 1));

  @override
  void onDispose() {
    throw ArgumentError('dispose failed');
  }
}
