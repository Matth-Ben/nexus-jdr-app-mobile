import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/character_creation/presentation/ability_score_step_screen.dart';
import '../../features/character_creation/presentation/appearance_and_backstory_step_screen.dart';
import '../../features/character_creation/presentation/background_step_screen.dart';
import '../../features/character_creation/presentation/class_step_screen.dart';
import '../../features/character_creation/presentation/equipment_step_screen.dart';
import '../../features/character_creation/presentation/race_step_screen.dart';
import '../../features/character_creation/presentation/skills_and_tools_step_screen.dart';
import '../../features/character_creation/presentation/spells_step_screen.dart';
import '../../features/character_creation/presentation/summary_step_screen.dart';
import '../../features/characters/presentation/character_detail_screen.dart';
import '../../features/characters/presentation/character_list_screen.dart';
import '../../features/characters/presentation/level_up_screen.dart';
import '../../features/join_story/presentation/join_character_step_screen.dart';
import '../../features/join_story/presentation/join_code_step_screen.dart';
import '../../features/join_story/presentation/join_confirmation_step_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/xml_import/presentation/xml_import_review_screen.dart';
import '../network/supabase_client_provider.dart';
import 'route_observer_provider.dart';

part 'app_router.g.dart';

/// Routeur applicatif : redirige automatiquement `/login` ↔ `/` selon
/// l'état d'authentification Supabase, conformément à l'arborescence
/// générale de `docs/cahier-des-charges/05-ux-navigation.md`
/// (non connecté → connexion, connecté → liste des personnages).
///
/// `go_router` est un choix technique assumé pour la suite de la Phase 2 :
/// l'assistant de création (étapes) et la fiche personnage (onglets) auront
/// besoin d'une navigation déclarative par route plutôt que d'une pile de
/// `Navigator.push` manuelle — à signaler au chef de projet si un autre
/// choix était préféré, ce point n'était pas tranché dans le cahier des
/// charges.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  final refreshListenable = _GoRouterRefreshStream(
    client.auth.onAuthStateChange,
  );
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    // Voir `route_observer_provider.dart` : permet à `CharacterListScreen`
    // (et tout futur écran équivalent) de se rafraîchir via
    // `RouteAware.didPopNext` au retour d'une route poussée par-dessus lui,
    // sans avoir à chasser chaque point d'écriture qui pourrait la rendre
    // obsolète.
    observers: [ref.watch(routeObserverProvider)],
    redirect: (context, state) => computeAuthRedirect(
      isLoggedIn: client.auth.currentSession != null,
      // `state.uri` (pas `state.matchedLocation`, qui omet la query) : la
      // reprise du parcours "Rejoindre une histoire" après connexion a
      // besoin du code d'invitation porté par la query (`?code=...`), voir
      // la documentation de [computeAuthRedirect].
      location: state.uri.toString(),
    ),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const CharacterListScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/characters/new',
        builder: (context, state) => const RaceStepScreen(),
      ),
      GoRoute(
        path: '/characters/new/step-2',
        builder: (context, state) => const ClassStepScreen(),
      ),
      GoRoute(
        path: '/characters/new/step-3',
        builder: (context, state) => const BackgroundStepScreen(),
      ),
      GoRoute(
        path: '/characters/new/step-4',
        builder: (context, state) => const AbilityScoreStepScreen(),
      ),
      GoRoute(
        path: '/characters/new/step-5',
        builder: (context, state) => const SkillsAndToolsStepScreen(),
      ),
      GoRoute(
        path: '/characters/new/step-6',
        builder: (context, state) => const SpellsStepScreen(),
      ),
      GoRoute(
        // Atteinte directement depuis l'étape 5/9 pour une classe non
        // lanceuse de sorts (`SkillsAndToolsStepScreen._submit` saute
        // l'étape 6/9) — voir `domain/spellcasting_rules.dart`.
        path: '/characters/new/step-7',
        builder: (context, state) => const EquipmentStepScreen(),
      ),
      GoRoute(
        path: '/characters/new/step-8',
        builder: (context, state) => const AppearanceAndBackstoryStepScreen(),
      ),
      GoRoute(
        // Étape 9/9 "Récapitulatif" : dernière étape, seule à écrire en
        // base (voir `presentation/summary_step_screen.dart`).
        path: '/characters/new/step-9',
        builder: (context, state) => const SummaryStepScreen(),
      ),
      GoRoute(
        // Écran de vérification de l'import XML aidedd.org
        // (`features/xml_import/`) : poussée avec `extra` (nom de fichier +
        // contenu XML déjà lu par le sélecteur de fichier natif,
        // `CharacterListScreen._startXmlImport`) — premier usage d'`extra`
        // dans ce dépôt (voir la doc de `LevelUpScreen`, qui avait
        // volontairement évité `extra` au profit d'un paramètre de requête
        // pour un flux plus simple) : un contenu de fichier XML entier
        // n'a pas vocation à transiter par l'URL ni à être deep-linké,
        // contrairement au niveau ciblé d'une montée de niveau — choix
        // technique signalé au chef de projet plutôt qu'un des deux
        // mécaniques déjà en place.
        path: '/characters/import',
        builder: (context, state) {
          final args = state.extra! as ({String fileName, String xmlSource});
          return XmlImportReviewScreen(
            fileName: args.fileName,
            xmlSource: args.xmlSource,
          );
        },
      ),
      GoRoute(
        // Écran "Profil / paramètres du compte" (`features/profile/`),
        // poussée depuis l'icône profil ronde de l'en-tête de la liste des
        // personnages (`character_list_screen.dart::_ProfileButton`), qui
        // ouvrait auparavant un bottom sheet minimal réduit à "Se
        // déconnecter" — voir la doc de classe de `ProfileScreen`.
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/characters/:id',
        builder: (context, state) =>
            CharacterDetailScreen(characterId: state.pathParameters['id']!),
      ),
      GoRoute(
        // Flux "Montée de niveau" (increment 1) : poussée avec `?level=N`
        // (le niveau ciblé, `currentLevel + 1`) plutôt qu'un `extra` — pas
        // de précédent `extra` dans ce dépôt (voir `app_router.dart`), et un
        // paramètre de requête reste simple/inspectable pour un flux qui
        // n'a de toute façon pas vocation à être deep-linké.
        path: '/characters/:id/level-up',
        builder: (context, state) => LevelUpScreen(
          characterId: state.pathParameters['id']!,
          initialTargetLevel: int.parse(state.uri.queryParameters['level']!),
        ),
      ),
      GoRoute(
        // Flux "Rejoindre une histoire" (`features/join_story/`), 4 étapes
        // — voir `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
        // section 7.1. Étape 1/4 : saisie du code, jamais atteinte via le
        // deep link `nexus-jdr.app/join/{code}` (voir `/join/:code`
        // ci-dessous, qui pousse directement l'étape 2/4).
        path: '/join',
        builder: (context, state) =>
            JoinCodeStepScreen(initialCode: state.uri.queryParameters['code']),
      ),
      GoRoute(
        // Étape 2/4 : confirmation (nom + couverture de l'histoire), avant
        // tout engagement — `?code=...` plutôt qu'`extra`, même rationale
        // que `/characters/:id/level-up` (`?level=...`) : un code
        // d'invitation reste simple/inspectable, contrairement au contenu
        // XML entier de `/characters/import`, seule route de ce dépôt à
        // utiliser `extra` (voir sa documentation).
        path: '/join/step-2',
        builder: (context, state) => JoinConfirmationStepScreen(
          code: state.uri.queryParameters['code']!,
        ),
      ),
      GoRoute(
        // Étape 3/4 : choix du personnage à rattacher. `code` toujours
        // transmis en query, jamais reperdu entre les étapes (voir aussi
        // `JoinCharacterStepScreen._startCharacterCreation`, qui le
        // réinjecte dans la route de retour posée avant de lancer
        // l'assistant de création).
        path: '/join/step-3',
        builder: (context, state) =>
            JoinCharacterStepScreen(code: state.uri.queryParameters['code']!),
      ),
      GoRoute(
        // Point d'entrée du deep link universel
        // `nexus-jdr.app/join/{code}` (voir `docs/cahier-des-charges/
        // 04-fonctionnalites-app-mobile.md` section 7.1 : "l'étape 1/4 est
        // sautée entièrement, l'app pousse directement l'étape 2/4 avec le
        // code déjà résolu") : même écran que `/join/step-2`, [code] est
        // simplement résolu depuis le segment de chemin plutôt que depuis
        // une query. Câblage `go_router` interne uniquement — la
        // configuration native complète (association de domaine Android/
        // iOS, fichiers `.well-known`) reste à faire, voir le rapport de la
        // tâche qui a introduit cette route pour le détail de ce qui
        // manque côté configuration native/serveur.
        path: '/join/:code',
        builder: (context, state) =>
            JoinConfirmationStepScreen(code: state.pathParameters['code']!),
      ),
    ],
  );
}

