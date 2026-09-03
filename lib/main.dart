import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/network/env_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/character_creation/presentation/providers/character_creation_catalog_preloader.dart';
import 'features/characters/presentation/providers/character_write_sync_coordinator.dart';

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
class NexusJdrApp extends ConsumerWidget {
  const NexusJdrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Instancie tôt (`keepAlive`) le coordinateur de synchro hors-ligne
    // PV/XP, pour toute la durée de l'app — voir
    // `character_write_sync_coordinator.dart`.
    ref.watch(characterWriteSyncCoordinatorProvider);
    // Instancie tôt (`keepAlive`) le préchargeur des catalogues de
    // référence de l'assistant de création, pour toute la durée de l'app —
    // voir `character_creation_catalog_preloader.dart`.
    ref.watch(characterCreationCatalogPreloaderProvider);

    return MaterialApp.router(
      title: 'Nexus JDR — Personnages',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
