# atelier — Lifecycle-first MVVM Framework for Flutter

## Summary

`atelier` is a lifecycle-first MVVM framework for Flutter inspired by Android Architecture Components, Hilt, ViewModel, and structured task execution.

The goal is not to create “another DI container” or “another state management library”, but to provide a small, coherent architecture layer for Flutter applications:

- typed ViewModels;
- lifecycle-aware async tasks;
- immutable UI state;
- one-shot UI effects;
- auto-dispose helpers;
- scoped dependency graph;
- build-time checked dependency injection;
- minimal Flutter-native boilerplate.

The framework should feel like an extension of Flutter’s existing `StatefulWidget` / `State` model, not a replacement for Flutter itself.

---



## Core Philosophy

Flutter already has a good UI model, but it lacks a unified architecture layer similar to Android’s:

- `ViewModel`;
- `viewModelScope`;
- lifecycle-aware subscriptions;
- structured async task handling;
- scoped DI;
- compile-time checked dependency graph.

`flutter_atelier` aims to fill this gap while staying Flutter-native.

The ViewModel should remain pure Dart and should not depend on `BuildContext`.

UI-local objects such as `TextEditingController`, `FocusNode`, `ScrollController`, and `AnimationController` belong to the Widget/State layer, not to the ViewModel.

---



## Key Concepts

Each concept below starts with its proposed public API. The declarations describe
the contract available to application code; concrete implementations remain
internal to the framework.

### 1. ViewModel

A ViewModel owns one aggregate state value, lifecycle-aware tasks, effects, and
resources.

Public API:

```dart
abstract class ViewModel<S extends Object> {
  ViewModel(S initialState);

  StateValue<S> get state;
  TaskExecutor<S> get execute;
  bool get isDisposed;

  @protected
  MutableEffects<E> effectsOf<E>();

  @nonVirtual
  void dispose();

  @protected
  void onDispose() {}
}
```

`effectsOf()` registers its result with the ViewModel lifecycle. `dispose()` is
public so the owning Atelier lifecycle integration can
call it, but it is non-overridable and idempotent. Custom cleanup belongs in
`onDispose()`. Disposal first cancels active and queued tasks, then invokes
`onDispose()`, and finally closes owned state and effect channels. An exception
from `onDispose()` does not prevent owned channels from being closed.

Usage:

```dart
class SearchViewModel extends ViewModel<SearchState> {
  SearchViewModel(this.searchRepository) : super(SearchState.initial());

  final SearchRepository searchRepository;

  Future<void> search(String query) => execute.restartable(
    key: 'search',
    (task) async {
      task.updateState((s) => s.copyWith(query: query, loading: true));

      final results = await searchRepository.search(
        query,
        cancellationToken: task,
      );

      task.ensureActive();

      task.updateState((s) => s.copyWith(loading: false, results: results));
    },
  );
}
```

The ViewModel provides:

- built-in read-only aggregate state and effect factories;
- task execution;
- cancellation token support;
- lifecycle-aware disposal;
- built-in observable state and optional effect channels.

---



### 2. StateValue and task-owned state updates

State updates should be safe when multiple async operations update the same state.

Public API:

```dart
abstract interface class StateValue<S> implements Stream<S> {
  S get value;
}
```

`StateValue` is the read-only broadcast stream consumed by UI bindings. It
replays its current value to new listeners, sends later notifications
asynchronously in order, updates `value` synchronously, and emits equal values.
It is closed with its owning ViewModel.

State mutation is source-breaking compared with the earlier proposal: the
`MutableState`, `MutableStateDisposedError`, and `mutableStateOf` APIs are
removed. Use the task context instead:

```dart
task.updateState((s) => s.copyWith(userLoading: true));

final user = await repository.loadUser();

task.ensureActive();

task.updateState((s) => s.copyWith(userLoading: false, user: user));
```

Reducers are synchronous and reduce against the latest committed state. Equal
results emit, while stale contexts silently no-op without evaluating reducers.
Reducers must be pure and non-reentrant; nested updates, starting an owning-VM
task, or disposing the ViewModel from a reducer throws `StateError`.

---



### 3. Effects

Transient semantic outcomes should not be stored in durable UI state.

Public API:

```dart
abstract interface class Effects<E> implements Stream<E> {}

abstract interface class MutableEffects<E> implements Effects<E> {
  void emit(E effect);
}
```

