import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Servicio de criptografía para el llavero offline.
/// - Deriva clave con PBKDF2-HMAC-SHA256 (256 bits).
/// - Cifra/descifra con AES-GCM (256 bits).
/// - No imprime ni devuelve contraseñas/keys en claro.
class CryptoService {
  static const int defaultIterations = 200000; // configurable
  static const int saltLength = 16; // 16 bytes
  static const int keyBits = 256;   // 256-bit key => 32 bytes
  static const int nonceLength = 12; // AES-GCM (96 bits)

  final AesGcm _aesGcm = AesGcm.with256bits();

  /// Genera salt criptográficamente seguro [length] bytes usando Random.secure().
  Uint8List generateSalt({int length = saltLength}) {
    final r = Random.secure();
    final bytes = List<int>.generate(length, (_) => r.nextInt(256));
    return Uint8List.fromList(bytes);
  }

  /// Deriva una clave de 256 bits a partir de la [password] y [salt],
  /// con [iterations] (>= 100k).
  Future<Uint8List> deriveKey({
    required String password,
    required List<int> salt,
    int iterations = defaultIterations,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: keyBits,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt, // en esta lib, 'nonce' actúa como 'salt' para PBKDF2
    );

    final keyBytes = await secretKey.extractBytes();
    return Uint8List.fromList(keyBytes);
  }

  /// Cifra [plaintext] UTF-8 con AES-GCM(256).
  /// - [keyBytes] debe tener 32 bytes (256 bits).
  /// Retorna mapa con base64: nonce, ciphertext, mac.
  Future<Map<String, String>> encryptUtf8({
    required String plaintext,
    required List<int> keyBytes,
  }) async {
    if (keyBytes.length != 32) {
      throw ArgumentError('keyBytes debe tener 32 bytes (256 bits)');
    }
    final secretKey = SecretKey(keyBytes);
    final nonce = _aesGcm.newNonce(); // 12 bytes por defecto

    final secretBox = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );

    return {
      'algo': 'AES-GCM',
      'nonce': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }

  /// Descifra a UTF-8 un mapa con {nonce, ciphertext, mac} (base64) usando [keyBytes].
  Future<String> decryptToUtf8({
    required Map<String, String> encrypted,
    required List<int> keyBytes,
  }) async {
    if (keyBytes.length != 32) {
      throw ArgumentError('keyBytes debe tener 32 bytes (256 bits)');
    }
    final secretKey = SecretKey(keyBytes);

    final nonce = base64Decode(encrypted['nonce']!);
    final ciphertext = base64Decode(encrypted['ciphertext']!);
    final macBytes = base64Decode(encrypted['mac']!);

    final secretBox = SecretBox(
      ciphertext,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final clearBytes = await _aesGcm.decrypt(
      secretBox,
      secretKey: secretKey,
    );
    return utf8.decode(clearBytes);
  }

  String b64(List<int> bytes) => base64Encode(bytes);
  Uint8List b64dec(String b64str) => Uint8List.fromList(base64Decode(b64str));
}