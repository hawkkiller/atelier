import 'dart:async';

import 'task_zone.dart';

enum TaskPolicy { concurrent, sequential, droppable, restartable }

abstract interface class CancellationToken {
  bool get isCancelled;

  /// Completes when this task is cancelled, but not when it finishes normally.
  Future<void> get cancelled;

  void throwIfCancelled();
}

abstract interface class TaskContext implements CancellationToken {
  bool get isActive;

  Object? get key;

  TaskPolicy get policy;

  void ensureActive();
}

/// Thrown when an Atelier task is invalidated by restart or disposal.
/// Any instance is swallowed whenever the throwing invocation's context is
/// cancelled; the same exception from an uncancelled context is propagated.
final class TaskCancelledException implements Exception {
  const TaskCancelledException([this.reason = 'The task was cancelled.']);

  final String reason;

  @override
  String toString() => 'TaskCancelledException: $reason';
}

abstract interface class TaskExecutor {
  /// Runs [block] as an Atelier task.
  ///
  /// All entry points return a [Future], including when [block] throws
  /// synchronously. Calls made after disposal complete normally without
  /// invoking [block].
  /// State/effect writes from stale task zones are discarded automatically.
  /// Dart cannot preempt arbitrary work or external side effects: call
  /// [TaskContext.ensureActive] immediately before repository, platform, or UI
  /// side effects (and for expensive work).
  /// Any [TaskCancelledException] thrown by a cancelled invocation is swallowed
  /// at the executor boundary, so cancellation completes its [Future] normally.
  /// Other errors propagate unchanged, including errors raised after
  /// cancellation.
  Future<void> call(Future<void> Function(TaskContext task) block, {Object? key});

  /// Runs independently. [key] is metadata only, so concurrent invocations
  /// can coexist with each other and with an owned keyed lane.
  Future<void> concurrent(
    Future<void> Function(TaskContext task) block, {
    Object? key,
  });

  /// Queues calls in order for [key]. Sequential, droppable, and restartable
  /// invocations own a keyed lane; concurrent invocations can coexist with
  /// any lane and keys do not affect other keys.
  Future<void> sequential(
    Future<void> Function(TaskContext task) block, {
    required Object key,
  });

  /// Shares the active invocation's future for [key] and does not run a
  /// repeated block. The lane is released after that future settles.
  Future<void> droppable(
    Future<void> Function(TaskContext task) block, {
    required Object key,
  });

  /// Invalidates the previous invocation for [key]. Cancellation is
  /// cooperative: an active block remains pending until it returns or throws.
  Future<void> restartable(
    Future<void> Function(TaskContext task) block, {
    required Object key,
  });
}

final class AtelierTaskExecutor implements TaskExecutor {
  bool _isDisposed = false;
  final Set<_TaskContext> _activeContexts = {};
  final Map<Object, _TaskLane> _lanes = {};

  @override
  Future<void> call(Future<void> Function(TaskContext task) block, {Object? key}) {
    return concurrent(block, key: key);
  }

  @override
  Future<void> concurrent(
    Future<void> Function(TaskContext task) block, {
    Object? key,
  }) {
    if (_isDisposed) {
      return _disposedFuture();
    }

    final context = _TaskContext(key: key, policy: TaskPolicy.concurrent);
    return _run(context, block);
  }

  @override
  Future<void> droppable(
    Future<void> Function(TaskContext task) block, {
    required Object key,
  }) {
    if (_isDisposed) {
      return _disposedFuture();
    }

    final existing = _lanes[key];
    if (existing != null) {
      _requirePolicy(existing, TaskPolicy.droppable);
      return existing.activeFuture!;
    }

    final lane = _TaskLane(TaskPolicy.droppable);
    _lanes[key] = lane;
    final context = _TaskContext(key: key, policy: TaskPolicy.droppable);
    final future = _run(context, block);
    lane.activeFuture = future;
    unawaited(
      future
          .whenComplete(() {
            if (identical(_lanes[key], lane)) {
              _lanes.remove(key);
            }
          })
          .then<void>((_) {}, onError: (_, _) {}),
    );
    return future;
  }

  @override
  Future<void> restartable(
    Future<void> Function(TaskContext task) block, {
    required Object key,
  }) {
    if (_isDisposed) {
      return _disposedFuture();
    }

    final existing = _lanes[key];
    if (existing != null) {
      _requirePolicy(existing, TaskPolicy.restartable);
      existing.activeContext?.cancel(
        const TaskCancelledException(
          'The task was superseded by a newer invocation.',
        ),
      );
    }

    final lane = existing ?? _TaskLane(TaskPolicy.restartable);
    _lanes[key] = lane;
    final context = _TaskContext(key: key, policy: TaskPolicy.restartable);
    final future = _run(context, block);
    lane
      ..activeContext = context
      ..activeFuture = future;

    unawaited(
      future
          .whenComplete(() {
            if (identical(lane.activeContext, context)) {
              lane
                ..activeContext = null
                ..activeFuture = null;
              if (identical(_lanes[key], lane)) {
                _lanes.remove(key);
              }
            }
          })
          .then<void>((_) {}, onError: (_, _) {}),
    );
    return future;
  }

