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
import 'features/app_update/domain/app_version_status.dart';
import 'features/app_update/presentation/force_update_screen.dart';
import 'features/app_update/presentation/providers/app_version_providers.dart';
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
///
/// Renvoie `true` si `Supabase.initialize` a réussi (et donc si
/// `Supabase.instance.client` est sûr d'accès), `false` sinon —
/// [AppBootstrap] s'en sert pour décider s'il peut construire [NexusJdrApp]
/// (dont le routeur lit `Supabase.instance.client` dès sa construction,
/// via `core/network/supabase_client_provider.dart`) ou doit rester sur un
/// écran de repli : `Supabase.instance.client` est un champ `late`, son
/// accès avant une initialisation réussie lève un
/// `LateInitializationError` **non lié aux `assert`** (donc pas retiré en
/// release) — contrairement à ce qu'un ancien commentaire ici laissait
/// entendre, laisser passer vers [NexusJdrApp] après un échec de
/// `Supabase.initialize` plante réellement, dans tous les modes de build.
Future<bool> _initializeSupabaseAndFirebase() async {
  assert(
    EnvConfig.isConfigured,
    'SUPABASE_URL / SUPABASE_ANON_KEY manquants : lancer avec '
    '--dart-define-from-file=config/<flavor>.json (voir config/README.md).',
  );

  var supabaseReady = false;
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
    supabaseReady = true;
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
  // Un échec ici (Firebase, secondaire aux notifications push) ne doit pas
  // empêcher l'app de démarrer si Supabase, lui, a bien réussi — même
  // rationale de résilience que ci-dessus.
  if (supabaseReady &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'nexus_jdr main',
          context: ErrorDescription('lors de Firebase.initializeApp'),
        ),
      );
    }
  }

  return supabaseReady;
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
///
/// Une fois [initialize] résolu **avec succès** (`true`, Supabase prêt), ce
/// widget vérifie aussi la version installée (`appVersionCheckProvider`,
/// `features/app_update/presentation/providers/app_version_providers.dart`)
/// avant de basculer sur [child] : `AppVersionStatus.updateRequired` affiche
/// `ForceUpdateScreen` à la place (écran bloquant, recettage
/// direction-artistique du 13/09/2026), tout autre statut — y compris un
/// échec de la vérification elle-même, voir la doc de
/// `appVersionCheckProvider` — laisse passer vers [child] normalement.
///
/// Si [initialize] résout `false` (Supabase indisponible), ni la
/// vérification de version ni [child] ne sont construits — tous deux
/// dépendent de `Supabase.instance.client`, qui planterait (voir la doc de
/// [_initializeSupabaseAndFirebase]) — [_SupabaseUnavailableScreen] prend le
/// relais à la place, avec un bouton "Réessayer" qui relance [initialize].
@visibleForTesting
class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({
    this.initialize = _initializeSupabaseAndFirebase,
    this.child = const NexusJdrApp(),
    super.key,
  });

  final Future<bool> Function() initialize;
  final Widget child;

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  late Future<bool> _initialization = widget.initialize();

  void _retryInitialization() {
    // Corps de bloc, pas d'expression : `setState(() => _initialization =
    // widget.initialize())` renvoie la valeur de l'affectation (le
    // `Future<bool>` lui-même), ce que `setState` interprète comme un
    // callback async invalide.
    setState(() {
      _initialization = widget.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _splashApp();
        }

        // `snapshot.data != true` couvre `false` (échec intercepté par
        // [_initializeSupabaseAndFirebase]) ET `snapshot.hasError` (défense
        // en profondeur : ne devrait pas arriver puisque cette fonction ne
        // laisse plus rien remonter, mais un `initialize` substitué en test
        // pourrait toujours le faire) — dans les deux cas, ni la
        // vérification de version ni [child] ne sont sûrs à construire.
        if (snapshot.data != true) {
          return MaterialApp(
            theme: AppTheme.light,
            debugShowCheckedModeBanner: false,
            home: _SupabaseUnavailableScreen(onRetry: _retryInitialization),
          );
        }

        final versionCheck = ref.watch(appVersionCheckProvider);
        return versionCheck.when(
          // Toujours affiché plutôt qu'une exception non gérée : un
          // provider `keepAlive` déjà en `AsyncError` (ex. lu une première
          // fois avant que Supabase soit prêt dans un test) ne devrait
          // normalement jamais arriver ici (`appVersionCheckProvider`
          // intercepte lui-même toute exception, voir sa documentation),
          // mais retomber sur [child] reste le choix le plus sûr si jamais
          // c'était le cas — jamais bloquant pour un souci de version.
          error: (error, stackTrace) => widget.child,
          loading: _splashApp,
          data: (result) {
            if (result.status == AppVersionStatus.updateRequired) {
              return MaterialApp(
                theme: AppTheme.light,
                debugShowCheckedModeBanner: false,
                home: ForceUpdateScreen(
                  installedVersion: result.installedVersion,
                  minimumVersion: result.minimumVersion,
                  storeUrl: result.storeUrl,
                ),
              );
            }
            return widget.child;
          },
        );
      },
    );
  }

  Widget _splashApp() {
    return MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

/// Repli minimal si [_initializeSupabaseAndFirebase] échoue — cas rare (ex.
/// configuration `SUPABASE_URL` malformée), mais [NexusJdrApp] ne peut pas
/// être construit dans cet état (voir la doc de classe d'[AppBootstrap]).
/// Volontairement sommaire (pas de maquette dédiée à cet état, contrairement
/// à [ForceUpdateScreen]/[SplashScreen]) : juste de quoi ne jamais laisser
/// l'utilisateur face à un écran figé sans recours.
class _SupabaseUnavailableScreen extends StatelessWidget {
  const _SupabaseUnavailableScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.light.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Impossible de démarrer l\'application. Vérifie ta '
                  'connexion et réessaie.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
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
