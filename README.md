# atelier

Atelier is a lifecycle-first MVVM framework for Flutter. It provides:

- ViewModel-owned state and effects;
- commands with concurrent, sequential, droppable, and restartable policies;
- cooperative task cancellation;
- Flutter lifecycle bindings with `watch`, `watchSelect`, and `listen`;
- automatic disposal for controllers and arbitrary resources.

Task APIs return `Future<void>`. Cancellation is cooperative: when a task is
cancelled by restart or disposal, its expected `TaskCancelledException` is
swallowed at the executor boundary and its future completes normally. Other
errors still propagate, including errors thrown after cancellation. A
`TaskCancelledException` is swallowed only when the invocation's own context is
cancelled; an uncancelled exception remains an error. `task.cancelled` is a
notification for cancellation and does not complete when a task finishes
normally. Dart cannot preempt or roll back arbitrary futures or side effects.

The keyed policies have distinct lane semantics. `sequential`, `droppable`,
and `restartable` own a lane, so they cannot share an active key with another
one of those policies; `concurrent` keys are metadata and may coexist with an
owned lane. Different keys are independent. A repeated droppable call shares
the active invocation's exact future and does not invoke its block. Sequential
calls queue, while queued calls skipped by disposal and every call made after
disposal complete normally without running.

Active disposal and restart only request cooperative cancellation. A block may
observe `task.cancelled`, call `throwIfCancelled()` or `ensureActive()`, and
settle normally; a non-cooperative block remains pending until it returns.
Atelier suppresses stale state updates and effect writes. State updates are
explicit through the active task context. For repository, platform, UI, or
other external side effects, cancellation cannot undo work:
call `task.ensureActive()` immediately before the side effect.

Each `ViewModel<S extends Object>` requires one initial aggregate state via
`super(initialState)`. Its built-in `state` is a read-only `StateValue<S>`.
Canonical mutations happen only inside a command or `execute` task, through
`task.state = ...` or `task.updateState`: writes are synchronous, use the
latest committed state, and emit equal values. Stale contexts silently no-op without evaluating their
reducers. Reducers are pure and non-reentrant; nested updates, starting a task
on the owning ViewModel, or disposing it from a reducer throws `StateError`.
Zones remain only for effect suppression: effects emitted by a cancelled task,
including callbacks it registered, are dropped. Callbacks registered by a task
that finished normally (stream listeners, timers) keep emitting until the
ViewModel is disposed.

Keyed calls are re-entrant: a task may start another task with its own key,
even before its first `await`, and the lane policy still applies.

Dependency injection is not part of the current implementation.

## Usage

```dart
class SearchViewModel extends ViewModel<SearchState> {
  SearchViewModel(this.repository) : super(SearchState.initial());

  final SearchRepository repository;
  late final MutableEffects<SearchEffect> _effects = effectsOf();

  Effects<SearchEffect> get effects => _effects;

  late final search = restartable((String query, task) async {
    final results = await repository.search(query, cancellationToken: task);
    task.state = task.state.copyWith(results: results);
  });
}
```

### Commands

`restartable`, `droppable`, `sequential` and `concurrent` declare a command as
a field. The command is called like a method (`viewModel.search('Kra')`),
returns `Future<void>`, and is its own lane key, so no key symbols are needed.
Use a record for several arguments and `.noArgs` for none:

```dart
late final refresh = droppable.noArgs((task) async { ... });
late final save = sequential(((String id, String name) args, task) async { ... });
```

Every command exposes `isRunning`, a `StateValue<bool>` that is true while an
invocation is running or queued, so loading flags don't need to live in state:

```dart
final searching = watch(viewModel.search.isRunning);
```

`command.cancel()` cancels its running invocation and skips queued ones.
`execute.*` remains available for ad-hoc tasks.
```

Own the ViewModel from a regular `StatefulWidget`:

```dart
class _SearchScreenState extends State<SearchScreen>
    with AtelierVmMixin<SearchViewModel, SearchScreen> {
  late final query = own(TextEditingController());

  @override
  SearchViewModel createViewModel(BuildContext context) {
    return SearchViewModel(SearchRepository());
  }

  @override
  void initState() {
    super.initState();
    listen(viewModel.effects, handleEffect);
  }

  @override
  Widget build(BuildContext context) {
    final state = watch(viewModel.state);
    return SearchView(state: state);
  }
}
```

`createViewModel()` runs during `super.initState()`. Context lookups performed
there must not subscribe to inherited widgets. Use a non-listening lookup:

```dart
@override
SearchViewModel createViewModel(BuildContext context) {
  final scope = context.getInheritedWidgetOfExactType<Scope>()!;
  return SearchViewModel(scope.repository);
}
```

Do not call `dependOnInheritedWidgetOfExactType` (or another listening lookup)
from `createViewModel()`.

### Errors

Errors other than a task's own cancellation propagate through the command's
`Future`. UI code usually does not await commands, so override `onTaskError` to
turn unexpected failures into state or effects instead of uncaught errors:

```dart
@override
void onTaskError(TaskContext<SearchState> task, Object error, StackTrace stackTrace) {
  task.updateState((state) => state.copyWith(loading: false, failed: true));
  _effects.emit(SearchEffect.failed);
}
```

When `onTaskError` returns normally, the task's `Future` completes normally.
The default implementation rethrows.

### Resources

`own(notifier)` disposes any `ChangeNotifier` (text, scroll, page and tab
controllers, focus nodes, `ValueNotifier`s) with the owning `State`;
`disposeWith(value, dispose)` handles everything else. ViewModels have their
own `disposeWith` for subscriptions and timers, released after `onDispose()`.

Call `watch`/`watchSelect` only while building and `listen` only outside
`build` (usually `initState`); debug builds assert both.

`watch` subscriptions are identified by their build call position and source;
repeating a `listen` call with the same effects and listener identities
deduplicates it. Distinct listener closures are distinct subscriptions. Atelier
disposes bindings and registered resources with the owning `State`; the
ViewModel mixin also disposes its ViewModel.

See [ROADMAP.md](ROADMAP.md) for release priorities and [PROPOSAL.md](PROPOSAL.md)
for the architecture and planned DI design.

## Example

The [`example`](example) directory contains a minimal weather app backed by the
keyless Open-Meteo geocoding and forecast APIs:

```sh
cd example
flutter run
```
