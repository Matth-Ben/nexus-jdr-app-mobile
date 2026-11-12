// P7 PR 2 : valeurs admises et validation de l'enrichissement d'un objet
// personnalisé, format de file hors ligne (payload, INSERT, ligne brute) et
// fusion avec l'état/la quantité d'un ajout en attente.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/character_inventory_row_mapper.dart';
import 'package:personnages/features/characters/domain/custom_item_enrichment.dart';
import 'package:personnages/features/characters/domain/offline_inventory_writes.dart';
import 'package:personnages/features/characters/domain/offline_state_writes.dart';
import 'package:personnages/features/characters/presentation/widgets/custom_item_form_sheet.dart';

const _uuid = '11111111-1111-4111-8111-111111111111';

const _weapon = CustomItemEnrichment(
  kind: CustomItemKinds.weapon,
  magicBonus: 3,
  weight: 2.5,
  requiresAttunement: true,
  weaponCategory: CustomWeaponCategories.common,
  weaponRange: CustomWeaponRanges.ranged,
);

void main() {
  group('CustomItemEnrichment.isValid', () {
    test('valeurs admises', () {
      expect(const CustomItemEnrichment().isValid, isTrue);
      expect(_weapon.isValid, isTrue);
      for (final kind in CustomItemKinds.all.where(
        (k) => k != CustomItemKinds.armor && k != CustomItemKinds.shield,
      )) {
        expect(CustomItemEnrichment(kind: kind).isValid, isTrue, reason: kind);
      }
      expect(
        const CustomItemEnrichment(
          kind: CustomItemKinds.armor,
          acBase: 14,
          armorCategory: CustomArmorCategories.medium,
          magicBonus: 1,
        ).isValid,
        isTrue,
      );
      expect(
        const CustomItemEnrichment(
          kind: CustomItemKinds.shield,
          acBase: 2,
        ).isValid,
        isTrue,
      );
    });

    test('bonus magique : 0..3 seulement, réservé à arme/armure/bouclier', () {
      for (final bonus in [-1, 4, 100]) {
        expect(
          CustomItemEnrichment(
            kind: CustomItemKinds.weapon,
            magicBonus: bonus,
          ).isValid,
          isFalse,
          reason: '$bonus',
        );
      }
      for (final bonus in [0, 1, 2, 3]) {
        expect(
          CustomItemEnrichment(
            kind: CustomItemKinds.weapon,
            magicBonus: bonus,
          ).isValid,
          isTrue,
          reason: '$bonus',
        );
      }
      expect(
        const CustomItemEnrichment(
          kind: CustomItemKinds.other,
          magicBonus: 1,
        ).isValid,
        isFalse,
      );
      expect(const CustomItemEnrichment(magicBonus: 1).isValid, isFalse);
    });

    test('poids : 0..9999,99 kg, fini', () {
      for (final w in [0.0, 0.01, 1.5, 9999.99]) {
        expect(CustomItemEnrichment(weight: w).isValid, isTrue, reason: '$w');
      }
      for (final w in [-0.01, 10000.0, 9999.995, double.nan, double.infinity]) {
        expect(CustomItemEnrichment(weight: w).isValid, isFalse, reason: '$w');
      }
    });

    test('catégories, portée, type : jetons connus seulement', () {
      expect(const CustomItemEnrichment(kind: 'epee').isValid, isFalse);
      expect(
        const CustomItemEnrichment(weaponCategory: 'exotique').isValid,
        isFalse,
      );
      expect(const CustomItemEnrichment(weaponRange: 'cac').isValid, isFalse);
      expect(
        const CustomItemEnrichment(armorCategory: 'mithril').isValid,
        isFalse,
      );
    });

    test('catégorie et portée de l arme : réservées au type arme', () {
      for (final kind in [
        CustomItemKinds.other,
        CustomItemKinds.shield,
        null,
      ]) {
        expect(
          CustomItemEnrichment(
            kind: kind,
            acBase: kind == CustomItemKinds.shield ? 2 : null,
            weaponCategory: CustomWeaponCategories.common,
          ).isValid,
          isFalse,
          reason: 'catégorie, type $kind',
        );
        expect(
          CustomItemEnrichment(
            kind: kind,
            acBase: kind == CustomItemKinds.shield ? 2 : null,
            weaponRange: CustomWeaponRanges.melee,
          ).isValid,
          isFalse,
          reason: 'portée, type $kind',
        );
      }
      expect(
        const CustomItemEnrichment(
          kind: CustomItemKinds.weapon,
          weaponCategory: CustomWeaponCategories.martial,
          weaponRange: CustomWeaponRanges.ranged,
        ).isValid,
        isTrue,
      );
    });

    test('CA de base 0..30 ; armure => CA + catégorie ; bouclier => CA', () {
      expect(const CustomItemEnrichment(acBase: 31).isValid, isFalse);
      expect(const CustomItemEnrichment(acBase: -1).isValid, isFalse);
      expect(const CustomItemEnrichment(acBase: 30).isValid, isTrue);
      expect(
        const CustomItemEnrichment(kind: CustomItemKinds.armor).isValid,
        isFalse,
      );
      expect(
        const CustomItemEnrichment(
          kind: CustomItemKinds.armor,
          acBase: 12,
        ).isValid,
        isFalse,
      );
      expect(
        const CustomItemEnrichment(kind: CustomItemKinds.shield).isValid,
        isFalse,
      );
    });

    test('isEmpty : rien d\'écrit', () {
      expect(const CustomItemEnrichment().isEmpty, isTrue);
      expect(const CustomItemEnrichment(attuneNow: true).isEmpty, isTrue);
      expect(const CustomItemEnrichment(kind: 'autre').isEmpty, isFalse);
      expect(const CustomItemEnrichment(weight: 0).isEmpty, isFalse);
    });
  });

  group('colonnes et payload', () {
    test('INSERT : valeurs non neutres seulement, jamais de null', () {
      expect(_weapon.toInsertColumns(), {
        'custom_kind': 'arme',
        'custom_magic_bonus': 3,
        'custom_weight': 2.5,
        'custom_requires_attunement': true,
        'custom_weapon_category': 'courante',
        'custom_weapon_range': 'distance',
      });
      expect(const CustomItemEnrichment(kind: 'autre').toInsertColumns(), {
        'custom_kind': 'autre',
      });
    });

    test('« Harmoniser maintenant » n\'est jamais écrit dans une colonne ni '
        'dans le payload', () {
      const e = CustomItemEnrichment(
        kind: CustomItemKinds.other,
        requiresAttunement: true,
        attuneNow: true,
      );

      expect(e.toInsertColumns().keys, isNot(contains('is_attuned')));
      expect(e.toPayload().keys, isNot(contains('attuned')));
      expect(e.toPayload(), {
        'customKind': 'autre',
        'customRequiresAttunement': true,
      });
    });

    test('ligne brute : même forme que PostgREST, bonus 0 -> null', () {
      expect(const CustomItemEnrichment(kind: 'autre').toRowColumns(), {
        'custom_kind': 'autre',
        'custom_magic_bonus': null,
        'custom_weight': null,
        'custom_requires_attunement': false,
        'custom_weapon_category': null,
        'custom_weapon_range': null,
        'custom_ac_base': null,
        'custom_armor_category': null,
      });
    });

    test('aller-retour payload -> parse -> payload identique', () {
      final payload = {
        'op': 'add',
        'customName': 'Arc',
        'quantity': 1,
        ..._weapon.toPayload(),
      };

      final write = parseInventoryItemPayload(payload)!;

      expect(write.toPayload(), payload);
      expect(write.enrichment!.magicBonus, 3);
      expect(write.enrichment!.weight, 2.5);
    });

    test('poids entier accepté et converti', () {
      final write = parseInventoryItemPayload({
        'op': 'add',
        'customName': 'Bûche',
        'quantity': 1,
        'customWeight': 3,
      })!;

      expect(write.enrichment!.weight, 3.0);
    });

    test('ancien payload : aucun enrichissement, payload inchangé', () {
      final payload = {
        'op': 'add',
        'customName': 'Zanbato',
        'quantity': 1,
        'customDamageDice': '2d6',
      };

      final write = parseInventoryItemPayload(payload)!;

      expect(write.enrichment, isNull);
      expect(write.toPayload(), payload);
      expect(
        write.toInsertColumns(inventoryId: _uuid, characterId: 'c1').keys,
        isNot(contains('custom_kind')),
      );
      expect(
        write.toRow(inventoryId: _uuid, characterId: 'c1').keys,
        isNot(contains('custom_kind')),
      );
    });

    test('valeur présente invalide : payload refusé', () {
      for (final bad in <Map<String, dynamic>>[
        {'customKind': 'epee'},
        {'customKind': null},
        {'customMagicBonus': 4},
        {'customMagicBonus': null},
        {'customWeight': double.nan},
        {'customWeight': null},
        {'customRequiresAttunement': null},
        {'customWeaponCategory': 3},
        {'itemId': 2, 'customKind': 'arme'},
      ]) {
        expect(
          parseInventoryItemPayload({
            'op': 'add',
            'customName': 'X',
            'quantity': 1,
            ...bad,
          }),
          isNull,
          reason: '$bad',
        );
      }
    });
  });

  group('superposition hors ligne', () {
    test('toRow lu par le mapper : mêmes règles qu\'une ligne serveur', () {
      const write = InventoryItemWrite.add(
        customName: 'Arc de lune',
        quantity: 2,
        customDamageDice: '1d8',
        customDamageType: 'perforant',
        enrichment: _weapon,
        state: InventoryStatePatch(attuned: true),
      );

      final item = CharacterInventoryRowMapper.toCharacterInventoryItems(
        [write.toRow(inventoryId: _uuid, characterId: 'c1')],
        names: const {},
        descriptions: const {},
      ).single;

      expect(item.customKind, 'arme');
      expect(item.magicBonus, 3);
      expect(item.unitWeight, 2.5);
      expect(item.totalWeight, 5.0);
      expect(item.requiresAttunement, isTrue);
      expect(item.isAttuned, isTrue);
      expect(item.isMagicBonusSuspended, isFalse);
      expect(item.customWeaponCategory, 'courante');
      expect(item.customWeaponRange, 'distance');
    });

    test('bonus suspendu : harmonisation requise sans être harmonisé', () {
      const write = InventoryItemWrite.add(
        customName: 'Arc',
        quantity: 1,
        enrichment: _weapon,
      );

      final item = CharacterInventoryRowMapper.toCharacterInventoryItems(
        [write.toRow(inventoryId: _uuid, characterId: 'c1')],
        names: const {},
        descriptions: const {},
      ).single;

      expect(item.isMagicBonusSuspended, isTrue);
    });

    test('mergeStateIntoPendingAdd et planInventoryUse conservent '
        'l\'enrichissement', () {
      const add = InventoryItemWrite.add(
        customName: 'Arc',
        quantity: 1,
        enrichment: _weapon,
      );

      final merged = mergeStateIntoPendingAdd(
        add,
        const InventoryStatePatch(equipped: true),
      );
      final used = planInventoryUse(pending: add, newQuantity: 4).write!;

      expect(merged.enrichment, same(_weapon));
      expect(used.enrichment, same(_weapon));
      expect(used.quantity, 4);
    });

    test('ajout du catalogue : jamais d\'enrichissement', () {
      expect(
        const InventoryItemWrite.add(
          itemId: 4,
          quantity: 1,
        ).toRow(inventoryId: _uuid, characterId: 'c1').keys,
        isNot(contains('custom_kind')),
      );
    });
  });

  group('armure et bouclier (P7 PR 3)', () {
    test('contraintes de production : armure => CA + catégorie ; bouclier => '
        'CA ; catégorie d\'armure jamais pour un bouclier', () {
      expect(
        const CustomItemEnrichment(
          kind: CustomItemKinds.armor,
          acBase: 14,
          armorCategory: CustomArmorCategories.medium,
        ).isValid,
        isTrue,
      );
      expect(
        const CustomItemEnrichment(
          kind: CustomItemKinds.armor,
          acBase: 14,
        ).isValid,
        isFalse,
      );
      expect(
        const CustomItemEnrichment(
          kind: CustomItemKinds.armor,
          armorCategory: CustomArmorCategories.light,
        ).isValid,
        isFalse,
      );
      expect(
        const CustomItemEnrichment(
          kind: CustomItemKinds.shield,
          acBase: 2,
        ).isValid,
        isTrue,
      );
      expect(
        const CustomItemEnrichment(kind: CustomItemKinds.shield).isValid,
        isFalse,
      );
      expect(
        const CustomItemEnrichment(
          kind: CustomItemKinds.shield,
          acBase: 2,
          armorCategory: CustomArmorCategories.heavy,
        ).isValid,
        isFalse,
      );
      expect(
        const CustomItemEnrichment(
          kind: CustomItemKinds.other,
          armorCategory: CustomArmorCategories.heavy,
        ).isValid,
        isFalse,
      );
    });

    test('colonnes écrites : CA et catégorie d\'une armure ; bonus seul '
        'pour un bouclier', () {
      expect(
        const CustomItemEnrichment(
          kind: CustomItemKinds.armor,
          acBase: 16,
          armorCategory: CustomArmorCategories.heavy,
          magicBonus: 1,
        ).toInsertColumns(),
        {
          'custom_kind': 'armure',
          'custom_magic_bonus': 1,
          'custom_ac_base': 16,
          'custom_armor_category': 'lourde',
        },
      );
      expect(
        const CustomItemEnrichment(
          kind: CustomItemKinds.shield,
          acBase: 2,
        ).toInsertColumns(),
        {'custom_kind': 'bouclier', 'custom_ac_base': 2},
      );
    });

    test('analyse d\'un payload de file : armure valide, bouclier avec '
        'catégorie refusé', () {
      final ok = parseCustomItemEnrichment({
        'customKind': 'armure',
        'customAcBase': 12,
        'customArmorCategory': 'legere',
      });
      expect(ok.isValid, isTrue);
      expect(ok.value!.acBase, 12);
      expect(
        parseCustomItemEnrichment({
          'customKind': 'bouclier',
          'customAcBase': 2,
          'customArmorCategory': 'legere',
        }).isValid,
        isFalse,
      );
    });
  });

  group('saisie du poids (virgule ou point)', () {
    test('vide : non renseigné ; valide : arrondi à 2 décimales', () {
      expect(parseCustomItemWeightInput(''), isNull);
      expect(parseCustomItemWeightInput('   '), isNull);
      expect(parseCustomItemWeightInput('1,5'), 1.5);
      expect(parseCustomItemWeightInput('1.5'), 1.5);
      expect(parseCustomItemWeightInput('0'), 0.0);
      expect(parseCustomItemWeightInput('9999,99'), 9999.99);
      expect(parseCustomItemWeightInput('2,256'), 2.26);
    });

    test('invalide : NaN', () {
      for (final bad in ['abc', '1.2.3', ',', '-1', '10000', '9999,995']) {
        expect(parseCustomItemWeightInput(bad)!.isNaN, isTrue, reason: bad);
      }
    });
  });
}
