// Mise en page du lancer sur la page entière (P2b, addendum 2), polyligne de
// repli (niveau 0) et lecteur de piste : logique pure.

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/dice3d/d20_orientation.dart';
import 'package:personnages/features/characters/domain/dice3d/dice_flight_simulator.dart';
import 'package:personnages/features/characters/presentation/widgets/dice/die_flight.dart';
import 'package:personnages/features/characters/presentation/widgets/dice/die_flight_runner.dart';

class _Case {
  const _Case(this.size, this.padTop, this.d1, this.d2);

  final Size size;
  final double padTop;
  final double d1;
  final double d2;
}

// Exemples de la spec (D1 / D2), avec l'inset haut qui les produit.
const _cases = [
  _Case(Size(320, 568), 20, 160, 144),
  _Case(Size(360, 640), 24, 183, 162),
  _Case(Size(411, 891), 24, 226, 185),
  _Case(Size(768, 1024), 24, 280, 240),
];

DiceFlightLayout _layout(_Case c, int count) => DiceFlightLayout.compute(
  c.size,
  paddingTop: c.padTop,
  paddingBottom: 0,
  count: count,
);

void main() {
  group('tailles (D = diamètre visible, S = D / 0,84, boîte 1,25 · S)', () {
    for (final c in _cases) {
      final name = '${c.size.width.toInt()}×${c.size.height.toInt()}';
      test('$name : D1 ≈ ${c.d1}, D2 ≈ ${c.d2}', () {
        expect(_layout(c, 1).diameter, closeTo(c.d1, 1));
        expect(_layout(c, 2).diameter, closeTo(c.d2, 1));
      });

      test('$name : formules de la spec, plancher 96, plafonds 280 / 240', () {
        final hf = (0.38 * c.size.height - 8) - (c.padTop + 8);
        expect(
          _layout(c, 1).diameter,
          max(96, min(0.55 * c.size.width, min(hf - 20, 280))),
        );
        expect(
          _layout(c, 2).diameter,
          max(96, min(0.45 * c.size.width, min(hf - 36, 240))),
        );
        for (final count in [1, 2]) {
          final l = _layout(c, count);
          expect(l.diameter, inInclusiveRange(96, 280));
          expect(l.nominal, closeTo(l.diameter / 0.84, 1e-9));
          expect(l.box, closeTo(1.25 * l.nominal, 1e-9));
        }
      });

      test('$name : deux dés tiennent dans la largeur, 12 dp d\'écart, '
          '>= 2R + 12 entre repos', () {
        final l = _layout(c, 2);
        expect(2 * l.diameter + 12, lessThanOrEqualTo(c.size.width - 16));
        final dx = l.rests[1].dx - l.rests[0].dx;
        expect(dx, closeTo(l.diameter + 12, 1e-9));
        expect(dx, greaterThanOrEqualTo(2 * l.radius + 12 - 1e-9));
        expect(l.rests[0].dx - l.radius, greaterThanOrEqualTo(8));
        expect(l.rests[1].dx + l.radius, lessThanOrEqualTo(c.size.width - 8));
      });

      test('$name : les dés au repos restent au-dessus de la feuille '
          '(0,38·H), étiquette comprise', () {
        for (final count in [1, 2]) {
          final l = _layout(c, count);
          for (final r in l.rests) {
            expect(r.dy - l.radius, greaterThanOrEqualTo(l.freeTop - 1e-9));
            final bottom = r.dy + l.radius + (count == 2 ? 24 : 0);
            expect(bottom, lessThanOrEqualTo(l.freeBottom + 1e-9));
          }
        }
      });
    }

    test('petit écran : plancher de 96 dp', () {
      final l = DiceFlightLayout.compute(
        const Size(320, 400),
        paddingTop: 40,
        paddingBottom: 0,
        count: 2,
      );
      expect(l.diameter, 96);
    });

    test('table : écran moins zones système, marge 8 dp ; étiquette 4 dp sous '
        'le bord (centre + 0,42·S + 4)', () {
      final l = DiceFlightLayout.compute(
        const Size(390, 844),
        paddingTop: 47,
        paddingBottom: 34,
        count: 2,
      );
      expect(l.table, const Rect.fromLTRB(8, 55, 382, 802));
      expect(l.labelTop - l.box / 2, closeTo(0.42 * l.nominal + 4, 1e-9));
      expect(0.42 * l.nominal, closeTo(l.radius, 1e-9));
    });

    test('durées : 1,6 s (1 dé), 1,8 s (2 dés)', () {
      expect(DiceFlightLayout.durationFor(1), 1.6);
      expect(DiceFlightLayout.durationFor(2), 1.8);
    });
  });

  group('plan de vol (repli niveau 0)', () {
    const table = Rect.fromLTRB(8, 55, 382, 802);

    DieFlightPlan plan(int seed) => DieFlightPlan.build(
      table: table,
      rest: const Offset(195, 280),
      radius: 74,
      random: Random(seed),
    );

    test('démarre sous l\'écran, finit exactement au repos', () {
      for (var seed = 0; seed < 20; seed++) {
        final p = plan(seed);
        expect(p.groundAt(0).dy, greaterThan(table.bottom));
        expect(p.groundAt(1), const Offset(195, 280));
      }
    });

    test('hauteur : rebonds 100 % puis 35 %, au sol dès 70 %', () {
      expect(DieFlightPlan.heightAt(0.30), closeTo(1, 1e-9));
      expect(DieFlightPlan.heightAt(0.45), closeTo(0.35, 1e-9));
      expect(DieFlightPlan.heightAt(0.70), closeTo(0, 1e-9));
      expect(DieFlightPlan.heightAt(1), 0);
    });
  });

  group('lecteur de piste (DieFlightRunner)', () {
    DiceFlightTrack stationary(List<ImpactEvent> impacts, {int count = 1}) {
      const n = 193;
      final samples = Float32List(count * n * 7);
      for (var d = 0; d < count; d++) {
        for (var i = 0; i < n; i++) {
          final o = (d * n + i) * 7;
          // Un dé qui glisse de 0 à 100 dp en x, au sol, à l'identité.
          samples[o] = 100.0 * i / (n - 1);
          samples[o + 1] = 200;
          samples[o + 2] = 0;
          samples[o + 3] = 1;
        }
      }
      return DiceFlightTrack(
        count: count,
        duration: 1.6,
        samples: samples,
        impacts: impacts,
      );
    }

    DieFlightRunner runner(DiceFlightTrack t, {DieSkipState? skip}) =>
        DieFlightRunner.track(
          track: t,
          die: 0,
          rest: const Offset(100, 200),
          target: D20Orientation.forValue(7),
          diameter: 160,
          skip: skip ?? DieSkipState(),
        );

    test('squash : amplitude <= 0,06 au sol, 40 % sur un mur, décroît '
        'e^(−t/0,04)', () {
      final t = stationary(const [
        ImpactEvent(t: 0.5, kind: ImpactKind.landing, strength: 1, die: 0),
        ImpactEvent(t: 1.0, kind: ImpactKind.wall, strength: 1, die: 0),
      ]);
      final r = runner(t)..update(0.5 / 1.6);
      expect(1 - r.squashY, closeTo(0.06, 1e-6));
      expect(r.squashX - 1, closeTo(0.06, 1e-6));
      r.update(0.54 / 1.6);
      expect(1 - r.squashY, closeTo(0.06 * exp(-1), 1e-3));
      r.update(0.8 / 1.6);
      expect(r.squashX, 1);
      r.update(1.0 / 1.6);
      expect(1 - r.squashY, lessThanOrEqualTo(0.06 * 0.4 + 1e-6));
      expect(1 - r.squashY, greaterThan(0));
    });

    test('impact d\'un autre dé : pas de squash', () {
      final t = stationary(const [
        ImpactEvent(t: 0.5, kind: ImpactKind.landing, strength: 1, die: 1),
      ], count: 2);
      final r = runner(t)..update(0.5 / 1.6);
      expect(r.squashX, 1);
    });

    test('échelle de vol 1 + 0,20·h, pulsation de pose 1 → 1,045 → 1', () {
      final r = runner(stationary(const []))..update(0.5);
      expect(r.scale, closeTo(1, 1e-9));
      r.update((1.6 - 0.125) / 1.6);
      expect(r.scale, closeTo(1.045, 1e-3));
      r.update(1);
      expect(r.scale, closeTo(1, 1e-9));
    });

    test(
      'fondu : 200 derniers ms ; tressautement : 150 derniers ms, ±4 dp',
      () {
        final r = runner(stationary(const []))..update(1.2 / 1.6);
        expect(r.fade, 0);
        r.update(1.5 / 1.6);
        expect(r.fade, closeTo(0.5, 1e-6));
        r.update(1);
        expect(r.fade, closeTo(1, 1e-9));
        expect(r.shakeDp.abs(), lessThan(1e-9));
        var peak = 0.0;
        for (var i = 0; i <= 100; i++) {
          r.update((1.45 + 0.15 * i / 100) / 1.6);
          peak = max(peak, r.shakeDp.abs());
        }
        expect(peak, inInclusiveRange(1, 4));
      },
    );

    test('saut : glissement de 160 ms vers le repos, sans discontinuité de '
        'position', () {
      final skip = DieSkipState();
      final r = runner(stationary(const []), skip: skip)..update(0.3);
      final before = r.x;
      skip.begin(0.3);
      r.update(0.3 + 1e-9);
      expect((r.x - before).abs(), lessThan(1e-3));
      r.update(0.3 + 0.35);
      final mid = r.x;
      expect(mid, greaterThan(before));
      expect(mid, lessThan(100));
      r.update(1);
      expect(r.x, closeTo(100, 1e-9));
      expect(r.y, closeTo(200, 1e-9));
      expect(r.h, 0);
    });

    test('orientation de repos exacte à la fin du saut', () {
      final skip = DieSkipState()..begin(0.2);
      final r = runner(stationary(const []), skip: skip)..update(1);
      final q = D20Orientation.forValue(7);
      // Même rotation (q et -q sont équivalents) : |produit scalaire| = 1.
      final dot = r.qw * q.w + r.qx * q.x + r.qy * q.y + r.qz * q.z;
      expect(dot.abs(), closeTo(1, 1e-9));
    });
  });
}
