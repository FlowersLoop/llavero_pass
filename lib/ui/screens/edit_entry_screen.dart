// file: lib/ui/screens/edit_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:llavero_pass/domain/models.dart';
import 'package:llavero_pass/ui/state/vault_controller.dart';

class EditEntryScreen extends ConsumerStatefulWidget {
  final VaultEntry? initial; // null => crear

  const EditEntryScreen({super.key, this.initial});

  @override
  ConsumerState<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends ConsumerState<EditEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();

  bool _obscure = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    if (e != null) {
      _titleCtrl.text = e.titulo;
      _userCtrl.text = e.usuario;
      _passCtrl.text = e.password;
      _noteCtrl.text = e.nota;
      _tagsCtrl.text = e.tags.join(', ');
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _noteCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final tags = _tagsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final now = DateTime.now();
      final controller = ref.read(vaultControllerProvider.notifier);

      if (widget.initial == null) {
        final e = VaultEntry(
          id: now.millisecondsSinceEpoch.toString(),
          titulo: _titleCtrl.text.trim(),
          usuario: _userCtrl.text.trim(),
          password: _passCtrl.text,
          nota: _noteCtrl.text,
          tags: tags,
          createdAt: now,
          updatedAt: now,
        );
        await controller.addEntry(e);
      } else {
        final e = widget.initial!.copyWith(
          titulo: _titleCtrl.text.trim(),
          usuario: _userCtrl.text.trim(),
          password: _passCtrl.text,
          nota: _noteCtrl.text,
          tags: tags,
          updatedAt: now,
        );
        await controller.updateEntry(e);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardado')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar entrada' : 'Nueva entrada'),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: 'Copiar contraseña',
              icon: const Icon(Icons.copy),
              onPressed: () => Clipboard.setData(ClipboardData(text: _passCtrl.text)),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Título (sitio, app, etc.)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _userCtrl,
                decoration: const InputDecoration(labelText: 'Usuario / correo'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerida' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tags (separados por coma)',
                  helperText: 'Ej: trabajo, banco, personal',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: _busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(isEdit ? 'Guardar cambios' : 'Crear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}