`Effects` is the read contract consumed by the UI. `MutableEffects` adds
emission for ViewModels and is created through `effectsOf()`. The channel is
closed automatically with its owning ViewModel. Unlike `StateValue`, effects
are broadcast without replaying previous values to new listeners. Delivery is
at most once to currently active subscribers; effects are not buffered for a
future subscriber. Emission after disposal throws `EffectsDisposedError`.

Examples:

- operation completed;
- operation rejected;
- confirmation required;
- external flow finished.

```dart
late final MutableEffects<PaymentEffect> _effects = effectsOf();

Effects<PaymentEffect> get effects => _effects;

_effects.emit(PaymentEffect.rejected(reason));
```

Effects should describe semantic outcomes, not presentation commands such as
`showSnackbar`, `closeSheet`, or `navigateHome`. The UI decides how to present
each effect.

The UI listens to effects:

```dart
@override
void initState() {
  super.initState();

  listen(paymentViewModel.effects, _handlePaymentEffect);
}
```

---



### 4. Task Execution

The framework should provide a lifecycle-aware task API similar in spirit to `viewModelScope.launch`, but adapted to Dart.

Public API:

```dart
abstract interface class TaskExecutor<S extends Object> {
  Future<void> call(Future<void> Function(TaskContext<S> task) block, {Object? key});

  Future<void> concurrent(
    Future<void> Function(TaskContext<S> task) block, {
    Object? key,
  });

  Future<void> sequential(
    Future<void> Function(TaskContext<S> task) block, {
    required Object key,
  });

  Future<void> droppable(
    Future<void> Function(TaskContext<S> task) block, {
    required Object key,
  });

  Future<void> restartable(
    Future<void> Function(TaskContext<S> task) block, {
    required Object key,
  });
}
```

The key identifies a task lane within a ViewModel. Non-concurrent policies only
coordinate invocations that use the same key, so those methods require one.
While a lane is active, a key must not be reused with another lane-owning
policy (`sequential`, `droppable`, or `restartable`). Concurrent invocations may
coexist with an owned lane because keys are metadata for that policy; all task
methods use `Future<void>` and have no result-type collision.

The executor methods map to the policies represented by:

```dart
enum TaskPolicy { concurrent, sequential, droppable, restartable }
```

`ViewModel<S>` exposes a callable `execute` property of type `TaskExecutor<S>`. Calling
`execute(...)` directly uses the concurrent policy. The other policies are
available as discoverable methods on the same executor:

```dart
execute(...);             // concurrent
execute.concurrent(...);  // explicit concurrent
execute.sequential(...);
execute.droppable(...);
execute.restartable(...);
```

Task completion follows these rules:

- `concurrent` invocations run independently;
- a repeated `droppable` invocation returns the active invocation's `Future`
  without running its block;
- `restartable` cancels the previous task context; its `Future<void>` completes
  normally when the block cooperatively returns or throws the expected
  `TaskCancelledException`;
- `sequential` invocations run in call order;
- disposing the ViewModel cancels active contexts and completes queued task
  `Future<void>`s normally;
- unexpected task errors remain visible through the returned `Future`.

Use cases:

```dart
execute.droppable(key: 'login', (task) async {
  // ignore repeated login clicks while already running
});
```

```dart
execute.restartable(key: 'search', (task) async {
  // invalidate previous search when new query arrives
});
```

```dart
execute.sequential(key: 'save', (task) async {
  // queue save operations one by one
});
```

`execute()` is still useful for concurrent tasks because it provides:

- lifecycle awareness;
- cancellation token;
- consistent error propagation through the returned `Future`;
- task registration;
- protection from updating state after ViewModel disposal.

---



### 5. TaskContext / CancellationToken

Dart cannot cancel arbitrary `Future`s, but many operations can support cooperative cancellation.

`TaskContext` should also act as a cancellation token.

Public API:

```dart
abstract interface class CancellationToken {
  bool get isCancelled;
  Future<void> get cancelled;

  void throwIfCancelled();
}

abstract interface class TaskContext<S extends Object> implements CancellationToken {
  bool get isActive;
  Object? get key;
  TaskPolicy get policy;

  void ensureActive();
  void updateState(S Function(S current) reducer);
}
```

`updateState` is synchronous and always reduces against the latest committed
state. It publishes before returning and emits equal values. Reducers must be
pure and non-reentrant: nested updates, starting or restarting a task on the
owning ViewModel, or disposing it throw `StateError`; reducer errors propagate
through the task `Future`. A stale context silently no-ops without evaluating
its reducer. Zones are retained only for stale effect suppression.

