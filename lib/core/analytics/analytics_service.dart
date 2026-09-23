import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Passerelle vers les deux SDK d'analytics produit installés dans ce dépôt
/// (Firebase Analytics + PostHog, `lib/core/analytics/`) — abstraction
/// (plutôt qu'un accès direct aux singletons de chaque package) pour
/// permettre aux tests de fournir un double sans jamais toucher à un canal
/// de plateforme réel, même principe que `CharacterRepository`
/// (`features/characters/data/character_repository.dart`)/
/// `PushNotificationGateway` (`core/notifications/push_notification_gateway.dart`).
///
/// Décision produit (chef de projet, RGPD) : bascule "Partager mes données
/// d'usage" activée par défaut, désactivable à tout moment depuis l'écran
/// "Confidentialité" (`features/profile/presentation/profile_privacy_screen.dart`)
/// — voir `analytics_preferences_provider.dart`. Aucun `identify()`/aucune
/// association à un identifiant utilisateur Supabase pour l'un ou l'autre
/// SDK dans cette itération (reste anonyme/pseudonyme via les identifiants
/// générés par chaque SDK) — décision différée, sensibilité RGPD plus
/// élevée.
abstract class AnalyticsService {
  /// `true` une fois au moins un des deux SDK sous-jacents effectivement
  /// initialisé (peut être partiel : ex. PostHog seul si Firebase non
  /// disponible sur cette plateforme, voir `main.dart`) — permet à
  /// l'appelant de savoir si [trackEvent]/[trackScreen] auront un effet réel.
  bool get isInitialized;

  /// Envoie un événement nommé [name] aux SDK disponibles, avec [parameters]
  /// optionnels. No-op silencieux (jamais d'exception) si aucun SDK n'est
  /// disponible.
  Future<void> trackEvent(String name, {Map<String, Object?> parameters});

  /// Envoie un événement d'affichage d'écran [screenName] aux SDK
  /// disponibles. No-op silencieux si aucun SDK n'est disponible.
  Future<void> trackScreen(String screenName);

  /// Active/désactive l'envoi effectif côté SDK (pas juste un guard côté
  /// Dart) — reflète la préférence utilisateur persistée par
  /// `AnalyticsPreferencesController`. No-op silencieux si aucun SDK n'est
  /// disponible.
  Future<void> setEnabled(bool enabled);
}

/// Implémentation réelle : enveloppe `FirebaseAnalytics.instance` (Android
/// uniquement pour l'instant, voir `main.dart::_initializeSupabaseAndFirebase`)
/// et le singleton `Posthog()` du package `posthog_flutter` (toutes
/// plateformes cibles dès que `EnvConfig.isPostHogConfigured`).
///
/// [firebaseAvailable]/[postHogAvailable] sont reçus au constructeur plutôt
/// que déduits ici d'une plateforme/config globale, pour rester testable
/// sans dépendre d'un vrai `Firebase.initializeApp`/`Posthog().setup` —
/// [firebaseAnalytics] permet en plus d'injecter un double de
/// `FirebaseAnalytics` dans les tests.
///
/// Chaque méthode publique est un no-op silencieux (jamais d'exception) si
/// le SDK correspondant n'est pas disponible, et toute exception levée par
/// un SDK sous-jacent est interceptée et journalisée via
/// `FlutterError.reportError` — même philosophie de résilience que
/// `main.dart::_initializeSupabaseAndFirebase` : un échec d'un SDK
/// d'analytics secondaire ne doit jamais faire planter l'app ni bloquer une
/// action utilisateur.
class CompositeAnalyticsService implements AnalyticsService {
  const CompositeAnalyticsService({
    required this.firebaseAvailable,
    required this.postHogAvailable,
    FirebaseAnalytics? firebaseAnalytics,
  }) : _firebaseAnalyticsOverride = firebaseAnalytics;

  final bool firebaseAvailable;
  final bool postHogAvailable;

  /// Double de `FirebaseAnalytics` injecté en test — sinon
  /// `FirebaseAnalytics.instance` est résolu paresseusement (jamais dans le
  /// constructeur), et uniquement quand [firebaseAvailable] est vrai : cette
  /// résolution suppose `Firebase.initializeApp` déjà réussi.
  final FirebaseAnalytics? _firebaseAnalyticsOverride;

  FirebaseAnalytics get _firebaseAnalytics =>
      _firebaseAnalyticsOverride ?? FirebaseAnalytics.instance;

