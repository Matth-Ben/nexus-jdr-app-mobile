// Lot A « Rituels et chronos » : lecture de `ritual` et des durées structurées
// par le mapper des sorts du propriétaire (cache hors ligne compris : un
// payload ancien n'a pas ces colonnes) et par celui de la vue partagée.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/character_sharing/domain/shared_character_mapper.dart';
import 'package:personnages/features/characters/data/character_spell_row_mapper.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/spell_duration.dart';

CharacterSpellEntry _map(Map<String, dynamic> row) =>
    CharacterSpellRowMapper.toCharacterSpellEntries(
      [
        {'id': 1, ...row},
      ],
      names: const {'1': 'Alarme'},
      descriptions: const {},
      statuses: const {1: SpellStatus.known},
      classes: const [],
    ).single;

void main() {
  group('CharacterSpellRowMapper — ritual et durée structurée', () {
    test('colonnes présentes : rituel et durée chiffrée', () {
      final entry = _map({
        'ritual': true,
        'concentration': true,
        'duration': '1 heure',
        'duration_kind': 'timed',
        'duration_value': 1,
        'duration_unit': 'hour',
      });
      expect(entry.ritual, isTrue);
      expect(entry.duration, '1 heure');
      expect(entry.spellDuration.isTimed, isTrue);
      expect(entry.spellDuration.value, 1);
      expect(entry.spellDuration.unit, SpellDurationUnit.hour);
      expect(entry.spellDuration.isConcentration, isTrue);
      expect(entry.spellDuration.isTrackable, isFalse);
    });

    test('kinds sans valeur', () {
      for (final kind in ['instant', 'until_dispelled', 'special']) {
        final entry = _map({
          'ritual': false,
          'duration_kind': kind,
          'duration_value': null,
          'duration_unit': null,
        });
        expect(entry.ritual, isFalse);
        expect(entry.spellDuration.kind.value, kind);
        expect(entry.spellDuration.isTimed, isFalse);
      }
    });

    test(
      'colonnes absentes (ligne ancienne / cache hors ligne) : sans crash',
      () {
        final entry = _map({
          'level': 1,
          'duration': 'Instantanée',
          'concentration': false,
        });
        expect(entry.ritual, isFalse);
        expect(entry.spellDuration, SpellDuration.unknown);
        expect(entry.duration, 'Instantanée');
      },
    );

    test(
      'colonnes nulles ou valeurs inconnues : rituel faux, durée inconnue',
      () {
        final nulls = _map({
          'ritual': null,
          'duration_kind': null,
          'duration_value': null,
          'duration_unit': null,
        });
        expect(nulls.ritual, isFalse);
        expect(nulls.spellDuration, SpellDuration.unknown);

        final weird = _map({
          'ritual': 'yes',
          'duration_kind': 'timed',
          'duration_value': 'abc',
          'duration_unit': 'fortnight',
        });
        expect(weird.ritual, isFalse);
        expect(weird.spellDuration.isTimed, isFalse);

        final unknownKind = _map({'ritual': 1, 'duration_kind': 'eternal'});
        expect(unknownKind.ritual, isFalse);
        expect(unknownKind.spellDuration, SpellDuration.unknown);
      },
    );

    test(
      'castingTime reste celui de la base (jamais modifié par le rituel)',
      () {
        final entry = _map({'ritual': true, 'casting_time': '1 action'});
        expect(entry.castingTime, '1 action');
      },
    );

    test('les copies conservent ritual et durée structurée', () {
      final entry = _map({
        'ritual': true,
        'duration_kind': 'timed',
        'duration_value': 10,
        'duration_unit': 'minute',
      });
      for (final copy in [
        entry.copyWithPendingState(prepared: true),
        entry.copyWithInnateUsesSpent(1),
      ]) {
        expect(copy.ritual, isTrue);
        expect(copy.spellDuration, entry.spellDuration);
      }
    });
  });

  group('mapSharedCharacterJson — ritual et durée structurée', () {
    CharacterSpellEntry shared(Map<String, dynamic> extra) =>
        mapSharedCharacterJson({
          'character': {'id': 'c', 'name': 'T'},
          'spells': [
            {
              'spell_id': 1,
              'spell_name': 'Alarme',
              'level': 1,
              'status': 'connu',
              ...extra,
            },
          ],
        }).spells.single;

    test('donnée présente : visible en lecture seule', () {
      final entry = shared({
        'ritual': true,
        'duration_kind': 'timed',
        'duration_value': 8,
        'duration_unit': 'hour',
      });
      expect(entry.ritual, isTrue);
      expect(entry.spellDuration.gameSeconds, 8 * 3600);
    });

    test('RPC ancien sans ces colonnes : pas un rituel, durée inconnue', () {
      final entry = shared({});
      expect(entry.ritual, isFalse);
      expect(entry.spellDuration, SpellDuration.unknown);
    });
  });
}
