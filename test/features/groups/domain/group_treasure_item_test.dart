// Tests de `GroupTreasureItem` : sérialisation jsonb de `group_treasure.items`
// (décision 91), entrées anciennes comprises.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/custom_item_enrichment.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';

void main() {
  group('entrées anciennes (avant la décision 91)', () {
    test('objet du catalogue : lu puis réécrit à l\'identique', () {
      const json = {'item_id': 7, 'display_name': 'Bouclier', 'quantity': 2};
      final item = GroupTreasureItem.fromJson(json);
      expect(item.entryId, isNull);
      expect(item.itemId, 7);
      expect(item.isCustom, isFalse);
      expect(item.category, isNull);
      expect(item.enrichment, isNull);
      expect(item.toJson(), json);
    });

    test('objet personnalisé : lu puis réécrit à l\'identique', () {
      const json = {
        'custom_name': 'Amulette',
        'display_name': 'Amulette',
        'quantity': 1,
      };
      final item = GroupTreasureItem.fromJson(json);
      expect(item.isCustom, isTrue);
      expect(item.customDescription, isNull);
      expect(item.customProperties, isEmpty);
      expect(item.toJson(), json);
    });

    test('fromJson tolère les champs manquants (défauts sûrs)', () {
      final item = GroupTreasureItem.fromJson(const {});
      expect(item.entryId, isNull);
      expect(item.itemId, isNull);
      expect(item.customName, isNull);
      expect(item.displayName, '');
      expect(item.quantity, 0);
      expect(item.enrichment, isNull);
    });
  });

  group('entrées complètes', () {
    test('objet personnalisé enrichi : aller-retour jsonb complet, clés aux '
        'noms des colonnes de character_inventory', () {
      final item = GroupTreasureItem.custom(
        entryId: 'e-1',
        name: 'Épée runique',
        quantity: 1,
        description: 'Gravée de runes.',
        damageDice: '1d8',
        damageType: 'tranchant',
        properties: ['polyvalente(1d10)'],
        enrichment: const CustomItemEnrichment(
          kind: CustomItemKinds.weapon,
          magicBonus: 1,
          weight: 1.5,
          requiresAttunement: true,
          weaponCategory: CustomWeaponCategories.martial,
          weaponRange: CustomWeaponRanges.melee,
        ),
      );
      final json = item.toJson();
      expect(json, {
        'entry_id': 'e-1',
        'custom_name': 'Épée runique',
        'display_name': 'Épée runique',
        'quantity': 1,
        'custom_description': 'Gravée de runes.',
        'custom_damage_dice': '1d8',
        'custom_damage_type': 'tranchant',
        'custom_properties': ['polyvalente(1d10)'],
        'custom_kind': 'arme',
        'custom_magic_bonus': 1,
        'custom_weight': 1.5,
        'custom_requires_attunement': true,
        'custom_weapon_category': 'guerre',
        'custom_weapon_range': 'melee',
      });
      expect(GroupTreasureItem.fromJson(json), item);
    });

    test('armure personnalisée : CA et catégorie conservées', () {
      final item = GroupTreasureItem.custom(
        entryId: 'e-2',
        name: 'Cotte elfique',
        quantity: 1,
        enrichment: const CustomItemEnrichment(
          kind: CustomItemKinds.armor,
          acBase: 14,
          armorCategory: CustomArmorCategories.medium,
        ),
      );
      final back = GroupTreasureItem.fromJson(item.toJson());
      expect(back.enrichment?.acBase, 14);
      expect(back.enrichment?.armorCategory, 'intermediaire');
      expect(back, item);
    });

    test('objet du catalogue : instantané catégorie/poids', () {
      const item = GroupTreasureItem.catalog(
        itemId: 9,
        displayName: 'Dague',
        quantity: 2,
        category: 'arme',
        weight: 0.5,
      );
      expect(item.toJson(), {
        'item_id': 9,
        'display_name': 'Dague',
        'quantity': 2,
        'category': 'arme',
        'weight': 0.5,
      });
    });

    test('custom() : textes vides ramenés à null, enrichissement vide et '
        '« Harmoniser maintenant » jamais gardés', () {
      final item = GroupTreasureItem.custom(
        name: 'Babiole',
        quantity: 1,
        description: '  ',
        damageDice: '',
        enrichment: const CustomItemEnrichment(attuneNow: true),
      );
      expect(item.customDescription, isNull);
      expect(item.customDamageDice, isNull);
      expect(item.enrichment, isNull);

      final kept = GroupTreasureItem.custom(
        name: 'Anneau',
        quantity: 1,
        enrichment: const CustomItemEnrichment(
          kind: CustomItemKinds.other,
          requiresAttunement: true,
          attuneNow: true,
        ),
      );
      expect(kept.enrichment?.attuneNow, isFalse);
      expect(kept.enrichment?.requiresAttunement, isTrue);
    });

    test('valeurs custom_* hors ensemble ou de mauvais type ignorées', () {
      final item = GroupTreasureItem.fromJson(const {
        'custom_name': 'Truc',
        'display_name': 'Truc',
        'quantity': 1,
        'custom_kind': 'dragon',
        'custom_magic_bonus': 9,
        'custom_ac_base': 'quinze',
        'custom_properties': ['ok', 3],
      });
      expect(item.enrichment, isNull);
      expect(item.customProperties, ['ok']);
    });

    test('clé inconnue (version plus récente) conservée à la réécriture', () {
      const json = {
        'entry_id': 'e-3',
        'item_id': 1,
        'display_name': 'Épée',
        'quantity': 1,
        'future_key': {'a': 1},
      };
      final item = GroupTreasureItem.fromJson(json);
      expect(item.extra, {
        'future_key': {'a': 1},
      });
      expect(item.toJson()['future_key'], {'a': 1});
      expect(item.copyWith(quantity: 2).toJson()['future_key'], {'a': 1});
    });
  });

  group('égalité et contenu', () {
    test('== compare tout le contenu, quantité et entry_id compris', () {
      const a = GroupTreasureItem(
        entryId: 'e',
        itemId: 1,
        displayName: 'Épée',
        quantity: 1,
      );
      expect(a, a.copyWith());
      expect(a == a.copyWith(quantity: 2), isFalse);
      expect(a == a.copyWith(entryId: 'f'), isFalse);
      expect(a.hashCode, a.copyWith().hashCode);
    });

    test('sameContentAs ignore entry_id et quantité, pas la description', () {
      final a = GroupTreasureItem.custom(
        entryId: 'x',
        name: 'Fiole',
        quantity: 1,
        description: 'Bleue',
      );
      final b = GroupTreasureItem.custom(
        entryId: 'y',
        name: 'Fiole',
        quantity: 5,
        description: 'Bleue',
      );
      final c = GroupTreasureItem.custom(
        name: 'Fiole',
        quantity: 1,
        description: 'Rouge',
      );
      expect(a.sameContentAs(b), isTrue);
      expect(a.sameContentAs(c), isFalse);
    });

    test('copyWith ne change que la quantité et l\'entry_id', () {
      const item = GroupTreasureItem(
        itemId: 1,
        displayName: 'Épée',
        quantity: 2,
        category: 'arme',
      );
      final updated = item.copyWith(quantity: 5, entryId: 'e');
      expect(updated.quantity, 5);
      expect(updated.entryId, 'e');
      expect(updated.itemId, 1);
      expect(updated.category, 'arme');
    });
  });
}
