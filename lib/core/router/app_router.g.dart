// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

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

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
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
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'3c03cccbd42d7ff8b6ed52c97325f4bb72ba8f73';
