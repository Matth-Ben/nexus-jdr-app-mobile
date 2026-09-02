import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'route_observer_provider.g.dart';

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
@Riverpod(keepAlive: true)
RouteObserver<PageRoute<dynamic>> routeObserver(Ref ref) {
  return RouteObserver<PageRoute<dynamic>>();
}
