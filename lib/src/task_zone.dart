import 'dart:async';

final Object _atelierTaskKey = Object();

/// A task as seen by zone-based effect suppression. Not exported.
abstract interface class AtelierTaskZoneContext {
  /// Whether effect writes from this task's zone must be dropped.
  ///
  /// True once the task is cancelled (by restart or disposal) or its owning
  /// ViewModel is disposed. A task that merely finished does not suppress
  /// writes, so callbacks it registered (stream listeners, timers) keep
  /// emitting until they are cancelled or the ViewModel is disposed.
  bool get suppressesWrites;
}

/// Runs [block] in a zone that identifies [task] to [atelierWritesAllowed].
Future<T> runWithAtelierTask<T>(
  AtelierTaskZoneContext task,
  Future<T> Function() block,
) {
  return runZoned(block, zoneValues: {_atelierTaskKey: task});
}

/// Whether an effect emitted from the current zone should be delivered.
bool atelierWritesAllowed() {
  final task = Zone.current[_atelierTaskKey] as AtelierTaskZoneContext?;
  return task == null || !task.suppressesWrites;
}
