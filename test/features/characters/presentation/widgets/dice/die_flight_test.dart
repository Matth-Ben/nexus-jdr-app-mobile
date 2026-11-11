// Trajectoire cosmétique du dé lancé sur la page entière (P2b, addendum) :
// logique pure.

import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/dice/die_flight.dart';

void main() {
  const screen = Size(390, 844);
  final table = tableRect(screen, top: 47, bottom: 34);

  test('table : écran moins zones système, marge de 8 dp', () {
    expect(table, const Rect.fromLTRB(8, 55, 382, 802));
  });

  test('tailles : 176 / 136 (tablette 220 / 168), écart de 16', () {
    expect(DieFlightSizes.single(390), 176);
    expect(DieFlightSizes.single(600), 220);
    expect(DieFlightSizes.pair(390), 136);
    expect(DieFlightSizes.pair(800), 168);
    expect(DieFlightSizes.pairGap, 16);
  });

  test('repos au-dessus de la feuille : centré, milieu de la zone libre', () {
    final one = restPoints(table: table, sheetTop: 500, dieSize: 176, count: 1);
    expect(one.single.dx, table.center.dx);
    expect(one.single.dy, closeTo((table.top + 492) / 2, 1e-9));
    final two = restPoints(table: table, sheetTop: 500, dieSize: 136, count: 2);
    expect(two[1].dx - two[0].dx, 136 + 16);
    expect((two[0].dx + two[1].dx) / 2, table.center.dx);
  });

  group('plan de vol', () {
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

    test('le centre reste borné par le rayon une fois entré', () {
      for (var seed = 0; seed < 20; seed++) {
        final p = plan(seed);
        for (var i = 25; i <= 100; i++) {
          final g = p.groundAt(i / 100);
          expect(g.dx, greaterThanOrEqualTo(table.left + 74 - 1e-6));
          expect(g.dx, lessThanOrEqualTo(table.right - 74 + 1e-6));
          expect(g.dy, greaterThanOrEqualTo(table.top + 74 - 1e-6));
          expect(g.dy, lessThanOrEqualTo(table.bottom + 1e-6));
        }
      }
    });

    test('au moins deux contacts de bord (~35 % et ~55 %)', () {
      for (var seed = 0; seed < 20; seed++) {
        final p = plan(seed);
        final side = p.groundAt(0.35);
        final top = p.groundAt(0.55);
        final onSide =
            (side.dx - (table.left + 74)).abs() < 1e-6 ||
            (side.dx - (table.right - 74)).abs() < 1e-6;
        expect(onSide, isTrue, reason: 'seed $seed');
        expect(top.dy, closeTo(table.top + 74, 1e-6));
      }
    });

    test(
      'déterministe pour un Random donné, variable d\'un Random à l\'autre',
      () {
        expect(plan(3).groundAt(0.3), plan(3).groundAt(0.3));
        final spread = {for (var s = 0; s < 10; s++) plan(s).groundAt(0.1)};
        expect(spread.length, greaterThan(1));
      },
    );
  });

  group('hauteur et échelle de vol', () {
    test('au sol à l\'entrée et dès 70 %, rebonds 100 % puis 35 %', () {
      expect(DieFlightPlan.heightAt(0), 0);
      expect(DieFlightPlan.heightAt(0.25), 0);
      expect(DieFlightPlan.heightAt(0.70), closeTo(0, 1e-9));
      expect(DieFlightPlan.heightAt(1), 0);
      final first = DieFlightPlan.heightAt(0.30);
      final second = DieFlightPlan.heightAt(0.45);
      expect(first, closeTo(1, 1e-9));
      expect(second, closeTo(0.35, 1e-9));
      // Contacts (hauteur nulle) à ~35 % et ~55 %.
      expect(DieFlightPlan.heightAt(0.35), closeTo(0, 1e-9));
      expect(DieFlightPlan.heightAt(0.55), closeTo(0, 1e-9));
    });

    test('échelle de vol = 1 + 0,25 · hauteur (1 à 1,25)', () {
      for (var i = 0; i <= 100; i++) {
        final s = DieFlightPlan.flightScale(i / 100);
        expect(s, inInclusiveRange(1, 1.25 + 1e-9));
      }
      expect(DieFlightPlan.flightScale(1), 1);
    });
  });
}
