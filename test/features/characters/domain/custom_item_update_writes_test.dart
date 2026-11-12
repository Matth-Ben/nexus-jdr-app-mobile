// P7 PR 4 : op `updateCustom` de la file `inventoryItem` — payload, validation
// stricte (enfilage ET rejeu), colonnes de l'UPDATE (null explicites),
// superposition, fusion avec un ajout / un usage en file, remplacement par une
// seconde modification, anciens payloads.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/custom_item_enrichment.dart';
import 'package:personnages/features/characters/domain/offline_inventory_writes.dart';
import 'package:personnages/features/characters/domain/offline_state_writes.dart';

const _armor = CustomItemEnrichment(
  kind: CustomItemKinds.armor,
  acBase: 16,
  armorCategory: CustomArmorCategories.heavy,
  magicBonus: 2,
  weight: 20,
  requiresAttunement: true,
);

const _weapon = CustomItemEnrichment(
  kind: CustomItemKinds.weapon,
  weaponCategory: CustomWeaponCategories.martial,
  weaponRange: CustomWeaponRanges.melee,
);

InventoryItemWrite _update(
  CustomItemEnrichment enrichment, {
  String name = 'Objet',
  int? quantity,
  int? base,
}) => InventoryItemWrite.updateCustom(
  customName: name,
  enrichment: enrichment,
  quantity: quantity,
  base: base,
);

