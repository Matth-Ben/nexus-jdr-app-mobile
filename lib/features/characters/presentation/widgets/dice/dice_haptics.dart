import 'package:flutter/services.dart';

import '../../../domain/dice3d/dice_flight_simulator.dart';

enum DiceHapticKind { light, medium, selection }

class DiceHapticEvent {
  const DiceHapticEvent(this.t, this.kind);

  /// Instant (secondes depuis le début du lancer).
  final double t;
  final DiceHapticKind kind;

  @override
  String toString() => 'DiceHapticEvent($t, $kind)';
}

/// Joue un retour haptique (remplaçable dans les tests).
abstract interface class DiceHapticPlayer {
  void play(DiceHapticKind kind);
}

/// Implémentation système : le réglage de retour haptique de l'appareil
/// s'applique de lui-même (rien n'est vibré s'il est coupé).
class SystemDiceHapticPlayer implements DiceHapticPlayer {
  const SystemDiceHapticPlayer();

  @override
  void play(DiceHapticKind kind) {
    switch (kind) {
      case DiceHapticKind.light:
        HapticFeedback.lightImpact();
      case DiceHapticKind.medium:
        HapticFeedback.mediumImpact();
      case DiceHapticKind.selection:
        HapticFeedback.selectionClick();
    }
  }
}

/// Plan des retours haptiques d'un lancer, déduit des chocs de la piste.
///
/// `lightImpact` au premier impact au sol, `mediumImpact` au premier choc
/// dé-dé, `selectionClick` à la pose ; au plus [maxEvents] événements, au
/// moins [minGapSeconds] entre deux ; **rien** si les animations sont coupées,
/// **seulement** le `selectionClick` de pose sous navigation accessible.
abstract final class DiceHapticsPlan {
  static const int maxEvents = 4;
  static const double minGapSeconds = 0.080;

  static List<DiceHapticEvent> build({
    required List<ImpactEvent> impacts,
    required double duration,
    bool reducedMotion = false,
    bool accessibleNavigation = false,
    bool throttle = true,
  }) {
    if (reducedMotion) return const [];
    final pose = DiceHapticEvent(duration, DiceHapticKind.selection);
    if (accessibleNavigation) return [pose];

    final candidates = <DiceHapticEvent>[];
    var landing = false;
    var dieDie = false;
    for (final e in impacts) {
      if (e.kind == ImpactKind.landing && !landing) {
        landing = true;
        candidates.add(DiceHapticEvent(e.t, DiceHapticKind.light));
      } else if (e.kind == ImpactKind.dieDie && !dieDie) {
        dieDie = true;
        candidates.add(DiceHapticEvent(e.t, DiceHapticKind.medium));
      }
    }
    candidates
      ..sort((a, b) => a.t.compareTo(b.t))
      ..add(pose);

    if (!throttle) return candidates;
    final out = <DiceHapticEvent>[];
    for (final e in candidates) {
      if (out.length >= maxEvents) break;
      if (out.isNotEmpty && e.t - out.last.t < minGapSeconds) {
        // La pose prime toujours sur un choc trop proche d'elle.
        if (e.kind == DiceHapticKind.selection) {
          out.removeLast();
          out.add(e);
        }
        continue;
      }
      out.add(e);
    }
    return out;
  }
}

/// Joue le plan au fil du temps du contrôleur (jamais depuis `paint`).
class DiceHapticsDriver {
  DiceHapticsDriver(this.player);

  final DiceHapticPlayer player;
  List<DiceHapticEvent> _events = const [];
  int _next = 0;
  bool _poseDone = false;

  /// Nouveau lancer.
  void start(List<DiceHapticEvent> events) {
    _events = events;
    _next = 0;
    _poseDone = false;
  }

  /// Fait avancer le lancer à l'instant [t] (secondes) : joue les chocs dont
  /// l'heure est passée (la pose, elle, n'est jouée que par [settle]).
  void tick(double t) {
    while (_next < _events.length) {
      final e = _events[_next];
      if (e.kind == DiceHapticKind.selection || e.t > t) break;
      _next++;
      player.play(e.kind);
    }
  }

  /// Saut au tap : les chocs restants sont abandonnés.
  void cancelImpacts() {
    while (_next < _events.length &&
        _events[_next].kind != DiceHapticKind.selection) {
      _next++;
    }
  }

  /// Le dé est posé : joue le `selectionClick` de pose (une seule fois).
  void settle() {
    if (_poseDone) return;
    _poseDone = true;
    final hasPose = _events.any((e) => e.kind == DiceHapticKind.selection);
    if (hasPose) player.play(DiceHapticKind.selection);
  }
}
