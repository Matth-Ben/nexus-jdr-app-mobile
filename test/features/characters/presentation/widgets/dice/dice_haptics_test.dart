// Plan et pilote des retours haptiques du dé (P2b, addendum 2) : logique pure.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/dice3d/dice_flight_simulator.dart';
import 'package:personnages/features/characters/presentation/widgets/dice/dice_haptics.dart';

class _Recorder implements DiceHapticPlayer {
  final List<DiceHapticKind> played = [];

  @override
  void play(DiceHapticKind kind) => played.add(kind);
}

ImpactEvent _e(double t, ImpactKind kind) =>
    ImpactEvent(t: t, kind: kind, strength: 1, die: 0);

void main() {
  group('plan', () {
    test('landing -> light, dé-dé -> medium, pose -> selection', () {
      final plan = DiceHapticsPlan.build(
        impacts: [
          _e(0.38, ImpactKind.landing),
          _e(0.55, ImpactKind.dieDie),
          _e(0.72, ImpactKind.landing),
        ],
        duration: 1.8,
      );
      expect(plan.map((e) => e.kind), [
        DiceHapticKind.light,
        DiceHapticKind.medium,
        DiceHapticKind.selection,
      ]);
      expect(plan.last.t, 1.8);
    });

    test('au plus 4 événements, au moins 80 ms entre deux', () {
      final plan = DiceHapticsPlan.build(
        impacts: [
          for (var i = 0; i < 20; i++) _e(0.1 + i * 0.05, ImpactKind.landing),
          for (var i = 0; i < 20; i++) _e(0.15 + i * 0.05, ImpactKind.dieDie),
        ],
        duration: 1.6,
      );
      expect(plan.length, lessThanOrEqualTo(DiceHapticsPlan.maxEvents));
      for (var i = 1; i < plan.length; i++) {
        expect(
          plan[i].t - plan[i - 1].t,
          greaterThanOrEqualTo(DiceHapticsPlan.minGapSeconds - 1e-9),
        );
      }
    });

    test('un choc trop proche du précédent est abandonné (throttle)', () {
      final plan = DiceHapticsPlan.build(
        impacts: [_e(0.30, ImpactKind.landing), _e(0.32, ImpactKind.dieDie)],
        duration: 1.6,
      );
      expect(plan.map((e) => e.kind), [
        DiceHapticKind.light,
        DiceHapticKind.selection,
      ]);
    });

    test('rien sous disableAnimations', () {
      expect(
        DiceHapticsPlan.build(
          impacts: [_e(0.4, ImpactKind.landing)],
          duration: 1.6,
          reducedMotion: true,
        ),
        isEmpty,
      );
    });

    test('navigation accessible : seulement le selectionClick de pose', () {
      final plan = DiceHapticsPlan.build(
        impacts: [_e(0.4, ImpactKind.landing), _e(0.6, ImpactKind.dieDie)],
        duration: 1.6,
        accessibleNavigation: true,
      );
      expect(plan.map((e) => e.kind), [DiceHapticKind.selection]);
    });
  });

  group('pilote', () {
    test('joue les chocs à leur heure, la pose une seule fois', () {
      final rec = _Recorder();
      DiceHapticsDriver(rec)
        ..start([
          const DiceHapticEvent(0.4, DiceHapticKind.light),
          const DiceHapticEvent(0.6, DiceHapticKind.medium),
          const DiceHapticEvent(1.6, DiceHapticKind.selection),
        ])
        ..tick(0.3);
      expect(rec.played, isEmpty);
      final d = DiceHapticsDriver(rec)
        ..start([
          const DiceHapticEvent(0.4, DiceHapticKind.light),
          const DiceHapticEvent(0.6, DiceHapticKind.medium),
          const DiceHapticEvent(1.6, DiceHapticKind.selection),
        ])
        ..tick(0.5);
      expect(rec.played, [DiceHapticKind.light]);
      d
        ..tick(1.0)
        ..tick(1.59);
      expect(rec.played, [DiceHapticKind.light, DiceHapticKind.medium]);
      d
        ..settle()
        ..settle();
      expect(rec.played.last, DiceHapticKind.selection);
      expect(rec.played.where((k) => k == DiceHapticKind.selection).length, 1);
    });

    test('saut : les chocs restants sont abandonnés, la pose est jouée', () {
      final rec = _Recorder();
      DiceHapticsDriver(rec)
        ..start([
          const DiceHapticEvent(0.4, DiceHapticKind.light),
          const DiceHapticEvent(0.6, DiceHapticKind.medium),
          const DiceHapticEvent(1.6, DiceHapticKind.selection),
        ])
        ..tick(0.1)
        ..cancelImpacts()
        ..tick(2)
        ..settle();
      expect(rec.played, [DiceHapticKind.selection]);
    });

    test('plan vide : settle ne joue rien', () {
      final rec = _Recorder();
      DiceHapticsDriver(rec)
        ..start(const [])
        ..settle();
      expect(rec.played, isEmpty);
    });
  });
}
