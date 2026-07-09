import 'dart:async';

final Object _atelierTaskKey = Object();

abstract interface class AtelierTaskZoneContext {
  bool get isActive;
}

Future<T> runWithAtelierTask<T>(
  AtelierTaskZoneContext task,
  Future<T> Function() block,
) {
  return runZoned(block, zoneValues: {_atelierTaskKey: task});
}

bool atelierWritesAllowed() {
  final task = Zone.current[_atelierTaskKey] as AtelierTaskZoneContext?;
  return task == null || task.isActive;
}
