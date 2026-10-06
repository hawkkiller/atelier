import 'dart:async';

import 'state_value.dart';
import 'task.dart';

/// What every command exposes besides being callable.
abstract interface class CommandHandle {
  /// Whether at least one invocation is running or queued.
  ///
  /// Updates synchronously when a call starts and when its [Future] settles,
  /// so it can replace a hand-written `loading` flag in state.
  StateValue<bool> get isRunning;

  /// Cancels running invocations and skips queued ones.
  ///
  /// Cancellation is cooperative, exactly as with restart or disposal.
  void cancel();
}

/// A ViewModel operation that takes one argument.
///
/// Declared with `restartable`, `droppable`, `sequential` or `concurrent` on
/// a ViewModel, and called like a function: `viewModel.search('Kra')`. Use a
/// record for several arguments.
abstract interface class Command<A> implements CommandHandle {
  /// Starts an invocation with [argument] under the command's policy.
  Future<void> call(A argument);
}

/// A ViewModel operation without arguments, created with `.noArgs`.
abstract interface class VoidCommand implements CommandHandle {
  /// Starts an invocation under the command's policy.
  Future<void> call();
}

/// Creates commands for one task policy; returned by the ViewModel's
/// `restartable`, `droppable`, `sequential` and `concurrent` getters.
final class CommandFactory<S extends Object> {
  /// Creates a factory backed by [createRunner]. Not intended for direct use.
  const CommandFactory(this._createRunner);

  final CommandRunner<S> Function() _createRunner;

  /// Declares a command that takes one argument.
  Command<A> call<A>(Future<void> Function(A argument, TaskContext<S> task) block) {
    return _ArgCommand<S, A>(_createRunner(), block);
  }

  /// Declares a command without arguments.
  VoidCommand noArgs(Future<void> Function(TaskContext<S> task) block) {
    return _VoidCommand<S>(_createRunner(), block);
  }
}

/// Runs a command's invocations and tracks [isRunning]. Not exported.
final class CommandRunner<S extends Object> {
  /// Creates a runner that starts tasks on [_executor] with [_policy].
  CommandRunner(this._executor, this._policy);

  final AtelierTaskExecutor<S> _executor;
  final TaskPolicy _policy;
  final AtelierMutableState<bool> _isRunning = AtelierMutableState(false);
  int _pending = 0;

  /// See [CommandHandle.isRunning].
  StateValue<bool> get isRunning => _isRunning;

  /// Starts [block] under the policy, keyed by this runner.
  Future<void> run(Future<void> Function(TaskContext<S> task) block) {
    final future = switch (_policy) {
      TaskPolicy.concurrent => _executor.concurrent(block, key: this),
      TaskPolicy.sequential => _executor.sequential(block, key: this),
      TaskPolicy.droppable => _executor.droppable(block, key: this),
      TaskPolicy.restartable => _executor.restartable(block, key: this),
    };
    _setPending(_pending + 1);
    unawaited(future.whenComplete(() => _setPending(_pending - 1)).then<void>((_) {}, onError: (_, _) {}));
    return future;
  }

  /// See [CommandHandle.cancel].
  void cancel() => _executor.cancelKey(this);

  /// Closes [isRunning]; called when the ViewModel is disposed.
  void close() => _isRunning.close();

  void _setPending(int pending) {
    final wasRunning = _pending > 0;
    _pending = pending;
    if (wasRunning != pending > 0) _isRunning.setValue(pending > 0);
  }
}

final class _ArgCommand<S extends Object, A> implements Command<A> {
  _ArgCommand(this._runner, this._block);

  final CommandRunner<S> _runner;
  final Future<void> Function(A argument, TaskContext<S> task) _block;

  @override
  StateValue<bool> get isRunning => _runner.isRunning;

  @override
  Future<void> call(A argument) => _runner.run((task) => _block(argument, task));

  @override
  void cancel() => _runner.cancel();
}

final class _VoidCommand<S extends Object> implements VoidCommand {
  _VoidCommand(this._runner, this._block);

  final CommandRunner<S> _runner;
  final Future<void> Function(TaskContext<S> task) _block;

  @override
  StateValue<bool> get isRunning => _runner.isRunning;

  @override
  Future<void> call() => _runner.run(_block);

  @override
  void cancel() => _runner.cancel();
}
