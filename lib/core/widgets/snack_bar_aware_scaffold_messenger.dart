import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// `ScaffoldMessenger` de l'app qui expose la `SnackBar` en cours
/// ([SnackBarAwareScaffoldMessengerState.currentSnackBar]) : les signaux
/// flottants posés au-dessus du navigateur (`CombatCallout`) se placent
/// au-dessus d'elle au lieu de la couvrir (revue visuelle du 24/11/2026 :
/// « Annuler » toujours touchable).
///
/// Placé dans `MaterialApp.router(builder: ...)` avec la clé globale de
/// l'app (`scaffoldMessengerKeyProvider`) : c'est le messager le plus proche
/// de toutes les pages, donc celui auquel les `Scaffold` s'inscrivent et que
/// `ScaffoldMessenger.of(context)` renvoie. Comportement des `SnackBar`
/// inchangé.
class SnackBarAwareScaffoldMessenger extends ScaffoldMessenger {
  const SnackBarAwareScaffoldMessenger({required super.child, super.key});

  @override
  ScaffoldMessengerState createState() => SnackBarAwareScaffoldMessengerState();
}

class SnackBarAwareScaffoldMessengerState extends ScaffoldMessengerState {
  /// File des `SnackBar` demandées, dans l'ordre : la première est affichée.
  final List<SnackBar> _queue = [];

  /// `SnackBar` affichée (ou en train d'apparaître ou de disparaître),
  /// `null` sans `SnackBar`.
  final ValueNotifier<SnackBar?> currentSnackBar = ValueNotifier(null);

  @override
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    SnackBar snackBar, {
    AnimationStyle? snackBarAnimationStyle,
  }) {
    final controller = super.showSnackBar(
      snackBar,
      snackBarAnimationStyle: snackBarAnimationStyle,
    );
    _queue.add(snackBar);
    _publish();
    unawaited(
      controller.closed.whenComplete(() {
        _queue.remove(snackBar);
        if (mounted) _publish();
      }),
    );
    return controller;
  }

  @override
  void clearSnackBars() {
    super.clearSnackBars();
    // Les `SnackBar` en attente sont retirées sans être fermées : seule la
    // courante reste (et se ferme normalement).
    if (_queue.length > 1) _queue.removeRange(1, _queue.length);
    _publish();
  }

  void _publish() {
    currentSnackBar.value = _queue.isEmpty ? null : _queue.first;
  }

  @override
  void dispose() {
    currentSnackBar.dispose();
    super.dispose();
  }
}

/// Haut (coordonnée globale) de l'emprise **finale** de [snackBar] dans la
/// page [scope] (`ModalRoute.subtreeContext` de la page affichée), `null` si
/// elle n'y est pas (encore) disposée.
///
/// Le `Scaffold` affiche une copie de la `SnackBar` demandée
/// (`SnackBar.withAnimation`) : elle est reconnue à son contenu, transmis
/// tel quel.
///
/// L'entrée d'une `SnackBar` anime une hauteur partielle ancrée en bas
/// (`Align(heightFactor)`) : la hauteur pleine est lue sur l'enfant de cet
/// `Align`, pour que le signal se pose d'emblée à sa place définitive.
double? snackBarTopIn(BuildContext scope, SnackBar snackBar) {
  Element? found;
  void visit(Element element) {
    if (found != null) return;
    final widget = element.widget;
    if (widget is SnackBar && identical(widget.content, snackBar.content)) {
      found = element;
      return;
    }
    element.visitChildElements(visit);
  }

  scope.visitChildElements(visit);
  final box = found?.renderObject;
  if (box is! RenderBox || !box.attached || !box.hasSize) return null;
  final bottom = box.localToGlobal(Offset(0, box.size.height)).dy;
  return bottom - (_fullHeightBelow(box) ?? box.size.height);
}

/// Hauteur de l'enfant du premier `Align` (animation d'entrée) sous [box].
double? _fullHeightBelow(RenderBox box) {
  RenderObject? node = box;
  for (var depth = 0; depth < 16 && node != null; depth++) {
    if (node is RenderPositionedBox) {
      final child = node.child;
      return child != null && child.hasSize ? child.size.height : null;
    }
    node = node is RenderObjectWithChildMixin ? node.child : null;
  }
  return null;
}
