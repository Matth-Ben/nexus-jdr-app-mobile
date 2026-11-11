// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_version_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appVersionRepository)
final appVersionRepositoryProvider = AppVersionRepositoryProvider._();

final class AppVersionRepositoryProvider
    extends
        $FunctionalProvider<
          AppVersionRepository,
          AppVersionRepository,
          AppVersionRepository
        >
    with $Provider<AppVersionRepository> {
  AppVersionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionRepositoryHash();

  @$internal
  @override
  $ProviderElement<AppVersionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppVersionRepository create(Ref ref) {
    return appVersionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppVersionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppVersionRepository>(value),
    );
  }
}

String _$appVersionRepositoryHash() =>
    r'4a9f6b9335eac38ed64b775d521e8de4a9eb9c1b';

/// Délais des relances automatiques de la vérification de version tant qu'elle
/// n'a pas obtenu de vraie réponse du serveur (une relance par délai, puis
/// plus aucune relance temporelle : seul le retour du réseau en relance
/// ensuite). Surchargeable en test.

@ProviderFor(appVersionRetryBackoff)
final appVersionRetryBackoffProvider = AppVersionRetryBackoffProvider._();

/// Délais des relances automatiques de la vérification de version tant qu'elle
/// n'a pas obtenu de vraie réponse du serveur (une relance par délai, puis
/// plus aucune relance temporelle : seul le retour du réseau en relance
/// ensuite). Surchargeable en test.

final class AppVersionRetryBackoffProvider
    extends $FunctionalProvider<List<Duration>, List<Duration>, List<Duration>>
    with $Provider<List<Duration>> {
  /// Délais des relances automatiques de la vérification de version tant qu'elle
  /// n'a pas obtenu de vraie réponse du serveur (une relance par délai, puis
  /// plus aucune relance temporelle : seul le retour du réseau en relance
  /// ensuite). Surchargeable en test.
  AppVersionRetryBackoffProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionRetryBackoffProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionRetryBackoffHash();

  @$internal
  @override
  $ProviderElement<List<Duration>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Duration> create(Ref ref) {
    return appVersionRetryBackoff(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Duration> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Duration>>(value),
    );
  }
}

String _$appVersionRetryBackoffHash() =>
    r'c6f4a394f1d16ccafaf305fadbb73bf4ae1cf587';

/// Vérification de version partagée — **seul point de lecture** consommé à
/// la fois par `main.dart::AppBootstrap` (écran bloquant
/// `force_update_screen.dart`) et par `character_list_screen.dart`
/// (bannière `widgets/update_suggested_banner.dart`), voir la documentation
/// de `AppVersionStatus`.
///
/// `keepAlive` : lu depuis 2 endroits distincts sur toute la durée de vie de
/// l'app (démarrage, puis liste de personnages tant que celle-ci reste
/// affichée).
///
/// **Ne bloque jamais l'utilisateur en cas d'échec réseau** (spec de la
/// tâche, cohérent avec `05-ux-navigation.md` sur l'initialisation) : toute
/// exception (pas de connexion, RLS, ligne absente...) est interceptée ici
/// et retombe sur `AppVersionStatus.upToDate` avec la version installée
/// recopiée dans les 3 champs — un statut "neutre" indiscernable d'un
/// "vraiment à jour" pour les deux consommateurs, qui n'affichent jamais
/// rien pour ce statut. Une requête sans réponse après
/// [appVersionCheckTimeout] est traitée de la même façon : cette vérification
/// ne retarde jamais le premier écran au-delà de ce délai.
///
/// **Relance en arrière-plan** : tant que le dernier résultat est un repli
/// (timeout ou erreur) et non une vraie réponse du serveur, la vérification
/// est relancée (a) après chaque délai de [appVersionRetryBackoff] (une
/// relance à la fois, nombre fini), (b) à chaque
/// `ConnectivityChecker.onConnectivityRestored`. Dès qu'une vraie réponse
/// arrive, l'état est mis à jour (`AppBootstrap` bascule alors sur
/// `ForceUpdateScreen` si « mise à jour obligatoire », la bannière apparaît si
/// « suggérée ») et toute relance s'arrête. Minuteur et abonnement sont
/// annulés à la libération du provider.

@ProviderFor(AppVersionCheck)
final appVersionCheckProvider = AppVersionCheckProvider._();

