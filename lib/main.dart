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
import 'features/splash/presentation/splash_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // `runApp` est appelé avant toute initialisation asynchrone (Supabase,
  // Firebase) : c'est `AppBootstrap` (ci-dessous), pas `main`, qui les
  // attend désormais, pour pouvoir afficher [SplashScreen] pendant ce délai
  // au lieu de laisser Flutter démarré mais rien affiché (l'ancien splash
  // natif de `flutter_native_splash` bascule directement sur cet écran vide
  // le temps du `await Supabase.initialize(...)` bloquant qui précédait
  // `runApp` ici) — voir `docs/cahier-des-charges/05-ux-navigation.md` et
  // `09-maquettes-captures.md` section "Lancement — Splash".
  runApp(const ProviderScope(child: AppBootstrap()));
}

/// Initialise Supabase puis, sur Android, Firebase — logique
/// d'initialisation par défaut d'[AppBootstrap], extraite en fonction
/// top-level pour rester substituable en test (voir [AppBootstrap
/// .initialize]).
Future<void> _initializeSupabaseAndFirebase() async {
  assert(
    EnvConfig.isConfigured,
    'SUPABASE_URL / SUPABASE_ANON_KEY manquants : lancer avec '
    '--dart-define-from-file=config/<flavor>.json (voir config/README.md).',
  );

  // `Supabase.initialize` ne fait aucun appel réseau bloquant en soi (mise en
  // place du client + stockage local de session) : en cas d'échec (ex.
  // plugin natif indisponible), on ne bloque quand même pas indéfiniment
  // l'écran de lancement (`05-ux-navigation.md` : « en cas d'échec réseau à
  // ce stade, l'app démarre quand même hors ligne sur les données déjà en
  // cache plutôt que de rester bloquée sur cet écran »). La résilience
  // réseau proprement dite (repli sur le cache `drift` des données de
  // référence/de la fiche personnage ouverte) est un mécanisme distinct,
  // déjà en place plus bas dans l'app (Phase 2, mode hors-ligne) et hors du
  // périmètre de cet écran.
  try {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      // Le nom de variable d'environnement `SUPABASE_ANON_KEY` (voir
      // config/README.md) est conservé pour rester cohérent avec l'app web
      // (`NEXT_PUBLIC_SUPABASE_ANON_KEY`), mais supabase_flutter attend
      // désormais ce paramètre sous le nom `publishableKey` (anonKey est
      // dépréciée).
      publishableKey: EnvConfig.supabaseAnonKey,
    );
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'nexus_jdr main',
        context: ErrorDescription('lors de Supabase.initialize'),
      ),
    );
  }

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
}

/// Racine réelle de l'app : affiche [SplashScreen] le temps que [initialize]
/// se résolve (Supabase puis, sur Android, Firebase par défaut — voir
/// [_initializeSupabaseAndFirebase]), puis bascule sur [child] ([NexusJdrApp]
/// par défaut) une fois prêt.
///
/// [NexusJdrApp] ne peut pas être construit avant la fin de
/// `Supabase.initialize` : son routeur (`core/router/app_router.dart`) lit
/// `Supabase.instance.client` dès sa construction (via
/// `core/network/supabase_client_provider.dart`) pour calculer la
/// redirection connecté/non connecté, et cet appel lève si `Supabase
/// .initialize` n'a pas encore été résolu — c'est pour ça que ce widget
/// bascule entre deux arbres de widgets distincts (un `MaterialApp` minimal
/// affichant [SplashScreen], puis [child]) plutôt que d'insérer [SplashScreen]
/// comme simple route du router de [NexusJdrApp].
///
/// [initialize] et [child] sont substituables (constructeur, pas de valeur
/// figée) uniquement pour permettre un test de widget de cet enchaînement
/// sans jamais appeler `Supabase.initialize`/`Firebase.initializeApp` pour de
/// vrai ni dépendre d'un `Supabase.instance.client` réel — voir
/// `test/main_test.dart`.
@visibleForTesting
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({
    this.initialize = _initializeSupabaseAndFirebase,
    this.child = const NexusJdrApp(),
    super.key,
  });

  final Future<void> Function() initialize;
  final Widget child;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<void> _initialization = widget.initialize();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            theme: AppTheme.light,
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
          );
        }
        return widget.child;
      },
    );
  }
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
