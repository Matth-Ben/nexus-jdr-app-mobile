import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/route_stack_observer.dart';

/// Déclare [child] comme **barre basse** de sa page (barre d'onglets de la
/// fiche) : sa hauteur est transmise à [RouteStackObserver], pour que les
/// signaux globaux flottants (`CombatCallout`) se posent au-dessus d'elle,
/// comme une `SnackBar`. Sans effet visuel.
class BottomBarInsetReporter extends ConsumerStatefulWidget {
  const BottomBarInsetReporter({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BottomBarInsetReporter> createState() =>
      _BottomBarInsetReporterState();
}

class _BottomBarInsetReporterState
    extends ConsumerState<BottomBarInsetReporter> {
  RouteStackObserver? _observer;
  Route<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer ??= ref.read(routeStackObserverProvider);
    final route = ModalRoute.of(context);
    if (route != _route) {
      final previous = _route;
      if (previous != null) _observer?.clearBottomBar(previous);
      _route = route;
    }
  }

  @override
  void dispose() {
    final route = _route;
    if (route != null) _observer?.clearBottomBar(route);
    super.dispose();
  }

  void _onSize(Size size) {
    final route = _route;
    if (!mounted || route == null) return;
    _observer?.reportBottomBar(route, size.height);
  }

  @override
  Widget build(BuildContext context) =>
      _SizeReporter(onSize: _onSize, child: widget.child);
}

/// Rapporte la taille de [child] après chaque mise en page qui la change
/// (après l'image, jamais pendant la mise en page).
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) {
    renderObject.onSize = onSize;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final current = size;
    if (current == _reported) return;
    _reported = current;
    SchedulerBinding.instance.addPostFrameCallback((_) => onSize(current));
  }
}
