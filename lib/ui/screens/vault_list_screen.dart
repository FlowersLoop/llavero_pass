// file: lib/ui/screens/vault_list_screen.dart
//import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';

//import 'package:llavero_pass/domain/models.dart';
import 'package:llavero_pass/ui/app_providers.dart';
import 'package:llavero_pass/ui/state/vault_controller.dart';
import 'dart:io' show File, Directory;
import 'package:path_provider/path_provider.dart';

class VaultListScreen extends ConsumerWidget {
  const VaultListScreen({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(vaultRepositoryProvider);
    try {
      // Exporta a .../app_flutter/export/ (visible en Device Explorer)
      final outPath = await repo.exportToInternalAppDir();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exportado a:\n$outPath')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(vaultRepositoryProvider);
    try {
      final docs = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${docs.path}/export');

      if (!await exportDir.exists()) {
        throw 'No existe la carpeta de export.';
      }

      final files = exportDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.vault'))
          .toList()
        ..sort((a, b) =>
            b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      if (files.isEmpty) {
        throw 'No se encontraron archivos .vault en export/.';
      }

      final lastFile = files.first;

      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Importar último backup'),
          content: Text(
              'Se importará el archivo más reciente:\n\n${lastFile.path}\n\n¿Deseas continuar?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Importar')),
          ],
        ),
      );
      if (ok != true) return;

      await repo.importFromPath(lastFile.path);

      ref.invalidate(vaultEntriesProvider);
      ref.invalidate(vaultContainerProvider);
      ref.invalidate(sessionMasterPasswordProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Importado correctamente desde:\n${lastFile.path}')),
      );
      context.go('/unlock');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al importar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(vaultControllerProvider);
    final q = ref.watch(searchQueryProvider);

    final filtered = q.trim().isEmpty
        ? entries
        : entries.where((e) {
      final t = '${e.titulo} ${e.usuario} ${e.tags.join(" ")} ${e.nota}'.toLowerCase();
      return t.contains(q.toLowerCase());
    }).toList();

    filtered.sortBy((e) => e.titulo.toLowerCase());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis contraseñas'),
        actions: [
          IconButton(
            tooltip: 'Exportar vault',
            onPressed: () => _export(context, ref),
            icon: const Icon(Icons.file_upload),
          ),
          IconButton(
            tooltip: 'Importar vault',
            onPressed: () => _import(context, ref),
            icon: const Icon(Icons.file_download),
          ),
          IconButton(
            tooltip: 'Importar último interno',
            onPressed: () => _import(context, ref), // usa el nuevo método interno
            icon: const Icon(Icons.folder_open),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar…',
                ),
                onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Sin resultados.'))
                  : ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final e = filtered[i];
                  return ListTile(
                    leading: const Icon(Icons.vpn_key),
                    title: Text(e.titulo),
                    subtitle: Text(e.usuario),
                    onTap: () => context.push('/edit', extra: e),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Acciones',
                      onSelected: (v) async {
                        if (v == 'copy_user') {
                          await Clipboard.setData(ClipboardData(text: e.usuario));
                          if (!context.mounted) return; // validar antes de usar context
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Usuario copiado')),
                          );
                        } else if (v == 'copy_pass') {
                          await Clipboard.setData(ClipboardData(text: e.password));
                          if (!context.mounted) return; // validar antes de usar context
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Contraseña copiada')),
                          );
                        } else if (v == 'delete') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Eliminar entrada'),
                              content: Text('¿Eliminar "${e.titulo}"? Esta acción no se puede deshacer.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await ref.read(vaultControllerProvider.notifier).deleteEntry(e.id);
                            // (No usamos context aquí después del await, así que no hace falta checar mounted)
                          }
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'copy_user', child: Text('Copiar usuario')),
                        PopupMenuItem(value: 'copy_pass', child: Text('Copiar contraseña')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/edit'),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    );
  }
}