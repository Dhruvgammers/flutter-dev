import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles all encryption operations for secure communication
class EncryptionService {
  static const _keyPairKey = 'device_key_pair';
  static const _deviceIdKey = 'device_id';

  final FlutterSecureStorage _storage;
  final X25519 _keyExchange = X25519();
  final AesGcm _aesGcm = AesGcm.with256bits();
  final Sha256 _sha256 = Sha256();

  SimpleKeyPair? _keyPair;
  String? _deviceId;

  // Cache for session keys with paired devices
  final Map<String, SecretKey> _sessionKeys = {};

  EncryptionService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  /// Initialize the encryption service
  Future<void> initialize() async {
    await _loadOrGenerateKeyPair();
    await _loadOrGenerateDeviceId();
  }

  /// Get the device ID
  String get deviceId => _deviceId ?? '';

  /// Get the public key as base64 string
  Future<String> getPublicKeyBase64() async {
    if (_keyPair == null) await _loadOrGenerateKeyPair();
    final publicKey = await _keyPair!.extractPublicKey();
    final bytes = publicKey.bytes;
    return base64Encode(bytes);
  }

  /// Load or generate the device key pair
  Future<void> _loadOrGenerateKeyPair() async {
    try {
      final stored = await _storage.read(key: _keyPairKey);
      if (stored != null) {
        final data = jsonDecode(stored);
        final privateKeyBytes = base64Decode(data['private']);
        final publicKeyBytes = base64Decode(data['public']);

        _keyPair = SimpleKeyPairData(
          privateKeyBytes,
          publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.x25519),
          type: KeyPairType.x25519,
        );
      } else {
        await _generateAndStoreKeyPair();
      }
    } catch (e) {
      await _generateAndStoreKeyPair();
    }
  }

  /// Generate and store a new key pair
  Future<void> _generateAndStoreKeyPair() async {
    _keyPair = await _keyExchange.newKeyPair();
    final privateKeyData = await _keyPair!.extractPrivateKeyBytes();
    final publicKey = await _keyPair!.extractPublicKey();

    final data = {
      'private': base64Encode(privateKeyData),
      'public': base64Encode(publicKey.bytes),
    };

    await _storage.write(key: _keyPairKey, value: jsonEncode(data));
  }

  /// Load or generate device ID
  Future<void> _loadOrGenerateDeviceId() async {
    _deviceId = await _storage.read(key: _deviceIdKey);
    if (_deviceId == null) {
      _deviceId = _generateSecureId();
      await _storage.write(key: _deviceIdKey, value: _deviceId);
    }
  }

  /// Generate a secure random ID
  String _generateSecureId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Perform key exchange with a peer and derive session key
  Future<SecretKey> deriveSessionKey(String peerPublicKeyBase64) async {
    // Check cache first
    if (_sessionKeys.containsKey(peerPublicKeyBase64)) {
      return _sessionKeys[peerPublicKeyBase64]!;
    }

    final peerPublicKeyBytes = base64Decode(peerPublicKeyBase64);
    final peerPublicKey = SimplePublicKey(
      peerPublicKeyBytes,
      type: KeyPairType.x25519,
    );

    // Perform X25519 key exchange
    final sharedSecret = await _keyExchange.sharedSecretKey(
      keyPair: _keyPair!,
      remotePublicKey: peerPublicKey,
    );

    // Derive AES key from shared secret using HKDF-like derivation
    final secretBytes = await sharedSecret.extractBytes();
    final hash = await _sha256.hash(secretBytes);
    final sessionKey = SecretKey(hash.bytes);

    // Cache the session key
    _sessionKeys[peerPublicKeyBase64] = sessionKey;

    return sessionKey;
  }

  /// Encrypt data with AES-GCM using the session key
  Future<String> encrypt(String plaintext, String peerPublicKeyBase64) async {
    final sessionKey = await deriveSessionKey(peerPublicKeyBase64);
    final plaintextBytes = utf8.encode(plaintext);

    // Generate random nonce (IV)
    final nonce = _aesGcm.newNonce();

    // Encrypt
    final secretBox = await _aesGcm.encrypt(
      plaintextBytes,
      secretKey: sessionKey,
      nonce: nonce,
    );

    // Combine nonce + ciphertext + mac
    final ciphertextBytes = Uint8List.fromList(secretBox.cipherText);
    final result = {
      'nonce': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(ciphertextBytes),
      'mac': base64Encode(secretBox.mac.bytes),
    };

    return jsonEncode(result);
  }

  /// Decrypt data with AES-GCM using the session key
  Future<String> decrypt(
    String encryptedData,
    String peerPublicKeyBase64,
  ) async {
    final sessionKey = await deriveSessionKey(peerPublicKeyBase64);
    final data = jsonDecode(encryptedData);

    final nonce = base64Decode(data['nonce']);
    final ciphertext = base64Decode(data['ciphertext']);
    final mac = Mac(base64Decode(data['mac']));

    final secretBox = SecretBox(ciphertext, nonce: nonce, mac: mac);

    final plaintextBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: sessionKey,
    );

    return utf8.decode(plaintextBytes);
  }

  /// Encrypt file bytes
  Future<Uint8List> encryptBytes(
    Uint8List data,
    String peerPublicKeyBase64,
  ) async {
    final sessionKey = await deriveSessionKey(peerPublicKeyBase64);
    final nonce = _aesGcm.newNonce();

    final secretBox = await _aesGcm.encrypt(
      data,
      secretKey: sessionKey,
      nonce: nonce,
    );

    // Combine: nonce (12 bytes) + mac (16 bytes) + ciphertext
    final ciphertextBytes = Uint8List.fromList(secretBox.cipherText);
    final result = Uint8List(12 + 16 + ciphertextBytes.length);
    result.setRange(0, 12, secretBox.nonce);
    result.setRange(12, 28, secretBox.mac.bytes);
    result.setRange(28, result.length, ciphertextBytes);

    return result;
  }

  /// Decrypt file bytes
  Future<Uint8List> decryptBytes(
    Uint8List encryptedData,
    String peerPublicKeyBase64,
  ) async {
    final sessionKey = await deriveSessionKey(peerPublicKeyBase64);

    final nonce = encryptedData.sublist(0, 12);
    final mac = Mac(encryptedData.sublist(12, 28));
    final ciphertext = encryptedData.sublist(28);

    final secretBox = SecretBox(ciphertext, nonce: nonce, mac: mac);

    final plaintext = await _aesGcm.decrypt(secretBox, secretKey: sessionKey);

    return Uint8List.fromList(plaintext);
  }

  /// Generate a pairing code (short code for manual verification)
  Future<String> generatePairingCode(String peerPublicKeyBase64) async {
    final myPublicKey = await getPublicKeyBase64();
    final combined = '$myPublicKey:$peerPublicKeyBase64';
    final hash = await _sha256.hash(utf8.encode(combined));

    // Take first 6 characters as pairing code
    return base64UrlEncode(
      hash.bytes.sublist(0, 4),
    ).replaceAll('=', '').toUpperCase().substring(0, 6);
  }

  /// Clear session key for a specific peer
  void clearSessionKey(String peerPublicKeyBase64) {
    _sessionKeys.remove(peerPublicKeyBase64);
  }

  /// Clear all session keys
  void clearAllSessionKeys() {
    _sessionKeys.clear();
  }

  /// Sign a message for authentication
  Future<String> signMessage(String message) async {
    final messageBytes = utf8.encode(message);
    final privateKeyBytes = await _keyPair!.extractPrivateKeyBytes();

    // Create HMAC-like signature using SHA256
    final combined = [...privateKeyBytes, ...messageBytes];
    final hash = await _sha256.hash(combined);

    return base64Encode(hash.bytes);
  }

  /// Verify message signature
  Future<bool> verifySignature(
    String message,
    String signature,
    String peerPublicKeyBase64,
  ) async {
    try {
      final sessionKey = await deriveSessionKey(peerPublicKeyBase64);
      final keyBytes = await sessionKey.extractBytes();
      final messageBytes = utf8.encode(message);

      final combined = [...keyBytes, ...messageBytes];
      final hash = await _sha256.hash(combined);
      final expectedSignature = base64Encode(hash.bytes);

      return signature == expectedSignature;
    } catch (e) {
      return false;
    }
  }
}
