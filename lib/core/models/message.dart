import 'dart:convert';

enum MessageType {
  handshake,
  handshakeResponse,
  clipboard,
  fileRequest,
  fileAccept,
  fileReject,
  fileChunk,
  fileComplete,
  ping,
  pong,
  disconnect,
  error,
}

class SecureMessage {
  final String id;
  final MessageType type;
  final String senderId;
  final String? receiverId;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final String? signature;

  SecureMessage({
    required this.id,
    required this.type,
    required this.senderId,
    this.receiverId,
    required this.payload,
    DateTime? timestamp,
    this.signature,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'senderId': senderId,
      'receiverId': receiverId,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'signature': signature,
    };
  }

  factory SecureMessage.fromJson(Map<String, dynamic> json) {
    return SecureMessage(
      id: json['id'],
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.error,
      ),
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      signature: json['signature'],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SecureMessage.fromJsonString(String jsonString) {
    return SecureMessage.fromJson(jsonDecode(jsonString));
  }

  SecureMessage copyWith({
    String? id,
    MessageType? type,
    String? senderId,
    String? receiverId,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    String? signature,
  }) {
    return SecureMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      signature: signature ?? this.signature,
    );
  }
}
