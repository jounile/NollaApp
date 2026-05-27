import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLogger {
  AppLogger._();

  static final List<LogEntry> _entries = [];

  static void log(String message) {
    final entry = LogEntry(DateTime.now(), message);
    _entries.insert(0, entry);
    if (_entries.length > 300) _entries.removeLast();
    debugPrint(message);
  }

  static List<LogEntry> get entries => List.unmodifiable(_entries);

  /// Returns only entries whose message contains at least one of [tags].
  /// If [tags] is empty, returns all entries.
  static List<LogEntry> filteredEntries(List<String> tags) {
    if (tags.isEmpty) return entries;
    return _entries.where((e) => tags.any((t) => e.message.contains(t))).toList();
  }

  static void clear() => _entries.clear();
}

class LogEntry {
  final DateTime timestamp;
  final String message;

  LogEntry(this.timestamp, this.message);

  String get formatted {
    final t = timestamp;
    final hms =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}.${t.millisecond.toString().padLeft(3, '0')}';
    return '[$hms] $message';
  }
}

/// Shows a draggable log viewer bottom sheet.
/// Pass [filter] tags (e.g. `['[FeedService]']`) to show only matching entries.
void showLogViewer(BuildContext context, {List<String> filter = const []}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        final entries = AppLogger.filteredEntries(filter);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.92,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollController) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.terminal, size: 20),
                    const SizedBox(width: 8),
                    const Text('Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Copy to clipboard',
                      onPressed: entries.isEmpty
                          ? null
                          : () async {
                              final text = entries.map((e) => e.formatted).join('\n');
                              await Clipboard.setData(ClipboardData(text: text));
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Logs copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                    ),
                    TextButton(
                      onPressed: () {
                        AppLogger.clear();
                        setModalState(() {});
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('No logs yet'))
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: entries.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            entries[i].formatted,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

