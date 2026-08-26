// Tests unitaires de la logique métier pure des 3 méthodes de génération
// des scores de caractéristiques de l'étape 4/9 "Caractéristiques"
// (`lib/features/character_creation/domain/ability_score_rules.dart`).

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/ability_score_method.dart';
import 'package:personnages/features/character_creation/domain/ability_score_rules.dart';

void main() {
  group('Tableau standard', () {
    test('assignation par défaut répartit les 6 valeurs du pool dans '
        "l'ordre décroissant sur For/Dex/Con/Int/Sag/Cha", () {
      final scores = AbilityScoreRules.defaultStandardArrayScores();

      expect(scores, {
        'str': 15,
        'dex': 14,
        'con': 13,
        'int': 12,
        'wis': 10,
        'cha': 8,
      });
    });

    test('swapUp échange la valeur avec la valeur immédiatement supérieure '
        'du pool, quelle que soit la caractéristique qui la détient', () {
      final scores = AbilityScoreRules.defaultStandardArrayScores();

      // 'wis' vaut 10, la valeur immédiatement supérieure est 12 ('int').
      final updated = AbilityScoreRules.swapUp(scores, 'wis');

      expect(updated['wis'], 12);
      expect(updated['int'], 10);
      // Le reste du pool est inchangé.
      expect(updated['str'], 15);
      expect(updated['dex'], 14);
      expect(updated['con'], 13);
      expect(updated['cha'], 8);
      // Le pool des 6 valeurs reste entier.
      expect(
        updated.values.toList()..sort(),
        AbilityScoreRules.standardArrayPool.toList()..sort(),
      );
    });

    test('swapDown échange la valeur avec la valeur immédiatement '
        'inférieure du pool', () {
      final scores = AbilityScoreRules.defaultStandardArrayScores();

      // 'int' vaut 12, la valeur immédiatement inférieure est 10 ('wis').
      final updated = AbilityScoreRules.swapDown(scores, 'int');

      expect(updated['int'], 10);
      expect(updated['wis'], 12);
    });

    test('canSwapUp est faux quand la caractéristique détient déjà la '
        'valeur maximale du pool (15)', () {
      final scores = AbilityScoreRules.defaultStandardArrayScores();

      expect(AbilityScoreRules.canSwapUp(scores, 'str'), isFalse);
      expect(
        AbilityScoreRules.swapUp(scores, 'str'),
        scores,
        reason: 'swapUp doit être un no-op si canSwapUp est faux',
      );
    });

    test('canSwapDown est faux quand la caractéristique détient déjà la '
        'valeur minimale du pool (8)', () {
      final scores = AbilityScoreRules.defaultStandardArrayScores();

      expect(AbilityScoreRules.canSwapDown(scores, 'cha'), isFalse);
      expect(
        AbilityScoreRules.swapDown(scores, 'cha'),
        scores,
        reason: 'swapDown doit être un no-op si canSwapDown est faux',
      );
    });

    test('des allers-retours de permutations répartissent toujours les 6 '
        'valeurs du pool sans duplication ni perte', () {
      var scores = AbilityScoreRules.defaultStandardArrayScores();

      scores = AbilityScoreRules.swapUp(scores, 'cha');
      scores = AbilityScoreRules.swapUp(scores, 'cha');
      scores = AbilityScoreRules.swapDown(scores, 'str');
      scores = AbilityScoreRules.swapUp(scores, 'wis');

      expect(
        scores.values.toList()..sort(),
        AbilityScoreRules.standardArrayPool.toList()..sort(),
      );
    });
  });

  group('Achat par points', () {
    test('assignation par défaut place toutes les caractéristiques à 8', () {
      final scores = AbilityScoreRules.defaultPointBuyScores();

      expect(scores.values, everyElement(8));
      expect(AbilityScoreRules.pointBuyRemaining(scores), 27);
    });

    test('pointBuyCost reflète la table officielle D&D 5e', () {
      expect(AbilityScoreRules.pointBuyCost(8), 0);
      expect(AbilityScoreRules.pointBuyCost(9), 1);
      expect(AbilityScoreRules.pointBuyCost(10), 2);
      expect(AbilityScoreRules.pointBuyCost(11), 3);
      expect(AbilityScoreRules.pointBuyCost(12), 4);
      expect(AbilityScoreRules.pointBuyCost(13), 5);
      expect(AbilityScoreRules.pointBuyCost(14), 7);
      expect(AbilityScoreRules.pointBuyCost(15), 9);
    });

    test('incrementPointBuy décrémente les points restants du coût '
        'marginal', () {
      final scores = AbilityScoreRules.defaultPointBuyScores();

      final updated = AbilityScoreRules.incrementPointBuy(scores, 'str');

      expect(updated['str'], 9);
      expect(AbilityScoreRules.pointBuyRemaining(updated), 26);
    });

    test('le coût marginal de 13 à 14 est bien de 2 points (7 - 5), pas 1', () {
      var scores = AbilityScoreRules.defaultPointBuyScores();
      for (var i = 0; i < 5; i++) {
        scores = AbilityScoreRules.incrementPointBuy(scores, 'str');
      }
      expect(scores['str'], 13);
      final remainingBefore = AbilityScoreRules.pointBuyRemaining(scores);

      scores = AbilityScoreRules.incrementPointBuy(scores, 'str');

      expect(scores['str'], 14);
      expect(remainingBefore - AbilityScoreRules.pointBuyRemaining(scores), 2);
    });

    test('canIncrementPointBuy est faux au-delà de 15 (score maximal)', () {
      var scores = AbilityScoreRules.defaultPointBuyScores();
      for (var i = 0; i < 7; i++) {
        scores = AbilityScoreRules.incrementPointBuy(scores, 'str');
      }

      expect(scores['str'], 15);
      expect(AbilityScoreRules.canIncrementPointBuy(scores, 'str'), isFalse);
      expect(
        AbilityScoreRules.incrementPointBuy(scores, 'str'),
        scores,
        reason: 'incrementPointBuy doit être un no-op au-delà de 15',
      );
    });

    test('canIncrementPointBuy est faux quand le budget restant ne couvre '
        'pas le coût marginal (budget épuisé)', () {
      // Dépense tout le budget sur 'str' (0+1+2+3+4+5+7+9 = 31 > 27, donc
      // le budget s'épuise avant d'atteindre 15).
      var scores = AbilityScoreRules.defaultPointBuyScores();
      while (AbilityScoreRules.canIncrementPointBuy(scores, 'str')) {
        scores = AbilityScoreRules.incrementPointBuy(scores, 'str');
      }

      // Coût cumulé pour atteindre 14 = 7, il reste 20 points, largement de
      // quoi passer à 15 (coût marginal 2) : 'str' doit donc pouvoir monter
      // jusqu'à son plafond naturel de 15 sans être bloquée par le budget
      // sur cette seule caractéristique.
      expect(scores['str'], 15);

      // Sur une caractéristique différente, la totalité du budget restant
      // (27 - 9 = 18) ne couvre plus le coût marginal vers 9 (1 point) :
      // faux — en réalité 18 >= 1, donc ce cas teste plutôt un budget worn
      // down sur plusieurs caractéristiques.
      var multi = AbilityScoreRules.defaultPointBuyScores();
      // Porte 5 caractéristiques à 14 (coût 7 chacune = 35, dépasse déjà 27
      // avant la fin) pour épuiser le budget avant d'atteindre le plafond.
      const keys = ['str', 'dex', 'con', 'int', 'wis'];
      for (final key in keys) {
        while (AbilityScoreRules.canIncrementPointBuy(multi, key) &&
            multi[key]! < 14) {
          multi = AbilityScoreRules.incrementPointBuy(multi, key);
        }
      }
      expect(AbilityScoreRules.pointBuyRemaining(multi), lessThan(2));
      expect(AbilityScoreRules.canIncrementPointBuy(multi, 'cha'), isFalse);
    });

    test('canDecrementPointBuy est faux quand la caractéristique est déjà '
        'à 8 (score minimal)', () {
      final scores = AbilityScoreRules.defaultPointBuyScores();

      expect(AbilityScoreRules.canDecrementPointBuy(scores, 'str'), isFalse);
      expect(
        AbilityScoreRules.decrementPointBuy(scores, 'str'),
        scores,
        reason: 'decrementPointBuy doit être un no-op à 8',
      );
    });

    test('decrementPointBuy restitue le coût marginal aux points restants', () {
      var scores = AbilityScoreRules.defaultPointBuyScores();
      scores = AbilityScoreRules.incrementPointBuy(scores, 'str');
      scores = AbilityScoreRules.incrementPointBuy(scores, 'str');
      final remainingAt10 = AbilityScoreRules.pointBuyRemaining(scores);

      scores = AbilityScoreRules.decrementPointBuy(scores, 'str');

      expect(scores['str'], 9);
      expect(AbilityScoreRules.pointBuyRemaining(scores), remainingAt10 + 1);
    });
  });

  group('Dés (4d6 drop lowest)', () {
    test('rollDiceScores avec un Random déterministe (seedé) produit des '
        'scores stables et dans la plage 3-18', () {
      final scores = AbilityScoreRules.rollDiceScores(Random(42));

      expect(scores.keys.toSet(), {'str', 'dex', 'con', 'int', 'wis', 'cha'});
      for (final score in scores.values) {
        expect(score, inInclusiveRange(3, 18));
      }
    });

    test('rollDiceScores est déterministe pour une même graine', () {
      final first = AbilityScoreRules.rollDiceScores(Random(7));
      final second = AbilityScoreRules.rollDiceScores(Random(7));

      expect(first, second);
    });

    test('les scores lancés forment un pool permutable comme le Tableau '
        'standard (swapUp/swapDown fonctionnent identiquement)', () {
      final scores = AbilityScoreRules.rollDiceScores(Random(1));
      final maxKey = scores.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;

      expect(AbilityScoreRules.canSwapUp(scores, maxKey), isFalse);
    });
  });

  group('defaultScoresFor', () {
    test(
      'bascule vers chaque méthode avec la bonne assignation par défaut',
      () {
        expect(
          AbilityScoreRules.defaultScoresFor(AbilityScoreMethod.standardArray),
          AbilityScoreRules.defaultStandardArrayScores(),
        );
        expect(
          AbilityScoreRules.defaultScoresFor(AbilityScoreMethod.pointBuy),
          AbilityScoreRules.defaultPointBuyScores(),
        );
        final diceScores = AbilityScoreRules.defaultScoresFor(
          AbilityScoreMethod.diceRoll,
          Random(3),
        );
        expect(diceScores.keys.toSet(), {
          'str',
          'dex',
          'con',
          'int',
          'wis',
          'cha',
        });
      },
    );
  });

  group('abilityModifier', () {
    test('reflète la table de modificateurs D&D 5e standard', () {
      expect(AbilityScoreRules.abilityModifier(1), -5);
      expect(AbilityScoreRules.abilityModifier(7), -2);
      expect(AbilityScoreRules.abilityModifier(8), -1);
      expect(AbilityScoreRules.abilityModifier(9), -1);
      expect(AbilityScoreRules.abilityModifier(10), 0);
      expect(AbilityScoreRules.abilityModifier(11), 0);
      expect(AbilityScoreRules.abilityModifier(12), 1);
      expect(AbilityScoreRules.abilityModifier(15), 2);
      expect(AbilityScoreRules.abilityModifier(20), 5);
    });
  });

  group('Achat par points — bornes exactes du budget restant', () {
    test("canIncrementPointBuy est vrai quand le budget restant est EXACTEMENT "
        "égal au coût marginal d'un achat à 2 points (13 -> 14)", () {
      // str=13 (coût 5), dex=15 (coût 9), con=15 (coût 9), int=10 (coût 2),
      // wis=8 (coût 0), cha=8 (coût 0) : coût total = 25, budget restant =
      // 27 - 25 = 2, pile la valeur du coût marginal 13 -> 14 (7 - 5 = 2).
      final scores = {
        'str': 13,
        'dex': 15,
        'con': 15,
        'int': 10,
        'wis': 8,
        'cha': 8,
      };

      expect(AbilityScoreRules.pointBuyRemaining(scores), 2);
      expect(AbilityScoreRules.canIncrementPointBuy(scores, 'str'), isTrue);

      final updated = AbilityScoreRules.incrementPointBuy(scores, 'str');

      expect(updated['str'], 14);
      expect(AbilityScoreRules.pointBuyRemaining(updated), 0);
      // Le budget est maintenant à 0 pile : plus aucun achat, même à 1
      // point, n'est permis sur une autre caractéristique.
      expect(AbilityScoreRules.canIncrementPointBuy(updated, 'wis'), isFalse);
    });

    test("canIncrementPointBuy est faux quand il manque tout juste 1 point au "
        'budget restant pour un achat à 2 points (14 -> 15)', () {
      // str=14 (coût 7), dex=15 (coût 9), con=14 (coût 7), int=11 (coût 3),
      // wis=8 (coût 0), cha=8 (coût 0) : coût total = 26, budget restant =
      // 1, insuffisant d'exactement 1 point pour le coût marginal 14 -> 15
      // (9 - 7 = 2).
      final scores = {
        'str': 14,
        'dex': 15,
        'con': 14,
        'int': 11,
        'wis': 8,
        'cha': 8,
      };

      expect(AbilityScoreRules.pointBuyRemaining(scores), 1);
      expect(AbilityScoreRules.canIncrementPointBuy(scores, 'str'), isFalse);
      expect(
        AbilityScoreRules.incrementPointBuy(scores, 'str'),
        scores,
        reason:
            'incrementPointBuy doit être un no-op quand le budget '
            'restant ne couvre pas le coût marginal, même à 1 point près',
      );
    });
  });

  group('Permutation avec des valeurs dupliquées dans le pool', () {
    // Contrairement au Tableau standard (6 valeurs distinctes par
    // construction : {15,14,13,12,10,8}), la méthode "Dés" peut produire des
    // doublons (deux 4d6-drop-lowest peuvent tomber sur la même somme). La
    // logique de permutation (swapUp/swapDown) doit rester correcte dans ce
    // cas : le pool des 6 valeurs ne doit jamais être perdu ni dupliqué.
    test('swapDown depuis une valeur maximale partagée par deux '
        "caractéristiques échange bien avec l'une des deux, sans perdre le "
        'pool', () {
      // 'str' et 'dex' partagent la valeur maximale (18).
      final scores = {
        'str': 18,
        'dex': 18,
        'con': 3,
        'int': 15,
        'wis': 12,
        'cha': 9,
      };

      // Aucune valeur du pool n'est strictement supérieure à 18 (dex vaut
      // 18, pas plus) : canSwapUp doit être faux malgré le doublon.
      expect(AbilityScoreRules.canSwapUp(scores, 'str'), isFalse);

      // La valeur immédiatement inférieure à 18 est 15 ('int').
      final updated = AbilityScoreRules.swapDown(scores, 'str');

      expect(updated['str'], 15);
      expect(updated['int'], 18);
      expect(updated['dex'], 18, reason: "l'autre 18 ('dex') est intact");
      expect(
        updated.values.toList()..sort(),
        scores.values.toList()..sort(),
        reason:
            'le pool des 6 valeurs doit être préservé (ni perdu, ni '
            'dupliqué)',
      );
    });

    test('swapUp vers une valeur cible partagée par deux autres '
        "caractéristiques échange avec l'une d'elles sans dupliquer ni perdre "
        'de valeur du pool', () {
      // 'str' et 'dex' partagent la valeur 10, immédiatement supérieure à
      // 'cha' (8).
      final scores = {
        'str': 10,
        'dex': 10,
        'con': 13,
        'int': 12,
        'wis': 15,
        'cha': 8,
      };

      final updated = AbilityScoreRules.swapUp(scores, 'cha');

      expect(updated['cha'], 10);
      // Le pool est préservé : la somme et le multiset des 6 valeurs sont
      // identiques à avant l'échange, quelle que soit la caractéristique
      // ('str' ou 'dex') choisie par l'implémentation comme partenaire de
      // l'échange.
      expect(updated.values.toList()..sort(), scores.values.toList()..sort());
      // Exactement une des deux ('str' ou 'dex') est retombée à 8 (l'autre
      // reste à 10) : le doublon n'a pas été dupliqué ni perdu.
      final formerHoldersAt8 = [
        updated['str'],
        updated['dex'],
      ].where((value) => value == 8).length;
      expect(formerHoldersAt8, 1);
    });

    test(
      'un pool de dés produit par rollDiceScores avec un Random truqué '
      'contenant des doublons reste permutable correctement (bout en bout)',
      () {
        // Dés truqués : force 'str' et 'dex' à obtenir exactement le même
        // résultat (4x un 6, drop lowest -> 18) pour vérifier que la
        // méthode "Dés" elle-même (pas seulement swapUp/swapDown sur une map
        // construite à la main) produit un pool correctement permutable en
        // présence de doublons.
        final rigged = _FixedRolls([
          5, 5, 5, 5, // str : 4x un 6 -> drop lowest -> 18
          5, 5, 5, 5, // dex : idem -> 18 (doublon avec str)
          0, 0, 0, 0, // con : 4x un 1 -> 3
          4, 4, 4, 0, // int : [1,5,5,5] -> drop le 1 -> 15
          3, 3, 3, 3, // wis : 4x un 4 -> 12
          2, 2, 2, 2, // cha : 4x un 3 -> 9
        ]);

        final scores = AbilityScoreRules.rollDiceScores(rigged);

        expect(scores, {
          'str': 18,
          'dex': 18,
          'con': 3,
          'int': 15,
          'wis': 12,
          'cha': 9,
        });
        expect(AbilityScoreRules.canSwapUp(scores, 'str'), isFalse);
        expect(AbilityScoreRules.canSwapUp(scores, 'dex'), isFalse);

        final updated = AbilityScoreRules.swapDown(scores, 'dex');
        expect(updated.values.toList()..sort(), scores.values.toList()..sort());
      },
    );
  });
}

/// [Random] truqué pour les tests : retourne une séquence fixe de valeurs
/// (au lieu d'un tirage réel), pour forcer `rollDiceScores` à produire des
/// doublons dans le pool de manière déterministe (voir groupe "Permutation
/// avec des valeurs dupliquées dans le pool" ci-dessus).
class _FixedRolls implements Random {
  _FixedRolls(this._values);

  final List<int> _values;
  int _index = 0;

  @override
  int nextInt(int max) {
    final value = _values[_index % _values.length];
    _index++;
    return value;
  }

  @override
  double nextDouble() => throw UnimplementedError();

  @override
  bool nextBool() => throw UnimplementedError();
}
