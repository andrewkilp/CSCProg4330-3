import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';

/// Shared lifecycle/state mechanics only; feature data stays in each provider.
/// Operations are serialized so a stale refresh cannot overwrite a later write.
abstract class AsyncProvider extends ChangeNotifier {
  bool _disposed = false;
  bool _initialLoading = false;
  bool _refreshing = false;
  bool _mutating = false;
  AppException? _error;
  Future<void> _tail = Future.value();

  @protected
  bool hasLoaded = false;
  @protected
  bool get isDisposed => _disposed;
  bool get isInitialLoading => _initialLoading;
  bool get isRefreshing => _refreshing;
  bool get isMutating => _mutating;
  AppException? get error => _error;

  @protected
  void changed() {
    if (!_disposed) notifyListeners();
  }

  @protected
  Future<T> operate<T>(
    Future<T> Function() action, {
    bool mutation = false,
    bool loading = false,
  }) {
    final result = _tail.then((_) async {
      if (_disposed) throw StateError('Provider has been disposed.');
      final stateChanged = _error != null || mutation || loading;
      _error = null;
      _mutating = mutation;
      _initialLoading = loading && !hasLoaded;
      _refreshing = loading && hasLoaded;
      if (stateChanged) changed();
      try {
        return await action();
      } on AppException catch (error) {
        if (!_disposed) _error = error;
        rethrow;
      } finally {
        _initialLoading = false;
        _refreshing = false;
        _mutating = false;
        changed();
      }
    });
    // A failed operation must not poison the queue or create an unhandled future.
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  /// A successful write remains successful if its subsequent refresh fails.
  /// Retain the prior snapshot and expose the refresh error for a separate retry.
  @protected
  Future<void> refreshAfterWrite(Future<void> Function() refresh) async {
    try {
      await refresh();
    } on AppException catch (error) {
      if (!_disposed) _error = error;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
