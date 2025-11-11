// file: lib/ui/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:llavero_pass/crypto/crypto_service.dart';
import 'package:llavero_pass/data/vault_repository.dart';
import 'package:llavero_pass/domain/models.dart';

// DI básica
final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());
final vaultRepositoryProvider = Provider<VaultRepository>(
      (ref) => VaultRepository(crypto: ref.read(cryptoServiceProvider)),
);

// Estado del contenedor/entradas cargadas
final vaultEntriesProvider = StateProvider<List<VaultEntry>>((ref) => <VaultEntry>[]);
final vaultContainerProvider = StateProvider<VaultContainer?>((ref) => null);

// MPW solo en memoria (ephemeral). No persistir.
final sessionMasterPasswordProvider = StateProvider<String?>((ref) => null);

// Búsqueda
final searchQueryProvider = StateProvider<String>((ref) => '');