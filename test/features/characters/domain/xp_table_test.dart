import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/xp_table.dart';

void main() {
  group('XpTable.cumulativeXpForLevel', () {
    test('niveau 1 requiert 0 XP', () {
      expect(XpTable.cumulativeXpForLevel(1), 0);
    });

    test('reflète la table de progression standard D&D 5e', () {
      expect(XpTable.cumulativeXpForLevel(2), 300);
      expect(XpTable.cumulativeXpForLevel(5), 6500);
      expect(XpTable.cumulativeXpForLevel(11), 85000);
      expect(XpTable.cumulativeXpForLevel(20), 355000);
    });

    // Vérifie les 20 seuils un par un, exactement comme listés dans
    // `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 6 —
    // pas seulement quelques points de contrôle isolés : une erreur de
    // décalage d'un cran dans la table (ex. valeur du niveau 9 copiée au
    // niveau 8) ne serait pas détectée par les seuls points de contrôle
    // ci-dessus.
    test(
      'reflète exactement chaque seuil de la table du cahier des charges',
      () {
        const expectedByLevel = <int, int>{
          1: 0,
          2: 300,
          3: 900,
          4: 2700,
          5: 6500,
          6: 14000,
          7: 23000,
          8: 34000,
          9: 48000,
          10: 64000,
          11: 85000,
          12: 100000,
          13: 120000,
          14: 140000,
          15: 165000,
          16: 195000,
          17: 225000,
          18: 265000,
          19: 305000,
          20: 355000,
        };

        for (final entry in expectedByLevel.entries) {
          expect(
            XpTable.cumulativeXpForLevel(entry.key),
            entry.value,
            reason: 'Niveau ${entry.key} devrait requérir ${entry.value} XP',
          );
        }
      },
    );

    test('une valeur sous 1 est ramenée au niveau 1', () {
      expect(XpTable.cumulativeXpForLevel(0), 0);
      expect(XpTable.cumulativeXpForLevel(-5), 0);
    });

    test('une valeur au-delà du niveau max est ramenée au niveau max', () {
      expect(
        XpTable.cumulativeXpForLevel(25),
        XpTable.cumulativeXpForLevel(20),
      );
    });
  });

  group('XpTable.cumulativeXpForNextLevel', () {
    test('niveau 1 requiert le seuil du niveau 2 pour progresser', () {
      expect(XpTable.cumulativeXpForNextLevel(1), 300);
    });

    test('niveau 19 requiert le seuil du niveau 20', () {
      expect(XpTable.cumulativeXpForNextLevel(19), 355000);
    });

    test('niveau max (20) n\'a pas de niveau suivant', () {
      expect(XpTable.cumulativeXpForNextLevel(20), isNull);
    });

    test('un niveau au-delà du max n\'a pas non plus de niveau suivant', () {
      expect(XpTable.cumulativeXpForNextLevel(30), isNull);
    });

    // Défensif : ce cas ne devrait jamais se produire en pratique
    // (`character_repository.dart` garantit déjà un niveau minimum de 1),
    // mais un niveau de départ incohérent doit être ramené au niveau 1 avant
    // de calculer le seuil suivant, comme `cumulativeXpForLevel` le fait déjà
    // pour son propre paramètre.
    test('un niveau de départ incohérent (0 ou négatif) est ramené au niveau 1 '
        'avant de calculer le seuil suivant', () {
      expect(
        XpTable.cumulativeXpForNextLevel(0),
        XpTable.cumulativeXpForNextLevel(1),
      );
      expect(
        XpTable.cumulativeXpForNextLevel(-5),
        XpTable.cumulativeXpForNextLevel(1),
      );
    });

    // Chaque niveau (hors le dernier) doit pointer vers le seuil du niveau
    // immédiatement supérieur — garde-fou contre une erreur de décalage
    // d'index dans `_cumulativeXpByLevel`.
    test('pour chaque niveau < max, le seuil suivant correspond au niveau + 1', () {
      for (var level = 1; level < XpTable.maxLevel; level++) {
        expect(
          XpTable.cumulativeXpForNextLevel(level),
          XpTable.cumulativeXpForLevel(level + 1),
          reason:
              'Le niveau $level devrait pointer vers le seuil du niveau ${level + 1}',
        );
      }
    });
  });
}
