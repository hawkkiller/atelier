import 'dart:async';

/// A read-only broadcast stream of the current value and subsequent updates.
///
/// Subscribing replays the current value. Notifications are asynchronous and
/// ordered, the stream is broadcast, and equal values are emitted. Once the
/// owner closes it, as a ViewModel does when disposed, new subscriptions
/// complete immediately without a replay, while [value] keeps returning the
/// last state.
abstract interface class StateValue<S> implements Stream<S> {
  /// The latest committed state, updated synchronously.
  S get value;
}

/// A [StateValue] its owner writes, for state that lives outside a ViewModel.
///
/// Keep it private and expose it as a read-only [StateValue], typically from
/// an application service that several ViewModels follow:
///
/// ```dart
/// final class SessionService {
///   final _session = MutableStateValue<Session>(const Session.signedOut());
///
///   StateValue<Session> get session => _session;
///
///   void signIn(User user) => _session.value = Session.signedIn(user);
///
///   void dispose() => _session.close();
/// }
/// ```
///
/// ViewModels already own one: [ViewModel.state] is written through tasks or
/// [ViewModel.updateState].
final class MutableStateValue<S> extends Stream<S> implements StateValue<S> {
  /// Creates an open state holding [_value].
  MutableStateValue(this._value);
  S _value;
  bool _isClosed = false;
  final Set<StreamController<S>> _listeners = {};

  @override
  bool get isBroadcast => true;
  @override
  S get value => _value;

  /// Whether [close] has been called.
  bool get isClosed => _isClosed;

  /// Publishes [next] to [value] and to every subscriber; ignored after close.
  set value(S next) {
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

  /// Closes every subscription; later subscriptions complete immediately.
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
