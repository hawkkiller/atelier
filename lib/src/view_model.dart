import 'dart:async';

import 'package:meta/meta.dart';

import 'effects.dart';
import 'state_value.dart';
import 'task.dart';

/// Owns one aggregate state value, effects, and lifecycle-aware tasks.
///
/// State is initialized by [initialState] and can only be changed from a task
/// through [TaskContext.updateState]. Reducers run synchronously and observe
/// the latest committed value.
abstract class ViewModel<S extends Object> {
  /// Creates a ViewModel whose [state] starts at [initialState].
  ViewModel(S initialState) : _state = AtelierMutableState(initialState) {
    _executor = AtelierTaskExecutor<S>(updateState: _commit, checkAllowed: _checkReducerGuard, onError: onTaskError);
  }

  final AtelierMutableState<S> _state;
  late final AtelierTaskExecutor<S> _executor;
  final List<void Function()> _ownedResources = [];
  bool _isDisposed = false;
  bool _inReducer = false;

  /// The current state and its subsequent updates.
  StateValue<S> get state => _state;

  /// Starts lifecycle-aware tasks; see [TaskExecutor] for the policies.
  TaskExecutor<S> get execute => _executor;

  /// Whether [dispose] has been called.
  bool get isDisposed => _isDisposed;

  /// Creates an effect channel that is closed when this ViewModel is disposed.
  ///
  /// Typically assigned to a `late final` field and exposed as [Effects].
  @protected
  MutableEffects<E> effectsOf<E>() {
    _ensureNotDisposed();
    final effects = AtelierMutableEffects<E>();
    _ownedResources.add(effects.close);
    return effects;
  }

  /// Registers [value] to be released with [dispose] when this ViewModel is
  /// disposed, and returns [value].
  ///
  /// Use it for ViewModel-owned resources such as a [StreamSubscription] or a
  /// [Timer]. Resources are released after [onDispose], in reverse
  /// registration order. Throws [StateError] after disposal.
  @protected
  T disposeWith<T>(T value, void Function(T value) dispose) {
    _ensureNotDisposed();
    _ownedResources.add(() => dispose(value));
    return value;
  }

  /// Called when a task fails with an error other than its own cancellation.
  ///
  /// [task] is still active unless it was cancelled, so an override can record
  /// the failure through [TaskContext.updateState] or emit an effect. If the
  /// override returns normally, the task's [Future] completes normally; the
  /// default rethrows, so the error propagates through the task's [Future].
  @protected
  void onTaskError(TaskContext<S> task, Object error, StackTrace stackTrace) {
    Error.throwWithStackTrace(error, stackTrace);
  }

  void _checkReducerGuard() {
    if (_inReducer) throw StateError('Cannot start or cancel a task from a state reducer.');
  }

  void _commit(TaskContext<S> context, S Function(S) reducer) {
    if (_inReducer) {
      throw StateError('Nested state updates are not allowed from a reducer.');
    }
    if (_isDisposed || !_state.isOpen || !context.isActive) return;
    _inReducer = true;
    S next;
    try {
      next = reducer(_state.value);
    } finally {
      _inReducer = false;
    }
    if (!_isDisposed && _state.isOpen && context.isActive) _state.setValue(next);
  }

  /// Cancels active and queued tasks, calls [onDispose], then closes state,
  /// effect channels and resources registered with [disposeWith].
  ///
  /// Idempotent. Called by `AtelierVmMixin`; call it yourself only when you
  /// own the ViewModel outside a widget.
  @nonVirtual
  void dispose() {
    if (_isDisposed) return;
    if (_inReducer) throw StateError('Cannot dispose a ViewModel from a state reducer.');
    _isDisposed = true;
    _executor.dispose();
    Object? error;
    StackTrace? stackTrace;
    try {
      onDispose();
    } catch (e, s) {
      error = e;
      stackTrace = s;
    }
    _state.close();
    for (final close in _ownedResources.reversed) {
      try {
        close();
      } catch (e, s) {
        error ??= e;
        stackTrace ??= s;
      }
    }
    _ownedResources.clear();
    if (error != null) Error.throwWithStackTrace(error, stackTrace!);
  }

  /// Custom cleanup. Runs after tasks are cancelled and before owned
  /// channels and resources are closed; state can still be read and effects
  /// emitted.
  @protected
  void onDispose() {}

  void _ensureNotDisposed() {
    if (_isDisposed) throw StateError('The ViewModel has been disposed.');
  }
}
