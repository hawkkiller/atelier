# atelier

Atelier is a lifecycle-first MVVM framework for Flutter. It provides:

- ViewModel-owned state and effects;
- concurrent, sequential, droppable, and restartable tasks;
- cooperative task cancellation;
- Flutter lifecycle bindings with `watch`, `watchSelect`, and `listen`;
- automatic disposal for controllers and arbitrary resources.

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
there must not subscribe to inherited widgets.

See [PROPOSAL.md](PROPOSAL.md) for the architecture and planned DI design.

## Example

The [`example`](example) directory contains a minimal weather app backed by the
keyless Open-Meteo geocoding and forecast APIs:

```sh
cd example
flutter run
```
