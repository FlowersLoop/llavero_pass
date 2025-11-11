import 'dart:convert';

/// Versión del contenedor de vault para validar compatibilidad
const int kVaultVersion = 1;

/// Entrada dentro del vault (se serializa a JSON y luego se cifra)
class VaultEntry {
  final String id;               // UUID o nanoid
  final String titulo;
  final String usuario;
  final String password;          // Se guarda EN PLANO solo en memoria;
                                  // en disco va cifrado (contenedor)
  final String nota;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  VaultEntry({
    required this.id,
    required this.titulo,
    required this.usuario,
    required this.password,
    required this.nota,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  VaultEntry copyWith({
    String? id,
    String? titulo,
    String? usuario,
    String? password,
    String? nota,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VaultEntry(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      usuario: usuario ?? this.usuario,
      password: password ?? this.password,
      nota: nota ?? this.nota,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'usuario': usuario,
    'password': password,
    'nota': nota,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory VaultEntry.fromJson(Map<String, dynamic> json) => VaultEntry(
    id: json['id'] as String,
    titulo: json['titulo'] as String,
    usuario: json['usuario'] as String,
    password: json['password'] as String,
    nota: json['nota'] as String? ?? '',
    tags: (json['tags'] as List?)?.cast<String>() ?? const [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

/// Estructura del contenedor cifrado que se escribe a disco.
/// Todo lo sensible está en ciphertext (Base64).
class VaultContainer {
  final int version;            // p. ej. 1
  final String kdf;             // 'PBKDF2-HMAC-SHA256'
  final int iterations;         // >=100k
  final String cipher;          // 'AES-GCM'
  final String saltB64;         // 16B -> Base64
  final String nonceB64;        // 12B -> Base64
  final String ciphertextB64;   // Base64
  final String macB64;          // Base64
  final DateTime updatedAt;

  VaultContainer({
    required this.version,
    required this.kdf,
    required this.iterations,
    required this.cipher,
    required this.saltB64,
    required this.nonceB64,
    required this.ciphertextB64,
    required this.macB64,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'kdf': kdf,
    'iterations': iterations,
    'cipher': cipher,
    'salt': saltB64,
    'nonce': nonceB64,
    'ciphertext': ciphertextB64,
    'mac': macB64,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory VaultContainer.fromJson(Map<String, dynamic> json) => VaultContainer(
    version: json['version'] as int,
    kdf: json['kdf'] as String,
    iterations: json['iterations'] as int,
    cipher: json['cipher'] as String,
    saltB64: json['salt'] as String,
    nonceB64: json['nonce'] as String,
    ciphertextB64: json['ciphertext'] as String,
    macB64: json['mac'] as String,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  String toPrettyString() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// Resultado al abrir/cargar el vault (útil para UI)
class VaultOpenResult {
  final List<VaultEntry> entries;
  final VaultContainer container;

  VaultOpenResult({required this.entries, required this.container});
}