// T5a : format de file des réglages d'état absolus et superposition sur les
// entrées de sort / d'objet.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
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
    test('sort : booléens uniquement, au moins une clé, clés inconnues '
        'ignorées', () {
      expect(parseSpellStatePayload({'prepared': true})!.prepared, isTrue);
      expect(parseSpellStatePayload({'favorite': false})!.favorite, isFalse);
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

    test('réglages : bonus de CA entier dans les bornes', () {
      expect(parseCharacterFlagsPayload({'armorClassBonus': 99}), isNotNull);
      expect(parseCharacterFlagsPayload({'armorClassBonus': -99}), isNotNull);
      expect(parseCharacterFlagsPayload({'armorClassBonus': 100}), isNull);
      expect(parseCharacterFlagsPayload({'armorClassBonus': -100}), isNull);
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
      final merged = const SpellStatePatch(
        prepared: true,
        favorite: true,
      ).merge(const SpellStatePatch(prepared: false));
      expect(merged.toPayload(), {'prepared': false, 'favorite': true});
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
      expect(
        innate.copyWithPendingState(favorite: true).isFavorite,
        isTrue,
        reason: 'le favori reste applicable',
      );
    });

    test('favori : ne touche pas au statut', () {
      final entry = _spell(SpellStatus.prepared)
          .copyWithPendingState(favorite: true);
      expect(entry.status, SpellStatus.prepared);
      expect(entry.isFavorite, isTrue);
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
  });
}
