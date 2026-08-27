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
import '../network/supabase_client_provider.dart';

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
    redirect: (context, state) => computeAuthRedirect(
      isLoggedIn: client.auth.currentSession != null,
      matchedLocation: state.matchedLocation,
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
    ],
  );
}

/// Logique pure de redirection auth, extraite de [appRouter] pour rester
/// testable sans dépendre d'un [SupabaseClient] réel : non connecté → force
/// `/login` ; connecté sur `/login` → renvoie vers `/`.
String? computeAuthRedirect({
  required bool isLoggedIn,
  required String matchedLocation,
}) {
  final isOnLoginRoute = matchedLocation == '/login';

  if (!isLoggedIn) {
    return isOnLoginRoute ? null : '/login';
  }
  if (isOnLoginRoute) {
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
