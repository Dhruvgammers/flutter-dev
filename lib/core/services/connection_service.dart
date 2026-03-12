import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/device.dart';
import '../models/message.dart';
import 'encryption_service.dart';

/// Handles secure P2P connections between devices
class ConnectionService extends ChangeNotifier {
  final EncryptionService _encryption;
  final _uuid = const Uuid();

  HttpServer? _server;
  WebSocket? _clientSocket;
  final Map<String, WebSocket> _connectedClients = {};
  final Map<String, Device> _pairedDevices = {};

  Device? _currentDevice;
  Device? _connectedDevice;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _pairingCode;

  final StreamController<SecureMessage> _messageController =
      StreamController<SecureMessage>.broadcast();

  // Callbacks
  Function(String)? onClipboardReceived;
  Function(String, int, String)? onFileReceived; // filename, size, transferId

  ConnectionService({required EncryptionService encryption})
    : _encryption = encryption;

  Device? get currentDevice => _currentDevice;
  Device? get connectedDevice => _connectedDevice;
  ConnectionStatus get status => _status;
  String? get pairingCode => _pairingCode;
  Stream<SecureMessage> get messageStream => _messageController.stream;
  List<Device> get pairedDevices => _pairedDevices.values.toList();
  bool get isConnected => _status == ConnectionStatus.connected;

  /// Initialize the connection service
  Future<void> initialize() async {
    await _encryption.initialize();
    await _initializeCurrentDevice();
  }

  /// Initialize current device info
  Future<void> _initializeCurrentDevice() async {
    final publicKey = await _encryption.getPublicKeyBase64();
    final deviceType = _getDeviceType();
    final platform = _getPlatform();

    _currentDevice = Device(
      id: _encryption.deviceId,
      name: await _getDeviceName(),
      type: deviceType,
      platform: platform,
      ipAddress: await _getLocalIpAddress(),
      port: 8765,
      publicKey: publicKey,
      lastSeen: DateTime.now(),
      status: ConnectionStatus.disconnected,
    );
    notifyListeners();
  }