Usage:

```dart
final result = await api.search(query, cancellationToken: task);

task.ensureActive();

task.updateState((s) => s.copyWith(result: result));
```

For HTTP clients like Dio, adapters can be provided:

```dart
final cancelToken = task.asDioCancelToken();
```

When the ViewModel is disposed, all active task contexts are cancelled.

---



### 6. UI Layer Integration

The UI should remain normal Flutter code.

Public API:

```dart
mixin AtelierVmMixin<VM extends ViewModel<Object>, W extends StatefulWidget>
    on State<W>
    implements AtelierStateBindings {
  VM createViewModel(BuildContext context);

  VM get viewModel;
}
```

The mixin creates the ViewModel once, exposes it through `viewModel`, provides
the state binding and auto-dispose APIs described below, and disposes the
ViewModel with the Flutter `State`.

Creation happens during `super.initState()`, before control returns to the
application State's `initState()` implementation. Consequently, `viewModel` is
available immediately after `super.initState()`. Any graph lookup used by
`createViewModel()` must be non-listening (for example, based on
`getInheritedWidgetOfExactType`) because inherited dependencies cannot be
registered from `initState()`. The ViewModel is created exactly once and is not
replaced when an ancestor changes.

A screen can use a regular `StatefulWidget` with an Atelier mixin:

```dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen>
    with AtelierVmMixin<LoginViewModel, LoginScreen> {
  late final email = textController();
  late final password = textController();

  @override
  LoginViewModel createViewModel(BuildContext context) {
    return context.vmFactory.createLoginViewModel();
  }

  @override
  Widget build(BuildContext context) {
    final state = watch(viewModel.state);

    return Column(
      children: [
        TextField(controller: email),
        TextField(controller: password),
        if (state.loading) const CircularProgressIndicator(),
        ElevatedButton(
          onPressed: () => viewModel.login(email.text, password.text),
          child: const Text('Login'),
        ),
      ],
    );
  }
}
```

---



### 7. Auto-dispose Helpers

Flutter has a lot of lifecycle boilerplate:

Public API:

```dart
mixin AtelierAutoDisposeMixin<W extends StatefulWidget> on State<W>
    implements AtelierStateBindings {
  T disposeWith<T>(T value, void Function(T value) dispose);

  TextEditingController textController({String? text});
  FocusNode focusNode();
  ScrollController scrollController({
    double initialScrollOffset = 0,
    bool keepScrollOffset = true,
  });
}
```

`AtelierVmMixin` exposes the same helpers without requiring both mixins in
the `with` clause.

```dart
final controller = TextEditingController();

@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

Atelier should provide reusable lifecycle helpers:

```dart
late final email = textController();
late final focus = focusNode();
late final scroll = scrollController();
```

These should automatically dispose when the owning `State` is disposed.

This should be available not only in screen-level ViewModel states, but also in smaller UI subsections.

```dart
class EmailFieldSection extends StatefulWidget {
  const EmailFieldSection({super.key});

  @override
  State<EmailFieldSection> createState() => _EmailFieldSectionState();
}

class _EmailFieldSectionState extends State<EmailFieldSection>
    with AtelierAutoDisposeMixin<EmailFieldSection> {
  late final controller = textController();
  late final focus = focusNode();

  @override
  Widget build(BuildContext context) {
    return TextField(controller: controller, focusNode: focus);
  }
}
```

This suggests two separate mixins:

```dart
AtelierAutoDisposeMixin
AtelierVmMixin<VM, W>
```

`AtelierVmMixin` can build on top of the auto-dispose lifecycle layer.

---



### 8. Watching State

Because `StateValue` implements `Stream`, it works directly with standard
Flutter APIs:

```dart
StreamBuilder<SearchState>(
  stream: viewModel.state,
  initialData: viewModel.state.value,
  builder: (context, snapshot) {
    return SearchView(state: snapshot.requireData);
  },
);
```

Atelier bindings avoid repetitive subscription and builder code when desired.

`AtelierStateBindings` is the shared public contract for lifecycle-aware state
and effect subscriptions in a Flutter `State`. Application code does not create
it directly. It is implemented by `AtelierAutoDisposeMixin` and
`AtelierVmMixin`, allowing both mixins to expose the same binding API.

Public API exposed by `AtelierAutoDisposeMixin` and `AtelierVmMixin`:

```dart
abstract interface class AtelierStateBindings {
  T watch<T>(StateValue<T> state);

