import 'dart:async';

import 'package:meta/meta.dart';

import 'command.dart';
import 'effects.dart';
import 'observer.dart';
import 'state_value.dart';
import 'task.dart';

/// Owns one aggregate state value, effects, and lifecycle-aware tasks.
///
/// State is initialized by [initialState] and changed from a task through
/// [TaskContext.state] or [TaskContext.updateState], or outside a task with
/// [updateState]. Writes run synchronously and observe the latest committed
/// value.
///
/// Public operations are usually declared as commands:
///
/// ```dart
/// class SearchViewModel extends ViewModel<SearchState> {
///   SearchViewModel(this._repository) : super(const SearchState());
///
///   final SearchRepository _repository;
///
///   late final search = restartable((String query, task) async {
///     task.state = SearchState(results: await _repository.search(query));
///   });
/// }
/// ```
abstract class ViewModel<S extends Object> {
  /// Creates a ViewModel whose [state] starts at [initialState].
  ViewModel(S initialState) : _state = MutableStateValue(initialState) {
    _executor = AtelierTaskExecutor<S>(
      updateState: _commit,
      readState: () => _state.value,
      checkAllowed: _checkReducerGuard,
      onError: (task, error, stackTrace) {
        observer?.onTaskError(this, error, stackTrace);
        onTaskError(task, error, stackTrace);
      },
    );
    _state.value = _derived(initialState);
    observer?.onCreate(this);
  }

  /// Receives the lifecycle, state, effect, and task error events of every
  /// ViewModel; see [AtelierObserver]. Read at each event, so replacing it
  /// applies to existing ViewModels too.
  static AtelierObserver? observer;

  final MutableStateValue<S> _state;
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

  /// Declares a command whose invocations run independently.
  ///
  /// ```dart
  /// late final log = concurrent((String event, task) async { ... });
  /// ```
  @protected
  CommandFactory<S> get concurrent => CommandFactory(_createCommandRunner(TaskPolicy.concurrent));

  /// Declares a command whose invocations run one at a time, in call order.
  @protected
  CommandFactory<S> get sequential => CommandFactory(_createCommandRunner(TaskPolicy.sequential));

  /// Declares a command that ignores calls while an invocation is running;
  /// repeated calls share the running invocation's [Future].
  @protected
  CommandFactory<S> get droppable => CommandFactory(_createCommandRunner(TaskPolicy.droppable));

  /// Declares a command where each call cancels the running invocation.
  ///
  /// ```dart
  /// late final search = restartable((String query, task) async {
  ///   task.state = SearchState(results: await repository.search(query));
  /// });
  /// ```
  @protected
  CommandFactory<S> get restartable => CommandFactory(_createCommandRunner(TaskPolicy.restartable));

  CommandRunner<S> Function() _createCommandRunner(TaskPolicy policy) {
    return () {
      final runner = CommandRunner<S>(_executor, policy);
      if (_isDisposed) {
        runner.close();
      } else {
        _ownedResources.add(runner.close);
      }
      return runner;
    };
  }

  /// Creates an effect channel that is closed when this ViewModel is disposed.
  ///
  /// Typically assigned to a `late final` field and exposed as [Effects].
  @protected
  MutableEffects<E> effectsOf<E>() {
    _ensureNotDisposed();
    return _createEffects<E>();
  }

  AtelierMutableEffects<E> _createEffects<E>() {
    final effects = AtelierMutableEffects<E>(
      onEmit: (effect) => observer?.onEffect(this, effect),
    );
    if (_isDisposed) {
      effects.close();
    } else {
      _ownedResources.add(effects.close);
    }
    return effects;
  }

