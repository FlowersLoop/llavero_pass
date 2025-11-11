// file: lib/ui/screens/setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:llavero_pass/ui/app_providers.dart';
import 'package:llavero_pass/ui/widgets/password_strength_bar.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mpwCtrl = TextEditingController();
  final _mpw2Ctrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _busy = false;

  @override
  void dispose() {
    _mpwCtrl.dispose();
    _mpw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _createVault() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = ref.read(vaultRepositoryProvider);
    final mpw = _mpwCtrl.text;
    try {
      // NUEVO: si ya existe → no intentamos crear, vamos a /unlock
      final exists = await repo.existsVault();
      if (exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya existe un vault. Ve a Desbloquear.')),
        );
        context.go('/unlock');
        return;
      }

      await repo.createNewVault(masterPassword: mpw);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault creado correctamente')),
      );
      context.go('/unlock');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear vault: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validateMPW(String? v) {
    if (v == null || v.isEmpty) return 'Requerida';
    if (v.length < 8) return 'Usa al menos 8 caracteres';
    final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
    final hasLower = RegExp(r'[a-z]').hasMatch(v);
    final hasDigit = RegExp(r'\d').hasMatch(v);
    if (!(hasUpper && hasLower && hasDigit)) {
      return 'Incluye mayúsculas, minúsculas y dígitos';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p1 = _mpwCtrl.text;
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración inicial')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'Crea tu Master Password (no se puede recuperar).',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mpwCtrl,
                  obscureText: _obscure1,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Master Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                      tooltip: _obscure1 ? 'Mostrar' : 'Ocultar',
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: _validateMPW,
                ),
                const SizedBox(height: 12),
                PasswordStrengthBar(password: p1),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mpw2Ctrl,
                  obscureText: _obscure2,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Master Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                      tooltip: _obscure2 ? 'Mostrar' : 'Ocultar',
                    ),
                  ),
                  validator: (v) => (v != _mpwCtrl.text) ? 'No coincide' : null,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _busy ? null : _createVault,
                  icon: _busy
                      ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: const Text('Crear vault'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => context.go('/unlock'),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Ya tengo vault → Desbloquear'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}