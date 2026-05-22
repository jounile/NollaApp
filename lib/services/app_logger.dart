import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static final List<_LogEntry> _entries = [];

  static void log(String message) {
    final entry = _LogEntry(DateTime.now(), message);
    _entries.insert(0, entry);
    if (_entries.length > 300) _entries.removeLast();
    debugPrint(message);
  }

  static List<_LogEntry> get entries => List.unmodifiable(_entries);

  static void clear() => _entries.clear();
}

class _LogEntry {
  final DateTime timestamp;
  final String message;

  _LogEntry(this.timestamp, this.message);

  String get formatted {
    final t = timestamp;
    final hms =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}.${t.millisecond.toString().padLeft(3, '0')}';
    return '[$hms] $message';
  }
}
