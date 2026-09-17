import 'package:flutter/material.dart';

import 'theme_preferences.dart';

/// Starts in system mode. A user choice takes priority over an in-flight load.
class ThemeController extends ChangeNotifier {
  ThemeController(this._preferences);
  final ThemePreferenceStore _preferences;
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  String? _error;
  String? get error => _error;
  int _revision = 0;
  bool _disposed = false;
  Future<void> _writes = Future<void>.value();
  Future<void> load() async {
    final revision = _revision;
    try {
      final saved = await _preferences.load();
      if (_disposed || revision != _revision) return;
      if (_mode != saved) {
        _mode = saved;
        notifyListeners();
      }
    } catch (_) {
      if (!_disposed && revision == _revision) {
        _error = 'Could not load the saved theme.';
        notifyListeners();
      }
    }
  }

  /// Applies immediately; serializes writes so rapid choices persist in order.
  Future<void> setMode(ThemeMode value) {
    if (_disposed) return Future<void>.value();
    final revision = ++_revision;
    if (_mode != value || _error != null) {
      _mode = value;
      _error = null;
      notifyListeners();
    }
    _writes = _writes.then((_) async {
      try {
        await _preferences.save(value);
      } catch (_) {
        if (!_disposed && revision == _revision) {
          _error = 'Could not save the theme. Please try again.';
          notifyListeners();
        }
      }
    });
    return _writes;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
