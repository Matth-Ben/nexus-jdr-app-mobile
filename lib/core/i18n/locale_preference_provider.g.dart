// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_preference_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Instance partagée de `SharedPreferences` — `keepAlive`, résolue une seule
/// fois pour toute la session. Dupliquée depuis
/// `core/analytics/analytics_preferences_provider.dart::sharedPreferencesProvider`
/// (aucun import cross-feature établi pour ce provider ailleurs dans ce
/// dépôt à ce jour, voir aussi `features/app_update/presentation/providers/
/// update_banner_dismissal_provider.dart::sharedPreferencesProvider`) plutôt
/// que réutilisée en import cross-feature — même convention de duplication
/// assumée que ces deux providers.

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Instance partagée de `SharedPreferences` — `keepAlive`, résolue une seule
/// fois pour toute la session. Dupliquée depuis
/// `core/analytics/analytics_preferences_provider.dart::sharedPreferencesProvider`
/// (aucun import cross-feature établi pour ce provider ailleurs dans ce
/// dépôt à ce jour, voir aussi `features/app_update/presentation/providers/
/// update_banner_dismissal_provider.dart::sharedPreferencesProvider`) plutôt
/// que réutilisée en import cross-feature — même convention de duplication
/// assumée que ces deux providers.

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
  /// fois pour toute la session. Dupliquée depuis
  /// `core/analytics/analytics_preferences_provider.dart::sharedPreferencesProvider`
  /// (aucun import cross-feature établi pour ce provider ailleurs dans ce
  /// dépôt à ce jour, voir aussi `features/app_update/presentation/providers/
  /// update_banner_dismissal_provider.dart::sharedPreferencesProvider`) plutôt
  /// que réutilisée en import cross-feature — même convention de duplication
  /// assumée que ces deux providers.
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

/// Préférence locale de langue forcée (écran "Langue", poussé depuis la
/// tuile "Langue" de l'écran Profil) — chantier "traduction de l'app" Phase
/// A : décision direction-artistique, stockage local uniquement (aucune
/// table Supabase), même précédent que
/// `AnalyticsPreferencesController`/`UpdateBannerDismissalController`.
///
/// État = [Locale]`?` : `null` signifie "suit la langue du téléphone" (valeur
/// par défaut, aucune clé écrite en `SharedPreferences` tant que
/// l'utilisateur n'a rien choisi explicitement) — câblé tel quel sur
/// `MaterialApp.router(locale: ...)` dans `main.dart::NexusJdrApp`, où
/// `null` laisse Flutter résoudre automatiquement la langue selon
/// l'appareil. Une valeur explicite (`Locale('fr')`/`Locale('en')`) force
/// cette langue indépendamment du téléphone.

@ProviderFor(LocalePreferenceController)
final localePreferenceControllerProvider =
    LocalePreferenceControllerProvider._();

/// Préférence locale de langue forcée (écran "Langue", poussé depuis la
/// tuile "Langue" de l'écran Profil) — chantier "traduction de l'app" Phase
/// A : décision direction-artistique, stockage local uniquement (aucune
/// table Supabase), même précédent que
/// `AnalyticsPreferencesController`/`UpdateBannerDismissalController`.
///
/// État = [Locale]`?` : `null` signifie "suit la langue du téléphone" (valeur
/// par défaut, aucune clé écrite en `SharedPreferences` tant que
/// l'utilisateur n'a rien choisi explicitement) — câblé tel quel sur
/// `MaterialApp.router(locale: ...)` dans `main.dart::NexusJdrApp`, où
/// `null` laisse Flutter résoudre automatiquement la langue selon
/// l'appareil. Une valeur explicite (`Locale('fr')`/`Locale('en')`) force
/// cette langue indépendamment du téléphone.
final class LocalePreferenceControllerProvider
    extends $NotifierProvider<LocalePreferenceController, Locale?> {
  /// Préférence locale de langue forcée (écran "Langue", poussé depuis la
  /// tuile "Langue" de l'écran Profil) — chantier "traduction de l'app" Phase
  /// A : décision direction-artistique, stockage local uniquement (aucune
  /// table Supabase), même précédent que
  /// `AnalyticsPreferencesController`/`UpdateBannerDismissalController`.
  ///
  /// État = [Locale]`?` : `null` signifie "suit la langue du téléphone" (valeur
  /// par défaut, aucune clé écrite en `SharedPreferences` tant que
  /// l'utilisateur n'a rien choisi explicitement) — câblé tel quel sur
  /// `MaterialApp.router(locale: ...)` dans `main.dart::NexusJdrApp`, où
  /// `null` laisse Flutter résoudre automatiquement la langue selon
  /// l'appareil. Une valeur explicite (`Locale('fr')`/`Locale('en')`) force
  /// cette langue indépendamment du téléphone.
  LocalePreferenceControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localePreferenceControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localePreferenceControllerHash();

  @$internal
  @override
  LocalePreferenceController create() => LocalePreferenceController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale?>(value),
    );
  }
}

String _$localePreferenceControllerHash() =>
    r'be22d05d7b073de67160e4e65d592ed56b99d9c0';

/// Préférence locale de langue forcée (écran "Langue", poussé depuis la
/// tuile "Langue" de l'écran Profil) — chantier "traduction de l'app" Phase
/// A : décision direction-artistique, stockage local uniquement (aucune
/// table Supabase), même précédent que
/// `AnalyticsPreferencesController`/`UpdateBannerDismissalController`.
///
/// État = [Locale]`?` : `null` signifie "suit la langue du téléphone" (valeur
/// par défaut, aucune clé écrite en `SharedPreferences` tant que
/// l'utilisateur n'a rien choisi explicitement) — câblé tel quel sur
/// `MaterialApp.router(locale: ...)` dans `main.dart::NexusJdrApp`, où
/// `null` laisse Flutter résoudre automatiquement la langue selon
/// l'appareil. Une valeur explicite (`Locale('fr')`/`Locale('en')`) force
/// cette langue indépendamment du téléphone.

abstract class _$LocalePreferenceController extends $Notifier<Locale?> {
  Locale? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Locale?, Locale?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Locale?, Locale?>,
              Locale?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
