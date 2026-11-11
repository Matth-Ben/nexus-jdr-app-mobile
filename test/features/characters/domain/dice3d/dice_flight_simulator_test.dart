// Invariants de la simulation précalculée du lancer (P2b, addendum 2) sur
// 1 000 graines, pour 1 et 2 dés et plusieurs tailles d'écran. Pur Dart.

import 'dart:math';
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/dice3d/d20_orientation.dart';
import 'package:personnages/features/characters/domain/dice3d/dice_flight_simulator.dart';
import 'package:personnages/features/characters/presentation/widgets/dice/die_flight.dart';

class _Screen {
  const _Screen(this.name, this.size, this.padTop);

  final String name;
  final Size size;
  final double padTop;
}

const _screens = [
  _Screen('320x568', Size(320, 568), 20),
  _Screen('360x640', Size(360, 640), 24),
  _Screen('411x891', Size(411, 891), 24),
  _Screen('768x1024', Size(768, 1024), 24),
];

DiceArena _arena(_Screen s, int count, List<int> values) {
  final layout = DiceFlightLayout.compute(
    s.size,
    paddingTop: s.padTop,
    paddingBottom: 0,
    count: count,
  );
  return layout.arena([
    for (final v in values) D20Orientation.forValue(v),
  ], DiceFlightLayout.durationFor(count));
}

double _angle(List<double> q, double w, double x, double y, double z) {
  final dot = (q[3] * w + q[4] * x + q[5] * y + q[6] * z).abs().clamp(0.0, 1.0);
  return 2 * acos(dot);
}

