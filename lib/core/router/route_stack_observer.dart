import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'route_stack_observer.g.dart';

/// Pile des routes du navigateur racine, telle qu'observée : page visible
/// (dernière `PageRoute`), feuille modale ou boîte de dialogue ouverte
/// par-dessus, et hauteur de la barre basse de chaque page.
///
/// Sert aux signaux globaux posés **au-dessus** du navigateur
/// (`CombatCallout`, `docs/combat-grimoire-ui.md` §6) : absents de l'écran
/// Combat du groupe concerné, différés tant qu'une feuille modale est ouverte,
/// posés au-dessus de la barre d'onglets.
///
/// Enregistré sur `GoRouter.observers` (`core/router/app_router.dart`). Les
/// changements sont notifiés **après** la mise à jour du navigateur (une
/// microtâche, regroupée), jamais pendant sa construction.
class RouteStackObserver extends NavigatorObserver with ChangeNotifier {
  final List<Route<dynamic>> _stack = [];
  final Map<Route<dynamic>, double> _bottomBars = {};
  bool _notifyScheduled = false;
  bool _disposed = false;

  /// Route du dessus (page, feuille ou boîte de dialogue).
  Route<dynamic>? get top => _stack.isEmpty ? null : _stack.last;

  /// Page affichée : la dernière `PageRoute` de la pile, même sous une
  /// feuille modale.
  PageRoute<dynamic>? get visiblePage {
    for (var i = _stack.length - 1; i >= 0; i--) {
      final route = _stack[i];
      if (route is PageRoute) return route;
    }
    return null;
  }

  /// Une feuille modale ou une boîte de dialogue couvre la page.
  bool get overlayOpen {
    final route = top;
    return route != null && route is! PageRoute;
  }

  /// Nom de la page affichée (`GoRoute.name`).
  String? get visiblePageName => visiblePage?.settings.name;

  /// Paramètre [key] de la page affichée (`go_router` range les paramètres
  /// de chemin et de requête dans `RouteSettings.arguments`).
  String? visiblePageParameter(String key) {
    final arguments = visiblePage?.settings.arguments;
    if (arguments is! Map) return null;
    return arguments[key]?.toString();
  }

  /// Hauteur de la barre basse (onglets) de la page affichée, 0 sans barre.
  double get visibleBottomBar => _bottomBars[visiblePage] ?? 0;

  /// La barre basse de [route] mesure [height].
  void reportBottomBar(Route<dynamic> route, double height) {
    if (_bottomBars[route] == height) return;
    _bottomBars[route] = height;
    _changed();
  }

  /// La barre basse de [route] a disparu.
  void clearBottomBar(Route<dynamic> route) {
    if (_bottomBars.remove(route) != null) _changed();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _changed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _forget(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _forget(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (newRoute != null) {
      if (index >= 0) {
        _stack[index] = newRoute;
      } else {
        _stack.add(newRoute);
      }
    } else if (index >= 0) {
      _stack.removeAt(index);
    }
    if (oldRoute != null) _bottomBars.remove(oldRoute);
    _changed();
  }

  void _forget(Route<dynamic> route) {
    _stack.remove(route);
    _bottomBars.remove(route);
    _changed();
  }

  void _changed() {
    if (_notifyScheduled || _disposed) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// [RouteStackObserver] unique de l'app (`keepAlive`), comme
/// `routeObserverProvider` : `GoRouter.observers` et ses lecteurs pointent vers
/// la même instance.
@Riverpod(keepAlive: true)
RouteStackObserver routeStackObserver(Ref ref) {
  final observer = RouteStackObserver();
  ref.onDispose(observer.dispose);
  return observer;
}
