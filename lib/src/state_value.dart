import 'dart:async';

import 'task_zone.dart';

/// A read-only observable value.
///
/// New listeners receive [value], followed by subsequent values. Stream
/// notifications are asynchronous. Every assignment is emitted, including
/// assignments equal to the current value.
abstract interface class StateValue<S> implements Stream<S> {
  S get value;
}

/// The mutable side of a [StateValue].
abstract interface class MutableState<S> implements StateValue<S> {
  set value(S value);

  /// Replaces [value] with the result of applying [transform] to its current
  /// value.
  void update(S Function(S current) transform);
}

final class MutableStateDisposedError extends StateError {
  MutableStateDisposedError()
    : super('Cannot update state after its ViewModel has been disposed.');
}

final class AtelierMutableState<S> extends Stream<S>
    implements MutableState<S> {
  AtelierMutableState(this._value);

  S _value;
  bool _isClosed = false;
  final Set<StreamController<S>> _listeners = {};

  @override
  bool get isBroadcast => true;

  @override
  S get value => _value;

  @override
  set value(S next) {
    if (!atelierWritesAllowed()) {
      return;
    }
    if (_isClosed) {
      throw MutableStateDisposedError();
    }

    _value = next;
    for (final listener in List<StreamController<S>>.of(_listeners)) {
      listener.add(next);
    }
  }

  @override
  void update(S Function(S current) transform) {
    if (!atelierWritesAllowed()) {
      return;
    }
    value = transform(_value);
  }

  @override
  StreamSubscription<S> listen(
    void Function(S event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    late final StreamController<S> controller;
    controller = StreamController<S>(
      onCancel: () {
        _listeners.remove(controller);
      },
    );

    final subscription = controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    if (_isClosed) {
      unawaited(controller.close());
    } else {
      _listeners.add(controller);
      controller.add(_value);
    }
    return subscription;
  }

  void close() {
    if (_isClosed) {
      return;
    }

    _isClosed = true;
    final listeners = List<StreamController<S>>.of(_listeners);
    _listeners.clear();
    for (final listener in listeners) {
      unawaited(listener.close());
    }
  }
}