/// Logique pure de redirection auth, extraite de [appRouter] pour rester
/// testable sans dépendre d'un [SupabaseClient] réel : non connecté → force
/// `/login` ; connecté sur `/login` → renvoie vers la destination
/// initialement visée (ou `/` à défaut).
///
/// **Reprise du parcours après connexion** (mécanisme générique, pas
/// spécifique au flux "Rejoindre une histoire", mais requis explicitement
/// par lui — `docs/cahier-des-charges/05-ux-navigation.md` : "si
/// l'utilisateur ouvre le lien alors qu'il n'est pas connecté, l'écran de
/// connexion s'affiche d'abord, puis reprend le parcours d'invitation là où
/// il s'était arrêté", pas une nuance optionnelle) : quand [location] n'est
/// pas déjà `/login` et que l'utilisateur n'est pas connecté, la
/// destination initialement visée (chemin **et** query, ex.
/// `/join/AB3F7K`) est encodée dans un paramètre `redirect` de l'URL de
/// connexion (`/login?redirect=%2Fjoin%2FAB3F7K`) plutôt que perdue. Une
/// fois connecté, `computeAuthRedirect` est réévalué (`GoRouter
/// .refreshListenable`, voir [appRouter]) pour la même location `/login?
/// redirect=...` — qui n'a pas changé entre-temps, [LoginScreen] ne navigue
/// jamais lui-même — et relit ce paramètre pour reprendre exactement là où
/// l'utilisateur s'était arrêté, au lieu de toujours atterrir sur `/`.
///
/// Cas particulier `location == '/'` : jamais encodé en `?redirect=...`
/// (repli silencieux sur `/login` nu, comme avant) — `/` est de toute façon
/// déjà la destination par défaut après connexion, un paramètre `redirect`
/// n'apporterait rien ici et polluerait inutilement l'URL du cas le plus
/// courant (premier lancement de l'app, non connecté).
String? computeAuthRedirect({
  required bool isLoggedIn,
  required String location,
}) {
  final uri = Uri.parse(location);
  final isOnLoginRoute = uri.path == '/login';

  if (!isLoggedIn) {
    if (isOnLoginRoute) return null;
    if (location == '/') return '/login';
    return Uri(
      path: '/login',
      queryParameters: {'redirect': location},
    ).toString();
  }
  if (isOnLoginRoute) {
    final redirectTarget = uri.queryParameters['redirect'];
    if (redirectTarget != null && redirectTarget.isNotEmpty) {
      return redirectTarget;
    }
    return '/';
  }
  return null;
}

/// Pont entre un [Stream] (ici `onAuthStateChange`) et l'interface
/// `Listenable` attendue par `GoRouter.refreshListenable`, pour redéclencher
/// l'évaluation de `redirect` à chaque connexion/déconnexion.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
