import 'dart:async';

import 'task_zone.dart';

/// How a task coordinates with other invocations that share its key.
///
/// See the matching [TaskExecutor] method for each policy's semantics.
enum TaskPolicy {
  /// Runs independently; the key is metadata only. See [TaskExecutor.concurrent].
  concurrent,

  /// Queues invocations in call order. See [TaskExecutor.sequential].
  sequential,

  /// Ignores calls while one is active. See [TaskExecutor.droppable].
  droppable,

  /// Cancels the active invocation and starts anew. See [TaskExecutor.restartable].
  restartable,
}

/// A read-only view of a task's cancellation, safe to pass to repositories.
abstract interface class CancellationToken {
  /// Whether the task was cancelled by restart or disposal.
  bool get isCancelled;

  /// Completes when this task is cancelled, but not when it finishes normally.
  Future<void> get cancelled;

  /// Throws [TaskCancelledException] if [isCancelled] is true.
  void throwIfCancelled();
}

/// The handle a task block receives: cancellation, metadata and state writes.
abstract interface class TaskContext<S extends Object> implements CancellationToken {
  /// Whether the task is neither cancelled nor finished.
  bool get isActive;

  /// The key the task was started with, or null for an unkeyed task.
  Object? get key;

  /// The policy the task was started with.
  TaskPolicy get policy;

  /// Throws [TaskCancelledException] if cancelled, or [StateError] if the task
  /// already finished.
  ///
  /// Call it immediately before external side effects (repository writes,
  /// navigation, platform calls) that must not run for a stale task.
  void ensureActive();

  /// Applies a synchronous reducer to the latest committed state.
  ///
  /// The new state is published before this method returns, and equal values
  /// are emitted. Reducers must be pure and non-reentrant: nested updates,
  /// starting a task on the owning ViewModel, or disposing it throw
  /// [StateError]. Reducer errors propagate through the task's [Future].
  /// Stale contexts are silent no-ops and their reducers are not evaluated.
  void updateState(S Function(S current) reducer);
}

/// Thrown when an Atelier task is invalidated by restart or disposal.
/// Any instance is swallowed whenever the throwing invocation's context is
/// cancelled; the same exception from an uncancelled context is propagated.
final class TaskCancelledException implements Exception {
  /// Creates a cancellation exception with a human-readable [reason].
  const TaskCancelledException([this.reason = 'The task was cancelled.']);

  /// Why the task was cancelled.
  final String reason;

  @override
  String toString() => 'TaskCancelledException: $reason';
}

/// Starts lifecycle-aware tasks for a ViewModel; available as `execute`.
abstract interface class TaskExecutor<S extends Object> {
  /// Runs [block] as an Atelier task. Shorthand for [concurrent].
  ///
  /// All entry points return a [Future], including when [block] throws
  /// synchronously. Calls made after disposal complete normally without
  /// invoking [block].
  /// Canonical state writes use [TaskContext.updateState]. Effects retain
  /// Zone-based stale-write suppression.
  /// Dart cannot preempt arbitrary work or external side effects: call
  /// [TaskContext<S>.ensureActive] immediately before repository, platform, or UI
  /// side effects (and for expensive work).
  /// Any [TaskCancelledException] thrown by a cancelled invocation is swallowed
  /// at the executor boundary, so cancellation completes its [Future] normally.
  /// Other errors propagate unchanged, including errors raised after
  /// cancellation.
  Future<void> call(Future<void> Function(TaskContext<S> task) block, {Object? key});

  /// Runs independently. [key] is metadata only, so concurrent invocations
  /// can coexist with each other and with an owned keyed lane.
  Future<void> concurrent(
    Future<void> Function(TaskContext<S> task) block, {
    Object? key,
  });

  /// Queues calls in order for [key]. Sequential, droppable, and restartable
  /// invocations own a keyed lane; concurrent invocations can coexist with
  /// any lane and keys do not affect other keys.
  Future<void> sequential(
    Future<void> Function(TaskContext<S> task) block, {
    required Object key,
  });

  /// Shares the active invocation's future for [key] and does not run a
  /// repeated block. The lane is released after that future settles.
  Future<void> droppable(
    Future<void> Function(TaskContext<S> task) block, {
    required Object key,
  });

  /// Invalidates the previous invocation for [key]. Cancellation is
  /// cooperative: an active block remains pending until it returns or throws.
  Future<void> restartable(
    Future<void> Function(TaskContext<S> task) block, {
    required Object key,
  });
}

/// The [TaskExecutor] implementation owned by a ViewModel. Not exported.
final class AtelierTaskExecutor<S extends Object> implements TaskExecutor<S> {
  /// Creates an executor wired to its ViewModel's state and error hooks.
  AtelierTaskExecutor({
    required void Function(TaskContext<S>, S Function(S)) updateState,
    required void Function() checkAllowed,
    required void Function(TaskContext<S> task, Object error, StackTrace stackTrace) onError,
  }) : _updateState = updateState,
       _checkAllowed = checkAllowed,
       _onError = onError;
  final void Function(TaskContext<S>, S Function(S)) _updateState;
  final void Function() _checkAllowed;
  final void Function(TaskContext<S> task, Object error, StackTrace stackTrace) _onError;
  bool _isDisposed = false;
  final Set<_TaskContext<S>> _activeContexts = {};
  final Map<Object, _TaskLane<S>> _lanes = {};

  @override
  Future<void> call(Future<void> Function(TaskContext<S> task) block, {Object? key}) {
    return concurrent(block, key: key);
  }

