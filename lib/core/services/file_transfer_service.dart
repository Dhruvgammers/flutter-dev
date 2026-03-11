import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/transfer_item.dart';
import 'connection_service.dart';
import 'encryption_service.dart';

/// Manages secure file transfers between devices
class FileTransferService extends ChangeNotifier {
  final ConnectionService _connectionService;
  final EncryptionService _encryptionService;
  final _uuid = const Uuid();

  final List<TransferItem> _transfers = [];
  final Map<String, StreamController<double>> _progressControllers = {};

  static const int chunkSize = 64 * 1024; // 64KB chunks

  FileTransferService({
    required ConnectionService connectionService,
    required EncryptionService encryptionService,
  }) : _connectionService = connectionService,
       _encryptionService = encryptionService {
    _connectionService.onFileReceived = _onFileTransferRequest;
  }

  List<TransferItem> get transfers => List.unmodifiable(_transfers);
  List<TransferItem> get pendingTransfers =>
      _transfers.where((t) => t.status == TransferStatus.pending).toList();
  List<TransferItem> get completedTransfers =>
      _transfers.where((t) => t.status == TransferStatus.completed).toList();

  /// Pick and send files
  Future<void> pickAndSendFiles() async {
    if (!_connectionService.isConnected) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      for (var file in result.files) {
        await sendFile(file.path!, file.name, file.size);
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }

  /// Send a file to connected device
  Future<void> sendFile(String filePath, String fileName, int fileSize) async {
    if (!_connectionService.isConnected) return;

    final transferId = _uuid.v4();
    final transfer = TransferItem(
      id: transferId,
      type: TransferType.file,
      senderId: _encryptionService.deviceId,
      receiverId: _connectionService.connectedDevice!.id,
      fileName: fileName,
      fileSize: fileSize,
      timestamp: DateTime.now(),
      status: TransferStatus.pending,
    );

    _transfers.insert(0, transfer);
    _progressControllers[transferId] = StreamController<double>.broadcast();
    notifyListeners();

    // Send file request
    await _connectionService.sendFileRequest(fileName, fileSize, transferId);

    // Start transfer (simplified for demo - in production would wait for acceptance)
    await _startFileTransfer(transferId, filePath);
  }

  /// Start the actual file transfer
  Future<void> _startFileTransfer(String transferId, String filePath) async {
    final index = _transfers.indexWhere((t) => t.id == transferId);
    if (index == -1) return;

    _transfers[index] = _transfers[index].copyWith(
      status: TransferStatus.inProgress,
    );
    notifyListeners();

    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final connectedDevice = _connectionService.connectedDevice;

      if (connectedDevice == null) {
        throw Exception('No connected device');
      }

      // Encrypt the file
      final encryptedBytes = await _encryptionService.encryptBytes(
        bytes,
        connectedDevice.publicKey,
      );

      // For this demo, we'll simulate chunked transfer
      final totalChunks = (encryptedBytes.length / chunkSize).ceil();

      for (var i = 0; i < totalChunks; i++) {
        // In production, would send: encryptedBytes.sublist(start, end)
        // final start = i * chunkSize;
        // final end = (start + chunkSize).clamp(0, encryptedBytes.length);

        // Simulate chunk transfer delay
        await Future.delayed(const Duration(milliseconds: 50));

        final progress = (i + 1) / totalChunks;
        _progressControllers[transferId]?.add(progress);

        _transfers[index] = _transfers[index].copyWith(progress: progress);
        notifyListeners();
      }

      _transfers[index] = _transfers[index].copyWith(
        status: TransferStatus.completed,
        progress: 1.0,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('File transfer error: $e');
      _transfers[index] = _transfers[index].copyWith(
        status: TransferStatus.failed,
        errorMessage: e.toString(),
      );
      notifyListeners();
    }
  }

  /// Handle incoming file transfer request
  void _onFileTransferRequest(
    String fileName,
    int fileSize,
    String transferId,
  ) {
    final transfer = TransferItem(
      id: transferId,
      type: TransferType.file,
      senderId: _connectionService.connectedDevice!.id,
      receiverId: _encryptionService.deviceId,
      fileName: fileName,
      fileSize: fileSize,
      timestamp: DateTime.now(),
      status: TransferStatus.pending,
    );

    _transfers.insert(0, transfer);
    _progressControllers[transferId] = StreamController<double>.broadcast();
    notifyListeners();
  }

  /// Accept incoming file transfer
  Future<void> acceptTransfer(String transferId) async {
    final index = _transfers.indexWhere((t) => t.id == transferId);
    if (index == -1) return;

    _transfers[index] = _transfers[index].copyWith(
      status: TransferStatus.inProgress,
    );
    notifyListeners();

    // Simulate receiving file
    await _receiveFile(transferId);
  }

  /// Receive file data
  Future<void> _receiveFile(String transferId) async {
    final index = _transfers.indexWhere((t) => t.id == transferId);
    if (index == -1) return;

    try {
      final transfer = _transfers[index];

      // Simulate progress
      for (var i = 0; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));

        final progress = i / 10;
        _progressControllers[transferId]?.add(progress);

        _transfers[index] = _transfers[index].copyWith(progress: progress);
        notifyListeners();
      }

      // Save file to downloads
      final downloadsDir = await _getDownloadsDirectory();
      final savePath = '${downloadsDir.path}/${transfer.fileName}';

      // In production, would save actual received data here
      final file = File(savePath);
      await file.writeAsString('Demo file content');

      _transfers[index] = _transfers[index].copyWith(
        status: TransferStatus.completed,
        progress: 1.0,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error receiving file: $e');
      _transfers[index] = _transfers[index].copyWith(
        status: TransferStatus.failed,
        errorMessage: e.toString(),
      );
      notifyListeners();
    }
  }

  /// Reject incoming file transfer
  void rejectTransfer(String transferId) {
    final index = _transfers.indexWhere((t) => t.id == transferId);
    if (index == -1) return;

    _transfers[index] = _transfers[index].copyWith(
      status: TransferStatus.cancelled,
    );
    notifyListeners();
  }

  /// Cancel ongoing transfer
  void cancelTransfer(String transferId) {
    final index = _transfers.indexWhere((t) => t.id == transferId);
    if (index == -1) return;

    _transfers[index] = _transfers[index].copyWith(
      status: TransferStatus.cancelled,
    );
    _progressControllers[transferId]?.close();
    _progressControllers.remove(transferId);
    notifyListeners();
  }

  /// Get progress stream for a transfer
  Stream<double>? getProgressStream(String transferId) {
    return _progressControllers[transferId]?.stream;
  }

  /// Clear completed transfers
  void clearCompleted() {
    _transfers.removeWhere(
      (t) =>
          t.status == TransferStatus.completed ||
          t.status == TransferStatus.cancelled ||
          t.status == TransferStatus.failed,
    );
    notifyListeners();
  }

  /// Get downloads directory
  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      return Directory('$userProfile\\Downloads');
    } else if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      return Directory('$home/Downloads');
    }
    return await getTemporaryDirectory();
  }

  @override
  void dispose() {
    for (var controller in _progressControllers.values) {
      controller.close();
    }
    super.dispose();
  }
}
