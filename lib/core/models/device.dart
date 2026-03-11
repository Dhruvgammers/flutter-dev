import 'dart:convert';

enum DeviceType { mobile, desktop, tablet, unknown }

enum ConnectionStatus { connected, connecting, disconnected, error }

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final String platform;
  final String ipAddress;
  final int port;
  final String publicKey;
  final DateTime lastSeen;
  final ConnectionStatus status;
  final bool isTrusted;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.platform,
    required this.ipAddress,
    required this.port,
    required this.publicKey,
    required this.lastSeen,
    this.status = ConnectionStatus.disconnected,
    this.isTrusted = false,
  });

  Device copyWith({
    String? id,
    String? name,
    DeviceType? type,
    String? platform,
    String? ipAddress,
    int? port,
    String? publicKey,
    DateTime? lastSeen,
    ConnectionStatus? status,
    bool? isTrusted,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      platform: platform ?? this.platform,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      publicKey: publicKey ?? this.publicKey,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
      isTrusted: isTrusted ?? this.isTrusted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'platform': platform,
      'ipAddress': ipAddress,
      'port': port,
      'publicKey': publicKey,
      'lastSeen': lastSeen.toIso8601String(),
      'status': status.name,
      'isTrusted': isTrusted,
    };
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      type: DeviceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DeviceType.unknown,
      ),
      platform: json['platform'],
      ipAddress: json['ipAddress'],
      port: json['port'],
      publicKey: json['publicKey'],
      lastSeen: DateTime.parse(json['lastSeen']),
      status: ConnectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConnectionStatus.disconnected,
      ),
      isTrusted: json['isTrusted'] ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Device.fromJsonString(String jsonString) {
    return Device.fromJson(jsonDecode(jsonString));
  }

  String get displayType {
    switch (type) {
      case DeviceType.mobile:
        return 'Mobile';
      case DeviceType.desktop:
        return 'Desktop';
      case DeviceType.tablet:
        return 'Tablet';
      default:
        return 'Unknown';
    }
  }

  String get statusText {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.error:
        return 'Connection Error';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
