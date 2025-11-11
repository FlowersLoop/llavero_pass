// file: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'ui/screens/setup_screen.dart';
import 'ui/screens/unlock_screen.dart';
import 'ui/screens/vault_list_screen.dart';
import 'ui/screens/edit_entry_screen.dart';
import 'domain/models.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: LlaveroApp()));
}

final _router = GoRouter(
  initialLocation: '/setup',
  routes: [
    GoRoute(path: '/setup', builder: (context, state) => const SetupScreen()),
    GoRoute(path: '/unlock', builder: (context, state) => const UnlockScreen()),
    GoRoute(path: '/vault', builder: (context, state) => const VaultListScreen()),
    GoRoute(
      path: '/edit',
      builder: (context, state) {
        final extra = state.extra;
        return EditEntryScreen(initial: extra is VaultEntry ? extra : null);
      },
    ),
  ],
);

class LlaveroApp extends StatelessWidget {
  const LlaveroApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    return MaterialApp.router(
      title: 'Llavero Offline',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(useMaterial3: true, colorScheme: scheme, brightness: Brightness.light),
      darkTheme:
      ThemeData(useMaterial3: true, colorScheme: scheme.copyWith(brightness: Brightness.dark)),
      themeMode: ThemeMode.system,
    );
  }
}