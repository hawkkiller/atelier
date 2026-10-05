---
name: atelier
description: Use when writing or changing code that uses the atelier Flutter package (ViewModel, execute.*, task.updateState, effects, AtelierVmMixin, watch/listen, own). Recipes and invariants.
---

# Using Atelier

Atelier is a small lifecycle-first MVVM layer for Flutter. The whole public API
is exported from `package:atelier/atelier.dart`; implementation lives in five
files under `lib/src/` (`view_model.dart`, `task.dart`, `effects.dart`,
`state_value.dart`, `flutter_bindings.dart`). Dartdoc on those files and the
contract tests in `test/` are the source of truth. `PROPOSAL.md` sections on
dependency injection and scopes are **not implemented**; do not generate
`@injectable`, `vmFactory` or scope code.

## Invariants

- One immutable state per ViewModel, passed to `super(initialState)`.
- State changes only inside a task: `task.updateState((s) => s.copyWith(...))`.
  Reducers are synchronous and pure; never start tasks, update state, or
  dispose from a reducer.
- After every `await`, a task may be stale. `updateState` and `emit` from a
  cancelled task are no-ops, but external side effects are not:
  call `task.ensureActive()` immediately before navigation, repository writes,
  or platform calls.
- Commands return `Future<void>`. Durable results go in state; one-shot
  outcomes go in effects. Effects are semantic (`PaymentEffect.rejected`), not
  UI commands (`showSnackbar`).
- Keyed policies: `sequential`, `droppable` and `restartable` own a key; using
  two different owning policies on the same active key throws `StateError`.
- `watch`/`watchSelect` only while building; `listen` only outside `build`
  (normally `initState`). Debug builds assert both.
- `createViewModel` runs inside `super.initState()`: use
  `context.getInheritedWidgetOfExactType`, never a listening lookup.

## Choosing a policy

| Need | Call |
|---|---|
| Independent work, no coordination | `execute((task) async {...})` |
| Latest call wins (search, reload) | `execute.restartable(key: #search, ...)` |
| Ignore repeats while running (submit button) | `execute.droppable(key: #submit, ...)` |
| Run in order (queued writes) | `execute.sequential(key: #save, ...)` |

## Recipes

ViewModel with state, effects and error handling:

```dart
class SearchViewModel extends ViewModel<SearchState> {
  SearchViewModel(this._repository) : super(const SearchState());

  final SearchRepository _repository;
  late final MutableEffects<SearchEffect> _effects = effectsOf();
  Effects<SearchEffect> get effects => _effects;

  Future<void> search(String query) => execute.restartable(key: #search, (task) async {
    task.updateState((s) => s.copyWith(loading: true));
    final results = await _repository.search(query, cancellationToken: task);
    task.updateState((s) => s.copyWith(loading: false, results: results));
  });

  @override
  void onTaskError(TaskContext<SearchState> task, Object error, StackTrace stackTrace) {
    task.updateState((s) => s.copyWith(loading: false));
    _effects.emit(SearchEffect.failed);
  }
}
```

ViewModel-owned subscription: `disposeWith(stream.listen(...), (s) => s.cancel())`.

Screen that owns the ViewModel:

```dart
class _SearchScreenState extends State<SearchScreen>
    with AtelierVmMixin<SearchViewModel, SearchScreen> {
  late final query = own(TextEditingController());

  @override
  SearchViewModel createViewModel(BuildContext context) => SearchViewModel(widget.repository);

  @override
  void initState() {
    super.initState();
    listen(viewModel.effects, _onEffect);
  }

  void _onEffect(SearchEffect effect) { /* present it */ }

  @override
  Widget build(BuildContext context) {
    final loading = watchSelect(viewModel.state, (s) => s.loading);
    return SearchView(loading: loading, onChanged: viewModel.search);
  }
}
```

A widget without a ViewModel that only needs disposal or bindings uses
`AtelierAutoDisposeMixin`. `own(notifier)` disposes any `ChangeNotifier`;
`disposeWith(value, dispose)` handles anything else.

## Testing

ViewModels are plain Dart: construct with a fake repository, `await` the
command, assert on `viewModel.state.value`, and collect effects with
`viewModel.effects.listen(list.add)` followed by
`await Future<void>.delayed(Duration.zero)`. See `example/test/` for
deterministic examples, including restartable cancellation.

## Working on the package itself

Run what CI runs before pushing:

```sh
dart format --output=none --set-exit-if-changed lib test example/lib example/test
flutter analyze
flutter test
(cd example && flutter test)
flutter pub publish --dry-run
```

Every behavior change needs a contract test in `test/core_test.dart` or
`test/flutter_bindings_test.dart`, a CHANGELOG entry, and matching README
wording.
