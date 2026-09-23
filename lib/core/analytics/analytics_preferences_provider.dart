import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';

part 'analytics_preferences_provider.g.dart';

/// Instance partagée de `SharedPreferences` — `keepAlive`, résolue une seule
/// fois pour toute la session. Dupliquée depuis `features/app_update/
/// presentation/providers/update_banner_dismissal_provider.dart::sharedPreferencesProvider`
/// (aucun import cross-feature établi pour ce provider ailleurs dans ce
/// dépôt à ce jour) plutôt que réutilisée en import cross-feature — même
/// convention de duplication assumée que `character_creation/data/
/// race_row_mapper.dart` : `core/analytics/` ne doit pas coupler cette
/// fonctionnalité à `features/app_update/`.
@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) =>
    SharedPreferences.getInstance();

/// Disponibilité réelle des deux SDK d'analytics — voir la doc de classe
/// d'[AnalyticsAvailability] (`analytics_service.dart`) pour le rationale
/// complet : valeur par défaut [AnalyticsAvailability.none] tant
/// qu'`AppBootstrap` (`main.dart`) n'a pas surchargé ce provider dans le
/// `ProviderScope` imbriqué autour de `child`, une fois le bootstrap
/// (Supabase/PostHog/Firebase) résolu.
@Riverpod(keepAlive: true)
AnalyticsAvailability analyticsAvailability(Ref ref) =>
    AnalyticsAvailability.none;

/// [AnalyticsService] réellement branché aux SDK — lit
/// [analyticsAvailabilityProvider] pour savoir quels SDK sont effectivement
/// démarrés, plutôt qu'un état global mutable (voir la doc de classe
/// d'[AnalyticsAvailability]).
///
/// `keepAlive`, normalement lu pour la première fois depuis l'intérieur du
/// `ProviderScope` imbriqué construit par `AppBootstrap` (`main.dart`) une
/// fois le bootstrap résolu — [analyticsAvailabilityProvider] y est déjà
/// surchargé avec la valeur réelle à ce moment. Si jamais lu avant cette
/// surcharge (ex. test qui ne passe pas par ce mécanisme),
/// [analyticsAvailabilityProvider] retombe sur
/// [AnalyticsAvailability.none] et [CompositeAnalyticsService.isInitialized]
/// renvoie `false` — équivalent fonctionnel de [NoopAnalyticsService] dans ce
/// cas.
@Riverpod(keepAlive: true)
AnalyticsService analyticsService(Ref ref) {
  final availability = ref.watch(analyticsAvailabilityProvider);
  return CompositeAnalyticsService(
    firebaseAvailable: availability.firebaseAnalyticsReady,
    postHogAvailable: availability.postHogReady,
  );
}

/// Préférence locale "Partager mes données d'usage" (écran "Confidentialité",
/// `features/profile/presentation/profile_privacy_screen.dart`) — décision
/// chef de projet (RGPD) : activée par défaut, désactivable à tout moment,
/// stockage `SharedPreferences` uniquement (aucune table Supabase, l'analytics
/// est de toute façon par appareil).
@Riverpod(keepAlive: true)
class AnalyticsPreferencesController extends _$AnalyticsPreferencesController {
  @override
  bool build() {
    // `.value` (getter nullable de `AsyncValue`), pas `await` (`build`
    // synchrone) : si `sharedPreferencesProvider` n'a pas encore résolu (très
    // bref, stockage local), ce provider retombe momentanément sur `true`
    // (activé par défaut) puis se reconstruit automatiquement dès que
    // `sharedPreferencesProvider` résout (`ref.watch`) — même mécanisme que
    // `UpdateBannerDismissalController.build`
    // (`features/app_update/presentation/providers/update_banner_dismissal_provider.dart`).
    final preferences = ref.watch(sharedPreferencesProvider).value;
    return preferences?.getBool(analyticsEnabledPrefsKey) ?? true;
  }

  /// Bascule la préférence — reflétée immédiatement dans [state] (jamais en
  /// attente de l'écriture disque ni de l'appel SDK), puis persistée via
  /// `SharedPreferences` et répercutée sur les SDK sous-jacents
  /// ([AnalyticsService.setEnabled], jamais un simple guard côté Dart).
  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final preferences = await ref.read(sharedPreferencesProvider.future);
    await preferences.setBool(analyticsEnabledPrefsKey, enabled);
    await ref.read(analyticsServiceProvider).setEnabled(enabled);
  }
}