  R watchSelect<T, R>(
    StateValue<T> state,
    R Function(T value) select, {
    bool Function(R previous, R next)? equals,
  });

  void listen<E>(
    Effects<E> effects,
    void Function(E effect) listener,
  );
}
```

Subscriptions created by these methods are removed automatically when the
Flutter `State` is disposed. `watch()` rebuilds for every emitted state,
`watchSelect()` rebuilds only when the selected value changes, and `listen()`
handles effects without rebuilding. `watch()` and `watchSelect()` are build-time
APIs: repeated calls in the same call position reuse their subscription, and a
changed source replaces the previous subscription. `listen()` may be called
after `super.initState()`. Repeating the same effects and listener identities
is deduplicated; a call with a distinct identity creates a subscription. All
subscriptions are removed with the owning State.

Basic usage:

```dart
final state = watch(viewModel.state);
```

This rebuilds the current widget when state changes.

For optimization, selectors can be added later:

```dart
final loading = watchSelect(viewModel.state, (s) => s.loading);
```

The default recommendation is to rebuild the screen from a single immutable UI state. In most Flutter screens this is acceptable, because rebuild does not necessarily mean repainting the entire screen.

Optimization escape hatches should exist, but should not be the primary API.

---



### 9. Dependency Injection

The framework can include a build-time checked generated dependency graph.

Annotation API:

```dart
const injectable = Injectable();
const singleton = Singleton();
const viewModel = ViewModelBinding();

final class Injectable {
  const Injectable();
}

final class Singleton {
  const Singleton();
}

final class ViewModelBinding {
  const ViewModelBinding();
}
```

Generated factory API is application-specific and fully typed. For the examples
below, the generated contracts are:

```dart
abstract interface class ViewModelFactory {
  LoginViewModel createLoginViewModel();
}

abstract interface class AtelierGraphContextApi {
  AppGraph get appGraph;
  ViewModelFactory get vmFactory;
}
```

The generator exposes `AtelierGraphContextApi` as extension getters on
`BuildContext`.

Example:

```dart
@singleton
class ApiClient {
  ApiClient();
}
```

```dart
@injectable
class AuthRepository {
  AuthRepository(this.apiClient);

  final ApiClient apiClient;
}
```

```dart
@viewModel
class LoginViewModel extends ViewModel<LoginState> {
  LoginViewModel(this.authRepository) : super(LoginState.initial());

  final AuthRepository authRepository;
}
```

Generated graph:

```dart
class AppGraph implements ViewModelFactory {
  late final ApiClient apiClient = ApiClient();

  late final AuthRepository authRepository = AuthRepository(apiClient);

  @override
  LoginViewModel createLoginViewModel() {
    return LoginViewModel(authRepository);
  }
}
```

The generator should validate:

- missing dependencies;
- duplicate bindings;
- dependency cycles;
- invalid scopes;
- singleton depending on invalid scoped objects;
- ViewModel factory generation.

The goal is closer to a typed generated composition root than to a runtime service locator.

Avoid this style:

```dart
get<T>();
```

Prefer explicit generated factories:

```dart
context.vmFactory.createLoginViewModel();
```

---



### 10. Scopes

Scopes should map to real Flutter lifetimes.

Public constructor contracts (`createState()` implementations omitted):

```dart
final class AtelierAppScope<G> extends StatefulWidget {
  const AtelierAppScope({super.key, required this.graph, required this.child});

  final G graph;
  final Widget child;
}

final class AtelierSessionScope<G> extends StatefulWidget {
  const AtelierSessionScope({
    super.key,
    required this.graph,
    required this.child,
  });

  final G graph;
  final Widget child;
}

final class AtelierFlowScope<G> extends StatefulWidget {
  const AtelierFlowScope({super.key, required this.graph, required this.child});

