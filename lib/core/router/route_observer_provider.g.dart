// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_observer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [RouteObserver] partagé, enregistré sur `GoRouter.observers` (voir
/// `core/router/app_router.dart`) et souscrit par tout écran qui a besoin de
/// réagir à son retour au premier plan après un `pop` d'une route poussée
/// par-dessus lui (`RouteAware.didPopNext`) — voir par exemple
/// `CharacterListScreen`, qui l'utilise pour se rafraîchir au retour de la
/// fiche personnage (`character_detail_screen.dart`) après une écriture
/// (montée de niveau, PV/XP, repos, portrait, sorts, inventaire, histoire...).
///
/// `keepAlive` : un seul [RouteObserver] doit exister pour toute la durée de
/// vie de l'app — `GoRouter.observers` et chaque `RouteAware.subscribe` ci-
/// dessous doivent tous pointer vers la même instance, jamais une par écran.
///
/// `go_router` s'appuie sur le `Navigator`/`Page` standard de Flutter en
/// dessous : ce `RouteObserver`/`RouteAware` est le mécanisme Flutter
/// générique documenté par `NavigatorObserver`, pas un pattern spécifique à
/// `go_router` — compatible tel quel.

@ProviderFor(routeObserver)
final routeObserverProvider = RouteObserverProvider._();

/// [RouteObserver] partagé, enregistré sur `GoRouter.observers` (voir
/// `core/router/app_router.dart`) et souscrit par tout écran qui a besoin de
/// réagir à son retour au premier plan après un `pop` d'une route poussée
/// par-dessus lui (`RouteAware.didPopNext`) — voir par exemple
/// `CharacterListScreen`, qui l'utilise pour se rafraîchir au retour de la
/// fiche personnage (`character_detail_screen.dart`) après une écriture
/// (montée de niveau, PV/XP, repos, portrait, sorts, inventaire, histoire...).
///
/// `keepAlive` : un seul [RouteObserver] doit exister pour toute la durée de
/// vie de l'app — `GoRouter.observers` et chaque `RouteAware.subscribe` ci-
/// dessous doivent tous pointer vers la même instance, jamais une par écran.
///
/// `go_router` s'appuie sur le `Navigator`/`Page` standard de Flutter en
/// dessous : ce `RouteObserver`/`RouteAware` est le mécanisme Flutter
/// générique documenté par `NavigatorObserver`, pas un pattern spécifique à
/// `go_router` — compatible tel quel.

final class RouteObserverProvider
    extends
        $FunctionalProvider<
          RouteObserver<PageRoute<dynamic>>,
          RouteObserver<PageRoute<dynamic>>,
          RouteObserver<PageRoute<dynamic>>
        >
    with $Provider<RouteObserver<PageRoute<dynamic>>> {
  /// [RouteObserver] partagé, enregistré sur `GoRouter.observers` (voir
  /// `core/router/app_router.dart`) et souscrit par tout écran qui a besoin de
  /// réagir à son retour au premier plan après un `pop` d'une route poussée
  /// par-dessus lui (`RouteAware.didPopNext`) — voir par exemple
  /// `CharacterListScreen`, qui l'utilise pour se rafraîchir au retour de la
  /// fiche personnage (`character_detail_screen.dart`) après une écriture
  /// (montée de niveau, PV/XP, repos, portrait, sorts, inventaire, histoire...).
  ///
  /// `keepAlive` : un seul [RouteObserver] doit exister pour toute la durée de
  /// vie de l'app — `GoRouter.observers` et chaque `RouteAware.subscribe` ci-
  /// dessous doivent tous pointer vers la même instance, jamais une par écran.
  ///
  /// `go_router` s'appuie sur le `Navigator`/`Page` standard de Flutter en
  /// dessous : ce `RouteObserver`/`RouteAware` est le mécanisme Flutter
  /// générique documenté par `NavigatorObserver`, pas un pattern spécifique à
  /// `go_router` — compatible tel quel.
  RouteObserverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeObserverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeObserverHash();

  @$internal
  @override
  $ProviderElement<RouteObserver<PageRoute<dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RouteObserver<PageRoute<dynamic>> create(Ref ref) {
    return routeObserver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RouteObserver<PageRoute<dynamic>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RouteObserver<PageRoute<dynamic>>>(
        value,
      ),
    );
  }
}

String _$routeObserverHash() => r'8e1e8bc8171e03340111f56e69c372820162e97c';
