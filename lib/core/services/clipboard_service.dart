import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'connection_service.dart';

/// Manages clipboard synchronization between devices
class ClipboardService extends ChangeNotifier {
  final ConnectionService _connectionService;

  String _lastClipboardContent = '';
  final List<ClipboardItem> _history = [];
  bool _autoSync = true;
  Timer? _clipboardWatcher;

  ClipboardService({required ConnectionService connectionService})
    : _connectionService = connectionService {
    _connectionService.onClipboardReceived = _onClipboardReceived;
  }

  List<ClipboardItem> get history => List.unmodifiable(_history);
  bool get autoSync => _autoSync;
  String get lastContent => _lastClipboardContent;

  /// Start watching clipboard for changes
  void startWatching() {
    _clipboardWatcher?.cancel();
    _clipboardWatcher = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkClipboard(),
    );
  }

  /// Stop watching clipboard
  void stopWatching() {
    _clipboardWatcher?.cancel();
    _clipboardWatcher = null;
  }

  /// Check clipboard for changes
  Future<void> _checkClipboard() async {
    if (!_autoSync || !_connectionService.isConnected) return;

    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final content = data?.text ?? '';

      if (content.isNotEmpty && content != _lastClipboardContent) {
        _lastClipboardContent = content;
        await sendClipboard(content);
      }
    } catch (e) {
      debugPrint('Error checking clipboard: $e');
    }
  }

  /// Send clipboard content to connected device
  Future<void> sendClipboard(String content) async {
    if (!_connectionService.isConnected) return;

    await _connectionService.sendClipboard(content);

    _addToHistory(
      ClipboardItem(
        content: content,
        timestamp: DateTime.now(),
        direction: ClipboardDirection.sent,
      ),
    );
  }

  /// Handle received clipboard content
  void _onClipboardReceived(String content) {
    _lastClipboardContent = content;

    // Copy to system clipboard
    Clipboard.setData(ClipboardData(text: content));

    _addToHistory(
      ClipboardItem(
        content: content,
        timestamp: DateTime.now(),
        direction: ClipboardDirection.received,
      ),
    );

    notifyListeners();
  }

  /// Add item to history
  void _addToHistory(ClipboardItem item) {
    _history.insert(0, item);

    // Limit history to 100 items
    if (_history.length > 100) {
      _history.removeRange(100, _history.length);
    }

    notifyListeners();
  }

  /// Toggle auto sync
  void toggleAutoSync() {
    _autoSync = !_autoSync;
    if (_autoSync) {
      startWatching();
    } else {
      stopWatching();
    }
    notifyListeners();
  }

  /// Clear history
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  /// Copy text from history
  Future<void> copyFromHistory(ClipboardItem item) async {
    await Clipboard.setData(ClipboardData(text: item.content));
    _lastClipboardContent = item.content;
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }
}

enum ClipboardDirection { sent, received }

class ClipboardItem {
  final String content;
  final DateTime timestamp;
  final ClipboardDirection direction;

  ClipboardItem({
    required this.content,
    required this.timestamp,
    required this.direction,
  });

  bool get isSent => direction == ClipboardDirection.sent;
  bool get isReceived => direction == ClipboardDirection.received;

  String get preview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  String get timeFormatted {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${timestamp.day}/${timestamp.month}';
  }
}