  @override
  Future<void> concurrent(
    Future<void> Function(TaskContext<S> task) block, {
    Object? key,
  }) {
    _checkAllowed();
    if (_isDisposed) {
      return _disposedFuture();
    }

    return _run(_newContext(key, TaskPolicy.concurrent), block);
  }

  @override
  Future<void> droppable(
    Future<void> Function(TaskContext<S> task) block, {
    required Object key,
  }) {
    _checkAllowed();
    if (_isDisposed) {
      return _disposedFuture();
    }

    final existing = _lanes[key];
    if (existing != null) {
      _requirePolicy(existing, TaskPolicy.droppable);
      return existing.activeFuture!;
    }

    final lane = _TaskLane<S>(TaskPolicy.droppable);
    _lanes[key] = lane;
    final context = _newContext(key, TaskPolicy.droppable);
    final future = _start(lane, context, block);
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
    Future<void> Function(TaskContext<S> task) block, {
    required Object key,
  }) {
    _checkAllowed();
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

    final lane = existing ?? _TaskLane<S>(TaskPolicy.restartable);
    _lanes[key] = lane;
    final context = _newContext(key, TaskPolicy.restartable);
    final future = _start(lane, context, block);

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
    Future<void> Function(TaskContext<S> task) block, {
    required Object key,
  }) {
    _checkAllowed();
    if (_isDisposed) {
      return _disposedFuture();
    }

    final existing = _lanes[key];
    if (existing != null) {
      _requirePolicy(existing, TaskPolicy.sequential);
    }

    final lane = existing ?? _TaskLane<S>(TaskPolicy.sequential);
    _lanes[key] = lane;
    final invocation = _SequentialInvocation(block);
    lane.queue.add(invocation);
    _startNextSequential(key, lane);
    return invocation.completer.future;
  }

  _TaskContext<S> _newContext(Object? key, TaskPolicy policy) {
    return _TaskContext<S>(key: key, policy: policy, update: _updateState, isOwnerDisposed: () => _isDisposed);
  }

  /// Publishes [context] as the lane's active invocation before [block] runs,
  /// so a re-entrant call for the same key made before the block's first
  /// `await` observes a fully initialized lane.
  Future<void> _start(
    _TaskLane<S> lane,
    _TaskContext<S> context,
    Future<void> Function(TaskContext<S> task) block,
  ) {
    final completer = Completer<void>();
    lane
      ..activeContext = context
      ..activeFuture = completer.future;
    unawaited(_run(context, block).then<void>(completer.complete, onError: completer.completeError));
    return completer.future;
  }

  Future<void> _run(
    _TaskContext<S> context,
    Future<void> Function(TaskContext<S> task) block,
  ) async {
    _activeContexts.add(context);
    try {
      await runWithAtelierTask(context, () => block(context));
      context.ensureActive();
    } catch (error, stackTrace) {
      if (context.isCancelled && error is TaskCancelledException) {
        return;
      }
      _onError(context, error, stackTrace);
    } finally {
      context.finish();
      _activeContexts.remove(context);
    }
  }

  void _startNextSequential(Object key, _TaskLane<S> lane) {
    if (_isDisposed || lane.activeFuture != null || lane.queue.isEmpty) {
      return;
    }

    final invocation = lane.queue.removeAt(0);
    final context = _newContext(key, TaskPolicy.sequential);
    final future = _start(lane, context, invocation.block);
    unawaited(
      future.then<void>(
        (_) => invocation.completer.complete(),
        onError: (Object error, StackTrace stackTrace) {
          invocation.completer.completeError(error, stackTrace);
        },
      ),
    );

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

  void _requirePolicy(_TaskLane<S> lane, TaskPolicy expectedPolicy) {
    if (lane.policy != expectedPolicy) {
      throw StateError(
        'Task key is already active with ${lane.policy.name} policy.',
      );
    }
  }

  Future<void> _disposedFuture() async {}

  /// Cancels active tasks, skips queued ones and rejects later calls.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;

    const cancellation = TaskCancelledException(
      'The ViewModel has been disposed.',
    );
    for (final context in List<_TaskContext<S>>.of(_activeContexts)) {
      context.cancel(cancellation);
    }
    for (final lane in _lanes.values) {
      for (final invocation in lane.queue) {
        invocation.cancel();
      }
      lane.queue.clear();
    }
    _lanes.clear();
  }
}

final class _TaskContext<S extends Object> implements TaskContext<S>, AtelierTaskZoneContext {
  _TaskContext({required this.key, required this.policy, required this.update, required this.isOwnerDisposed});
  final void Function(TaskContext<S>, S Function(S)) update;
  final bool Function() isOwnerDisposed;

  @override
  bool get suppressesWrites => isCancelled || isOwnerDisposed();

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

  @override
  void updateState(S Function(S current) reducer) {
    if (isActive) update(this, reducer);
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

final class _TaskLane<S extends Object> {
  _TaskLane(this.policy);

  final TaskPolicy policy;
  final List<_SequentialInvocation<S>> queue = [];
  _TaskContext<S>? activeContext;
  Future<void>? activeFuture;
}

final class _SequentialInvocation<S extends Object> {
  _SequentialInvocation(this.block);

  final Future<void> Function(TaskContext<S> task) block;
  final Completer<void> completer = Completer<void>();

  void cancel() {
    if (!completer.isCompleted) {
      completer.complete();
    }
  }
}
