// Tests des règles d'édition de `group_treasure.items` (décision 91) :
// identifiant stable `entry_id` et garde de concurrence (l'entrée vue par
// le joueur a-t-elle disparu ou changé avant l'écriture ?).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/domain/group_treasure_items.dart';

void main() {
  late int counter;
  String newId() => 'id-${++counter}';
  setUp(() => counter = 0);

  const legacyPotion = GroupTreasureItem(
    itemId: 7,
    displayName: 'Potion',
    quantity: 3,
  );
  final rope = GroupTreasureItem.custom(
    entryId: 'rope',
    name: 'Corde elfique',
    quantity: 1,
    description: 'Ne casse jamais.',
  );

  group('entry_id', () {
    test('les entrées anciennes en reçoivent un à la première écriture, '
        'jamais les autres', () {
      final result = GroupTreasureItems.withEntryIds([
        legacyPotion,
        rope,
      ], newId: newId);
      expect(result.first.entryId, 'id-1');
      // Contenu inchangé, seul l'identifiant s'ajoute.
      expect(result.first.toJson()..remove('entry_id'), legacyPotion.toJson());
      expect(result.last, rope);
    });

    test('identifiants générés par défaut : UUID v4 distincts', () {
      final result = GroupTreasureItems.withEntryIds([
        legacyPotion,
        legacyPotion,
      ]);
      expect(result.first.entryId, isNot(result.last.entryId));
      expect(
        result.first.entryId,
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-')),
      );
    });

    test('renommer un objet garde son entry_id (remplacement)', () {
      final renamed = GroupTreasureItem.custom(
        name: 'Corde des elfes',
        quantity: 1,
      );
      final result = GroupTreasureItems.replace([rope], rope, renamed)!;
      expect(result.single.entryId, 'rope');
      expect(result.single.customName, 'Corde des elfes');
    });
  });

  group('indexOfUnchanged (concurrence)', () {
    test('entrée inchangée retrouvée par entry_id, même déplacée', () {
      final items = [legacyPotion.copyWith(entryId: 'p'), rope];
      expect(
        GroupTreasureItems.indexOfUnchanged(items.reversed.toList(), rope),
        0,
      );
    });

    test('entrée disparue -> -1', () {
      expect(GroupTreasureItems.indexOfUnchanged([], rope), -1);
    });

    test('entrée modifiée (quantité ou contenu) -> -1', () {
      expect(
        GroupTreasureItems.indexOfUnchanged([rope.copyWith(quantity: 2)], rope),
        -1,
      );
      final renamed = GroupTreasureItem.custom(
        entryId: 'rope',
        name: 'Autre',
        quantity: 1,
      );
      expect(GroupTreasureItems.indexOfUnchanged([renamed], rope), -1);
    });

    test('entrée ancienne : retrouvée seulement si le tableau n\'a pas été '
        'réécrit entre-temps', () {
      expect(
        GroupTreasureItems.indexOfUnchanged([legacyPotion], legacyPotion),
        0,
      );
      final rewritten = GroupTreasureItems.withEntryIds([legacyPotion]);
      expect(GroupTreasureItems.indexOfUnchanged(rewritten, legacyPotion), -1);
    });
  });

  group('merge (ajout)', () {
    test('objet du catalogue déjà présent : quantité additionnée, entrée '
        'ancienne complétée par l\'instantané du catalogue', () {
      const addition = GroupTreasureItem.catalog(
        itemId: 7,
        displayName: 'Potion',
        quantity: 2,
        category: 'equipement_general',
        weight: 0.5,
      );
      final result = GroupTreasureItems.merge(
        [legacyPotion],
        [addition],
        newId: newId,
      );
      expect(result, hasLength(1));
      expect(result.single.quantity, 5);
      expect(result.single.entryId, 'id-1');
      expect(result.single.category, 'equipement_general');
      expect(result.single.weight, 0.5);
    });

    test('objet personnalisé : fusion seulement si le contenu est '
        'identique ; sinon nouvelle entrée avec entry_id', () {
      final same = GroupTreasureItem.custom(
        name: 'Corde elfique',
        quantity: 2,
        description: 'Ne casse jamais.',
      );
      final other = GroupTreasureItem.custom(
        name: 'Corde elfique',
        quantity: 1,
        description: 'Effilochée.',
      );
      final result = GroupTreasureItems.merge(
        [rope],
        [same, other],
        newId: newId,
      );
      expect(result, hasLength(2));
      expect(result.first.quantity, 3);
      expect(result.first.entryId, 'rope');
      expect(result.last.entryId, 'id-1');
      expect(result.last.customDescription, 'Effilochée.');
    });
  });

  group('remove / replace / claim', () {
    test('remove retire tous les exemplaires ; null si l\'entrée a changé', () {
      expect(GroupTreasureItems.remove([rope], rope), isEmpty);
      expect(
        GroupTreasureItems.remove([rope.copyWith(quantity: 4)], rope),
        isNull,
      );
    });

    test('replace : null si l\'entrée a disparu', () {
      expect(GroupTreasureItems.replace([], rope, rope), isNull);
    });

    test('claim partiel : quantité restante, entrée attribuée complète', () {
      final potion = legacyPotion.copyWith(entryId: 'p');
      final claim = GroupTreasureItems.claim([potion, rope], potion, 2)!;
      expect(claim.items.first.quantity, 1);
      expect(claim.items.first.entryId, 'p');
      expect(claim.claimed.quantity, 2);
      expect(claim.claimed.itemId, 7);
    });

    test(
      'claim total : l\'entrée disparaît ; entrées anciennes identifiées',
      () {
        final claim = GroupTreasureItems.claim(
          [legacyPotion, rope],
          rope,
          1,
          newId: newId,
        )!;
        expect(claim.items.single.itemId, 7);
        expect(claim.items.single.entryId, 'id-1');
        expect(claim.claimed.customDescription, 'Ne casse jamais.');
      },
    );

    test(
      'claim refusé : entrée attribuée entre-temps, quantité hors bornes',
      () {
        expect(
          GroupTreasureItems.claim([rope.copyWith(quantity: 0)], rope, 1),
          isNull,
        );
        expect(GroupTreasureItems.claim([rope], rope, 2), isNull);
        expect(GroupTreasureItems.claim([rope], rope, 0), isNull);
      },
    );
  });
}
