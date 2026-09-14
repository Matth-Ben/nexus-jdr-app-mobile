// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_banner_dismissal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Instance partagée de `SharedPreferences` — `keepAlive`, résolue une seule
/// fois pour toute la session (même rationale que `packageInfoProvider`).

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

/// Instance partagée de `SharedPreferences` — `keepAlive`, résolue une seule
/// fois pour toute la session (même rationale que `packageInfoProvider`).

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
  /// fois pour toute la session (même rationale que `packageInfoProvider`).
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

/// Persiste, sous forme d'une simple chaîne `SharedPreferences` (stockage
/// local à l'appareil, jamais synchronisé), la dernière valeur de
/// `AppVersionCheckResult.latestVersion` pour laquelle la bannière "Mise à
/// jour suggérée" (`widgets/update_suggested_banner.dart`) a été refermée
/// par le joueur.
///
/// **Pourquoi par version plutôt qu'un simple booléen "refermée"** : si une
/// NOUVELLE version sort après la fermeture (`latestVersion` change), la
/// comparaison `state == result.latestVersion` échoue et la bannière
/// réapparaît normalement pour cette nouvelle version — spec explicite de la
/// tâche ("si une NOUVELLE version sort, la bannière doit pouvoir
/// réapparaître même si l'ancienne avait été fermée").

@ProviderFor(UpdateBannerDismissalController)
final updateBannerDismissalControllerProvider =
    UpdateBannerDismissalControllerProvider._();

/// Persiste, sous forme d'une simple chaîne `SharedPreferences` (stockage
/// local à l'appareil, jamais synchronisé), la dernière valeur de
/// `AppVersionCheckResult.latestVersion` pour laquelle la bannière "Mise à
/// jour suggérée" (`widgets/update_suggested_banner.dart`) a été refermée
/// par le joueur.
///
/// **Pourquoi par version plutôt qu'un simple booléen "refermée"** : si une
/// NOUVELLE version sort après la fermeture (`latestVersion` change), la
/// comparaison `state == result.latestVersion` échoue et la bannière
/// réapparaît normalement pour cette nouvelle version — spec explicite de la
/// tâche ("si une NOUVELLE version sort, la bannière doit pouvoir
/// réapparaître même si l'ancienne avait été fermée").
final class UpdateBannerDismissalControllerProvider
    extends $NotifierProvider<UpdateBannerDismissalController, String?> {
  /// Persiste, sous forme d'une simple chaîne `SharedPreferences` (stockage
  /// local à l'appareil, jamais synchronisé), la dernière valeur de
  /// `AppVersionCheckResult.latestVersion` pour laquelle la bannière "Mise à
  /// jour suggérée" (`widgets/update_suggested_banner.dart`) a été refermée
  /// par le joueur.
  ///
  /// **Pourquoi par version plutôt qu'un simple booléen "refermée"** : si une
  /// NOUVELLE version sort après la fermeture (`latestVersion` change), la
  /// comparaison `state == result.latestVersion` échoue et la bannière
  /// réapparaît normalement pour cette nouvelle version — spec explicite de la
  /// tâche ("si une NOUVELLE version sort, la bannière doit pouvoir
  /// réapparaître même si l'ancienne avait été fermée").
  UpdateBannerDismissalControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateBannerDismissalControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateBannerDismissalControllerHash();

  @$internal
  @override
  UpdateBannerDismissalController create() => UpdateBannerDismissalController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$updateBannerDismissalControllerHash() =>
    r'3e64fb9039d4a82668c3800253d2b190b3e7c60a';

/// Persiste, sous forme d'une simple chaîne `SharedPreferences` (stockage
/// local à l'appareil, jamais synchronisé), la dernière valeur de
/// `AppVersionCheckResult.latestVersion` pour laquelle la bannière "Mise à
/// jour suggérée" (`widgets/update_suggested_banner.dart`) a été refermée
/// par le joueur.
///
/// **Pourquoi par version plutôt qu'un simple booléen "refermée"** : si une
/// NOUVELLE version sort après la fermeture (`latestVersion` change), la
/// comparaison `state == result.latestVersion` échoue et la bannière
/// réapparaît normalement pour cette nouvelle version — spec explicite de la
/// tâche ("si une NOUVELLE version sort, la bannière doit pouvoir
/// réapparaître même si l'ancienne avait été fermée").

abstract class _$UpdateBannerDismissalController extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
