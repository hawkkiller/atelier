## Unreleased

- **Breaking:** replace `textController()`, `focusNode()` and `scrollController()` with
  `own(notifier)`, which disposes any `ChangeNotifier`; `disposeWith` is now part of
  `AtelierStateBindings`.
- **Breaking:** require Flutter 3.38 or later, matching the Dart 3.10 SDK constraint.
- Fix re-entrant `droppable`, `sequential` and `restartable` calls made before the
  block's first `await` (null-check crash, parallel sequential runs, and an
  untracked restartable task).
- Effects emitted by callbacks that a task registered (stream listeners, timers) are
  no longer dropped once the task finishes normally; they are still dropped for
  cancelled tasks and after disposal.
- Add `ViewModel.onTaskError` to handle task failures as state or effects.
- Add `ViewModel.disposeWith` for ViewModel-owned resources.
- Assert in debug builds when `watch` is called outside a build or `listen` from
  `build`.
- Document the full public API and mark unimplemented proposal sections.
- Add commands: declare `late final search = restartable((String query, task) async {...})`
  (also `droppable`, `sequential`, `concurrent`, and `.noArgs`). Commands are callable,
  are their own lane key, and expose `isRunning` and `cancel()`.
- Add `TaskContext.state` getter and setter (`task.state = task.state.copyWith(...)`).

## 0.0.1

- Add ViewModel lifecycle ownership.
- Add observable state and transient effects.
- Add lifecycle-aware task execution and cancellation policies.
- Add Flutter watch/listen bindings and automatic resource disposal.
