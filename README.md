# atelier

Atelier is a lifecycle-first MVVM framework for Flutter. It provides:

- ViewModel-owned state and effects;
- concurrent, sequential, droppable, and restartable tasks;
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
Atelier automatically suppresses stale state and effect writes. For repository,
platform, UI, or other external side effects, cancellation cannot undo work:
call `task.ensureActive()` immediately before the side effect.

Dependency injection is not part of the current implementation.

## Usage

```dart
class SearchViewModel extends ViewModel {
  SearchViewModel(this.repository);

  final SearchRepository repository;
  late final MutableState<SearchState> _state =
      mutableStateOf(SearchState.initial());
  late final MutableEffects<SearchEffect> _effects = effectsOf();

  StateValue<SearchState> get state => _state;
  Effects<SearchEffect> get effects => _effects;

  Future<void> search(String query) => execute.restartable(
        key: 'search',
        (task) async {
          _state.update((state) => state.copyWith(loading: true));

          final results = await repository.search(
            query,
            cancellationToken: task,
          );
          task.ensureActive();

          _state.update(
            (state) => state.copyWith(loading: false, results: results),
          );
        },
      );
}
```

Own the ViewModel from a regular `StatefulWidget`:

```dart
class _SearchScreenState extends State<SearchScreen>
    with AtelierVmStateMixin<SearchViewModel, SearchScreen> {
  late final query = textController();

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
