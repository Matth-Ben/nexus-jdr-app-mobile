// Décision n° 37 (20/11/2026) : une seule armure et un seul bouclier équipés.
// `ArmorSlotRules` porte la règle « est une armure / un bouclier », la même que
// le calcul de CA (emplacement `slot ?? category`, propriétés d'armure
// requises ; objet personnalisé : `custom_ac_base` + bouclier, ou armure de
// catégorie légère/intermédiaire/lourde), et le refus d'équiper le second.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/armor_slot_rules.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/custom_armor_properties.dart';
import 'package:personnages/features/characters/domain/custom_item_enrichment.dart';
import 'package:personnages/features/characters/presentation/character_failure_l10n.dart';
import 'package:personnages/l10n/app_localizations.dart';

CharacterInventoryItem _catalog(
  String id, {
  required String? category,
  String? slot,
  bool withProperties = true,
  bool equipped = false,
  int? acBonus,
  String? acBonusKind,
}) => CharacterInventoryItem(
  id: id,
  itemId: id.hashCode,
  name: id,
  category: category,
  quantity: 1,
  equipped: equipped,
  acBonus: acBonus,
  acBonusKind: acBonusKind,
  armorProperties: withProperties
      ? CharacterInventoryArmorProperties(
          acBase: 14,
          acDexBonus: 'max_2',
          stealthDisadvantage: false,
          slot: slot,
        )
      : null,
);

CharacterInventoryItem _custom(
  String id, {
  required String? kind,
  int? acBase,
  String? category,
  bool equipped = false,
}) => CharacterInventoryItem(
  id: id,
  name: id,
  quantity: 1,
  equipped: equipped,
  customKind: kind,
  customAcBase: acBase,
  customArmorCategory: category,
  // Comme le mapper : propriétés construites seulement si les données
  // suffisent.
  armorProperties: customArmorPropertiesOf(
    kind: kind,
    acBase: acBase,
    armorCategory: category,
  ),
);