  DeviceType _getDeviceType() {
    if (kIsWeb) return DeviceType.unknown;
    if (Platform.isAndroid || Platform.isIOS) return DeviceType.mobile;
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return DeviceType.desktop;
    }
    return DeviceType.unknown;
  }

  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  Future<String> _getDeviceName() async {
    if (kIsWeb) return 'Web Browser';
    if (Platform.isWindows) {
      return Platform.environment['COMPUTERNAME'] ?? 'Windows PC';
    }
    if (Platform.isMacOS) {
      return Platform.environment['USER'] ?? 'Mac';
    }
    if (Platform.isAndroid) return 'Android Device';
    if (Platform.isIOS) return 'iPhone';
    return 'Unknown Device';
  }

  Future<String> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting IP: $e');
    }
    return '0.0.0.0';
  }

  /// Start server to listen for incoming connections
  Future<void> startServer({int port = 8765}) async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _currentDevice = _currentDevice?.copyWith(port: port);
      debugPrint('Server started on port $port');

      _server!
          .transform(WebSocketTransformer())
          .listen(
            _handleIncomingConnection,
            onError: (error) {
              debugPrint('Server error: $error');
            },
          );

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to start server: $e');
      rethrow;
    }
  }

  /// Handle incoming WebSocket connections
  void _handleIncomingConnection(WebSocket socket) {
    debugPrint('New incoming connection');

    socket.listen(
      (data) => _handleMessage(socket, data),
      onDone: () => _handleDisconnection(socket),
      onError: (error) {
        debugPrint('Socket error: $error');
        _handleDisconnection(socket);
      },
    );
  }

  /// Connect to a remote device
  Future<void> connectToDevice(String ipAddress, int port, {Duration timeout = const Duration(seconds: 10)}) async {
    _updateStatus(ConnectionStatus.connecting);

    try {
      final uri = Uri.parse('ws://$ipAddress:$port');
      
      // Connect with timeout
      _clientSocket = await WebSocket.connect(uri.toString())
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Connection timed out. Make sure the other device is running Conto and both devices are on the same network.');
      });

      _clientSocket!.listen(
        (data) => _handleMessage(_clientSocket!, data),
        onDone: () => _handleDisconnection(_clientSocket!),
        onError: (error) {
          debugPrint('Connection error: $error');
          _handleDisconnection(_clientSocket!);
        },
      );

      // Send handshake
      await _sendHandshake(_clientSocket!);
    } catch (e) {
      _updateStatus(ConnectionStatus.error);
      debugPrint('Failed to connect: $e');
      rethrow;
    }
  }

  /// Send handshake message
  Future<void> _sendHandshake(WebSocket socket) async {
    final message = SecureMessage(
      id: _uuid.v4(),
      type: MessageType.handshake,
      senderId: _encryption.deviceId,
      payload: {'device': _currentDevice!.toJson()},
    );

    socket.add(message.toJsonString());
  }

  /// Handle incoming messages
  Future<void> _handleMessage(WebSocket socket, dynamic data) async {
    try {
      final message = SecureMessage.fromJsonString(data);

      switch (message.type) {
        case MessageType.handshake:
          await _handleHandshake(socket, message);
          break;
        case MessageType.handshakeResponse:
          await _handleHandshakeResponse(socket, message);
          break;
        case MessageType.clipboard:
          await _handleClipboard(message);
          break;
        case MessageType.fileRequest:
          await _handleFileRequest(message);
          break;
        case MessageType.ping:
          await _sendPong(socket);
          break;
        case MessageType.pong:
          // Connection is alive
          break;
        case MessageType.disconnect:
          _handleDisconnection(socket);
          break;
        default:
          _messageController.add(message);
      }
    } catch (e) {
      debugPrint('Error handling message: $e');
    }
  }

  /// Handle handshake from connecting device
  Future<void> _handleHandshake(WebSocket socket, SecureMessage message) async {
    final deviceData = message.payload['device'];
    final device = Device.fromJson(deviceData);

    // Generate pairing code for verification
    _pairingCode = await _encryption.generatePairingCode(device.publicKey);

    // Store connection
    _connectedClients[device.id] = socket;
    _connectedDevice = device.copyWith(status: ConnectionStatus.connected);

    // Send response
    final response = SecureMessage(
      id: _uuid.v4(),
      type: MessageType.handshakeResponse,
      senderId: _encryption.deviceId,
      receiverId: device.id,
      payload: {
        'device': _currentDevice!.toJson(),
        'pairingCode': _pairingCode,
      },
    );

    socket.add(response.toJsonString());
    _updateStatus(ConnectionStatus.connected);
  }

  /// Handle handshake response
  Future<void> _handleHandshakeResponse(
    WebSocket socket,
    SecureMessage message,
  ) async {
    final deviceData = message.payload['device'];
    final device = Device.fromJson(deviceData);
    _pairingCode = message.payload['pairingCode'];

    _connectedDevice = device.copyWith(status: ConnectionStatus.connected);
    _updateStatus(ConnectionStatus.connected);

    debugPrint('Connected to ${device.name}, Pairing code: $_pairingCode');
  }

  /// Handle clipboard data
  Future<void> _handleClipboard(SecureMessage message) async {
    if (_connectedDevice == null) return;

    try {
      final encryptedContent = message.payload['content'] as String;
      final content = await _encryption.decrypt(
        encryptedContent,
        _connectedDevice!.publicKey,
      );

      onClipboardReceived?.call(content);
      _messageController.add(message);
    } catch (e) {
      debugPrint('Error decrypting clipboard: $e');
    }
  }

  /// Handle file transfer request
  Future<void> _handleFileRequest(SecureMessage message) async {
    final fileName = message.payload['fileName'] as String;
    final fileSize = message.payload['fileSize'] as int;
    final transferId = message.payload['transferId'] as String;

    onFileReceived?.call(fileName, fileSize, transferId);
    _messageController.add(message);
  }

  /// Send clipboard content
  Future<void> sendClipboard(String content) async {
    if (!isConnected || _connectedDevice == null) return;

    try {
      final encryptedContent = await _encryption.encrypt(
        content,
        _connectedDevice!.publicKey,
      );

      final message = SecureMessage(
        id: _uuid.v4(),
        type: MessageType.clipboard,
        senderId: _encryption.deviceId,
        receiverId: _connectedDevice!.id,
        payload: {'content': encryptedContent},
      );

      _sendToConnectedDevice(message);
    } catch (e) {
      debugPrint('Error sending clipboard: $e');
    }
  }

  /// Send file transfer request
  Future<void> sendFileRequest(
    String fileName,
    int fileSize,
    String transferId,
  ) async {
    if (!isConnected || _connectedDevice == null) return;

    final message = SecureMessage(
      id: _uuid.v4(),
      type: MessageType.fileRequest,
      senderId: _encryption.deviceId,
      receiverId: _connectedDevice!.id,
      payload: {
        'fileName': fileName,
        'fileSize': fileSize,
        'transferId': transferId,
      },
    );

    _sendToConnectedDevice(message);
  }

  /// Send message to connected device
  void _sendToConnectedDevice(SecureMessage message) {
    if (_clientSocket != null) {
      _clientSocket!.add(message.toJsonString());
    } else if (_connectedDevice != null &&
        _connectedClients.containsKey(_connectedDevice!.id)) {
      _connectedClients[_connectedDevice!.id]!.add(message.toJsonString());
    }
  }

  /// Send pong response
  Future<void> _sendPong(WebSocket socket) async {
    final message = SecureMessage(
      id: _uuid.v4(),
      type: MessageType.pong,
      senderId: _encryption.deviceId,
      payload: {},
    );
    socket.add(message.toJsonString());
  }

  /// Handle disconnection
  void _handleDisconnection(WebSocket socket) {
    // Find and remove disconnected client
    _connectedClients.removeWhere((id, ws) => ws == socket);

    if (_clientSocket == socket) {
      _clientSocket = null;
    }

    _connectedDevice = null;
    _pairingCode = null;
    _updateStatus(ConnectionStatus.disconnected);
  }

  /// Update connection status
  void _updateStatus(ConnectionStatus status) {
    _status = status;
    notifyListeners();
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    if (_clientSocket != null) {
      final message = SecureMessage(
        id: _uuid.v4(),
        type: MessageType.disconnect,
        senderId: _encryption.deviceId,
        payload: {},
      );
      _clientSocket!.add(message.toJsonString());
      await _clientSocket!.close();
      _clientSocket = null;
    }

    for (var socket in _connectedClients.values) {
      await socket.close();
    }
    _connectedClients.clear();

    _connectedDevice = null;
    _pairingCode = null;
    _updateStatus(ConnectionStatus.disconnected);
  }

  /// Stop the server
  Future<void> stopServer() async {
    await disconnect();
    await _server?.close();
    _server = null;
  }

  @override
  void dispose() {
    stopServer();
    _messageController.close();
    super.dispose();
  }
}