void main() {
  group('payload', () {
    test(
      'instantané : uniquement les valeurs non neutres, op updateCustom',
      () {
        final payload = InventoryItemWrite.updateCustom(
          customName: 'Plate runique',
          customDescription: 'Gravée',
          enrichment: _armor,
        ).toPayload();

        expect(payload, {
          'op': 'updateCustom',
          'customName': 'Plate runique',
          'customDescription': 'Gravée',
          'customKind': 'armure',
          'customMagicBonus': 2,
          'customWeight': 20,
          'customRequiresAttunement': true,
          'customAcBase': 16,
          'customArmorCategory': 'lourde',
        });
      },
    );

    test('aller-retour (parse) : mêmes valeurs', () {
      final original = InventoryItemWrite.updateCustom(
        customName: 'Épée',
        customDamageDice: '1d8',
        customDamageType: 'tranchant',
        customProperties: const ['finesse'],
        enrichment: _weapon,
      );

      final parsed = parseInventoryItemPayload(original.toPayload())!;

      expect(parsed.op, InventoryItemOp.updateCustom);
      expect(parsed.customName, 'Épée');
      expect(parsed.customDamageDice, '1d8');
      expect(parsed.customDamageType, 'tranchant');
      expect(parsed.customProperties, ['finesse']);
      expect(parsed.enrichment!.kind, 'arme');
      expect(parsed.enrichment!.weaponCategory, 'guerre');
      expect(parsed.toPayload(), original.toPayload());
    });

    test('quantité et base d\'un usage fusionné sont conservées', () {
      final parsed = parseInventoryItemPayload(
        _update(_weapon, quantity: 3, base: 5).toPayload(),
      )!;

      expect(parsed.quantity, 3);
      expect(parsed.base, 5);
    });

    test('aucune clé d\'enrichissement : toutes les colonnes à NULL', () {
      final parsed = parseInventoryItemPayload({
        'op': 'updateCustom',
        'customName': 'Caillou',
      })!;

      expect(parsed.enrichment!.isEmpty, isTrue);
      final columns = parsed.toUpdateColumns();
      expect(columns['custom_kind'], isNull);
      expect(columns['custom_ac_base'], isNull);
      expect(columns['custom_description'], isNull);
    });
  });

  group('colonnes de l\'UPDATE', () {
    test(
      'armure devenue arme : CA et catégorie d\'armure à NULL EXPLICITE',
      () {
        final columns = InventoryItemWrite.updateCustom(
          customName: 'Lame',
          customDamageDice: '1d6',
          customDamageType: 'feu',
          enrichment: _weapon,
        ).toUpdateColumns();

        expect(columns.containsKey('custom_ac_base'), isTrue);
        expect(columns['custom_ac_base'], isNull);
        expect(columns.containsKey('custom_armor_category'), isTrue);
        expect(columns['custom_armor_category'], isNull);
        expect(columns['custom_kind'], 'arme');
        expect(columns['custom_weapon_category'], 'guerre');
        expect(columns['custom_weapon_range'], 'melee');
        expect(columns['custom_magic_bonus'], isNull);
        expect(columns['custom_weight'], isNull);
        expect(columns['custom_damage_dice'], '1d6');
        expect(columns['custom_damage_type'], 'feu');
      },
    );

    test('arme devenue armure : dés, dégâts, propriétés, catégorie et portée '
        'd\'arme à NULL', () {
      final columns = InventoryItemWrite.updateCustom(
        customName: 'Plate',
        enrichment: _armor,
      ).toUpdateColumns();

      for (final key in [
        'custom_damage_dice',
        'custom_damage_type',
        'custom_properties',
        'custom_weapon_category',
        'custom_weapon_range',
        'custom_description',
      ]) {
        expect(columns.containsKey(key), isTrue, reason: key);
        expect(columns[key], isNull, reason: key);
      }
      expect(columns['custom_ac_base'], 16);
      expect(columns['custom_armor_category'], 'lourde');
      expect(columns['custom_magic_bonus'], 2);
    });

    test('ne requiert plus l\'harmonisation : is_attuned remis à faux', () {
      final columns = _update(
        const CustomItemEnrichment(kind: CustomItemKinds.other),
      ).toUpdateColumns();

      expect(columns['custom_requires_attunement'], false);
      expect(columns['is_attuned'], false);
    });

    test('requiert l\'harmonisation : is_attuned jamais écrit (jamais '
        'harmonisé automatiquement)', () {
      final columns = _update(_armor).toUpdateColumns();

      expect(columns['custom_requires_attunement'], true);
      expect(columns.containsKey('is_attuned'), isFalse);
    });

    test('la quantité n\'est écrite que si un usage a été fusionné', () {
      expect(_update(_weapon).toUpdateColumns().containsKey('quantity'), false);
      expect(_update(_weapon, quantity: 4).toUpdateColumns()['quantity'], 4);
    });

    test('applyToRow superpose sur la ligne existante', () {
      final row = _update(_weapon, name: 'Neuf').applyToRow({
        'id': 'x',
        'quantity': 2,
        'custom_name': 'Ancien',
        'custom_ac_base': 12,
        'is_attuned': true,
        'equipped': true,
      });

      expect(row['custom_name'], 'Neuf');
      expect(row['custom_ac_base'], isNull);
      expect(row['quantity'], 2);
      expect(row['equipped'], true);
      expect(row['is_attuned'], false);
    });
  });

  group('validation à l\'enfilage et au rejeu', () {
    Map<String, dynamic> base([Map<String, dynamic> extra = const {}]) => {
      'op': 'updateCustom',
      'customName': 'Objet',
      ...extra,
    };

    final invalid = <String, Map<String, dynamic>>{
      'nom vide': base({'customName': '  '}),
      'nom absent': {'op': 'updateCustom'},
      'nom trop long': base({'customName': 'a' * 201}),
      'itemId présent (objet du catalogue)': base({'itemId': 3}),
      'armure sans CA': base({
        'customKind': 'armure',
        'customArmorCategory': 'legere',
      }),
      'bouclier avec catégorie d\'armure': base({
        'customKind': 'bouclier',
        'customAcBase': 2,
        'customArmorCategory': 'legere',
      }),
      'bonus magique sur « autre »': base({
        'customKind': 'autre',
        'customMagicBonus': 1,
      }),
      'bonus magique 4': base({'customKind': 'arme', 'customMagicBonus': 4}),
      'catégorie d\'arme sur une armure': base({
        'customKind': 'armure',
        'customAcBase': 12,
        'customArmorCategory': 'legere',
        'customWeaponCategory': 'courante',
      }),
      'kind inconnu': base({'customKind': 'potion'}),
      'poids négatif': base({'customWeight': -1}),
      'quantité 0': base({'quantity': 0}),
      'description vide': base({'customDescription': ''}),
      'propriétés non texte': base({
        'customProperties': [1],
      }),
    };
    for (final entry in invalid.entries) {
      test('${entry.key} : refusé', () {
        expect(parseInventoryItemPayload(entry.value), isNull);
      });
    }

    test('nom de 200 caractères : accepté', () {
      expect(
        parseInventoryItemPayload(base({'customName': 'a' * 200})),
        isNotNull,
      );
    });
  });

  group('anciens payloads', () {
    test('add sans enrichissement, delete et quantity : inchangés', () {
      expect(
        parseInventoryItemPayload({
          'op': 'add',
          'customName': 'Dague',
          'quantity': 1,
        })!.op,
        InventoryItemOp.add,
      );
      expect(
        parseInventoryItemPayload({'op': 'delete'})!.op,
        InventoryItemOp.delete,
      );
      expect(
        parseInventoryItemPayload({'op': 'quantity', 'quantity': 2})!.op,
        InventoryItemOp.quantity,
      );
    });
  });

  group('planInventoryCustomUpdate', () {
    final requested = InventoryItemWrite.updateCustom(
      customName: 'Neuf',
      customDescription: 'Desc',
      enrichment: _armor,
    );

    test('aucune écriture en file : la modification telle quelle', () {
      final plan = planInventoryCustomUpdate(
        pending: null,
        requested: requested,
      );

      expect(plan.isRejected, isFalse);
      expect(plan.mergedIntoPendingAdd, isFalse);
      expect(plan.write!.op, InventoryItemOp.updateCustom);
      expect(plan.write!.quantity, isNull);
    });

    test('tombstone en file : refusé', () {
      final plan = planInventoryCustomUpdate(
        pending: const InventoryItemWrite.delete(),
        requested: requested,
      );

      expect(plan.isRejected, isTrue);
    });

    test('ajout en file : fusionné dans l\'ajout, quantité et état gardés, '
        'aucune donnée perdue', () {
      final pendingAdd = InventoryItemWrite.add(
        customName: 'Ancien',
        quantity: 3,
        customDamageDice: '1d6',
        customDamageType: 'feu',
        enrichment: _weapon,
        state: const InventoryStatePatch(equipped: true),
      );

      final plan = planInventoryCustomUpdate(
        pending: pendingAdd,
        requested: requested,
      );

      expect(plan.mergedIntoPendingAdd, isTrue);
      final merged = plan.write!;
      expect(merged.op, InventoryItemOp.add);
      expect(merged.customName, 'Neuf');
      expect(merged.quantity, 3);
      expect(merged.customDescription, 'Desc');
      // Les dégâts de l'ancienne arme ne survivent pas à une armure.
      expect(merged.customDamageDice, isNull);
      expect(merged.customDamageType, isNull);
      expect(merged.enrichment!.kind, 'armure');
      expect(merged.state!.equipped, isTrue);
      // Le payload d'ajout reste un INSERT complet.
      expect(
        merged.toInsertColumns(inventoryId: 'i', characterId: 'c'),
        containsPair('custom_ac_base', 16),
      );
    });

    test('ajout en file harmonisé : plus d\'harmonisation requise -> '
        'is_attuned à faux dans l\'ajout', () {
      final pendingAdd = InventoryItemWrite.add(
        customName: 'Amulette',
        quantity: 1,
        enrichment: const CustomItemEnrichment(
          kind: CustomItemKinds.other,
          requiresAttunement: true,
        ),
        state: const InventoryStatePatch(attuned: true),
      );

      final plan = planInventoryCustomUpdate(
        pending: pendingAdd,
        requested: _update(const CustomItemEnrichment(kind: 'autre')),
      );

      expect(plan.write!.state!.attuned, isFalse);
    });

    test('usage en file : la modification reprend quantité et base', () {
      final plan = planInventoryCustomUpdate(
        pending: const InventoryItemWrite.quantity(quantity: 2, base: 5),
        requested: requested,
      );

      expect(plan.mergedIntoPendingAdd, isFalse);
      expect(plan.write!.op, InventoryItemOp.updateCustom);
      expect(plan.write!.quantity, 2);
      expect(plan.write!.base, 5);
    });

    test('2e modification : REMPLACE la 1re (dernière écriture gagnante)', () {
      final first = _update(_armor, name: 'Première');
      final plan = planInventoryCustomUpdate(
        pending: first,
        requested: _update(_weapon, name: 'Seconde'),
      );

      expect(plan.write!.customName, 'Seconde');
      expect(plan.write!.enrichment!.kind, 'arme');
      expect(plan.write!.enrichment!.acBase, isNull);
    });

    test('2e modification : l\'usage fusionné de la 1re est conservé', () {
      final plan = planInventoryCustomUpdate(
        pending: _update(_armor, quantity: 2, base: 4),
        requested: _update(_weapon, name: 'Seconde'),
      );

      expect(plan.write!.quantity, 2);
      expect(plan.write!.base, 4);
    });
  });

  group('usage d\'un objet dont la modification est en file', () {
    test('la quantité est fusionnée dans la modification', () {
      final plan = planInventoryUse(
        pending: _update(_armor),
        newQuantity: 2,
        serverQuantity: 5,
      );

      expect(plan.write!.op, InventoryItemOp.updateCustom);
      expect(plan.write!.quantity, 2);
      expect(plan.write!.base, 5);
      expect(plan.write!.customName, 'Objet');
    });

    test('2e usage : la base du premier est conservée', () {
      final plan = planInventoryUse(
        pending: _update(_armor, quantity: 2, base: 5),
        newQuantity: 1,
        serverQuantity: 9,
      );

      expect(plan.write!.quantity, 1);
      expect(plan.write!.base, 5);
    });

    test('quantité 0 : tombstone', () {
      final plan = planInventoryUse(
        pending: _update(_armor),
        newQuantity: 0,
        serverQuantity: 5,
      );

      expect(plan.write!.op, InventoryItemOp.delete);
    });
  });
}
