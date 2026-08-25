import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/network/env_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(
    EnvConfig.isConfigured,
    'SUPABASE_URL / SUPABASE_ANON_KEY manquants : lancer avec '
    '--dart-define-from-file=config/<flavor>.json (voir config/README.md).',
  );

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    // Le nom de variable d'environnement `SUPABASE_ANON_KEY` (voir
    // config/README.md) est conservé pour rester cohérent avec l'app web
    // (`NEXT_PUBLIC_SUPABASE_ANON_KEY`), mais supabase_flutter attend
    // désormais ce paramètre sous le nom `publishableKey` (anonKey est
    // dépréciée).
    publishableKey: EnvConfig.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: NexusJdrApp()));
}

/// Point d'entrée de l'application "Nexus JDR — Personnages".
class NexusJdrApp extends StatelessWidget {
  const NexusJdrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus JDR — Personnages',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const _HomePlaceholder(),
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nexus JDR — Personnages')),
      body: const Center(child: Text('Nexus JDR — Personnages')),
    );
  }
}
