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
}