  @override
  Future<void> sequential(
    Future<void> Function(TaskContext task) block, {
    required Object key,
  }) {
    if (_isDisposed) {
      return _disposedFuture();
    }

    final existing = _lanes[key];
    if (existing != null) {
      _requirePolicy(existing, TaskPolicy.sequential);
    }

    final lane = existing ?? _TaskLane(TaskPolicy.sequential);
    _lanes[key] = lane;
    final invocation = _SequentialInvocation(block);
    lane.queue.add(invocation);
    _startNextSequential(key, lane);
    return invocation.completer.future;
  }

  Future<void> _run(
    _TaskContext context,
    Future<void> Function(TaskContext task) block,
  ) async {
    _activeContexts.add(context);
    try {
      await runWithAtelierTask(context, () => block(context));
      context.ensureActive();
    } catch (error, stackTrace) {
      if (context.isCancelled && error is TaskCancelledException) {
        return;
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      context.finish();
      _activeContexts.remove(context);
    }
  }

  void _startNextSequential(Object key, _TaskLane lane) {
    if (_isDisposed || lane.activeFuture != null || lane.queue.isEmpty) {
      return;
    }

    final invocation = lane.queue.removeAt(0);
    final context = _TaskContext(key: key, policy: TaskPolicy.sequential);
    final future = invocation.run(this, context);
    lane
      ..activeContext = context
      ..activeFuture = future;

    unawaited(
      future
          .whenComplete(() {
            if (!identical(lane.activeContext, context)) {
              return;
            }
            lane
              ..activeContext = null
              ..activeFuture = null;
            if (lane.queue.isEmpty) {
              if (identical(_lanes[key], lane)) {
                _lanes.remove(key);
              }
            } else {
              _startNextSequential(key, lane);
            }
          })
          .then<void>((_) {}, onError: (_, _) {}),
    );
  }

  void _requirePolicy(_TaskLane lane, TaskPolicy expectedPolicy) {
    if (lane.policy != expectedPolicy) {
      throw StateError(
        'Task key is already active with ${lane.policy.name} policy.',
      );
    }
  }

  Future<void> _disposedFuture() async {}

  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    const cancellation = TaskCancelledException(
      'The ViewModel has been disposed.',
    );
    for (final context in List<_TaskContext>.of(_activeContexts)) {
      context.cancel(cancellation);
    }
    for (final lane in _lanes.values) {
      for (final invocation in lane.queue) {
        invocation.cancel(cancellation);
      }
      lane.queue.clear();
    }
    _lanes.clear();
  }
}

final class _TaskContext implements TaskContext, AtelierTaskZoneContext {
  _TaskContext({required this.key, required this.policy});

  @override
  final Object? key;

  @override
  final TaskPolicy policy;

  final Completer<void> _cancelled = Completer<void>();
  bool _isFinished = false;
  TaskCancelledException? _cancellationException;

  @override
  bool get isCancelled => _cancellationException != null;

  @override
  bool get isActive => !_isFinished && !isCancelled;

  @override
  Future<void> get cancelled => _cancelled.future;

  TaskCancelledException get cancellationException =>
      _cancellationException ?? const TaskCancelledException('The task is no longer active.');

  @override
  void throwIfCancelled() {
    final exception = _cancellationException;
    if (exception != null) {
      throw exception;
    }
  }

  @override
  void ensureActive() {
    throwIfCancelled();
    if (_isFinished) {
      throw StateError('The task is no longer active.');
    }
  }

  void cancel(TaskCancelledException exception) {
    if (_isFinished || isCancelled) {
      return;
    }
    _cancellationException = exception;
    _cancelled.complete();
  }

  void finish() {
    _isFinished = true;
  }
}

final class _TaskLane {
  _TaskLane(this.policy);

  final TaskPolicy policy;
  final List<_SequentialInvocation> queue = [];
  _TaskContext? activeContext;
  Future<void>? activeFuture;
}

final class _SequentialInvocation {
  _SequentialInvocation(this.block);

  final Future<void> Function(TaskContext task) block;
  final Completer<void> completer = Completer<void>();

  Future<void> run(AtelierTaskExecutor executor, _TaskContext context) {
    final future = executor._run(context, block);
    unawaited(
      future.then<void>(
        (_) => completer.complete(),
        onError: (Object error, StackTrace stackTrace) {
          completer.completeError(error, stackTrace);
        },
      ),
    );
    return future;
  }

  void cancel(TaskCancelledException exception) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  }
}
