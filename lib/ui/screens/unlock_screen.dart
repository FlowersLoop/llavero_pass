// file: lib/ui/screens/unlock_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:llavero_pass/ui/app_providers.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mpwCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _mpwCtrl.dispose();
    super.dispose();
  }

  Future<void> _onUnlock() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(vaultRepositoryProvider);
    final mpw = _mpwCtrl.text;
    try {
      final opened = await repo.loadVault(masterPassword: mpw);
      // Estado en memoria
      ref.read(vaultEntriesProvider.notifier).state = opened.entries;
      ref.read(vaultContainerProvider.notifier).state = opened.container;
      ref.read(sessionMasterPasswordProvider.notifier).state = mpw; // <- guardar MPW en RAM

      if (!mounted) return;
      context.go('/vault');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Desbloqueo fallido: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Desbloquear')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ingresa tu Master Password para abrir el llavero.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mpwCtrl,
                  obscureText: _obscure,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Master Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                      tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerida' : null,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _busy ? null : _onUnlock,
                  icon: _busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.lock_open),
                  label: const Text('Desbloquear'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}