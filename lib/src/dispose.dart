/// Runs every cleanup in order, then rethrows the first failure.
void disposeAll(Iterable<void Function()> disposers) {
  Object? error;
  StackTrace? stackTrace;
  for (final dispose in disposers) {
    try {
      dispose();
    } catch (caughtError, caughtStackTrace) {
      error ??= caughtError;
      stackTrace ??= caughtStackTrace;
    }
  }
  if (error != null) Error.throwWithStackTrace(error, stackTrace!);
}
