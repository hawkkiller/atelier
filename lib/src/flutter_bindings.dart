import 'dart:async';

import 'package:flutter/widgets.dart';

import 'effects.dart';
import 'state_value.dart';
import 'view_model.dart';

/// Lifecycle-aware bindings available to an Atelier-managed Flutter [State].
abstract interface class AtelierStateBindings {
  /// Returns the current value and rebuilds this [State] for every update.
  ///
  /// Call this method from [State.build].
  T watch<T>(StateValue<T> state);

  /// Returns a selected value and rebuilds when that selection changes.
  ///
  /// Call this method from [State.build]. By default, selections are compared
  /// with `==`.
  R watchSelect<T, R>(
    StateValue<T> state,
    R Function(T value) select, {
    bool Function(R previous, R next)? equals,
  });

  /// Listens for effects without rebuilding.
  ///
  /// Call this from [State.initState] or another lifecycle method, not from
  /// [State.build]. Repeating the same [effects]/[listener] identity is a
  /// no-op; a different identity creates a separate subscription.
  ///
  /// The subscription is cancelled automatically during [State.dispose].
  void listen<E>(Effects<E> effects, void Function(E effect) listener);
}

/// Adds state/effect bindings and automatic resource disposal to a [State].
mixin AtelierAutoDisposeMixin<W extends StatefulWidget> on State<W> implements AtelierStateBindings {
  late final _AtelierStateLifecycle _atelierLifecycle = _AtelierStateLifecycle(
    isMounted: () => mounted,
    rebuild: () => setState(() {}),
  );

  @override
  T watch<T>(StateValue<T> state) => _atelierLifecycle.watch(state);

  @override
  R watchSelect<T, R>(
    StateValue<T> state,
    R Function(T value) select, {
    bool Function(R previous, R next)? equals,
  }) {
    return _atelierLifecycle.watchSelect(state, select, equals: equals);
  }

  @override
  void listen<E>(Effects<E> effects, void Function(E effect) listener) {
    _atelierLifecycle.listen(effects, listener);
  }

  T disposeWith<T>(T value, void Function(T value) dispose) {
    return _atelierLifecycle.disposeWith(value, dispose);
  }

  TextEditingController textController({String? text}) {
    return disposeWith(
      TextEditingController(text: text),
      (controller) => controller.dispose(),
    );
  }

  FocusNode focusNode() {
    return disposeWith(FocusNode(), (node) => node.dispose());
  }

  ScrollController scrollController({
    double initialScrollOffset = 0,
    bool keepScrollOffset = true,
  }) {
    return disposeWith(
      ScrollController(
        initialScrollOffset: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
      ),
      (controller) => controller.dispose(),
    );
  }

  @override
  @mustCallSuper
  void setState(VoidCallback fn) {
    super.setState(fn);
    _atelierLifecycle.beginWatchCycle(afterBuild: true);
  }

  @override
  @mustCallSuper
  void didUpdateWidget(covariant W oldWidget) {
    super.didUpdateWidget(oldWidget);
    _atelierLifecycle.beginWatchCycle(afterBuild: true);
  }

  @override
  @mustCallSuper
  void didChangeDependencies() {
    super.didChangeDependencies();
    _atelierLifecycle.beginWatchCycle(afterBuild: true);
  }

  @override
  @mustCallSuper
  void dispose() {
    Object? error;
    StackTrace? stackTrace;
    try {
      _atelierLifecycle.dispose();
    } catch (caughtError, caughtStackTrace) {
      error = caughtError;
      stackTrace = caughtStackTrace;
    }

    try {
      super.dispose();
    } catch (caughtError, caughtStackTrace) {
      error ??= caughtError;
      stackTrace ??= caughtStackTrace;
    }

    if (error != null) {
      Error.throwWithStackTrace(error, stackTrace!);
    }
  }
}

