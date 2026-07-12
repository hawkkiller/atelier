# Atelier roadmap

Atelier is a small, lifecycle-first UDF framework for Flutter ViewModels, state,
effects, and tasks—not a replacement for Flutter's widget model.

## Principles

- Keep ViewModels pure Dart; `BuildContext` and UI-owned resources stay in
  Flutter `State` objects.
- Make lifecycle, task, and cancellation behavior explicit and tested.
- Prefer one immutable screen state plus semantic, one-shot effects.
- Keep the public API small and Flutter-native.
- Pull features forward only when **real applications demonstrate a recurring
  problem** that Flutter and Dart do not solve well.

## Current baseline

- [x] ViewModels own state, effects, tasks, and idempotent disposal. Disposal
  cancels tasks, runs `onDispose()`, and closes owned channels.
- [x] `StateValue` provides a current value and replaying broadcast stream;
  effects are non-replaying broadcasts to current listeners.
- [x] Concurrent, sequential, droppable, and restartable task policies coordinate
  work through keyed lanes.
- [x] Commands return `Future<void>`. Cancellation from restart or disposal
  settles normally when work returns cooperatively or throws the expected
  `TaskCancelledException`; unrelated errors still propagate, including errors
  thrown after cancellation.
- [x] Stale task zones discard Atelier state and effect writes, while
  `TaskContext.ensureActive()` protects non-Atelier side effects.
- [x] Flutter bindings provide `watch`, `watchSelect`, `listen`, ViewModel
  ownership, and resource disposal; the weather example uses Open-Meteo.

## Before 0.0.1

The first release should verify and document the existing implementation.

### Contracts

- [ ] Add focused tests for all task policies, key collisions, synchronous
  failures, and sequential progress after an invocation fails.
- [ ] Lock down cancellation settlement for restartable replacement, active
  disposal, queued sequential disposal, cooperative return, expected
  `TaskCancelledException`, and unrelated errors after cancellation.
- [ ] Document droppable future sharing, keyed lanes, calls after disposal, and
  the cooperative limits of Dart cancellation.
- [ ] Verify stale tasks cannot write state or effects, and document the required
  activity check before repository, platform, or UI side effects.

### Lifecycle and bindings

- [ ] Test ViewModel disposal order, idempotency, channel closure, and cleanup
  continuation when `onDispose()` or a resource disposer throws.
- [ ] Add widget tests for ViewModel creation/disposal exactly once, unmounting,
  `watch` source replacement, conditional watches, selector equality, and
  duplicate `listen` calls.
- [ ] Document that `createViewModel()` runs during `super.initState()` and show
  the correct non-listening inherited-widget lookup.
- [ ] Review the weather flow for ViewModel boilerplate; change ergonomics only
  when application code is repeated and error-prone.

### Release quality

- [ ] Cover loading, empty, success, API error, retry, and rapid-query
  cancellation in the weather example without stale updates or uncaught errors.
- [ ] Keep weather repository and ViewModel tests deterministic; the default test
  suite must not require live network access.
- [ ] Add CI that formats, analyzes, and tests the package and example.
- [ ] Complete package metadata and publish exclusions; resolve warnings from
  `flutter pub publish --dry-run`.
- [ ] Audit public exports and dartdoc so every exported symbol is intentional,
  documented, and covered by an example or contract test.

## After 0.0.1

- [ ] Validate Atelier in at least one non-example application across navigation,
  retries, app lifecycle changes, and teardown before expanding the API.
- [ ] Harden cancellation races, re-entrant commands, nested rebuilds, and
  dependency changes only from reproducible application failures; add a focused
  regression test for each change.
- [ ] Define pre-1.0 compatibility rules. Every breaking change needs a changelog
  entry, migration snippet, and replacement contract test.
- [ ] Evaluate adapters, diagnostics, test utilities, disposal helpers, and
  binding refinements only after repeated real-app usage.
- [ ] Keep README snippets, API docs, and the weather example checked against the
  supported public API in CI where practical.

## Deferred and non-goals

- Generated dependency injection, generated ViewModel factories, modules,
  qualifiers, or generated scopes. Use constructor injection and explicit
  composition roots for now.
- Generic task results. Commands remain `Future<void>`; durable results belong in
  state, while transient outcomes belong in effects or errors.
- Structured concurrency or task trees.
- Framework debounce; keep timing policy at the input or repository boundary.
- Package splitting while the framework remains small.
- Aggregate disposal exceptions; cleanup continues and the first error remains
  visible.
- Broad route integration, scoped composition, or DevTools support without
  evidence from real applications.