  final G graph;
  final Widget child;
}
```

Each scope exposes its graph to descendants and disposes the graph-owned
resources when the scope leaves the widget tree.

Examples:

- app scope;
- session scope;
- flow scope;
- route/screen scope.

App scope:

```dart
AtelierAppScope(graph: AppGraph(), child: const App());
```

Session scope after login:

```dart
AtelierSessionScope(
  graph: context.appGraph.createSessionGraph(session),
  child: const HomeShell(),
);
```

Flow scope:

```dart
AtelierFlowScope(
  graph: context.sessionGraph.createCheckoutGraph(cartId),
  child: const CheckoutFlow(),
);
```

A flow spanning multiple routes may require a shared route subtree, such as a shell route or nested navigator. This is a natural consequence of Flutter’s context-based widget tree lifecycle.

---



## MVP Scope

The initial MVP should not try to implement everything.

Recommended MVP:

1. `ViewModel`;
2. `StateValue<S>` with task-owned updates;
3. `Effects<E>` / `MutableEffects<E>`;
4. callable `TaskExecutor` with `TaskContext`;
5. `execute()` / `execute.concurrent()`;
6. `execute.droppable()`;
7. `execute.restartable()`;
8. `execute.sequential()`;
9. `AtelierStateBindings`;
10. `AtelierAutoDisposeMixin`;
11. `AtelierVmMixin`;
12. `listen()`;
13. `watch()`;
14. basic generated ViewModel factories.

Later:

- DI modules;
- qualifiers;
- session/flow scopes;
- async dependency initialization;
- Dio cancellation adapter;
- test overrides;
- route integration;
- selectors;
- devtools/debug task tracing.

---



## Why Not BLoC?

BLoC is powerful, but often verbose for MVVM-style applications.

Typical BLoC flow:

```text
UI → Event → Bloc → State
```

Atelier flow:

```text
UI → ViewModel method → State
```

Instead of events for every user action, the UI calls ViewModel methods directly:

```dart
viewModel.login(email.text, password.text);
```

This is often more natural for teams coming from Android MVVM, SwiftUI, or general imperative application architecture.

Concurrency policies also become part of the ViewModel task API instead of requiring separate event transformers.

---



## Why Not Elementary?

Elementary already provides an MVVM-like structure for Flutter, but it has a different philosophy.

Atelier should be:

- less verbose;
- not require a mandatory Model layer;
- keep ViewModel pure Dart;
- avoid giving ViewModel access to `BuildContext`;
- focus on lifecycle-aware tasks and auto-dispose;
- provide build-time checked DI.

---



## Positioning

`flutter_atelier` should be positioned as:

> A lifecycle-first MVVM architecture framework for Flutter.

Not:

> Another state management library.

Not:

> Another DI container.

The unique value is the combination of:

- ViewModel lifecycle;
- lifecycle-aware async tasks;
- cancellation token support;
- immutable UI state;
- effects;
- auto-dispose helpers;
- build-time checked DI.

---



## Possible Package Split

```text
atelier_core
  ViewModel
  StateValue
  Effects
  MutableEffects
  TaskExecutor
  TaskContext
  TaskPolicy
  CancellationToken

atelier_flutter
  AtelierAutoDisposeMixin
  AtelierVmMixin
  AtelierStateBindings
  watch
  listen
  AppScope widgets

atelier_annotations
  @injectable
  @singleton
  @viewModel
  @module
  @bind

atelier_generator
  graph generation
  factory generation
  validation
```

The public package could be:

```text
flutter_atelier
```

or a branded package ecosystem:

```text
atelier
atelier_flutter
atelier_generator
```

---



## Example Final DX

```dart
@viewModel
class LoginViewModel extends ViewModel<LoginState> {
  LoginViewModel(this.authRepository) : super(LoginState.initial());

  final AuthRepository authRepository;

  Future<void> login(String email, String password) => execute.droppable(
    key: 'login',
    (task) async {
      task.updateState((s) => s.copyWith(loading: true));

      final user = await authRepository.login(
        email,
        password,
        cancellationToken: task,
      );

      task.ensureActive();

      task.updateState((s) => s.copyWith(loading: false, user: user));
    },
  );
}
```

```dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen>
    with AtelierVmMixin<LoginViewModel, LoginScreen> {
  late final email = textController();
  late final password = textController();

  @override
  LoginViewModel createViewModel(BuildContext context) {
    return context.vmFactory.createLoginViewModel();
  }

  @override
  Widget build(BuildContext context) {
    final state = watch(viewModel.state);

    return LoginView(
      email: email,
      password: password,
      loading: state.loading,
      onLogin: () => viewModel.login(email.text, password.text),
    );
  }
}
```



## Final Idea

`flutter_atelier` should be Android-inspired, but Flutter-native.

It should not fight Flutter’s `StatefulWidget` model. Instead, it should make it better by adding the missing architecture and lifecycle primitives around it.
