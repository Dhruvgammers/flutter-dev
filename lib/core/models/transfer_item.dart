import 'dart:convert';

enum TransferType { clipboard, file }

enum TransferStatus { pending, inProgress, completed, failed, cancelled }

class TransferItem {
  final String id;
  final TransferType type;
  final String senderId;
  final String receiverId;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final String? content; // For clipboard text
  final DateTime timestamp;
  final TransferStatus status;
  final double progress;
  final String? errorMessage;

  TransferItem({
    required this.id,
    required this.type,
    required this.senderId,
    required this.receiverId,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.content,
    required this.timestamp,
    this.status = TransferStatus.pending,
    this.progress = 0.0,
    this.errorMessage,
  });

  TransferItem copyWith({
    String? id,
    TransferType? type,
    String? senderId,
    String? receiverId,
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? content,
    DateTime? timestamp,
    TransferStatus? status,
    double? progress,
    String? errorMessage,
  }) {
    return TransferItem(
      id: id ?? this.id,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'senderId': senderId,
      'receiverId': receiverId,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'progress': progress,
      'errorMessage': errorMessage,
    };
  }

  factory TransferItem.fromJson(Map<String, dynamic> json) {
    return TransferItem(
      id: json['id'],
      type: TransferType.values.firstWhere((e) => e.name == json['type']),
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      status: TransferStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransferStatus.pending,
      ),
      progress: json['progress']?.toDouble() ?? 0.0,
      errorMessage: json['errorMessage'],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory TransferItem.fromJsonString(String jsonString) {
    return TransferItem.fromJson(jsonDecode(jsonString));
  }

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  bool get isClipboard => type == TransferType.clipboard;
  bool get isFile => type == TransferType.file;
  bool get isCompleted => status == TransferStatus.completed;
  bool get isFailed => status == TransferStatus.failed;
  bool get isInProgress => status == TransferStatus.inProgress;
}
