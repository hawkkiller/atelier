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

final class _ToggleWatchHostState extends State<_ToggleWatchHost>
    with AtelierAutoDisposeMixin<_ToggleWatchHost> {
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

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_WatchFlagScope>()!.useWatch;

  @override
  bool updateShouldNotify(_WatchFlagScope oldWidget) =>
      useWatch != oldWidget.useWatch;
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

final class _TestHostState extends State<_TestHost>
    with AtelierVmStateMixin<_BindingViewModel, _TestHost> {
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

final class _AutoDisposeHostState extends State<_AutoDisposeHost>
    with AtelierAutoDisposeMixin<_AutoDisposeHost> {
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
  bool updateShouldNotify(_ViewModelScope oldWidget) =>
      !identical(viewModel, oldWidget.viewModel);
}

final class _LookupHost extends StatefulWidget {
  const _LookupHost({required this.events});

  final List<String> events;

  @override
  State<_LookupHost> createState() => _LookupHostState();
}

final class _LookupHostState extends State<_LookupHost>
    with AtelierVmStateMixin<_BindingViewModel, _LookupHost> {
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
