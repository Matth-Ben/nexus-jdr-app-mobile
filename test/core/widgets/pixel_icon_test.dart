// Règles testables de `docs/p6-icones-conditions.md` (1 à 7) + peintre.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/pixel_icon.dart';
import 'package:personnages/core/widgets/pixel_icons/condition_pixel_icons.dart';
import 'package:personnages/features/characters/domain/condition_type.dart';

int _filled(String row) => '#'.allMatches(row).length;

int _hamming(List<String> a, List<String> b) {
  var distance = 0;
  for (var r = 0; r < 16; r++) {
    for (var c = 0; c < 16; c++) {
      if (a[r][c] != b[r][c]) distance++;
    }
  }
  return distance;
}

/// Nombre de bandes verticales : suites de lignes non vides séparées par au
/// moins une ligne vide. Une bande isolée du corps de l'icône est une
/// « ligne parasite ».
int _bands(List<String> m) {
  var bands = 0;
  var inBand = false;
  for (final row in m) {
    final filled = _filled(row) > 0;
    if (filled && !inBand) bands++;
    inBand = filled;
  }
  return bands;
}

void main() {
  group('kConditionPixelMatrices', () {
    test(
      'règle 1 : exactement les 14 clés, une par valeur de ConditionType',
      () {
        expect(kConditionPixelMatrices.length, 14);
        expect(
          kConditionPixelMatrices.keys.toSet(),
          ConditionType.values.map((c) => c.storageKey).toSet(),
        );
      },
    );

    test('règle 2 : 16 lignes de 16 caractères dans {., #}', () {
      kConditionPixelMatrices.forEach((key, matrix) {
        expect(matrix.length, 16, reason: key);
        for (final row in matrix) {
          expect(row.length, 16, reason: '$key : $row');
          expect(RegExp(r'^[.#]{16}$').hasMatch(row), isTrue, reason: key);
        }
      });
    });

    test('règle 3 : entre 20 et 150 cellules pleines', () {
      kConditionPixelMatrices.forEach((key, matrix) {
        final total = matrix.fold<int>(0, (s, row) => s + _filled(row));
        expect(total, inInclusiveRange(20, 150), reason: key);
      });
    });

    test('règle 4 : au moins 8 cellules pleines dans les lignes 2 à 13', () {
      kConditionPixelMatrices.forEach((key, matrix) {
        final middle = matrix
            .sublist(1, 13)
            .fold<int>(0, (s, row) => s + _filled(row));
        expect(middle, greaterThanOrEqualTo(8), reason: key);
      });
    });

    test('règle 5 : pas de ligne parasite (une seule bande de lignes non '
        'vides), sauf liste blanche des motifs en plusieurs parties', () {
      const multiPart = {'invisible', 'stunned', 'prone', 'unconscious'};
      kConditionPixelMatrices.forEach((key, matrix) {
        if (multiPart.contains(key)) return;
        expect(_bands(matrix), 1, reason: key);
      });
    });

    test('règle 6 : distance de Hamming >= 20 entre deux matrices', () {
      final entries = kConditionPixelMatrices.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        for (var j = i + 1; j < entries.length; j++) {
          expect(
            _hamming(entries[i].value, entries[j].value),
            greaterThanOrEqualTo(20),
            reason: '${entries[i].key} / ${entries[j].key}',
          );
        }
      }
    });
  });

  group('PixelIcon', () {
    testWidgets('règle 7 : enveloppé dans ExcludeSemantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: PixelIcon(matrix: kConditionPixelMatrices['charmed']!),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(PixelIcon),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(find.byType(PixelIcon)), const Size(32, 32));
    });

    test('règle 7 : rejette une taille non multiple de 16 (assert)', () {
      final matrix = kConditionPixelMatrices['charmed']!;
      expect(
        () => PixelIcon(matrix: matrix, size: 24),
        throwsA(isA<AssertionError>()),
      );
      expect(PixelIcon(matrix: matrix, size: 16), isA<PixelIcon>());
      expect(PixelIcon(matrix: matrix, size: 48), isA<PixelIcon>());
    });

    test('cellule arrondie à un multiple entier de pixels physiques', () {
      // 32 dp à dpr 2,625 : 2 dp -> 5,25 px -> 5 px physiques.
      final cell = PixelIconPainter.cellSize(32, 2.625);
      expect((cell * 2.625).roundToDouble(), closeTo(cell * 2.625, 1e-9));
      expect(PixelIconPainter.cellSize(16, 1), 1);
    });

    test(
      'les suites horizontales de # sont fusionnées en un seul rectangle',
      () {
        final rects = PixelIconPainter.runs(['##..#', '.....'], 2, Offset.zero);
        expect(rects, [
          const Rect.fromLTWH(0, 0, 4, 2),
          const Rect.fromLTWH(8, 0, 2, 2),
        ]);
      },
    );

    test('shouldRepaint : matrice ou couleur différente', () {
      const a = PixelIconPainter(
        matrix: ['#'],
        color: Colors.black,
        devicePixelRatio: 1,
      );
      expect(
        a.shouldRepaint(
          const PixelIconPainter(
            matrix: ['#'],
            color: Colors.black,
            devicePixelRatio: 1,
          ),
        ),
        isFalse,
      );
      expect(
        a.shouldRepaint(
          const PixelIconPainter(
            matrix: ['.'],
            color: Colors.black,
            devicePixelRatio: 1,
          ),
        ),
        isTrue,
      );
      expect(
        a.shouldRepaint(
          const PixelIconPainter(
            matrix: ['#'],
            color: Colors.red,
            devicePixelRatio: 1,
          ),
        ),
        isTrue,
      );
    });
  });
}
