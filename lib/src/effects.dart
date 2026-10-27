import 'dart:async';

import 'task_zone.dart';

/// A stream of transient semantic outcomes.
///
/// Effects are delivered at most once to current listeners. They are neither
/// replayed nor buffered for future listeners.
abstract interface class Effects<E> implements Stream<E> {}

/// The emitting side of [Effects].
abstract interface class MutableEffects<E> implements Effects<E> {
  /// Delivers [effect] to current listeners.
  ///
  /// Dropped silently when called from a task that was cancelled (restart or
  /// disposal), including callbacks that task registered. Throws
  /// [EffectsDisposedError] when called after disposal from outside a task.
  void emit(E effect);
}

/// Thrown by [MutableEffects.emit] after the owning ViewModel is disposed.
final class EffectsDisposedError extends StateError {
  /// Creates the error.
  EffectsDisposedError() : super('Cannot emit an effect after its ViewModel has been disposed.');
}

/// The [MutableEffects] implementation created by `effectsOf`. Not exported.
final class AtelierMutableEffects<E> extends Stream<E> implements MutableEffects<E> {
  /// Creates an open effect channel that reports delivered effects to [onEmit].
  AtelierMutableEffects({void Function(E effect)? onEmit})
    : _controller = StreamController<E>.broadcast(),
      _onEmit = onEmit;

  final StreamController<E> _controller;
  final void Function(E effect)? _onEmit;
  bool _isClosed = false;

  @override
  bool get isBroadcast => true;

  @override
  void emit(E effect) {
    if (!atelierWritesAllowed()) {
      return;
    }
    if (_isClosed) {
      throw EffectsDisposedError();
    }
    _controller.add(effect);
    _onEmit?.call(effect);
  }

  @override
  StreamSubscription<E> listen(
    void Function(E event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  /// Closes the channel; later emissions throw [EffectsDisposedError].
  void close() {
    if (_isClosed) {
      return;
    }
    _isClosed = true;
    unawaited(_controller.close());
  }
}