void main() {
  const seeds = 1000;

  for (final screen in _screens) {
    for (final count in [1, 2]) {
      group('${screen.name}, $count dé(s) : 1 000 graines', () {
        late List<DiceFlightTrack?> tracks;
        late DiceArena arena0;

        setUpAll(() {
          tracks = [];
          for (var seed = 0; seed < seeds; seed++) {
            final values = [
              for (var i = 0; i < count; i++) 1 + (seed * 7 + i * 5) % 20,
            ];
            final arena = _arena(screen, count, values);
            if (seed == 0) arena0 = arena;
            tracks.add(DiceFlightSimulator.simulate(arena, Random(seed)));
          }
        });

        test('la simulation aboutit (jamais de repli niveau 0 sur ces '
            'écrans)', () {
          expect(tracks.where((t) => t == null).length, 0);
        });

        test('position finale = repos exact (< 0,01 dp), dès T - 0,25 s', () {
          for (var seed = 0; seed < seeds; seed++) {
            final t = tracks[seed]!;
            final a = _arena(screen, count, [
              for (var i = 0; i < count; i++) 1 + (seed * 7 + i * 5) % 20,
            ]);
            final lockIndex = ((t.duration - 0.25) * 120).round();
            final rest = [
              for (var d = 0; d < count; d++) (a.restX[d], a.restY[d]),
            ];
            for (var d = 0; d < count; d++) {
              for (final i in [lockIndex, t.sampleCount - 1]) {
                final s = t.sample(d, i);
                // Les repos peuvent être permutés (tri par x) : au moins un
                // repos coïncide, et deux dés occupent deux repos distincts.
                final hit = rest.any(
                  (r) =>
                      (s[0] - r.$1).abs() < 0.01 && (s[1] - r.$2).abs() < 0.01,
                );
                expect(hit, isTrue, reason: 'seed $seed die $d idx $i $s');
                expect(s[2], 0, reason: 'h final');
              }
            }
            if (count == 2) {
              final p0 = t.sample(0, t.sampleCount - 1);
              final p1 = t.sample(1, t.sampleCount - 1);
              expect((p0[0] - p1[0]).abs(), greaterThan(a.diameter));
            }
          }
        });

        test('quaternion final = orientation cible', () {
          for (var seed = 0; seed < seeds; seed++) {
            final t = tracks[seed]!;
            for (var d = 0; d < count; d++) {
              final value = 1 + (seed * 7 + d * 5) % 20;
              final q = D20Orientation.forValue(value);
              final s = t.sample(d, t.sampleCount - 1);
              expect(
                _angle(s, q.w, q.x, q.y, q.z),
                lessThan(1e-3),
                reason: 'seed $seed',
              );
              final lock = t.sample(d, ((t.duration - 0.25) * 120).round());
              expect(_angle(lock, q.w, q.x, q.y, q.z), lessThan(1e-3));
            }
          }
        });

        test('aucun NaN ni infini', () {
          for (final t in tracks) {
            for (final v in t!.samples) {
              expect(v.isNaN || v.isInfinite, isFalse);
            }
          }
        });

        test('même graine -> même piste', () {
          for (final seed in [0, 17, 404, 999]) {
            final values = [
              for (var i = 0; i < count; i++) 1 + (seed * 7 + i * 5) % 20,
            ];
            final again = DiceFlightSimulator.simulate(
              _arena(screen, count, values),
              Random(seed),
            )!;
            expect(again.samples, tracks[seed]!.samples);
            expect(again.impacts.length, tracks[seed]!.impacts.length);
          }
        });

        test('au plus 4 impacts au sol par dé, au moins un contact de mur', () {
          for (final t in tracks) {
            for (var d = 0; d < count; d++) {
              final landings = t!.impacts
                  .where((e) => e.kind == ImpactKind.landing && e.die == d)
                  .length;
              expect(landings, lessThanOrEqualTo(4));
            }
            expect(t!.impacts.any((e) => e.kind == ImpactKind.wall), isTrue);
          }
        });

        test('vitesse < 12 dp/s à T - 0,25 s et nulle ensuite', () {
          for (final t in tracks) {
            final lock = ((t!.duration - 0.25) * 120).round();
            for (var d = 0; d < count; d++) {
              final a = t.sample(d, lock - 1);
              final b = t.sample(d, lock);
              final speed =
                  sqrt(pow(b[0] - a[0], 2) + pow(b[1] - a[1], 2)) * 120;
              expect(speed, lessThan(12));
              final c = t.sample(d, lock + 3);
              expect(c[0], b[0]);
              expect(c[1], b[1]);
            }
          }
        });

        test('continuité : aucun saut de position d\'une image à l\'autre', () {
          final d = arena0.diameter;
          for (final t in tracks) {
            for (var die = 0; die < count; die++) {
              for (var i = 1; i < t!.sampleCount; i++) {
                final a = t.sample(die, i - 1);
                final b = t.sample(die, i);
                final jump = sqrt(pow(b[0] - a[0], 2) + pow(b[1] - a[1], 2));
                expect(jump, lessThan(0.35 * d), reason: 'saut de $jump dp');
              }
            }
          }
        });

        test('convergence d\'orientation sans saut (pas de snap)', () {
          for (final t in tracks) {
            for (var die = 0; die < count; die++) {
              for (var i = 1; i < t!.sampleCount; i++) {
                final a = t.sample(die, i - 1);
                final b = t.sample(die, i);
                expect(
                  _angle(a, b[3], b[4], b[5], b[6]),
                  lessThan(0.6),
                  reason:
                      'rotation de ${_angle(a, b[3], b[4], b[5], b[6])} rad',
                );
              }
            }
          }
        });

        if (count == 2) {
          test('au moins un choc dé-dé (vitesse relative >= 1,0·D dp/s entre '
              '0,3 et 1,0 s) et jamais de chevauchement ensuite', () {
            final r = arena0.radius;
            for (final t in tracks) {
              final shocks = t!.impacts
                  .where((e) => e.kind == ImpactKind.dieDie)
                  .toList();
              expect(shocks, isNotEmpty);
              expect(shocks.length, lessThanOrEqualTo(4));
              expect(shocks.first.t, inInclusiveRange(0.3, 1.0));
              final first = (shocks.first.t * 120).floor();
              for (var i = first; i < t.sampleCount; i++) {
                final a = t.sample(0, i);
                final b = t.sample(1, i);
                final dist = sqrt(pow(a[0] - b[0], 2) + pow(a[1] - b[1], 2));
                expect(
                  dist,
                  greaterThanOrEqualTo(1.88 * r - 0.01),
                  reason: 'idx $i',
                );
              }
            }
          });
        }
      });
    }
  }

  test('le Random du vol ne change jamais le résultat (les cibles sont des '
      'entrées)', () {
    final a = DiceFlightSimulator.simulate(
      _arena(_screens[1], 1, [13]),
      Random(1),
    )!;
    final b = DiceFlightSimulator.simulate(
      _arena(_screens[1], 1, [13]),
      Random(2),
    )!;
    final q = D20Orientation.forValue(13);
    for (final t in [a, b]) {
      final s = t.sample(0, t.sampleCount - 1);
      expect(_angle(s, q.w, q.x, q.y, q.z), lessThan(1e-3));
    }
  });
}
