import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/network/env_config.dart';
import 'core/notifications/notification_providers.dart';
import 'core/notifications/push_token_registrar.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/character_creation/presentation/providers/character_creation_catalog_preloader.dart';
import 'features/characters/presentation/providers/character_write_sync_coordinator.dart';
import 'firebase_options.dart';

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

  // Notifications push (chantier "Notifications" —
  // `docs/cahier-des-charges/15-profil-parametres.md` section 3) : Android
  // uniquement pour cette itération, `firebase_options.dart` (généré par
  // FlutterFire CLI) ne couvre pas encore iOS (compte Apple Developer en
  // attente) — `DefaultFirebaseOptions.currentPlatform` lèverait
  // `UnsupportedError` sur cette plateforme. `kIsWeb` exclu par construction
  // (ce dépôt ne cible aucune cible web, voir `01-architecture-technique.md`).
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

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
    // Instancie tôt (`keepAlive`) le câblage des notifications push
    // (jeton FCM, réception au premier plan, tap sur notification), pour
    // toute la durée de l'app — voir `push_token_registrar.dart`.
    ref.watch(pushTokenRegistrarProvider);

    return MaterialApp.router(
      title: 'Nexus JDR — Personnages',
      theme: AppTheme.light,
      // Voir `notification_providers.dart::scaffoldMessengerKeyProvider` :
      // seul point d'accès à un `ScaffoldMessengerState` en dehors de tout
      // `BuildContext` d'écran, pour le `SnackBar` de message FCM reçu au
      // premier plan (`PushTokenRegistrar`).
      scaffoldMessengerKey: ref.watch(scaffoldMessengerKeyProvider),
      routerConfig: router,
    );
  }
}