void main() {
  group('slotOf : même règle que le calcul de CA', () {
    test('catalogue : catégorie armure/bouclier avec propriétés', () {
      expect(
        ArmorSlotRules.slotOf(_catalog('a', category: 'armure')),
        ArmorSlot.armor,
      );
      expect(
        ArmorSlotRules.slotOf(_catalog('b', category: 'bouclier')),
        ArmorSlot.shield,
      );
    });

    test('objet magique : le slot prime sur la catégorie', () {
      expect(
        ArmorSlotRules.slotOf(
          _catalog('m', category: 'objet_magique', slot: 'armure'),
        ),
        ArmorSlot.armor,
      );
      expect(
        ArmorSlotRules.slotOf(
          _catalog('s', category: 'armure', slot: 'bouclier'),
        ),
        ArmorSlot.shield,
      );
    });

    test('sans propriétés d\'armure : jamais une armure (Armure +1, anneau, '
        'ligne « bouclier » incomplète)', () {
      expect(
        ArmorSlotRules.slotOf(
          _catalog(
            'armure+1',
            category: 'objet_magique',
            withProperties: false,
            acBonus: 1,
            acBonusKind: 'avec_armure',
          ),
        ),
        isNull,
      );
      expect(
        ArmorSlotRules.slotOf(
          _catalog('b', category: 'bouclier', withProperties: false),
        ),
        isNull,
      );
    });

    test('propriétés d\'armure mais emplacement inconnu : ni armure ni '
        'bouclier', () {
      expect(
        ArmorSlotRules.slotOf(_catalog('x', category: 'objet_magique')),
        isNull,
      );
    });

    test('objet personnalisé : armure de catégorie connue avec CA, bouclier '
        'avec CA', () {
      for (final category in [
        CustomArmorCategories.light,
        CustomArmorCategories.medium,
        CustomArmorCategories.heavy,
      ]) {
        expect(
          ArmorSlotRules.slotOf(
            _custom(
              'a',
              kind: CustomItemKinds.armor,
              acBase: 12,
              category: category,
            ),
          ),
          ArmorSlot.armor,
          reason: category,
        );
      }
      expect(
        ArmorSlotRules.slotOf(
          _custom('s', kind: CustomItemKinds.shield, acBase: 2),
        ),
        ArmorSlot.shield,
      );
    });

    test('objet personnalisé : sans CA, sans catégorie, type autre ou arme : '
        'ni armure ni bouclier', () {
      for (final item in [
        _custom(
          'a',
          kind: CustomItemKinds.armor,
          category: CustomArmorCategories.heavy,
        ),
        _custom('b', kind: CustomItemKinds.armor, acBase: 15),
        _custom('c', kind: CustomItemKinds.shield),
        _custom('d', kind: CustomItemKinds.other, acBase: 15),
        _custom('e', kind: CustomItemKinds.weapon, acBase: 15),
        _custom('f', kind: null, acBase: 15),
      ]) {
        expect(ArmorSlotRules.slotOf(item), isNull, reason: item.id);
      }
    });
  });

  group('equipConflict', () {
    final equippedArmor = _catalog('cotte', category: 'armure', equipped: true);
    final equippedShield = _catalog(
      'bouclier',
      category: 'bouclier',
      equipped: true,
    );

    test('seconde armure du catalogue : refus armorAlreadyEquipped', () {
      final candidate = _catalog('cuir', category: 'armure');
      final failure = ArmorSlotRules.equipConflict(
        inventory: [equippedArmor, candidate],
        inventoryId: 'cuir',
      );
      expect(failure?.code, CharacterErrorCode.armorAlreadyEquipped);
      expect(
        ArmorSlotRules.occupantFor(
          inventory: [equippedArmor, candidate],
          candidate: candidate,
        )?.id,
        'cotte',
      );
    });

    test('second bouclier (catalogue, magique ou personnalisé) : refus '
        'shieldAlreadyEquipped', () {
      for (final candidate in [
        _catalog('b2', category: 'bouclier'),
        _catalog('b+2', category: 'objet_magique', slot: 'bouclier'),
        _custom('perso', kind: CustomItemKinds.shield, acBase: 3),
      ]) {
        expect(
          ArmorSlotRules.equipConflict(
            inventory: [candidate, equippedShield],
            inventoryId: candidate.id,
          )?.code,
          CharacterErrorCode.shieldAlreadyEquipped,
          reason: candidate.id,
        );
      }
    });

    test('armure personnalisée face à une armure magique du catalogue '
        'équipée : refus', () {
      final magic = _catalog(
        'écailles',
        category: 'objet_magique',
        slot: 'armure',
        equipped: true,
      );
      final custom = _custom(
        'plate',
        kind: CustomItemKinds.armor,
        acBase: 18,
        category: CustomArmorCategories.heavy,
      );
      expect(
        ArmorSlotRules.equipConflict(
          inventory: [magic, custom],
          inventoryId: 'plate',
        )?.code,
        CharacterErrorCode.armorAlreadyEquipped,
      );
    });

    test('une armure et un bouclier ensemble : permis', () {
      expect(
        ArmorSlotRules.equipConflict(
          inventory: [
            equippedArmor,
            _catalog('b', category: 'bouclier'),
          ],
          inventoryId: 'b',
        ),
        isNull,
      );
      expect(
        ArmorSlotRules.equipConflict(
          inventory: [
            equippedShield,
            _catalog('a', category: 'armure'),
          ],
          inventoryId: 'a',
        ),
        isNull,
      );
    });

    test('autre armure présente mais NON équipée : permis', () {
      expect(
        ArmorSlotRules.equipConflict(
          inventory: [
            _catalog('cotte', category: 'armure'),
            _catalog('cuir', category: 'armure'),
          ],
          inventoryId: 'cuir',
        ),
        isNull,
      );
    });

    test(
      'rééquiper l\'objet déjà équipé : jamais en conflit avec lui-même',
      () {
        expect(
          ArmorSlotRules.equipConflict(
            inventory: [equippedArmor],
            inventoryId: 'cotte',
          ),
          isNull,
        );
      },
    );

    test('objet qui n\'est ni armure ni bouclier : permis même avec armure et '
        'bouclier équipés (anneau, Armure +1, armure perso incomplète)', () {
      final inventory = [
        equippedArmor,
        equippedShield,
        _catalog(
          'anneau',
          category: 'objet_magique',
          withProperties: false,
          acBonus: 1,
          acBonusKind: 'toujours',
        ),
        _custom('maison', kind: CustomItemKinds.armor, acBase: 14),
      ];
      expect(
        ArmorSlotRules.equipConflict(
          inventory: inventory,
          inventoryId: 'anneau',
        ),
        isNull,
      );
      expect(
        ArmorSlotRules.equipConflict(
          inventory: inventory,
          inventoryId: 'maison',
        ),
        isNull,
      );
    });

    test('une armure équipée incomplète (sans propriétés) n\'occupe pas '
        'l\'emplacement', () {
      expect(
        ArmorSlotRules.equipConflict(
          inventory: [
            _custom('maison', kind: CustomItemKinds.armor, equipped: true),
            _catalog('cuir', category: 'armure'),
          ],
          inventoryId: 'cuir',
        ),
        isNull,
      );
    });

    test('message français de repli identique au texte FR localisé', () {
      final fr = lookupAppLocalizations(const Locale('fr'));
      final armor = ArmorSlotRules.equipConflict(
        inventory: [
          equippedArmor,
          _catalog('cuir', category: 'armure'),
        ],
        inventoryId: 'cuir',
      )!;
      final shield = ArmorSlotRules.equipConflict(
        inventory: [
          equippedShield,
          _catalog('b2', category: 'bouclier'),
        ],
        inventoryId: 'b2',
      )!;
      expect(armor.message, fr.characterArmorAlreadyEquippedErrorMessage);
      expect(armor.localizedWith(fr), armor.message);
      expect(shield.message, fr.characterShieldAlreadyEquippedErrorMessage);
      expect(shield.localizedWith(fr), shield.message);
    });

    test('ligne absente de l\'inventaire : aucun refus (le dépôt échoue '
        'ailleurs)', () {
      expect(
        ArmorSlotRules.equipConflict(
          inventory: [equippedArmor],
          inventoryId: 'inconnu',
        ),
        isNull,
      );
    });
  });
}