  @override
  bool get isInitialized => firebaseAvailable || postHogAvailable;

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    final sanitized = _sanitize(parameters);
    if (firebaseAvailable) {
      await _guard(
        () => _firebaseAnalytics.logEvent(
          name: name,
          parameters: sanitized.isEmpty ? null : sanitized,
        ),
      );
    }
    if (postHogAvailable) {
      await _guard(
        () => Posthog().capture(
          eventName: name,
          properties: sanitized.isEmpty ? null : sanitized,
        ),
      );
    }
  }

  @override
  Future<void> trackScreen(String screenName) async {
    if (firebaseAvailable) {
      await _guard(
        () => _firebaseAnalytics.logScreenView(screenName: screenName),
      );
    }
    if (postHogAvailable) {
      await _guard(() => Posthog().screen(screenName: screenName));
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (firebaseAvailable) {
      await _guard(
        () => _firebaseAnalytics.setAnalyticsCollectionEnabled(enabled),
      );
    }
    if (postHogAvailable) {
      await _guard(() => enabled ? Posthog().enable() : Posthog().disable());
    }
  }

  /// Filtre les entrées `null` de [parameters] : `Map<String, Object>` est
  /// attendu par les deux SDK sous-jacents (`FirebaseAnalytics.logEvent`/
  /// `Posthog().capture`), contrairement à l'interface [AnalyticsService]
  /// qui accepte des valeurs nullables par confort d'appel.
  Map<String, Object> _sanitize(Map<String, Object?> parameters) {
    final sanitized = <String, Object>{};
    for (final entry in parameters.entries) {
      final value = entry.value;
      if (value != null) sanitized[entry.key] = value;
    }
    return sanitized;
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'nexus_jdr analytics',
          context: ErrorDescription("lors d'un appel analytics"),
        ),
      );
    }
  }
}

/// Clé `SharedPreferences` de la préférence locale "Partager mes données
/// d'usage" — partagée entre `main.dart` (application immédiate au démarrage
/// de la valeur déjà persistée, avant que l'arbre de widgets/Riverpod ne
/// soit monté) et `AnalyticsPreferencesController`
/// (`analytics_preferences_provider.dart`), pour ne jamais dupliquer ce
/// littéral.
const String analyticsEnabledPrefsKey = 'analytics_enabled';

/// Disponibilité effective des deux SDK d'analytics (Firebase Analytics /
/// PostHog) une fois `main.dart::_initializeSupabaseAndFirebase` résolu —
/// valeur immuable, exposée via `analyticsAvailabilityProvider`
/// (`analytics_preferences_provider.dart`) plutôt que comme état global
/// mutable : `main()` ne peut faire aucun travail asynchrone avant `runApp`
/// dans ce dépôt (voir la doc de classe d'`AppBootstrap`, `main.dart`), donc
/// un override de `ProviderScope` "à la racine" au sens littéral n'est pas
/// possible avant que ce résultat soit connu — `AppBootstrap` insère donc,
/// une fois `initialize()` résolu avec succès, un `ProviderScope`
/// **imbriqué** autour de `child` qui surcharge `analyticsAvailabilityProvider`
/// avec la valeur réelle.
///
/// Contrairement à ce qu'un ancien commentaire ici laissait entendre, ce
/// n'est PAS le même principe que `core/network/supabase_client_provider.dart
/// ::supabaseClientProvider` : celui-ci lit `Supabase.instance.client`, un
/// singleton **géré par le package `supabase_flutter` lui-même** (champ
/// `late`, échec bruyant — `LateInitializationError` — en cas de mauvais
/// usage), pas un état applicatif bricolé comme l'était l'ancienne version de
/// cette classe (deux `static bool` mutables, jamais réinitialisés entre
/// tests, sans distinction entre "pas encore renseigné" et "explicitement
/// indisponible").
///
/// `analyticsServiceProvider` (`analytics_preferences_provider.dart`) lit
/// cette valeur via `ref.watch(analyticsAvailabilityProvider)` pour
/// construire le [CompositeAnalyticsService] réellement branché aux SDK ;
/// `core/router/app_router.dart` fait de même pour ne poser un observateur
/// de navigation que pour un SDK réellement démarré.
class AnalyticsAvailability {
  const AnalyticsAvailability({
    required this.firebaseAnalyticsReady,
    required this.postHogReady,
  });

  /// Valeur par défaut avant toute surcharge de
  /// `analyticsAvailabilityProvider` — ne devrait normalement jamais être
  /// observée en usage réel (`AppBootstrap` surcharge toujours ce provider
  /// avant de construire `child`), seulement dans un test qui lit
  /// `analyticsServiceProvider`/`analyticsAvailabilityProvider` sans passer
  /// par ce mécanisme.
  static const none = AnalyticsAvailability(
    firebaseAnalyticsReady: false,
    postHogReady: false,
  );

  final bool firebaseAnalyticsReady;
  final bool postHogReady;
}

/// Implémentation "rien n'est configuré" — tous les appels sont des no-op
/// silencieux, [isInitialized] renvoie toujours `false`. Utilisée comme
/// valeur par défaut du provider Riverpod (`analytics_preferences_provider.dart`)
/// avant que `main.dart` n'expose la vraie instance construite au démarrage,
/// et dans les tests qui n'ont pas besoin d'observer les appels envoyés
/// (sinon voir `FakeAnalyticsService`, `test/core/analytics/`).
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  bool get isInitialized => false;

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {}

  @override
  Future<void> trackScreen(String screenName) async {}

  @override
  Future<void> setEnabled(bool enabled) async {}
}
