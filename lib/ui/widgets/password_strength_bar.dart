import 'package:flutter/material.dart';

/// Evaluación muy simple de fortaleza de contraseña (MVP):
/// - longitud
/// - mezcla de may/min
/// - dígitos
/// - símbolos
class PasswordStrengthBar extends StatelessWidget {
  final String password;
  const PasswordStrengthBar({super.key, required this.password});

  int _score(String p) {
    int s = 0;
    if (p.length >= 8) s++;
    if (p.length >= 12) s++;
    if (RegExp(r'[a-z]').hasMatch(p) && RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'\d').hasMatch(p)) s++;
    if (RegExp(r'[^\w\s]').hasMatch(p)) s++;
    return s.clamp(0, 5);
  }

  @override
  Widget build(BuildContext context) {
    final s = _score(password);
    final colors = <Color>[
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.lightGreen,
      Colors.green,
    ];
    final labels = <String>['Muy débil', 'Débil', 'Aceptable', 'Fuerte', 'Muy fuerte'];
    final idx = s == 0 ? 0 : (s - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: s / 5.0,
          minHeight: 8,
          color: colors[idx],
          backgroundColor: Colors.grey.shade300,
          semanticsLabel: 'Nivel de seguridad de la contraseña',
        ),
        const SizedBox(height: 6),
        Text('Fortaleza: ${labels[idx]}', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}