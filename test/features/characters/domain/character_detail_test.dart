import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';

CharacterDetail _detail({
  List<CharacterDetailClassRow> classes = const [],
  int xp = 0,
  int currentHp = 10,
  int maxHp = 10,
  int temporaryHp = 0,
  Map<String, int> abilityScores = const {},
  List<CharacterInventoryItem> inventory = const [],
}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    classes: classes,
    xp: xp,
    currentHp: currentHp,
    maxHp: maxHp,
    temporaryHp: temporaryHp,
    abilityScores: abilityScores,
    inventory: inventory,
  );
}

void main() {
  group('CharacterDetail.totalLevel', () {
    test('somme les niveaux de toutes les classes (multiclassage)', () {
      final detail = _detail(
        classes: const [
          CharacterDetailClassRow(
            classId: 1,
            hitDie: 8,
            className: 'Guerrier',
            level: 3,
            isPrimary: true,
            savingThrowProficiencies: [],
          ),
          CharacterDetailClassRow(
            classId: 2,
            hitDie: 8,
            className: 'Magicien',
            level: 2,
            isPrimary: false,
            savingThrowProficiencies: [],
          ),
        ],
      );
      expect(detail.totalLevel, 5);
    });

    test('vaut 0 pour un personnage sans classe enregistrée', () {
      expect(_detail().totalLevel, 0);
    });
  });

  group('CharacterDetail.primaryClass / primarySavingThrowProficiencies', () {
    test(
      'retient la classe marquée is_primary, pas la première de la liste',
      () {
        final detail = _detail(
          classes: const [
            CharacterDetailClassRow(
              classId: 1,
              hitDie: 8,
              className: 'Guerrier',
              level: 1,
              isPrimary: false,
              savingThrowProficiencies: ['str', 'con'],
            ),
            CharacterDetailClassRow(
              classId: 2,
              hitDie: 8,
              className: 'Magicien',
              level: 4,
              isPrimary: true,
              savingThrowProficiencies: ['int', 'wis'],
            ),
          ],
        );

        expect(detail.primaryClass?.className, 'Magicien');
        expect(detail.primarySavingThrowProficiencies, {'int', 'wis'});
      },
    );

    test('retombe sur la première classe si aucune n\'est is_primary', () {
      final detail = _detail(
        classes: const [
          CharacterDetailClassRow(
            classId: 1,
            hitDie: 8,
            className: 'Guerrier',
            level: 1,
            isPrimary: false,
            savingThrowProficiencies: ['str', 'con'],
          ),
        ],
      );
      expect(detail.primaryClass?.className, 'Guerrier');
    });

    test('null/vide sans classe enregistrée', () {
      final detail = _detail();
      expect(detail.primaryClass, isNull);
      expect(detail.primarySavingThrowProficiencies, isEmpty);
    });
  });

  group('CharacterDetail.hpRatio', () {
    test('exclut les PV temporaires du ratio', () {
      final detail = _detail(currentHp: 15, maxHp: 30, temporaryHp: 20);
      expect(detail.hpRatio, 0.5);
    });

    test('vaut 0 si max_hp est nul ou négatif (robustesse)', () {
      expect(_detail(currentHp: 0, maxHp: 0).hpRatio, 0);
    });
  });

  group('CharacterDetail.xpProgress', () {
    test('0 en début de niveau, croît vers 1 au seuil suivant', () {
      final detail = _detail(
        classes: const [
          CharacterDetailClassRow(
            classId: 1,
            hitDie: 8,
            className: 'Guerrier',
            level: 1,
            isPrimary: true,
            savingThrowProficiencies: [],
          ),
        ],
        xp: 150, // à mi-chemin entre 0 (niv. 1) et 300 (niv. 2)
      );
      expect(detail.xpProgress, closeTo(0.5, 0.001));
    });

    test('pleine (1) au niveau maximum de la table de progression', () {
      final detail = _detail(
        classes: const [
          CharacterDetailClassRow(
            classId: 1,
            hitDie: 8,
            className: 'Guerrier',
            level: 20,
            isPrimary: true,
            savingThrowProficiencies: [],
          ),
        ],
        xp: 355000,
      );
      expect(detail.xpProgress, 1);
      expect(detail.nextLevelXpThreshold, isNull);
    });
  });

  group('CharacterDetail.inventoryWeight / carryingCapacity / isOverloaded', () {
    test('capacité = Force x 7,5 kg, Force par défaut 10 (absente)', () {
      expect(_detail().carryingCapacity, 75);
    });

    test('capacité dérivée du score de Force réel', () {
      expect(_detail(abilityScores: const {'str': 16}).carryingCapacity, 120);
    });

    test('poids total agrège CharacterInventoryItem.totalWeight', () {
      final detail = _detail(
        inventory: const [
          CharacterInventoryItem(
            id: '1',
            name: 'A',
            quantity: 1,
            equipped: false,
            totalWeight: 3,
          ),
          CharacterInventoryItem(
            id: '2',
            name: 'B',
            quantity: 1,
            equipped: false,
            totalWeight: 4,
          ),
        ],
      );
      expect(detail.inventoryWeight, 7);
    });

    test('isOverloaded faux quand le poids reste sous la capacité', () {
      final detail = _detail(
        abilityScores: const {'str': 10}, // capacité 75
        inventory: const [
          CharacterInventoryItem(
            id: '1',
            name: 'A',
            quantity: 1,
            equipped: false,
            totalWeight: 50,
          ),
        ],
      );
      expect(detail.isOverloaded, isFalse);
    });

    test('isOverloaded vrai quand le poids dépasse la capacité', () {
      final detail = _detail(
        abilityScores: const {'str': 8}, // capacité 60
        inventory: const [
          CharacterInventoryItem(
            id: '1',
            name: 'A',
            quantity: 1,
            equipped: false,
            totalWeight: 100,
          ),
        ],
      );
      expect(detail.isOverloaded, isTrue);
    });
  });

  group('CharacterDetail.attunedItemCount / attunementCap', () {
    test('attunementCap vaut 3 (RAW 5e)', () {
      expect(CharacterDetail.attunementCap, 3);
    });

    test('compte uniquement les objets isAttuned', () {
      final detail = _detail(
        inventory: const [
          CharacterInventoryItem(
            id: '1',
            name: 'Anneau',
            quantity: 1,
            equipped: false,
            requiresAttunement: true,
            isAttuned: true,
          ),
          CharacterInventoryItem(
            id: '2',
            name: 'Amulette',
            quantity: 1,
            equipped: false,
            requiresAttunement: true,
            isAttuned: false,
          ),
          CharacterInventoryItem(
            id: '3',
            name: 'Bâton',
            quantity: 1,
            equipped: false,
            requiresAttunement: true,
            isAttuned: true,
          ),
        ],
      );
      expect(detail.attunedItemCount, 2);
    });

    test('vaut 0 sur un inventaire vide', () {
      expect(_detail().attunedItemCount, 0);
    });
  });
}