/// Owns one [ViewModel] for the lifetime of a Flutter [State].
///
/// The ViewModel is created while `super.initState()` is executing, before
/// control returns to the application's `initState()` implementation. Because
/// this is still initialization, [createViewModel] must use non-listening
/// context lookups such as [BuildContext.getInheritedWidgetOfExactType], not
/// `dependOnInheritedWidgetOfExactType`.
mixin AtelierVmMixin<VM extends ViewModel, W extends StatefulWidget> on State<W> implements AtelierStateBindings {
  late final _atelierLifecycle = _AtelierStateLifecycle(
    isMounted: () => mounted,
    rebuild: () => setState(() {}),
  );
  late final VM _atelierViewModel;
  bool _atelierViewModelCreated = false;

  VM createViewModel(BuildContext context);

  VM get viewModel {
    if (!_atelierViewModelCreated) {
      throw StateError(
        'viewModel is available after super.initState() has completed.',
      );
    }
    return _atelierViewModel;
  }

  @override
  @mustCallSuper
  void initState() {
    super.initState();
    _atelierViewModel = createViewModel(context);
    _atelierViewModelCreated = true;
  }

  @override
  T watch<T>(StateValue<T> state) => _atelierLifecycle.watch(state);

  @override
  R watchSelect<T, R>(
    StateValue<T> state,
    R Function(T value) select, {
    bool Function(R previous, R next)? equals,
  }) {
    return _atelierLifecycle.watchSelect(state, select, equals: equals);
  }

  @override
  void listen<E>(Effects<E> effects, void Function(E effect) listener) {
    _atelierLifecycle.listen(effects, listener);
  }

  T disposeWith<T>(T value, void Function(T value) dispose) {
    return _atelierLifecycle.disposeWith(value, dispose);
  }

  TextEditingController textController({String? text}) {
    return disposeWith(
      TextEditingController(text: text),
      (controller) => controller.dispose(),
    );
  }

  FocusNode focusNode() {
    return disposeWith(FocusNode(), (node) => node.dispose());
  }

  ScrollController scrollController({
    double initialScrollOffset = 0,
    bool keepScrollOffset = true,
  }) {
    return disposeWith(
      ScrollController(
        initialScrollOffset: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
      ),
      (controller) => controller.dispose(),
    );
  }

  @override
  @mustCallSuper
  void setState(VoidCallback fn) {
    super.setState(fn);
    _atelierLifecycle.beginWatchCycle(afterBuild: true);
  }

  @override
  @mustCallSuper
  void didUpdateWidget(covariant W oldWidget) {
    super.didUpdateWidget(oldWidget);
    _atelierLifecycle.beginWatchCycle(afterBuild: true);
  }

  @override
  @mustCallSuper
  void didChangeDependencies() {
    super.didChangeDependencies();
    _atelierLifecycle.beginWatchCycle(afterBuild: true);
  }

  @override
  @mustCallSuper
  void dispose() {
    Object? error;
    StackTrace? stackTrace;

    try {
      _atelierLifecycle.disposeBindings();
    } catch (caughtError, caughtStackTrace) {
      error = caughtError;
      stackTrace = caughtStackTrace;
    }

    if (_atelierViewModelCreated) {
      try {
        _atelierViewModel.dispose();
      } catch (caughtError, caughtStackTrace) {
        error ??= caughtError;
        stackTrace ??= caughtStackTrace;
      }
    }

    try {
      _atelierLifecycle.disposeResources();
    } catch (caughtError, caughtStackTrace) {
      error ??= caughtError;
      stackTrace ??= caughtStackTrace;
    }

    try {
      super.dispose();
    } catch (caughtError, caughtStackTrace) {
      error ??= caughtError;
      stackTrace ??= caughtStackTrace;
    }

    if (error != null) {
      Error.throwWithStackTrace(error, stackTrace!);
    }
  }
}

final class _AtelierStateLifecycle {
  _AtelierStateLifecycle({
    required bool Function() isMounted,
    required void Function() rebuild,
  }) : _isMounted = isMounted,
       _rebuild = rebuild;

  final bool Function() _isMounted;
  final void Function() _rebuild;
  final List<_WatchSlot> _watchSlots = [];
  final List<_EffectSubscription> _effectSubscriptions = [];
  final List<void Function()> _resourceDisposers = [];

  int _watchCursor = 0;
  bool _watchCycleScheduled = false;
  bool _bindingsDisposed = false;
  bool _resourcesDisposed = false;

  T watch<T>(StateValue<T> state) {
    return _configureWatch<T, T>(
      state,
      (value) => value,
      (previous, next) => false,
    );
  }

  R watchSelect<T, R>(
    StateValue<T> state,
    R Function(T value) select, {
    bool Function(R previous, R next)? equals,
  }) {
    return _configureWatch<T, R>(
      state,
      select,
      equals ?? (previous, next) => previous == next,
    );
  }

