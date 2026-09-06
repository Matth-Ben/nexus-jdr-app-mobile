import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/spell_slot_change.dart';
import 'package:personnages/features/characters/domain/spell_slot_progression.dart';

void main() {
  group('SpellSlotProgression.slotsForLevel — lanceurs complets', () {
    test('niveau 1 : [2,0,0,0,0,0,0,0,0]', () {
      expect(SpellSlotProgression.slotsForLevel('Clerc', 1), [
        2,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ]);
    });

    test('niveau 3 (palier 1 renforcé + palier 2 débloqué) : '
        '[4,2,0,0,0,0,0,0,0]', () {
      expect(SpellSlotProgression.slotsForLevel('Druide', 3), [
        4,
        2,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ]);
    });

    test('niveau 9 (palier 5 débloqué) : [4,3,3,3,1,0,0,0,0]', () {
      expect(SpellSlotProgression.slotsForLevel('Magicien', 9), [
        4,
        3,
        3,
        3,
        1,
        0,
        0,
        0,
        0,
      ]);
    });

    test('niveau 17 (les 9 paliers débloqués) : [4,3,3,3,2,1,1,1,1]', () {
      expect(SpellSlotProgression.slotsForLevel('Ensorceleur', 17), [
        4,
        3,
        3,
        3,
        2,
        1,
        1,
        1,
        1,
      ]);
    });

    test('niveau 20 (table maximale) : [4,3,3,3,3,2,2,1,1]', () {
      expect(SpellSlotProgression.slotsForLevel('Barde', 20), [
        4,
        3,
        3,
        3,
        3,
        2,
        2,
        1,
        1,
      ]);
    });

    test('les 5 classes lanceuses complètes renvoient la même table à un '
        'niveau donné', () {
      for (final className in [
        'Barde',
        'Clerc',
        'Druide',
        'Magicien',
        'Ensorceleur',
      ]) {
        expect(SpellSlotProgression.slotsForLevel(className, 5), [
          4,
          3,
          2,
          0,
          0,
          0,
          0,
          0,
          0,
        ], reason: '$className niveau 5');
      }
    });
  });

  group('SpellSlotProgression.slotsForLevel — demi-lanceurs', () {
    test('niveau 1 : aucun emplacement (RAW, lancer de sorts démarre au '
        'niveau 2)', () {
      expect(
        SpellSlotProgression.slotsForLevel('Paladin', 1),
        List<int>.filled(9, 0),
      );
    });

    test('niveau 2 (1er palier débloqué) : [2,0,0,0,0,0,0,0,0]', () {
      expect(SpellSlotProgression.slotsForLevel('Rôdeur', 2), [
        2,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ]);
    });

    test('niveau 13 (palier 4 débloqué) : [4,3,3,1,0,0,0,0,0]', () {
      expect(SpellSlotProgression.slotsForLevel('Paladin', 13), [
        4,
        3,
        3,
        1,
        0,
        0,
        0,
        0,
        0,
      ]);
    });

    test('niveau 17 (palier 5 débloqué, plafond des demi-lanceurs) : '
        '[4,3,3,3,1,0,0,0,0]', () {
      expect(SpellSlotProgression.slotsForLevel('Rôdeur', 17), [
        4,
        3,
        3,
        3,
        1,
        0,
        0,
        0,
        0,
      ]);
    });

    test('niveau 20 : jamais de palier au-delà du niveau de sort 5 (index '
        '5-8 toujours à 0)', () {
      expect(SpellSlotProgression.slotsForLevel('Paladin', 20), [
        4,
        3,
        3,
        3,
        2,
        0,
        0,
        0,
        0,
      ]);
    });
  });

  group('SpellSlotProgression.slotsForLevel — hors périmètre visuel', () {
    test('classe non lanceuse -> 9 zéros à tout niveau', () {
      for (final level in [1, 5, 20]) {
        expect(
          SpellSlotProgression.slotsForLevel('Guerrier', level),
          List<int>.filled(9, 0),
          reason: 'Guerrier niveau $level',
        );
      }
    });

    test('Occultiste (magie de pacte) -> 9 zéros : géré séparément par '
        'pactMagicFor, jamais par slotsForLevel', () {
      expect(
        SpellSlotProgression.slotsForLevel('Occultiste', 5),
        List<int>.filled(9, 0),
      );
    });

    test('niveau de personnage hors 1-20 (défensif) -> 9 zéros', () {
      expect(
        SpellSlotProgression.slotsForLevel('Clerc', 0),
        List<int>.filled(9, 0),
      );
      expect(
        SpellSlotProgression.slotsForLevel('Clerc', 21),
        List<int>.filled(9, 0),
      );
    });
  });

  group('SpellSlotProgression.pactMagicFor — Occultiste', () {
    test('niveau 1 : 1 charge de niveau 1', () {
      expect(SpellSlotProgression.pactMagicFor(1), (charges: 1, slotLevel: 1));
    });

    test('niveau 2 : 2 charges de niveau 1', () {
      expect(SpellSlotProgression.pactMagicFor(2), (charges: 2, slotLevel: 1));
    });

    test('niveau 11 à 16 : 3 charges de niveau 5', () {
      for (final level in [11, 13, 16]) {
        expect(SpellSlotProgression.pactMagicFor(level), (
          charges: 3,
          slotLevel: 5,
        ), reason: 'niveau $level');
      }
    });

    test('niveau 17 à 20 : 4 charges de niveau 5', () {
      for (final level in [17, 19, 20]) {
        expect(SpellSlotProgression.pactMagicFor(level), (
          charges: 4,
          slotLevel: 5,
        ), reason: 'niveau $level');
      }
    });

    test('niveau hors 1-20 (défensif) -> null', () {
      expect(SpellSlotProgression.pactMagicFor(0), isNull);
      expect(SpellSlotProgression.pactMagicFor(21), isNull);
    });
  });

  group('SpellSlotProgression.changesFor', () {
    test('niveau 2 (Clerc) : le palier 1 se renforce (2 -> 3), cas B — déjà '
        'débloqué au niveau 1', () {
      final changes = SpellSlotProgression.changesFor(
        className: 'Clerc',
        targetLevel: 2,
      );
      expect(changes, [
        const SpellSlotChange(spellLevel: 1, oldTotal: 2, newTotal: 3),
      ]);
      expect(changes.single.isNewlyUnlocked, isFalse);
      expect(changes.single.delta, 1);
    });

    test('niveau 3 (Magicien) : un palier renforcé (cas B) ET un palier '
        'débloqué (cas A), triés par niveau de sort croissant', () {
      final changes = SpellSlotProgression.changesFor(
        className: 'Magicien',
        targetLevel: 3,
      );
      expect(changes, [
        const SpellSlotChange(spellLevel: 1, oldTotal: 3, newTotal: 4),
        const SpellSlotChange(spellLevel: 2, oldTotal: 0, newTotal: 2),
      ]);
      expect(changes[0].isNewlyUnlocked, isFalse);
      expect(changes[0].delta, 1);
      expect(changes[1].isNewlyUnlocked, isTrue);
    });

    test("niveau 4 (Magicien) : le palier 1 ne bouge pas (4 -> 4 aux deux "
        'niveaux) -> aucune entrée pour ce palier', () {
      final changes = SpellSlotProgression.changesFor(
        className: 'Magicien',
        targetLevel: 4,
      );
      expect(changes.where((change) => change.spellLevel == 1), isEmpty);
      expect(changes, [
        const SpellSlotChange(spellLevel: 2, oldTotal: 2, newTotal: 3),
      ]);
    });

    test('classe non lanceuse -> aucun changement (tables identiques, 9 '
        'zéros des deux côtés)', () {
      expect(
        SpellSlotProgression.changesFor(className: 'Guerrier', targetLevel: 5),
        isEmpty,
      );
    });

    test('Occultiste -> aucun changement via changesFor (hors périmètre '
        'visuel, magie de pacte gérée par pactMagicFor)', () {
      expect(
        SpellSlotProgression.changesFor(
          className: 'Occultiste',
          targetLevel: 5,
        ),
        isEmpty,
      );
    });

    test(
      'demi-lanceur (Paladin) niveau 2 : premier palier débloqué, cas A',
      () {
        final changes = SpellSlotProgression.changesFor(
          className: 'Paladin',
          targetLevel: 2,
        );
        expect(changes, [
          const SpellSlotChange(spellLevel: 1, oldTotal: 0, newTotal: 2),
        ]);
      },
    );
  });

  group('SpellSlotChange', () {
    test('égalité structurelle', () {
      expect(
        const SpellSlotChange(spellLevel: 1, oldTotal: 2, newTotal: 3),
        const SpellSlotChange(spellLevel: 1, oldTotal: 2, newTotal: 3),
      );
    });

    test(
      'isNewlyUnlocked faux si oldTotal > 0, même si newTotal > oldTotal',
      () {
        expect(
          const SpellSlotChange(
            spellLevel: 1,
            oldTotal: 3,
            newTotal: 4,
          ).isNewlyUnlocked,
          isFalse,
        );
      },
    );
  });

  group('SpellSlotProgression.isNonPactCasterClass', () {
    test('lanceur complet -> true', () {
      expect(SpellSlotProgression.isNonPactCasterClass('Clerc'), isTrue);
    });

    test('demi-lanceur -> true', () {
      expect(SpellSlotProgression.isNonPactCasterClass('Paladin'), isTrue);
    });

    test('Occultiste (magie de pacte) -> false', () {
      expect(SpellSlotProgression.isNonPactCasterClass('Occultiste'), isFalse);
    });

    test('classe non lanceuse -> false', () {
      expect(SpellSlotProgression.isNonPactCasterClass('Guerrier'), isFalse);
    });
  });

  group('SpellSlotProgression.combinedCasterLevel', () {
    test('un seul lanceur complet -> son propre niveau', () {
      expect(
        SpellSlotProgression.combinedCasterLevel([
          (className: 'Clerc', level: 5),
        ]),
        5,
      );
    });

    test(
      "un seul demi-lanceur -> niveau divise par 2 arrondi a l'inferieur",
      () {
        expect(
          SpellSlotProgression.combinedCasterLevel([
            (className: 'Paladin', level: 5),
          ]),
          2,
        );
      },
    );

    test('demi-lanceur niveau 4 + lanceur complet niveau 1 -> floor(4/2) + 1 '
        '= 3 (exemple RAW Paladin/Clerc)', () {
      expect(
        SpellSlotProgression.combinedCasterLevel([
          (className: 'Paladin', level: 4),
          (className: 'Clerc', level: 1),
        ]),
        3,
      );
    });

    test('deux lanceurs complets -> somme brute des niveaux', () {
      expect(
        SpellSlotProgression.combinedCasterLevel([
          (className: 'Magicien', level: 3),
          (className: 'Ensorceleur', level: 2),
        ]),
        5,
      );
    });

    test('Occultiste ignore meme present dans la liste (magie de pacte, '
        'jamais combinee)', () {
      expect(
        SpellSlotProgression.combinedCasterLevel([
          (className: 'Clerc', level: 5),
          (className: 'Occultiste', level: 10),
        ]),
        5,
      );
    });

    test('aucune classe -> 0', () {
      expect(SpellSlotProgression.combinedCasterLevel([]), 0);
    });

    test('cape a 20 (defensif)', () {
      expect(
        SpellSlotProgression.combinedCasterLevel([
          (className: 'Magicien', level: 20),
          (className: 'Ensorceleur', level: 20),
        ]),
        20,
      );
    });
  });

  group('SpellSlotProgression.multiclassSlotsForCombinedLevel', () {
    test('niveau combine 0 -> 9 zeros', () {
      expect(
        SpellSlotProgression.multiclassSlotsForCombinedLevel(0),
        List<int>.filled(9, 0),
      );
    });

    test('niveau combine 3 -> table lanceur complet niveau 3 : '
        '[4,2,0,0,0,0,0,0,0]', () {
      expect(SpellSlotProgression.multiclassSlotsForCombinedLevel(3), [
        4,
        2,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ]);
    });
  });

  group('SpellSlotProgression.totalsForClasses', () {
    test('aucune classe lanceuse -> 9 zeros', () {
      expect(
        SpellSlotProgression.totalsForClasses([
          (className: 'Guerrier', level: 5),
        ]),
        List<int>.filled(9, 0),
      );
    });

    test('une seule classe lanceuse "non-pacte" -> identique a slotsForLevel '
        '(jamais le calcul combine pour un mono-lanceur)', () {
      expect(
        SpellSlotProgression.totalsForClasses([(className: 'Clerc', level: 5)]),
        SpellSlotProgression.slotsForLevel('Clerc', 5),
      );
    });

    test('deux classes lanceuses "non-pacte" -> bascule sur le calcul '
        'combine (exemple RAW Paladin niveau 4 + Clerc niveau 1)', () {
      expect(
        SpellSlotProgression.totalsForClasses([
          (className: 'Paladin', level: 4),
          (className: 'Clerc', level: 1),
        ]),
        [4, 2, 0, 0, 0, 0, 0, 0, 0],
      );
    });

    test('Occultiste multiclasse avec un vrai lanceur -> magie de pacte '
        'ignoree, seul le lanceur "non-pacte" compte (mono-lanceur)', () {
      expect(
        SpellSlotProgression.totalsForClasses([
          (className: 'Occultiste', level: 10),
          (className: 'Clerc', level: 5),
        ]),
        SpellSlotProgression.slotsForLevel('Clerc', 5),
      );
    });
  });

  group('SpellSlotProgression.resolveChangesForLevelUp - multiclassage', () {
    test('multiclassage frais (niveau 1 dans une nouvelle classe lanceuse) '
        'depuis une seule classe deja lanceuse : bascule sur le total '
        'combine, jamais un simple changesFor de la classe existante', () {
      final changes = SpellSlotProgression.resolveChangesForLevelUp(
        beforeClasses: [(className: 'Paladin', level: 4)],
        afterClasses: [
          (className: 'Paladin', level: 4),
          (className: 'Clerc', level: 1),
        ],
      );
      // Avant (Paladin seul niveau 4, mono-lanceur : slotsForLevel direct)
      // : [3,0,...]. Apres (2 lanceurs "non-pacte" -> calcul combine niveau
      // 3) : [4,2,0,...].
      expect(changes, [
        const SpellSlotChange(spellLevel: 1, oldTotal: 3, newTotal: 4),
        const SpellSlotChange(spellLevel: 2, oldTotal: 0, newTotal: 2),
      ]);
    });

    test("multiclassage dans l'Occultiste depuis un lanceur \"non-pacte\" "
        'existant -> aucun changement (la magie de pacte ne fait jamais '
        'partie du total "non-pacte")', () {
      final changes = SpellSlotProgression.resolveChangesForLevelUp(
        beforeClasses: [(className: 'Clerc', level: 5)],
        afterClasses: [
          (className: 'Clerc', level: 5),
          (className: 'Occultiste', level: 1),
        ],
      );
      expect(changes, isEmpty);
    });

    test('personnage mono-classe qui continue (comportement historique '
        'inchange) : equivaut a changesFor', () {
      final changes = SpellSlotProgression.resolveChangesForLevelUp(
        beforeClasses: [(className: 'Magicien', level: 2)],
        afterClasses: [(className: 'Magicien', level: 3)],
      );
      expect(
        changes,
        SpellSlotProgression.changesFor(className: 'Magicien', targetLevel: 3),
      );
    });
  });
}
