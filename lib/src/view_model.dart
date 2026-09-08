import 'package:meta/meta.dart';
import 'dispose.dart';
import 'effects.dart';
import 'state_value.dart';
import 'task.dart';

/// Owns one aggregate state value, effects, and lifecycle-aware tasks.
///
/// State is initialized by [initialState] and can only be changed from a task
/// through [TaskContext.updateState]. Reducers run synchronously and observe
/// the latest committed value.
abstract class ViewModel<S extends Object> {
  ViewModel(S initialState) : _state = AtelierMutableState(initialState) {
    _executor = AtelierTaskExecutor<S>(updateState: _commit, checkAllowed: _checkReducerGuard);
  }

  final AtelierMutableState<S> _state;
  late final AtelierTaskExecutor<S> _executor;
  final List<void Function()> _ownedResources = [];
  bool _isDisposed = false;
  bool _inReducer = false;

  StateValue<S> get state => _state;

  /// Runs work owned by this ViewModel. Expose application actions as methods.
  @protected
  TaskExecutor<S> get execute => _executor;
  bool get isDisposed => _isDisposed;

  @protected
  MutableEffects<E> effectsOf<E>() {
    _ensureNotDisposed();
    final effects = AtelierMutableEffects<E>();
    _ownedResources.add(effects.close);
    return effects;
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

  @nonVirtual
  void dispose() {
    if (_isDisposed) return;
    if (_inReducer) throw StateError('Cannot dispose a ViewModel from a state reducer.');
    _isDisposed = true;
    _executor.dispose();
    try {
      disposeAll([onDispose, _state.close, ..._ownedResources.reversed]);
    } finally {
      _ownedResources.clear();
    }
  }

  @protected
  void onDispose() {}
  void _ensureNotDisposed() {
    if (_isDisposed) throw StateError('The ViewModel has been disposed.');
  }
}