/// Vérification de version partagée — **seul point de lecture** consommé à
/// la fois par `main.dart::AppBootstrap` (écran bloquant
/// `force_update_screen.dart`) et par `character_list_screen.dart`
/// (bannière `widgets/update_suggested_banner.dart`), voir la documentation
/// de `AppVersionStatus`.
///
/// `keepAlive` : lu depuis 2 endroits distincts sur toute la durée de vie de
/// l'app (démarrage, puis liste de personnages tant que celle-ci reste
/// affichée).
///
/// **Ne bloque jamais l'utilisateur en cas d'échec réseau** (spec de la
/// tâche, cohérent avec `05-ux-navigation.md` sur l'initialisation) : toute
/// exception (pas de connexion, RLS, ligne absente...) est interceptée ici
/// et retombe sur `AppVersionStatus.upToDate` avec la version installée
/// recopiée dans les 3 champs — un statut "neutre" indiscernable d'un
/// "vraiment à jour" pour les deux consommateurs, qui n'affichent jamais
/// rien pour ce statut. Une requête sans réponse après
/// [appVersionCheckTimeout] est traitée de la même façon : cette vérification
/// ne retarde jamais le premier écran au-delà de ce délai.
///
/// **Relance en arrière-plan** : tant que le dernier résultat est un repli
/// (timeout ou erreur) et non une vraie réponse du serveur, la vérification
/// est relancée (a) après chaque délai de [appVersionRetryBackoff] (une
/// relance à la fois, nombre fini), (b) à chaque
/// `ConnectivityChecker.onConnectivityRestored`. Dès qu'une vraie réponse
/// arrive, l'état est mis à jour (`AppBootstrap` bascule alors sur
/// `ForceUpdateScreen` si « mise à jour obligatoire », la bannière apparaît si
/// « suggérée ») et toute relance s'arrête. Minuteur et abonnement sont
/// annulés à la libération du provider.
final class AppVersionCheckProvider
    extends $AsyncNotifierProvider<AppVersionCheck, AppVersionCheckResult> {
  /// Vérification de version partagée — **seul point de lecture** consommé à
  /// la fois par `main.dart::AppBootstrap` (écran bloquant
  /// `force_update_screen.dart`) et par `character_list_screen.dart`
  /// (bannière `widgets/update_suggested_banner.dart`), voir la documentation
  /// de `AppVersionStatus`.
  ///
  /// `keepAlive` : lu depuis 2 endroits distincts sur toute la durée de vie de
  /// l'app (démarrage, puis liste de personnages tant que celle-ci reste
  /// affichée).
  ///
  /// **Ne bloque jamais l'utilisateur en cas d'échec réseau** (spec de la
  /// tâche, cohérent avec `05-ux-navigation.md` sur l'initialisation) : toute
  /// exception (pas de connexion, RLS, ligne absente...) est interceptée ici
  /// et retombe sur `AppVersionStatus.upToDate` avec la version installée
  /// recopiée dans les 3 champs — un statut "neutre" indiscernable d'un
  /// "vraiment à jour" pour les deux consommateurs, qui n'affichent jamais
  /// rien pour ce statut. Une requête sans réponse après
  /// [appVersionCheckTimeout] est traitée de la même façon : cette vérification
  /// ne retarde jamais le premier écran au-delà de ce délai.
  ///
  /// **Relance en arrière-plan** : tant que le dernier résultat est un repli
  /// (timeout ou erreur) et non une vraie réponse du serveur, la vérification
  /// est relancée (a) après chaque délai de [appVersionRetryBackoff] (une
  /// relance à la fois, nombre fini), (b) à chaque
  /// `ConnectivityChecker.onConnectivityRestored`. Dès qu'une vraie réponse
  /// arrive, l'état est mis à jour (`AppBootstrap` bascule alors sur
  /// `ForceUpdateScreen` si « mise à jour obligatoire », la bannière apparaît si
  /// « suggérée ») et toute relance s'arrête. Minuteur et abonnement sont
  /// annulés à la libération du provider.
  AppVersionCheckProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionCheckProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionCheckHash();

  @$internal
  @override
  AppVersionCheck create() => AppVersionCheck();
}

String _$appVersionCheckHash() => r'9643be6758b191648d300af3d3f7b914ded0f631';

/// Vérification de version partagée — **seul point de lecture** consommé à
/// la fois par `main.dart::AppBootstrap` (écran bloquant
/// `force_update_screen.dart`) et par `character_list_screen.dart`
/// (bannière `widgets/update_suggested_banner.dart`), voir la documentation
/// de `AppVersionStatus`.
///
/// `keepAlive` : lu depuis 2 endroits distincts sur toute la durée de vie de
/// l'app (démarrage, puis liste de personnages tant que celle-ci reste
/// affichée).
///
/// **Ne bloque jamais l'utilisateur en cas d'échec réseau** (spec de la
/// tâche, cohérent avec `05-ux-navigation.md` sur l'initialisation) : toute
/// exception (pas de connexion, RLS, ligne absente...) est interceptée ici
/// et retombe sur `AppVersionStatus.upToDate` avec la version installée
/// recopiée dans les 3 champs — un statut "neutre" indiscernable d'un
/// "vraiment à jour" pour les deux consommateurs, qui n'affichent jamais
/// rien pour ce statut. Une requête sans réponse après
/// [appVersionCheckTimeout] est traitée de la même façon : cette vérification
/// ne retarde jamais le premier écran au-delà de ce délai.
///
/// **Relance en arrière-plan** : tant que le dernier résultat est un repli
/// (timeout ou erreur) et non une vraie réponse du serveur, la vérification
/// est relancée (a) après chaque délai de [appVersionRetryBackoff] (une
/// relance à la fois, nombre fini), (b) à chaque
/// `ConnectivityChecker.onConnectivityRestored`. Dès qu'une vraie réponse
/// arrive, l'état est mis à jour (`AppBootstrap` bascule alors sur
/// `ForceUpdateScreen` si « mise à jour obligatoire », la bannière apparaît si
/// « suggérée ») et toute relance s'arrête. Minuteur et abonnement sont
/// annulés à la libération du provider.

abstract class _$AppVersionCheck extends $AsyncNotifier<AppVersionCheckResult> {
  FutureOr<AppVersionCheckResult> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<AppVersionCheckResult>, AppVersionCheckResult>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<AppVersionCheckResult>,
                AppVersionCheckResult
              >,
              AsyncValue<AppVersionCheckResult>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
