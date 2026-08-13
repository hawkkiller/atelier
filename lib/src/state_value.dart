import 'dart:async';

/// A read-only broadcast stream of the current value and subsequent updates.
///
/// Subscribing replays the current value. Notifications are asynchronous and
/// ordered, the stream is broadcast, and equal values are emitted.
abstract interface class StateValue<S> implements Stream<S> {
  S get value;
}

final class AtelierMutableState<S> extends Stream<S> implements StateValue<S> {
  AtelierMutableState(this._value);
  S _value;
  bool _isClosed = false;
  final Set<StreamController<S>> _listeners = {};

  @override
  bool get isBroadcast => true;
  @override
  S get value => _value;
  bool get isOpen => !_isClosed;

  void setValue(S next) {
    if (_isClosed) return;
    _value = next;
    for (final listener in List<StreamController<S>>.of(_listeners)) {
      listener.add(next);
    }
  }

  @override
  StreamSubscription<S> listen(
    void Function(S event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    late final StreamController<S> controller;
    controller = StreamController<S>(onCancel: () => _listeners.remove(controller));
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
    if (_isClosed) return;
    _isClosed = true;
    final listeners = List<StreamController<S>>.of(_listeners);
    _listeners.clear();
    for (final listener in listeners) {
      unawaited(listener.close());
    }
  }
}
