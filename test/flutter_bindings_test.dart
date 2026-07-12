import 'dart:async';

import 'package:atelier/atelier.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('creates ViewModel inside super.initState and disposes it', (
    tester,
  ) async {
    final events = <String>[];
    final viewModel = _BindingViewModel(
      disposeCallback: () => events.add('dispose'),
    );

    await tester.pumpWidget(
      _TestHost(viewModel: viewModel, events: events, selectParity: false),
    );

    expect(events.take(3), ['before-super', 'create', 'after-super']);
    expect(find.text('value:0'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());

    expect(viewModel.isDisposed, isTrue);
    expect(events, contains('dispose'));
  });

  testWidgets('createViewModel can perform a non-listening inherited lookup', (
    tester,
  ) async {
    final viewModel = _BindingViewModel();
    final events = <String>[];

    await tester.pumpWidget(
      _ViewModelScope(
        viewModel: viewModel,
        child: _LookupHost(events: events),
      ),
    );

    expect(events, ['before-super', 'create', 'after-super', 'build']);
    expect(find.text('lookup:0'), findsOneWidget);
  });

  testWidgets('watch rebuilds without accumulating subscriptions', (
    tester,
  ) async {
    final viewModel = _BindingViewModel();
    final events = <String>[];

    await tester.pumpWidget(
      _TestHost(viewModel: viewModel, events: events, selectParity: false),
    );
    expect(events.where((event) => event == 'build').length, 1);

    viewModel.setValue(1);
    await tester.pump();
    await tester.pump();
    expect(find.text('value:1'), findsOneWidget);
    expect(events.where((event) => event == 'build').length, 2);

    viewModel.setValue(2);
    await tester.pump();
    await tester.pump();
    expect(events.where((event) => event == 'build').length, 3);
  });

  testWidgets('watchSelect rebuilds only when the selection changes', (
    tester,
  ) async {
    final viewModel = _BindingViewModel();
    final events = <String>[];

    await tester.pumpWidget(
      _TestHost(viewModel: viewModel, events: events, selectParity: true),
    );

    viewModel.setValue(2);
    await tester.pump();
    await tester.pump();
    expect(events.where((event) => event == 'build').length, 1);
    expect(find.text('parity:0'), findsOneWidget);

    viewModel.setValue(3);
    await tester.pump();
    await tester.pump();
    expect(events.where((event) => event == 'build').length, 2);
    expect(find.text('parity:1'), findsOneWidget);
  });

  testWidgets('unused watches are trimmed when a later build has none', (
    tester,
  ) async {
    final viewModel = _BindingViewModel();
    final events = <String>[];

    await tester.pumpWidget(_ConditionalWatchHost(viewModel, events, true));
    await tester.pumpWidget(_ConditionalWatchHost(viewModel, events, false));
    await tester.pump();

    viewModel.setValue(1);
    await tester.pump();

    expect(events.where((event) => event == 'build').length, 2);
  });

  testWidgets('inherited dependency rebuild trims removed watch', (
    tester,
  ) async {
    final viewModel = _BindingViewModel();
    final events = <String>[];

    await tester.pumpWidget(
      _WatchFlagScope(
        useWatch: true,
        child: _InheritedWatchHost(viewModel: viewModel, events: events),
      ),
    );
    await tester.pumpWidget(
      _WatchFlagScope(
        useWatch: false,
        child: _InheritedWatchHost(viewModel: viewModel, events: events),
      ),
    );
    await tester.pump();

    viewModel.setValue(1);
    await tester.pump();

    expect(events.where((event) => event == 'build').length, 2);
  });

  testWidgets('unused watches are trimmed after local setState', (
    tester,
  ) async {
    final viewModel = _BindingViewModel();
    final events = <String>[];
    final key = GlobalKey<_ToggleWatchHostState>();

    await tester.pumpWidget(
      _ToggleWatchHost(key: key, viewModel: viewModel, events: events),
    );
    key.currentState!.disableWatch();
    await tester.idle();
    viewModel.setValue(1);
    await tester.pump();
    await tester.pump();

    expect(events.where((event) => event == 'build').length, 2);
  });

  testWidgets('listen receives effects without rebuilding', (tester) async {
    final viewModel = _BindingViewModel();
    final events = <String>[];

    await tester.pumpWidget(
      _TestHost(viewModel: viewModel, events: events, selectParity: false),
    );

    viewModel.emit('saved');
    await tester.pump();

    expect(events, contains('effect:saved'));
    expect(events.where((event) => event == 'build').length, 1);
  });

  testWidgets('listen ignores duplicate effects/listener pairs', (
    tester,
  ) async {
    final viewModel = _BindingViewModel();
    final events = <String>[];

    await tester.pumpWidget(
      _DuplicateListenHost(viewModel: viewModel, events: events),
    );

    viewModel.emit('saved');
    await tester.pump();

    expect(events.where((event) => event == 'effect:saved').length, 1);
  });

  testWidgets(
    'ViewModel mixin disposes registered resources in reverse order',
    (tester) async {
      final viewModel = _BindingViewModel();
      final events = <String>[];

      await tester.pumpWidget(
        _TestHost(viewModel: viewModel, events: events, selectParity: false),
      );
      await tester.pumpWidget(const SizedBox());

      expect(events.where((event) => event.startsWith('resource:')), [
        'resource:second',
        'resource:first',
      ]);
    },
  );

  testWidgets('standalone auto-dispose mixin owns resources', (tester) async {
    final disposed = <String>[];

    await tester.pumpWidget(_AutoDisposeHost(disposed));
    expect(find.text('automatic'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());

    expect(disposed, ['resource']);
  });

  testWidgets('ViewModel disposal preserves first error and continues cleanup', (tester) async {
    final events = <String>[];
    final effects = _SynchronousEffects();
    final vm = _FailingViewModel(events, effects);
    await tester.pumpWidget(_FailingVmWidget(vm, effects, events));
    await tester.pumpWidget(const SizedBox());

    expect(events, [
      'vm',
      'resource:b',
      'resource:a',
      'super',
    ]);
    expect(tester.takeException(), same(_errorA));
    expect(effects.cancelledAtEmit, isTrue);
  });

  testWidgets('auto-dispose resources run in reverse order after failure', (tester) async {
    final events = <String>[];
    await tester.pumpWidget(_FailingAutoWidget(events));
    await tester.pumpWidget(const SizedBox());
    expect(events, ['resource:c', 'resource:b', 'resource:a', 'super']);
    expect(tester.takeException(), same(_errorB));
  });

  testWidgets('ViewModel is created and disposed exactly once', (tester) async {
    final events = <String>[];
    final vm = _BindingViewModel(disposeCallback: () => events.add('dispose'));
    final candidate = _BindingViewModel(
      disposeCallback: () => events.add('candidate-dispose'),
    );
    final key = GlobalKey<_CountingHostState>();
    await tester.pumpWidget(
      _StableLifecycleScope(
        value: 1,
        child: _CountingHost(vm, events, key: key),
      ),
    );
    key.currentState!.rebuildLocally();
    await tester.pump();
    await tester.pumpWidget(
      _StableLifecycleScope(
        value: 2,
        child: _CountingHost(candidate, events, key: key),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    expect(events.where((e) => e == 'create').length, 1);
    expect(events.where((e) => e == 'dispose').length, 1);
    expect(events.where((e) => e == 'candidate-dispose'), isEmpty);
  });

  testWidgets('watch replaces a source in the same slot', (tester) async {
    final first = _SourceVm(0);
    final second = _SourceVm(10);
    final key = GlobalKey<_SourceHostState>();
    await tester.pumpWidget(_SourceHost(key: key, source: first.state));
    expect(find.text('value:0'), findsOneWidget);
    key.currentState!.replace(second.state);
    await tester.pump();
    expect(find.text('value:10'), findsOneWidget);
    expect(key.currentState!.builds, 2);
    expect(key.currentState!.selections, 2);
    first.setValue(1);
    await tester.pump();
    expect(find.text('value:10'), findsOneWidget);
    expect(key.currentState!.builds, 2);
    expect(key.currentState!.selections, 2);
    first.setValue(2);
    await tester.pump();
    expect(find.text('value:10'), findsOneWidget);
    expect(key.currentState!.builds, 2);
    expect(key.currentState!.selections, 2);
    second.setValue(11);
    await tester.pump();
    await tester.pump();
    expect(find.text('value:11'), findsOneWidget);
  });

  testWidgets('watchSelect honors custom equality', (tester) async {
    final vm = _BindingViewModel();
    final events = <String>[];
    await tester.pumpWidget(_CustomEqualityHost(vm, events));
    vm.setValue(2);
    await tester.pump();
    await tester.pump();
    expect(events.where((e) => e == 'build').length, 1);
    vm.setValue(3);
    await tester.pump();
    await tester.pump();
    expect(events.where((e) => e == 'build').length, 2);
  });

  testWidgets('external state and effects stop at unmount', (tester) async {
    final vm = _BindingViewModel();
    final events = <String>[];
    final key = GlobalKey<_ExternalHostState>();
    await tester.pumpWidget(_ExternalHost(key: key, vm: vm, events: events));
    await tester.pumpWidget(_ExternalHost(key: key, vm: vm, events: events));
    vm.setValue(1);
    vm.emit('before');
    await tester.pump();
    expect(events.where((e) => e == 'effect:before').length, 3);
    final builds = events.where((e) => e == 'build').length;
    await tester.pumpWidget(const SizedBox());
    vm.setValue(2);
    vm.emit('after');
    await tester.pump();
    expect(events.where((e) => e == 'build').length, builds);
    expect(events.where((e) => e == 'effect:after'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-listening inherited lookup does not rebuild stable child', (tester) async {
    final vm = _BindingViewModel();
    final replacement = _BindingViewModel();
    final events = <String>[];
    final child = _LookupHost(events: events);
    await tester.pumpWidget(_ViewModelScope(viewModel: vm, child: child));
    await tester.pumpWidget(
      _ViewModelScope(viewModel: replacement, child: child),
    );
    expect(events.where((e) => e == 'build').length, 1);
    expect(events.where((e) => e == 'create').length, 1);
  });
}

final class _ConditionalWatchHost extends StatefulWidget {
  const _ConditionalWatchHost(this.viewModel, this.events, this.useWatch);

  final _BindingViewModel viewModel;
  final List<String> events;
  final bool useWatch;

  @override
  State<_ConditionalWatchHost> createState() => _ConditionalWatchHostState();
}

final class _ConditionalWatchHostState extends State<_ConditionalWatchHost>
    with AtelierAutoDisposeMixin<_ConditionalWatchHost> {
  @override
  Widget build(BuildContext context) {
    widget.events.add('build');
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        widget.useWatch ? '${watch(widget.viewModel.state)}' : 'none',
      ),
    );
  }
}

final class _ToggleWatchHost extends StatefulWidget {
  const _ToggleWatchHost({
    super.key,
    required this.viewModel,
    required this.events,
  });

  final _BindingViewModel viewModel;
  final List<String> events;

  @override
  State<_ToggleWatchHost> createState() => _ToggleWatchHostState();
}

final class _ToggleWatchHostState extends State<_ToggleWatchHost> with AtelierAutoDisposeMixin<_ToggleWatchHost> {
  var useWatch = true;

  void disableWatch() {
    setState(() {
      useWatch = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    widget.events.add('build');
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(useWatch ? '${watch(widget.viewModel.state)}' : 'none'),
    );
  }
}

final class _WatchFlagScope extends InheritedWidget {
  const _WatchFlagScope({required this.useWatch, required super.child});

  final bool useWatch;

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_WatchFlagScope>()!.useWatch;

  @override
  bool updateShouldNotify(_WatchFlagScope oldWidget) => useWatch != oldWidget.useWatch;
}

final class _InheritedWatchHost extends StatefulWidget {
  const _InheritedWatchHost({required this.viewModel, required this.events});

  final _BindingViewModel viewModel;
  final List<String> events;

  @override
  State<_InheritedWatchHost> createState() => _InheritedWatchHostState();
}

final class _InheritedWatchHostState extends State<_InheritedWatchHost>
    with AtelierAutoDisposeMixin<_InheritedWatchHost> {
  @override
  Widget build(BuildContext context) {
    widget.events.add('build');
    final useWatch = _WatchFlagScope.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(useWatch ? '${watch(widget.viewModel.state)}' : 'none'),
    );
  }
}

final class _DuplicateListenHost extends StatefulWidget {
  const _DuplicateListenHost({required this.viewModel, required this.events});

  final _BindingViewModel viewModel;
  final List<String> events;

  @override
  State<_DuplicateListenHost> createState() => _DuplicateListenHostState();
}

final class _DuplicateListenHostState extends State<_DuplicateListenHost>
    with AtelierAutoDisposeMixin<_DuplicateListenHost> {
  late final void Function(String effect) _listener = _addEffect;

  void _addEffect(String effect) {
    widget.events.add('effect:$effect');
  }

  @override
  void initState() {
    super.initState();
    listen(widget.viewModel.effects, _listener);
    listen(widget.viewModel.effects, _listener);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

final class _BindingViewModel extends ViewModel {
  _BindingViewModel({this.disposeCallback});

  final VoidCallback? disposeCallback;
  late final MutableState<int> _state = mutableStateOf(0);
  late final MutableEffects<String> _effects = effectsOf();

  StateValue<int> get state => _state;
  Effects<String> get effects => _effects;

  void setValue(int value) => _state.value = value;
  void emit(String effect) => _effects.emit(effect);

  @override
  void onDispose() {
    disposeCallback?.call();
  }
}

final class _TestHost extends StatefulWidget {
  const _TestHost({
    required this.viewModel,
    required this.events,
    required this.selectParity,
  });

  final _BindingViewModel viewModel;
  final List<String> events;
  final bool selectParity;

  @override
  State<_TestHost> createState() => _TestHostState();
}

final class _TestHostState extends State<_TestHost> with AtelierVmMixin<_BindingViewModel, _TestHost> {
  @override
  void initState() {
    widget.events.add('before-super');
    super.initState();
    widget.events.add('after-super');
    listen(viewModel.effects, (effect) {
      widget.events.add('effect:$effect');
    });
    disposeWith('first', (value) {
      widget.events.add('resource:$value');
    });
    disposeWith('second', (value) {
      widget.events.add('resource:$value');
    });
  }

  @override
  _BindingViewModel createViewModel(BuildContext context) {
    widget.events.add('create');
    return widget.viewModel;
  }

  @override
  Widget build(BuildContext context) {
    widget.events.add('build');
    final text = widget.selectParity
        ? 'parity:${watchSelect(viewModel.state, (value) => value % 2)}'
        : 'value:${watch(viewModel.state)}';
    return Directionality(textDirection: TextDirection.ltr, child: Text(text));
  }
}

final class _AutoDisposeHost extends StatefulWidget {
  const _AutoDisposeHost(this.disposed);

  final List<String> disposed;

  @override
  State<_AutoDisposeHost> createState() => _AutoDisposeHostState();
}

final class _AutoDisposeHostState extends State<_AutoDisposeHost> with AtelierAutoDisposeMixin<_AutoDisposeHost> {
  late final TextEditingController controller = textController(
    text: 'automatic',
  );

  @override
  void initState() {
    super.initState();
    disposeWith('resource', widget.disposed.add);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(controller.text),
    );
  }
}

final class _ViewModelScope extends InheritedWidget {
  const _ViewModelScope({required this.viewModel, required super.child});

  final _BindingViewModel viewModel;

  @override
  bool updateShouldNotify(_ViewModelScope oldWidget) => !identical(viewModel, oldWidget.viewModel);
}

final class _LookupHost extends StatefulWidget {
  const _LookupHost({required this.events});

  final List<String> events;

  @override
  State<_LookupHost> createState() => _LookupHostState();
}

final class _LookupHostState extends State<_LookupHost> with AtelierVmMixin<_BindingViewModel, _LookupHost> {
  @override
  void initState() {
    widget.events.add('before-super');
    super.initState();
    widget.events.add('after-super');
  }

  @override
  _BindingViewModel createViewModel(BuildContext context) {
    widget.events.add('create');
    return context.getInheritedWidgetOfExactType<_ViewModelScope>()!.viewModel;
  }

  @override
  Widget build(BuildContext context) {
    widget.events.add('build');
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text('lookup:${watch(viewModel.state)}'),
    );
  }
}

final _errorA = StateError('error A');
final _errorB = StateError('error B');

final class _FailingViewModel extends ViewModel {
  _FailingViewModel(this.events, this.effects);
  final List<String> events;
  final _SynchronousEffects effects;

  @override
  void onDispose() {
    events.add('vm');
    effects.emit('too-late');
    throw _errorA;
  }
}

final class _FailingVmWidget extends StatefulWidget {
  const _FailingVmWidget(this.vm, this.effects, this.events);
  final _FailingViewModel vm;
  final _SynchronousEffects effects;
  final List<String> events;
  @override
  State<_FailingVmWidget> createState() => _FailingVmState();
}

class _FailingVmBaseState extends State<_FailingVmWidget> {
  @override
  void dispose() {
    widget.events.add('super');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

final class _FailingVmState extends _FailingVmBaseState with AtelierVmMixin<_FailingViewModel, _FailingVmWidget> {
  @override
  _FailingViewModel createViewModel(BuildContext context) => widget.vm;

  @override
  void initState() {
    super.initState();
    listen(widget.effects, (effect) => widget.events.add('bindings'));
    disposeWith('a', (value) => widget.events.add('resource:$value'));
    disposeWith('b', (value) {
      widget.events.add('resource:$value');
      throw _errorB;
    });
  }
}

final class _FailingAutoWidget extends StatefulWidget {
  const _FailingAutoWidget(this.events);
  final List<String> events;
  @override
  State<_FailingAutoWidget> createState() => _FailingAutoState();
}

class _FailingAutoBaseState extends State<_FailingAutoWidget> {
  @override
  void dispose() {
    widget.events.add('super');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

final class _FailingAutoState extends _FailingAutoBaseState with AtelierAutoDisposeMixin<_FailingAutoWidget> {
  @override
  void initState() {
    super.initState();
    disposeWith('a', (value) => widget.events.add('resource:$value'));
    disposeWith('b', (value) {
      widget.events.add('resource:$value');
      throw _errorB;
    });
    disposeWith('c', (value) => widget.events.add('resource:$value'));
  }
}

final class _StableLifecycleScope extends InheritedWidget {
  const _StableLifecycleScope({required this.value, required super.child});
  final int value;
  static int of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_StableLifecycleScope>()!.value;
  @override
  bool updateShouldNotify(_StableLifecycleScope oldWidget) => value != oldWidget.value;
}

final class _CountingHost extends StatefulWidget {
  const _CountingHost(this.vm, this.events, {super.key});
  final _BindingViewModel vm;
  final List<String> events;
  @override
  State<_CountingHost> createState() => _CountingHostState();
}

final class _CountingHostState extends State<_CountingHost> with AtelierVmMixin<_BindingViewModel, _CountingHost> {
  void rebuildLocally() => setState(() {});
  @override
  _BindingViewModel createViewModel(BuildContext context) {
    widget.events.add('create');
    return widget.vm;
  }

  @override
  Widget build(BuildContext context) {
    _StableLifecycleScope.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text('${watch(viewModel.state)}'),
    );
  }
}

final class _SourceHost extends StatefulWidget {
  const _SourceHost({super.key, required this.source});
  final StateValue<int> source;
  @override
  State<_SourceHost> createState() => _SourceHostState();
}

final class _SourceHostState extends State<_SourceHost> with AtelierAutoDisposeMixin<_SourceHost> {
  late StateValue<int> source = widget.source;
  var builds = 0;
  var selections = 0;
  void replace(StateValue<int> next) => setState(() => source = next);
  @override
  Widget build(BuildContext context) {
    builds++;
    final value = watchSelect(source, (value) {
      selections++;
      return value;
    });
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text('value:$value'),
    );
  }
}

final class _SynchronousEffects extends Stream<String> implements Effects<String> {
  _SynchronousEffects() : _controller = StreamController<String>.broadcast(sync: true);
  final StreamController<String> _controller;
  var cancelled = false;
  var cancelledAtEmit = false;

  void emit(String effect) {
    cancelledAtEmit = cancelled;
    _controller.add(effect);
  }

  @override
  StreamSubscription<String> listen(
    void Function(String event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    return _TrackingSubscription(subscription, () => cancelled = true);
  }
}

final class _TrackingSubscription implements StreamSubscription<String> {
  _TrackingSubscription(this._delegate, this._onCancel);
  final StreamSubscription<String> _delegate;
  final void Function() _onCancel;

  @override
  bool get isPaused => _delegate.isPaused;

  @override
  Future<void> cancel() {
    _onCancel();
    return _delegate.cancel();
  }

  @override
  void onData(void Function(String data)? handleData) => _delegate.onData(handleData);
  @override
  void onError(Function? handleError) => _delegate.onError(handleError);
  @override
  void onDone(void Function()? handleDone) => _delegate.onDone(handleDone);
  @override
  void pause([Future<void>? resumeSignal]) => _delegate.pause(resumeSignal);
  @override
  void resume() => _delegate.resume();
  @override
  Future<E> asFuture<E>([E? futureValue]) => _delegate.asFuture(futureValue);
}

final class _SourceVm extends ViewModel {
  _SourceVm(int initial) : _initial = initial;
  final int _initial;
  late final MutableState<int> _state = mutableStateOf(_initial);
  StateValue<int> get state => _state;
  void setValue(int value) => _state.value = value;
}

final class _CustomEqualityHost extends StatefulWidget {
  const _CustomEqualityHost(this.vm, this.events);
  final _BindingViewModel vm;
  final List<String> events;
  @override
  State<_CustomEqualityHost> createState() => _CustomEqualityHostState();
}

final class _CustomEqualityHostState extends State<_CustomEqualityHost>
    with AtelierAutoDisposeMixin<_CustomEqualityHost> {
  @override
  Widget build(BuildContext context) {
    widget.events.add('build');
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        '${watchSelect(widget.vm.state, (value) => value, equals: (a, b) => a % 2 == b % 2)}',
      ),
    );
  }
}

final class _ExternalHost extends StatefulWidget {
  const _ExternalHost({super.key, required this.vm, required this.events});
  final _BindingViewModel vm;
  final List<String> events;
  @override
  State<_ExternalHost> createState() => _ExternalHostState();
}

final class _ExternalHostState extends State<_ExternalHost> with AtelierAutoDisposeMixin<_ExternalHost> {
  late final void Function(String) _stable = _record;
  void _record(String effect) => widget.events.add('effect:$effect');

  @override
  void initState() {
    super.initState();
    listen(widget.vm.effects, _stable);
  }

  @override
  void didUpdateWidget(covariant _ExternalHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    listen(widget.vm.effects, _stable);
    listen(widget.vm.effects, (effect) => widget.events.add('effect:$effect'));
    listen(widget.vm.effects, (effect) => widget.events.add('effect:$effect'));
  }

  @override
  Widget build(BuildContext context) {
    widget.events.add('build');
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text('${watch(widget.vm.state)}'),
    );
  }
}
