import 'package:meta/meta.dart';

import 'effects.dart';
import 'state_value.dart';
import 'task.dart';

/// Owns observable values, effects, and lifecycle-aware tasks.
abstract class ViewModel {
  ViewModel() : _executor = AtelierTaskExecutor();

  final AtelierTaskExecutor _executor;
  final List<void Function()> _ownedResources = [];
  bool _isDisposed = false;

  TaskExecutor get execute => _executor;

  bool get isDisposed => _isDisposed;

  @protected
  MutableState<T> mutableStateOf<T>(T initialValue) {
    _ensureNotDisposed();
    final state = AtelierMutableState<T>(initialValue);
    _ownedResources.add(state.close);
    return state;
  }

  @protected
  MutableEffects<E> effectsOf<E>() {
    _ensureNotDisposed();
    final effects = AtelierMutableEffects<E>();
    _ownedResources.add(effects.close);
    return effects;
  }

  @nonVirtual
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _executor.dispose();

    Object? error;
    StackTrace? stackTrace;
    try {
      onDispose();
    } catch (caughtError, caughtStackTrace) {
      error = caughtError;
      stackTrace = caughtStackTrace;
    } finally {
      for (final dispose in _ownedResources.reversed) {
        try {
          dispose();
        } catch (caughtError, caughtStackTrace) {
          error ??= caughtError;
          stackTrace ??= caughtStackTrace;
        }
      }
      _ownedResources.clear();
    }

    if (error != null) {
      Error.throwWithStackTrace(error, stackTrace!);
    }
  }

  @protected
  void onDispose() {}

  void _ensureNotDisposed() {
    if (_isDisposed) {
      throw StateError('The ViewModel has been disposed.');
    }
  }
}
