// file: lib/data/vault_repository.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../crypto/crypto_service.dart';
import '../domain/models.dart';

const String kVaultFileName = 'vault.vault';

class VaultRepository {
  final CryptoService crypto;

  VaultRepository({required this.crypto});

  // ---------- Rutas internas ----------
  Future<Directory> _appDocsDir() => getApplicationDocumentsDirectory(); // .../app_flutter

  Future<File> _vaultFile() async {
    final dir = await _appDocsDir();
    final path = '${dir.path}/$kVaultFileName';
    return File(path);
  }

  /// Ruta ABSOLUTA del vault interno (para mostrar al usuario).
  Future<String> vaultInternalPath() async => (await _vaultFile()).path;

  /// ¿Existe el archivo del vault?
  Future<bool> existsVault() async => (await _vaultFile()).exists();

  // ---------- Crear / Cargar / Guardar ----------
  Future<VaultContainer> createNewVault({
    required String masterPassword,
    int iterations = CryptoService.defaultIterations,
  }) async {
    final file = await _vaultFile();
    if (await file.exists()) {
      throw StateError('El vault ya existe. Usa loadVault o borra manualmente antes de crear.');
    }

    final clearJson = {
      'meta': {
        'createdAt': DateTime.now().toIso8601String(),
        'version': kVaultVersion,
      },
      'entries': <Map<String, dynamic>>[],
    };
    final plaintext = jsonEncode(clearJson);

    final Uint8List salt = crypto.generateSalt();
    final key = await crypto.deriveKey(
      password: masterPassword,
      salt: salt,
      iterations: iterations,
    );

    final enc = await crypto.encryptUtf8(
      plaintext: plaintext,
      keyBytes: key,
    );

    final container = VaultContainer(
      version: kVaultVersion,
      kdf: 'PBKDF2-HMAC-SHA256',
      iterations: iterations,
      cipher: 'AES-GCM',
      saltB64: crypto.b64(salt),
      nonceB64: enc['nonce']!,
      ciphertextB64: enc['ciphertext']!,
      macB64: enc['mac']!,
      updatedAt: DateTime.now(),
    );

    await _atomicWriteJson(file, container.toJson());
    return container;
  }

  Future<VaultOpenResult> loadVault({required String masterPassword}) async {
    final file = await _vaultFile();
    if (!await file.exists()) {
      throw StateError('No existe el archivo del vault. Crea uno primero.');
    }

    final text = await file.readAsString();
    final jsonMap = jsonDecode(text) as Map<String, dynamic>;
    final container = VaultContainer.fromJson(jsonMap);

    if (container.version != kVaultVersion) {
      throw StateError('Versión de vault incompatible: ${container.version}.');
    }
    if (container.kdf != 'PBKDF2-HMAC-SHA256' || container.cipher != 'AES-GCM') {
      throw StateError('Parámetros cripto incompatibles.');
    }

    final salt = base64Decode(container.saltB64);
    final key = await crypto.deriveKey(
      password: masterPassword,
      salt: salt,
      iterations: container.iterations,
    );

    final clear = await crypto.decryptToUtf8(
      encrypted: {
        'nonce': container.nonceB64,
        'ciphertext': container.ciphertextB64,
        'mac': container.macB64,
      },
      keyBytes: key,
    );

    final clearJson = jsonDecode(clear) as Map<String, dynamic>;
    final entriesList = (clearJson['entries'] as List?) ?? const [];
    final entries = entriesList
        .map((e) => VaultEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    return VaultOpenResult(entries: entries, container: container);
  }

  Future<VaultContainer> saveVault({
    required String masterPassword,
    required List<VaultEntry> entries,
  }) async {
    final file = await _vaultFile();
    if (!await file.exists()) {
      throw StateError('No existe el archivo del vault. Crea uno primero.');
    }

    final text = await file.readAsString();
    final current = VaultContainer.fromJson(jsonDecode(text));

    final salt = base64Decode(current.saltB64);
    final key = await crypto.deriveKey(
      password: masterPassword,
      salt: salt,
      iterations: current.iterations,
    );

    final clearJson = {
      'meta': {
        'updatedAt': DateTime.now().toIso8601String(),
        'version': kVaultVersion,
      },
      'entries': entries.map((e) => e.toJson()).toList(),
    };
    final plaintext = jsonEncode(clearJson);

    final enc = await crypto.encryptUtf8(
      plaintext: plaintext,
      keyBytes: key,
    );

    final updated = VaultContainer(
      version: kVaultVersion,
      kdf: 'PBKDF2-HMAC-SHA256',
      iterations: current.iterations,
      cipher: 'AES-GCM',
      saltB64: current.saltB64,
      nonceB64: enc['nonce']!,
      ciphertextB64: enc['ciphertext']!,
      macB64: enc['mac']!,
      updatedAt: DateTime.now(),
    );

    await _atomicWriteJson(file, updated.toJson());
    return updated;
  }

  // ---------- Export / Import ----------

  /// Exporta al directorio **interno** de la app (visible en Device Explorer):
  /// /data/data/<package>/app_flutter/export/vault_<ts>.vault
  Future<String> exportToInternalAppDir() async {
    final docs = await getApplicationDocumentsDirectory(); // .../app_flutter
    final outDir = Directory('${docs.path}/export');
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outPath = '${outDir.path}/vault_$ts.vault';
    await exportToPath(outPath);
    return outPath;
  }

  /// Exporta una copia a [destPath].
  Future<void> exportToPath(String destPath) async {
    final file = await _vaultFile();
    if (!await file.exists()) {
      throw StateError('No existe el archivo del vault local para exportar.');
    }
    final dest = File(destPath);
    await dest.create(recursive: true);
    await file.copy(dest.path);
  }

  /// Importa desde [srcPath]. Valida estructura y hace respaldo `.bak`.
  Future<void> importFromPath(String srcPath) async {
    final file = await _vaultFile();
    final src = File(srcPath);
    if (!await src.exists()) {
      throw StateError('No existe el archivo origen para importar.');
    }

    final text = await src.readAsString();
    final jsonMap = jsonDecode(text) as Map<String, dynamic>;
    final container = VaultContainer.fromJson(jsonMap);
    if (container.kdf != 'PBKDF2-HMAC-SHA256' || container.cipher != 'AES-GCM') {
      throw StateError('El archivo importado no cumple los parámetros cripto requeridos.');
    }

    if (await file.exists()) {
      final bak = File('${file.path}.bak');
      await file.copy(bak.path);
    }

    await src.copy(file.path);
  }

  // ---------- Util ----------
  Future<void> _atomicWriteJson(File target, Map<String, dynamic> jsonMap) async {
    final tmp = File('${target.path}.tmp');
    final content = const JsonEncoder().convert(jsonMap);
    await tmp.writeAsString(content, flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await tmp.rename(target.path);
  }
}