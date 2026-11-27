// T5a : format de file des réglages d'état absolus et superposition sur les
// entrées de sort / d'objet.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/offline_state_writes.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';

CharacterSpellEntry _spell(SpellStatus status, {bool persisted = true}) =>
    CharacterSpellEntry(
      id: 1,
      name: 'Soin',
      level: 1,
      school: 'Évocation',
      status: status,
      isPersisted: persisted,
    );

void main() {
  group('analyse stricte des payloads', () {
    test('sort : booléen `prepared` uniquement, clés inconnues ignorées', () {
      expect(parseSpellStatePayload({'prepared': true})!.prepared, isTrue);
      // Compatibilité des anciennes lignes de file (favoris retirés) : la clé
      // `favorite` est ignorée ; sans `prepared`, la ligne est invalide.
      expect(
        parseSpellStatePayload({'prepared': false, 'favorite': true})!
            .toPayload(),
        {'prepared': false},
      );
      expect(parseSpellStatePayload({'favorite': false}), isNull);
      expect(parseSpellStatePayload({'favorite': true}), isNull);
      expect(parseSpellStatePayload({'favorite': 1}), isNull);
      expect(
        parseSpellStatePayload({'prepared': true, 'futur': 1})!.prepared,
        isTrue,
      );
      expect(parseSpellStatePayload({}), isNull);
      expect(parseSpellStatePayload({'prepared': 1}), isNull);
      expect(parseSpellStatePayload({'prepared': null}), isNull);
      expect(parseSpellStatePayload('x'), isNull);
      expect(parseSpellStatePayload(null), isNull);
    });

    test('objet : set d\'arme connu seulement, jamais avec équipé=false', () {
      final equip = parseInventoryStatePayload({
        'equipped': true,
        'weaponSlot': 'secondaire',
      })!;
      expect(equip.weaponSlot, WeaponSlot.secondary);
      final clear = parseInventoryStatePayload({
        'equipped': false,
        'weaponSlot': null,
      })!;
      expect(clear.hasWeaponSlot, isTrue);
      expect(clear.weaponSlot, isNull);
      expect(parseInventoryStatePayload({'weaponSlot': 'main'}), isNull);
      expect(parseInventoryStatePayload({'weaponSlot': 4}), isNull);
      expect(
        parseInventoryStatePayload({
          'equipped': false,
          'weaponSlot': 'principal',
        }),
        isNull,
      );
      expect(parseInventoryStatePayload({'attuned': 'x'}), isNull);
      expect(parseInventoryStatePayload({}), isNull);
    });

    test('objet : surcharge de prix (spec du prix d\'un objet modifiable, '
        '§2b) — l\'un est nul si et seulement si l\'autre l\'est', () {
      final set = parseInventoryStatePayload({
        'priceOverrideAmount': 15,
        'priceOverrideCurrency': 'sp',
      })!;
      expect(set.hasPriceOverride, isTrue);
      expect(set.priceOverrideAmount, 15);
      expect(set.priceOverrideCurrency, CurrencyKind.silver);

      final cleared = parseInventoryStatePayload({
        'priceOverrideAmount': null,
        'priceOverrideCurrency': null,
      })!;
      expect(cleared.hasPriceOverride, isTrue);
      expect(cleared.priceOverrideAmount, isNull);
      expect(cleared.priceOverrideCurrency, isNull);

      expect(parseInventoryStatePayload({'priceOverrideAmount': 15}), isNull);
      expect(
        parseInventoryStatePayload({'priceOverrideCurrency': 'sp'}),
        isNull,
      );
      expect(
        parseInventoryStatePayload({
          'priceOverrideAmount': 15,
          'priceOverrideCurrency': 'xx',
        }),
        isNull,
      );
      expect(
        parseInventoryStatePayload({
          'priceOverrideAmount': 'x',
          'priceOverrideCurrency': 'sp',
        }),
        isNull,
      );
      expect(
        parseInventoryStatePayload({
          'priceOverrideAmount': 0,
          'priceOverrideCurrency': 'sp',
        }),
        isNull,
      );
    });

    test('réglages : bonus de CA entier dans les bornes', () {
      for (final ok in [100, -100, 2147483647, -2147483648]) {
        expect(parseCharacterFlagsPayload({'armorClassBonus': ok}), isNotNull);
      }
      expect(
        parseCharacterFlagsPayload({'armorClassBonus': 2147483648}),
        isNull,
      );
      expect(
        parseCharacterFlagsPayload({'armorClassBonus': -2147483649}),
        isNull,
      );
      expect(parseCharacterFlagsPayload({'armorClassBonus': 1.5}), isNull);
      expect(parseCharacterFlagsPayload({'inspiration': 'oui'}), isNull);
      expect(parseCharacterFlagsPayload({}), isNull);
    });

    test('cibles : sort = entier positif canonique, objet = non vide', () {
      expect(parseSpellTargetId('42'), 42);
      for (final bad in ['', 'abc', '0', '-1', '042', '4.2']) {
        expect(parseSpellTargetId(bad), isNull, reason: bad);
      }
      expect(isValidInventoryTargetId('inv-1'), isTrue);
      expect(isValidInventoryTargetId(''), isFalse);
      expect(isValidInventoryTargetId('   '), isFalse);
    });
  });

  group('fusion « dernière valeur gagnante » champ par champ', () {
    test('sort', () {
      final merged = const SpellStatePatch(prepared: true)
          .merge(const SpellStatePatch(prepared: false));
      expect(merged.toPayload(), {'prepared': false});
    });

    test('objet : déséquiper efface le set d\'arme déjà en file', () {
      final merged = const InventoryStatePatch(
        equipped: true,
        hasWeaponSlot: true,
        weaponSlot: WeaponSlot.principal,
        attuned: true,
      ).merge(const InventoryStatePatch(equipped: false, hasWeaponSlot: true));
      expect(merged.toPayload(), {
        'equipped': false,
        'weaponSlot': null,
        'attuned': true,
      });
      expect(merged.toColumns(), {
        'equipped': false,
        'weapon_slot': null,
        'is_attuned': true,
      });
    });

    test('objet : la dernière surcharge de prix gagne', () {
      final merged =
          const InventoryStatePatch(
            hasPriceOverride: true,
            priceOverrideAmount: 15,
            priceOverrideCurrency: CurrencyKind.silver,
          ).merge(
            const InventoryStatePatch(
              hasPriceOverride: true,
              priceOverrideAmount: 250,
              priceOverrideCurrency: CurrencyKind.gold,
            ),
          );
      expect(merged.toPayload(), {
        'priceOverrideAmount': 250,
        'priceOverrideCurrency': 'gp',
      });
      expect(merged.toColumns(), {
        'price_override_amount': 250,
        'price_override_currency': 'gp',
      });
    });

    test('objet : un réglage équipé/harmonisé ne touche pas une surcharge '
        'de prix déjà en file', () {
      final merged = const InventoryStatePatch(
        hasPriceOverride: true,
        priceOverrideAmount: 15,
        priceOverrideCurrency: CurrencyKind.silver,
      ).merge(const InventoryStatePatch(attuned: true));
      expect(merged.priceOverrideAmount, 15);
      expect(merged.priceOverrideCurrency, CurrencyKind.silver);
      expect(merged.attuned, isTrue);
    });

    test('réglages', () {
      final merged = const CharacterFlagsPatch(inspiration: true)
          .merge(const CharacterFlagsPatch(armorClassBonus: -2));
      expect(merged.toColumns(), {
        'inspiration': true,
        'armor_class_bonus': -2,
      });
    });
  });

  group('superposition sur une entrée de sort', () {
    test('préparer / dé-préparer un sort ordinaire', () {
      final prepared = _spell(
        SpellStatus.known,
        persisted: false,
      ).copyWithPendingState(prepared: true);
      expect(prepared.status, SpellStatus.prepared);
      expect(prepared.isPersisted, isTrue, reason: 'la ligne sera créée');
      expect(
        prepared.copyWithPendingState(prepared: false).status,
        SpellStatus.known,
      );
    });

    test('un sort inné n\'est jamais modifié par une préparation', () {
      final innate = _spell(SpellStatus.innate);
      expect(
        innate.copyWithPendingState(prepared: true).status,
        SpellStatus.innate,
      );
    });
  });

  group('superposition sur un objet d\'inventaire', () {
    const base = CharacterInventoryItem(
      id: 'inv-1',
      name: 'Épée',
      quantity: 1,
      equipped: true,
      weaponSlot: WeaponSlot.principal,
      isAttuned: true,
    );

    test('ne pas toucher le set d\'arme sans le demander', () {
      final copy = base.copyWithPendingState(isAttuned: false);
      expect(copy.isAttuned, isFalse);
      expect(copy.weaponSlot, WeaponSlot.principal);
    });

    test('effacer le set d\'arme en déséquipant', () {
      final copy = base.copyWithPendingState(
        equipped: false,
        changeWeaponSlot: true,
      );
      expect(copy.equipped, isFalse);
      expect(copy.weaponSlot, isNull);
    });

    test('surcharge de prix posée, puis retirée (spec du prix d\'un objet '
        'modifiable)', () {
      final overridden = base.copyWithPendingState(
        changePriceOverride: true,
        priceOverrideAmount: 15,
        priceOverrideCurrency: CurrencyKind.silver,
      );
      expect(overridden.priceOverrideAmount, 15);
      expect(overridden.priceOverrideCurrency, CurrencyKind.silver);
      // Un autre réglage (ex. harmoniser) ne doit pas effacer la surcharge
      // déjà superposée.
      final stillOverridden = overridden.copyWithPendingState(isAttuned: false);
      expect(stillOverridden.priceOverrideAmount, 15);

      final removed = overridden.copyWithPendingState(
        changePriceOverride: true,
      );
      expect(removed.priceOverrideAmount, isNull);
      expect(removed.priceOverrideCurrency, isNull);
    });
  });
}
