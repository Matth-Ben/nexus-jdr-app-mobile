// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Instance partagée de `SharedPreferences` — `keepAlive`, résolue une seule
/// fois pour toute la session. Dupliquée depuis `features/app_update/
/// presentation/providers/update_banner_dismissal_provider.dart::sharedPreferencesProvider`
/// (aucun import cross-feature établi pour ce provider ailleurs dans ce
/// dépôt à ce jour) plutôt que réutilisée en import cross-feature — même
/// convention de duplication assumée que `character_creation/data/
/// race_row_mapper.dart` : `core/analytics/` ne doit pas coupler cette
/// fonctionnalité à `features/app_update/`.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Instance partagée de `SharedPreferences` — `keepAlive`, résolue une seule
/// fois pour toute la session. Dupliquée depuis `features/app_update/
/// presentation/providers/update_banner_dismissal_provider.dart::sharedPreferencesProvider`
/// (aucun import cross-feature établi pour ce provider ailleurs dans ce
/// dépôt à ce jour) plutôt que réutilisée en import cross-feature — même
/// convention de duplication assumée que `character_creation/data/
/// race_row_mapper.dart` : `core/analytics/` ne doit pas coupler cette
/// fonctionnalité à `features/app_update/`.

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<SharedPreferences>,
          SharedPreferences,
          FutureOr<SharedPreferences>
        >
    with
        $FutureModifier<SharedPreferences>,
        $FutureProvider<SharedPreferences> {
  /// Instance partagée de `SharedPreferences` — `keepAlive`, résolue une seule
  /// fois pour toute la session. Dupliquée depuis `features/app_update/
  /// presentation/providers/update_banner_dismissal_provider.dart::sharedPreferencesProvider`
  /// (aucun import cross-feature établi pour ce provider ailleurs dans ce
  /// dépôt à ce jour) plutôt que réutilisée en import cross-feature — même
  /// convention de duplication assumée que `character_creation/data/
  /// race_row_mapper.dart` : `core/analytics/` ne doit pas coupler cette
  /// fonctionnalité à `features/app_update/`.
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $FutureProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SharedPreferences> create(Ref ref) {
    return sharedPreferences(ref);
  }
}

String _$sharedPreferencesHash() => r'ad13470fe866595ad0f58a3e26f11048d94ef22e';

/// Disponibilité réelle des deux SDK d'analytics — voir la doc de classe
/// d'[AnalyticsAvailability] (`analytics_service.dart`) pour le rationale
/// complet : valeur par défaut [AnalyticsAvailability.none] tant
/// qu'`AppBootstrap` (`main.dart`) n'a pas surchargé ce provider dans le
/// `ProviderScope` imbriqué autour de `child`, une fois le bootstrap
/// (Supabase/PostHog/Firebase) résolu.

@ProviderFor(analyticsAvailability)
final analyticsAvailabilityProvider = AnalyticsAvailabilityProvider._();

/// Disponibilité réelle des deux SDK d'analytics — voir la doc de classe
/// d'[AnalyticsAvailability] (`analytics_service.dart`) pour le rationale
/// complet : valeur par défaut [AnalyticsAvailability.none] tant
/// qu'`AppBootstrap` (`main.dart`) n'a pas surchargé ce provider dans le
/// `ProviderScope` imbriqué autour de `child`, une fois le bootstrap
/// (Supabase/PostHog/Firebase) résolu.

final class AnalyticsAvailabilityProvider
    extends
        $FunctionalProvider<
          AnalyticsAvailability,
          AnalyticsAvailability,
          AnalyticsAvailability
        >
    with $Provider<AnalyticsAvailability> {
  /// Disponibilité réelle des deux SDK d'analytics — voir la doc de classe
  /// d'[AnalyticsAvailability] (`analytics_service.dart`) pour le rationale
  /// complet : valeur par défaut [AnalyticsAvailability.none] tant
  /// qu'`AppBootstrap` (`main.dart`) n'a pas surchargé ce provider dans le
  /// `ProviderScope` imbriqué autour de `child`, une fois le bootstrap
  /// (Supabase/PostHog/Firebase) résolu.
  AnalyticsAvailabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsAvailabilityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsAvailabilityHash();

  @$internal
  @override
  $ProviderElement<AnalyticsAvailability> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AnalyticsAvailability create(Ref ref) {
    return analyticsAvailability(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyticsAvailability value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyticsAvailability>(value),
    );
  }
}

String _$analyticsAvailabilityHash() =>
    r'f93c2f94eb8e36aa153cb11aa2e57e254b463f08';

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

@ProviderFor(analyticsService)
final analyticsServiceProvider = AnalyticsServiceProvider._();

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

final class AnalyticsServiceProvider
    extends
        $FunctionalProvider<
          AnalyticsService,
          AnalyticsService,
          AnalyticsService
        >
    with $Provider<AnalyticsService> {
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
  AnalyticsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsServiceHash();

  @$internal
  @override
  $ProviderElement<AnalyticsService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AnalyticsService create(Ref ref) {
    return analyticsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyticsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyticsService>(value),
    );
  }
}

String _$analyticsServiceHash() => r'6994a06e2408f0d4dd8b01448adcfe94fbccba92';

/// Préférence locale "Partager mes données d'usage" (écran "Confidentialité",
/// `features/profile/presentation/profile_privacy_screen.dart`) — décision
/// chef de projet (RGPD) : activée par défaut, désactivable à tout moment,
/// stockage `SharedPreferences` uniquement (aucune table Supabase, l'analytics
/// est de toute façon par appareil).

@ProviderFor(AnalyticsPreferencesController)
final analyticsPreferencesControllerProvider =
    AnalyticsPreferencesControllerProvider._();

/// Préférence locale "Partager mes données d'usage" (écran "Confidentialité",
/// `features/profile/presentation/profile_privacy_screen.dart`) — décision
/// chef de projet (RGPD) : activée par défaut, désactivable à tout moment,
/// stockage `SharedPreferences` uniquement (aucune table Supabase, l'analytics
/// est de toute façon par appareil).
final class AnalyticsPreferencesControllerProvider
    extends $NotifierProvider<AnalyticsPreferencesController, bool> {
  /// Préférence locale "Partager mes données d'usage" (écran "Confidentialité",
  /// `features/profile/presentation/profile_privacy_screen.dart`) — décision
  /// chef de projet (RGPD) : activée par défaut, désactivable à tout moment,
  /// stockage `SharedPreferences` uniquement (aucune table Supabase, l'analytics
  /// est de toute façon par appareil).
  AnalyticsPreferencesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsPreferencesControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsPreferencesControllerHash();

  @$internal
  @override
  AnalyticsPreferencesController create() => AnalyticsPreferencesController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$analyticsPreferencesControllerHash() =>
    r'248b286810ddcbcbde34b288077adae84ac5a83d';

/// Préférence locale "Partager mes données d'usage" (écran "Confidentialité",
/// `features/profile/presentation/profile_privacy_screen.dart`) — décision
/// chef de projet (RGPD) : activée par défaut, désactivable à tout moment,
/// stockage `SharedPreferences` uniquement (aucune table Supabase, l'analytics
/// est de toute façon par appareil).

abstract class _$AnalyticsPreferencesController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
