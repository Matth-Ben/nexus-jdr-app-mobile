import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/domain/character_vital_status.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_role.dart';

GroupMember _member({
  int currentHp = 10,
  int maxHp = 20,
  bool isDead = false,
  String? raceName = 'Elfe',
  String? className = 'Rôdeur',
  int level = 3,
}) {
  return GroupMember(
    characterId: 'char-1',
    userId: 'user-1',
    role: GroupRole.membre,
    name: 'Sylvi',
    isGameMaster: false,
    level: level,
    currentHp: currentHp,
    maxHp: maxHp,
    temporaryHp: 0,
    isDead: isDead,
    raceName: raceName,
    className: className,
  );
}

void main() {
  group('GroupMember.vitalStatus', () {
    test('délègue à CharacterVitalStatusResolver', () {
      expect(_member().vitalStatus, CharacterVitalStatus.alive);
      expect(
        _member(currentHp: 0).vitalStatus,
        CharacterVitalStatus.unconscious,
      );
      expect(_member(isDead: true).vitalStatus, CharacterVitalStatus.dead);
    });
  });

  group('GroupMember.hpRatio', () {
    test('ratio normal', () {
      expect(_member(currentHp: 5, maxHp: 20).hpRatio, 0.25);
    });

    test('maxHp nul -> 0 (jamais de division par zéro)', () {
      expect(_member(currentHp: 0, maxHp: 0).hpRatio, 0);
    });

    test(
      'clampé à 1 même si currentHp > maxHp (PV temp. absorbés ailleurs)',
      () {
        expect(_member(currentHp: 25, maxHp: 20).hpRatio, 1);
      },
    );
  });

  group('GroupMember.summaryLine', () {
    test('race, classe et niveau présents', () {
      expect(_member().summaryLine, 'Elfe · Rôdeur · Niv. 3');
    });

    test('race personnalisée/non résolue omise', () {
      expect(_member(raceName: null).summaryLine, 'Rôdeur · Niv. 3');
    });

    test('sans classe enregistrée', () {
      expect(_member(className: null).summaryLine, 'Elfe · Niv. 3');
    });

    test('ni race ni classe : seul le niveau reste', () {
      expect(_member(raceName: null, className: null).summaryLine, 'Niv. 3');
    });
  });

  group(
    'GroupMember.isGameMaster — sourcé de la colonne DB, jamais dérivé',
    () {
      test('faux quand characterId est renseigné', () {
        expect(_member().isGameMaster, isFalse);
      });

      test(
        'vrai quand isGameMaster est posé explicitement (MJ volontaire)',
        () {
          const gameMaster = GroupMember(
            userId: 'user-mj',
            role: GroupRole.membre,
            name: 'MJ',
            isGameMaster: true,
          );
          expect(gameMaster.isGameMaster, isTrue);
          expect(gameMaster.isAwaitingCharacter, isFalse);
          expect(gameMaster.vitalStatus, isNull);
          expect(gameMaster.hpRatio, 0);
          expect(gameMaster.summaryLine, isEmpty);
        },
      );

      test('characterId null ET isGameMaster faux -> PAS un MJ (orphelin) — '
          'jamais dérivé de characterId seul', () {
        const orphan = GroupMember(
          userId: 'user-orphan',
          role: GroupRole.membre,
          name: "En attente d'un personnage",
          isGameMaster: false,
        );
        expect(orphan.isGameMaster, isFalse);
      });
    },
  );

  group('GroupMember.isAwaitingCharacter', () {
    test('vrai : characterId null et isGameMaster faux (orphelin)', () {
      const orphan = GroupMember(
        userId: 'user-orphan',
        role: GroupRole.membre,
        name: "En attente d'un personnage",
        isGameMaster: false,
      );
      expect(orphan.isAwaitingCharacter, isTrue);
      expect(orphan.vitalStatus, isNull);
      expect(orphan.hpRatio, 0);
      expect(orphan.summaryLine, isEmpty);
    });

    test('faux : characterId renseigné', () {
      expect(_member().isAwaitingCharacter, isFalse);
    });

    test('faux : MJ volontaire', () {
      const gameMaster = GroupMember(
        userId: 'user-mj',
        role: GroupRole.membre,
        name: 'MJ',
        isGameMaster: true,
      );
      expect(gameMaster.isAwaitingCharacter, isFalse);
    });
  });
}