  /// Returns [state] with its computed fields brought up to date.
  ///
  /// Runs on the initial state and on the result of every write, from
  /// [updateState] and from tasks, so derived values such as `canSave` are
  /// set in one place and cannot go stale:
  ///
  /// ```dart
  /// @override
  /// FormState derive(FormState state) =>
  ///     state.copyWith(canSave: state.name.isNotEmpty && !state.saving);
  /// ```
  ///
  /// It is a reducer: keep it synchronous and pure, and never start tasks,
  /// update state, or dispose from it. The first call happens inside this
  /// class's constructor, before the subclass constructor body runs, so it
  /// can read fields set by initializers but not ones the body assigns.
  @protected
  S derive(S state) => state;

  S _derived(S state) {
    _inReducer = true;
    try {
      return derive(state);
    } finally {
      _inReducer = false;
    }
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

  /// Replaces the state with [reducer] applied to it, outside any task.
  ///
  /// Use it for synchronous changes such as input edits or values that
  /// [follow] delivers; asynchronous work belongs in a task. Ignored after
  /// disposal. Like task writes, it throws [StateError] from a reducer.
  @protected
  void updateState(S Function(S current) reducer) => _reduce(reducer, () => true);

  /// Calls [onData] with every event of [source] until this ViewModel is
  /// disposed, and returns the subscription.
  ///
  /// When [source] is a [StateValue], [onData] first runs synchronously with
  /// its current value, so the ViewModel can apply it before its first frame,
  /// and the replay that subscribing delivers is skipped:
  ///
  /// ```dart
  /// LibraryViewModel(this.library) : super(const LibraryState()) {
  ///   follow(library.snapshot, (snapshot) {
  ///     updateState((state) => state.copyWith(items: snapshot.items));
  ///   });
  /// }
  /// ```
  ///
  /// Throws [StateError] after disposal.
  @protected
  StreamSubscription<T> follow<T>(
    Stream<T> source,
    void Function(T value) onData, {
    Function? onError,
  }) {
    _ensureNotDisposed();
    final StreamSubscription<T> subscription;
    if (source is StateValue<T>) {
      var replayed = false;
      subscription = source.listen((value) {
        if (replayed) {
          onData(value);
        } else {
          replayed = true;
        }
      }, onError: onError);
      onData(source.value);
    } else {
      subscription = source.listen(onData, onError: onError);
    }
    return disposeWith(subscription, (subscription) => subscription.cancel());
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

  void _commit(TaskContext<S> context, S Function(S) reducer) => _reduce(reducer, () => context.isActive);

  void _reduce(S Function(S) reducer, bool Function() isActive) {
    if (_inReducer) {
      throw StateError('Nested state updates are not allowed from a reducer.');
    }
    if (_isDisposed || _state.isClosed || !isActive()) return;
    _inReducer = true;
    S next;
    try {
      next = derive(reducer(_state.value));
    } finally {
      _inReducer = false;
    }
    if (_isDisposed || _state.isClosed || !isActive()) return;
    final previous = _state.value;
    _state.value = next;
    observer?.onStateChanged(this, previous, next);
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
    observer?.onDispose(this);
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

/// Gives a ViewModel one effect channel of type [E], closed on disposal.
///
/// ```dart
/// class SaveViewModel extends ViewModel<SaveState>
///     with ViewModelEffects<SaveState, SaveEffect> {
///   SaveViewModel() : super(const SaveState());
///
///   late final save = droppable.noArgs((task) async {
///     await repository.save(task.state.draft);
///     emit(SaveEffect.saved);
///   });
/// }
/// ```
///
/// Use [ViewModel.effectsOf] instead when a ViewModel needs several channels.
mixin ViewModelEffects<S extends Object, E> on ViewModel<S> {
  late final AtelierMutableEffects<E> _effects = _createEffects<E>();

  /// One-shot outcomes for the view to present, such as navigation or a message.
  Effects<E> get effects => _effects;

  /// Delivers [effect] to current listeners of [effects].
  ///
  /// Follows [MutableEffects.emit]: dropped silently from a cancelled task,
  /// and throws [EffectsDisposedError] after disposal from outside a task.
  @protected
  void emit(E effect) => _effects.emit(effect);
}
