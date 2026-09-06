## Unreleased

- **Breaking:** `ViewModel.execute` is protected. Call ViewModel action methods
  from widgets. Replace `execute.concurrent(...)` with `execute(...)` inside
  ViewModels.

- **Breaking:** both Atelier mixins now own `build()`. Rename application
  overrides to `Widget view(BuildContext context)`; call watches during `view`.
- Clean up unused watches immediately after each view, including failed builds.
- Fix reentrant droppable, restartable, and sequential task execution.

## 0.0.1

- Add ViewModel lifecycle ownership.
- Add observable state and transient effects.
- Add lifecycle-aware task execution and cancellation policies.
- Add Flutter watch/listen bindings and automatic resource disposal.
