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

/// Vérification de version partagée — **seul point de lecture** consommé à
/// la fois par `main.dart::AppBootstrap` (écran bloquant
/// `force_update_screen.dart`) et par `character_list_screen.dart`
/// (bannière `widgets/update_suggested_banner.dart`), voir la documentation
/// de `AppVersionStatus`.
///
/// `keepAlive` : lu depuis 2 endroits distincts sur toute la durée de vie de
/// l'app (démarrage, puis liste de personnages tant que celle-ci reste
/// affichée) — la ligne `app_versions` ne change jamais au cours d'une
/// session (une nouvelle version publiée implique un redémarrage de l'app de
/// toute façon), pas besoin de relancer une requête réseau à chaque
/// navigation entre les deux.
///
/// **Ne bloque jamais l'utilisateur en cas d'échec réseau** (spec de la
/// tâche, cohérent avec `05-ux-navigation.md` sur l'initialisation) : toute
/// exception (pas de connexion, RLS, ligne absente...) est interceptée ici
/// et retombe sur `AppVersionStatus.upToDate` avec la version installée
/// recopiée dans les 3 champs — un statut "neutre" indiscernable d'un
/// "vraiment à jour" pour les deux consommateurs, qui n'affichent jamais
/// rien pour ce statut.

@ProviderFor(appVersionCheck)
final appVersionCheckProvider = AppVersionCheckProvider._();

/// Vérification de version partagée — **seul point de lecture** consommé à
/// la fois par `main.dart::AppBootstrap` (écran bloquant
/// `force_update_screen.dart`) et par `character_list_screen.dart`
/// (bannière `widgets/update_suggested_banner.dart`), voir la documentation
/// de `AppVersionStatus`.
///
/// `keepAlive` : lu depuis 2 endroits distincts sur toute la durée de vie de
/// l'app (démarrage, puis liste de personnages tant que celle-ci reste
/// affichée) — la ligne `app_versions` ne change jamais au cours d'une
/// session (une nouvelle version publiée implique un redémarrage de l'app de
/// toute façon), pas besoin de relancer une requête réseau à chaque
/// navigation entre les deux.
///
/// **Ne bloque jamais l'utilisateur en cas d'échec réseau** (spec de la
/// tâche, cohérent avec `05-ux-navigation.md` sur l'initialisation) : toute
/// exception (pas de connexion, RLS, ligne absente...) est interceptée ici
/// et retombe sur `AppVersionStatus.upToDate` avec la version installée
/// recopiée dans les 3 champs — un statut "neutre" indiscernable d'un
/// "vraiment à jour" pour les deux consommateurs, qui n'affichent jamais
/// rien pour ce statut.

final class AppVersionCheckProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppVersionCheckResult>,
          AppVersionCheckResult,
          FutureOr<AppVersionCheckResult>
        >
    with
        $FutureModifier<AppVersionCheckResult>,
        $FutureProvider<AppVersionCheckResult> {
  /// Vérification de version partagée — **seul point de lecture** consommé à
  /// la fois par `main.dart::AppBootstrap` (écran bloquant
  /// `force_update_screen.dart`) et par `character_list_screen.dart`
  /// (bannière `widgets/update_suggested_banner.dart`), voir la documentation
  /// de `AppVersionStatus`.
  ///
  /// `keepAlive` : lu depuis 2 endroits distincts sur toute la durée de vie de
  /// l'app (démarrage, puis liste de personnages tant que celle-ci reste
  /// affichée) — la ligne `app_versions` ne change jamais au cours d'une
  /// session (une nouvelle version publiée implique un redémarrage de l'app de
  /// toute façon), pas besoin de relancer une requête réseau à chaque
  /// navigation entre les deux.
  ///
  /// **Ne bloque jamais l'utilisateur en cas d'échec réseau** (spec de la
  /// tâche, cohérent avec `05-ux-navigation.md` sur l'initialisation) : toute
  /// exception (pas de connexion, RLS, ligne absente...) est interceptée ici
  /// et retombe sur `AppVersionStatus.upToDate` avec la version installée
  /// recopiée dans les 3 champs — un statut "neutre" indiscernable d'un
  /// "vraiment à jour" pour les deux consommateurs, qui n'affichent jamais
  /// rien pour ce statut.
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
  $FutureProviderElement<AppVersionCheckResult> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppVersionCheckResult> create(Ref ref) {
    return appVersionCheck(ref);
  }
}

String _$appVersionCheckHash() => r'1eb9452a1da51d1cb6e7811a1895747459781cea';
