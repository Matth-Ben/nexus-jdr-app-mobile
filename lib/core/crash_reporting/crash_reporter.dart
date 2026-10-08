import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Remontée non-fatale vers Crashlytics (dette D13,
/// `docs/dette-technique.md`) pour une sélection d'exceptions **inattendues**
/// avalées par un `catch (_)` dans les dépôts d'écriture
/// (`features/*/data/`) — jamais pour un repli réseau/hors-ligne déjà
/// documenté comme intentionnellement silencieux (ex. `_cleanupPartialCharacter`
/// de `character_creation_repository.dart`), seulement là où un bug
/// silencieux pourrait corrompre des données.
///
/// Jamais d'appel direct à `FirebaseCrashlytics.instance` depuis un dépôt :
/// cette passerelle avale elle-même toute erreur de la remontée (Crashlytics
/// non initialisé — toujours le cas en test, et sur toute plateforme autre
/// qu'Android pour l'instant, voir `main.dart::_initializeSupabaseAndFirebase`)
/// pour ne jamais faire planter le code appelant avec une erreur de
/// *journalisation* alors qu'il est déjà en train de gérer l'erreur
/// d'origine — même philosophie de résilience que
/// `CompositeAnalyticsService._guard` (`core/analytics/analytics_service.dart`).
///
/// Jamais `await`é par l'appelant (délibérément fire-and-forget, cohérent
/// avec "journalisation secondaire, jamais bloquante") : le `catchError`
/// ci-dessous absorbe aussi bien un échec synchrone (accès à
/// `FirebaseCrashlytics.instance` sans app Firebase) qu'un rejet asynchrone
/// du `Future` renvoyé par `recordError`.
void reportNonFatal(Object error, StackTrace stackTrace, {String? reason}) {
  Future<void>(
    () => FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    ),
  ).catchError((_) {});
}
