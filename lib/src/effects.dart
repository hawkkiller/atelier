import 'dart:async';

import 'task_zone.dart';

/// A stream of transient semantic outcomes.
///
/// Effects are delivered at most once to current listeners. They are neither
/// replayed nor buffered for future listeners.
abstract interface class Effects<E> implements Stream<E> {}

/// The emitting side of [Effects].
abstract interface class MutableEffects<E> implements Effects<E> {
  void emit(E effect);
}

final class EffectsDisposedError extends StateError {
  EffectsDisposedError() : super('Cannot emit an effect after its ViewModel has been disposed.');
}

final class AtelierMutableEffects<E> extends Stream<E> implements MutableEffects<E> {
  AtelierMutableEffects() : _controller = StreamController<E>.broadcast();

  final StreamController<E> _controller;
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

  void close() {
    if (_isClosed) {
      return;
    }
    _isClosed = true;
    unawaited(_controller.close());
  }
}