  R _configureWatch<T, R>(
    StateValue<T> state,
    R Function(T value) select,
    bool Function(R previous, R next) equals,
  ) {
    _ensureBindingsActive();
    beginWatchCycle();

    final index = _watchCursor++;
    final selected = select(state.value);

    if (index < _watchSlots.length && identical(_watchSlots[index].source, state)) {
      final slot = _watchSlots[index];
      slot.select = (value) => select(value as T);
      slot.equals = (previous, next) => equals(previous as R, next as R);
      slot.selected = selected;
      return selected;
    }

    final slot = _WatchSlot(
      source: state,
      selected: selected,
      select: (value) => select(value as T),
      equals: (previous, next) => equals(previous as R, next as R),
      onChanged: _requestRebuild,
    );

    var isInitialValue = true;
    slot.subscription = state.listen((value) {
      if (isInitialValue) {
        isInitialValue = false;
        return;
      }
      slot.accept(value);
    });

    if (index < _watchSlots.length) {
      final replaced = _watchSlots[index];
      _watchSlots[index] = slot;
      _ignoreCancel(replaced.cancel());
    } else {
      _watchSlots.add(slot);
    }

    return selected;
  }

  void beginWatchCycle({bool afterBuild = false}) {
    _ensureBindingsActive();
    if (_watchCycleScheduled) {
      return;
    }
    _watchCycleScheduled = true;
    void cleanup() {
      if (_bindingsDisposed) {
        return;
      }

      while (_watchSlots.length > _watchCursor) {
        _ignoreCancel(_watchSlots.removeLast().cancel());
      }
      _watchCursor = 0;
      _watchCycleScheduled = false;
    }

    if (afterBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) => cleanup());
    } else {
      scheduleMicrotask(cleanup);
    }
  }

  void _requestRebuild() {
    if (!_bindingsDisposed && _isMounted()) {
      _rebuild();
      beginWatchCycle(afterBuild: true);
    }
  }

  void listen<E>(Effects<E> effects, void Function(E effect) listener) {
    _ensureBindingsActive();
    for (final entry in _effectSubscriptions) {
      if (identical(entry.effects, effects) && identical(entry.listener, listener)) {
        return;
      }
    }
    final subscription = effects.listen((effect) {
      if (!_bindingsDisposed && _isMounted()) {
        listener(effect);
      }
    });
    _effectSubscriptions.add(
      _EffectSubscription(effects, listener, subscription),
    );
  }

  T disposeWith<T>(T value, void Function(T value) dispose) {
    if (_resourcesDisposed) {
      throw StateError('Cannot register a resource after State disposal.');
    }
    _resourceDisposers.add(() => dispose(value));
    return value;
  }

  void dispose() {
    Object? error;
    StackTrace? stackTrace;
    try {
      disposeBindings();
    } catch (caughtError, caughtStackTrace) {
      error = caughtError;
      stackTrace = caughtStackTrace;
    }
    try {
      disposeResources();
    } catch (caughtError, caughtStackTrace) {
      error ??= caughtError;
      stackTrace ??= caughtStackTrace;
    }
    if (error != null) {
      Error.throwWithStackTrace(error, stackTrace!);
    }
  }

  void disposeBindings() {
    if (_bindingsDisposed) {
      return;
    }
    _bindingsDisposed = true;

    for (final slot in _watchSlots) {
      _ignoreCancel(slot.cancel());
    }
    _watchSlots.clear();

    for (final entry in _effectSubscriptions) {
      _ignoreCancel(entry.subscription.cancel());
    }
    _effectSubscriptions.clear();
  }

  void disposeResources() {
    if (_resourcesDisposed) {
      return;
    }
    _resourcesDisposed = true;

    Object? error;
    StackTrace? stackTrace;
    for (final dispose in _resourceDisposers.reversed) {
      try {
        dispose();
      } catch (caughtError, caughtStackTrace) {
        error ??= caughtError;
        stackTrace ??= caughtStackTrace;
      }
    }
    _resourceDisposers.clear();

    if (error != null) {
      Error.throwWithStackTrace(error, stackTrace!);
    }
  }

  void _ensureBindingsActive() {
    if (_bindingsDisposed) {
      throw StateError('Atelier bindings have already been disposed.');
    }
  }
}

void _ignoreCancel(Future<void> cancel) => cancel.ignore();

final class _WatchSlot {
  _WatchSlot({
    required this.source,
    required this.selected,
    required this.select,
    required this.equals,
    required this.onChanged,
  });

  final Object source;
  Object? selected;
  Object? Function(Object? value) select;
  bool Function(Object? previous, Object? next) equals;
  final void Function() onChanged;
  late final StreamSubscription<dynamic> subscription;

  void accept(Object? value) {
    if (!active) {
      return;
    }
    final next = select(value);
    if (equals(selected, next)) {
      return;
    }
    selected = next;
    onChanged();
  }

  bool active = true;

  Future<void> cancel() {
    active = false;
    return subscription.cancel();
  }
}

final class _EffectSubscription {
  _EffectSubscription(this.effects, this.listener, this.subscription);

  final Object effects;
  final Object listener;
  final StreamSubscription<dynamic> subscription;
}
