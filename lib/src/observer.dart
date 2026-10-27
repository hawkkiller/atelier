import 'view_model.dart';

/// Observes every [ViewModel] in the app, for logging, analytics, or debugging.
///
/// Install one with [ViewModel.observer], usually at startup. Every method
/// does nothing by default, so override only what you need:
///
/// ```dart
/// final class LoggingObserver extends AtelierObserver {
///   @override
///   void onStateChanged(ViewModel<Object> viewModel, Object previous, Object next) {
///     debugPrint('${viewModel.runtimeType}: $next');
///   }
/// }
///
/// ViewModel.observer = LoggingObserver();
/// ```
///
/// Hooks run synchronously on the ViewModel's own call path; an error thrown
/// by one propagates to that call.
abstract class AtelierObserver {
  /// Creates an observer.
  const AtelierObserver();

  /// Called when [viewModel] is created, before its subclass constructor body runs.
  void onCreate(ViewModel<Object> viewModel) {}

  /// Called after [viewModel] commits [next] in place of [previous].
  ///
  /// Called for every write, including writes of an equal value.
  void onStateChanged(ViewModel<Object> viewModel, Object previous, Object next) {}

  /// Called after [viewModel] delivers [effect] through a channel from
  /// `effectsOf`. Effects dropped for a cancelled task are not reported.
  void onEffect(ViewModel<Object> viewModel, Object? effect) {}

  /// Called when a task of [viewModel] fails with an error other than its own
  /// cancellation, before [ViewModel.onTaskError] handles it.
  void onTaskError(ViewModel<Object> viewModel, Object error, StackTrace stackTrace) {}

  /// Called when [viewModel] starts disposing, before its tasks are cancelled.
  void onDispose(ViewModel<Object> viewModel) {}
}
