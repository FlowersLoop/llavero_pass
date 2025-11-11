// file: lib/ui/state/vault_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:llavero_pass/domain/models.dart';
import 'package:llavero_pass/ui/app_providers.dart';

/// Notifier que opera sobre entries en memoria y persiste con saveVault().
final vaultControllerProvider = NotifierProvider<VaultController, List<VaultEntry>>(
  VaultController.new,
);

class VaultController extends Notifier<List<VaultEntry>> {
  @override
  List<VaultEntry> build() {
    // fuente de verdad: vaultEntriesProvider
    return ref.watch(vaultEntriesProvider);
  }

  void _commit(List<VaultEntry> updated) {
    state = updated;
    ref.read(vaultEntriesProvider.notifier).state = updated;
  }

  Future<void> addEntry(VaultEntry e) async {
    final updated = [...state, e];
    await _save(updated);
  }

  Future<void> updateEntry(VaultEntry e) async {
    final updated = [
      for (final it in state) if (it.id == e.id) e else it,
    ];
    await _save(updated);
  }

  Future<void> deleteEntry(String id) async {
    final updated = [for (final it in state) if (it.id != id) it];
    await _save(updated);
  }

  Future<void> _save(List<VaultEntry> entries) async {
    final repo = ref.read(vaultRepositoryProvider);
    final mpw = ref.read(sessionMasterPasswordProvider);
    if (mpw == null || mpw.isEmpty) {
      throw StateError('Sesión no desbloqueada (MPW no disponible)');
    }
    await repo.saveVault(masterPassword: mpw, entries: entries);
    _commit(entries);
    // Actualiza marca de tiempo del contenedor
    final opened = await repo.loadVault(masterPassword: mpw);
    ref.read(vaultContainerProvider.notifier).state = opened.container;
  }
}