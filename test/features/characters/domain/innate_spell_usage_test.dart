// Tests unitaires de `domain/innate_spell_usage.dart` : règles d'usage d'un
// sort inné de niveau >= 1 (sans emplacement, une fois par repos long).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/innate_spell_usage.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';

CharacterSpellEntry _spell({
  int level = 2,
  String status = 'inné',
  int innateUsesSpent = 0,
}) => CharacterSpellEntry(
  id: 1,
  name: 'Test',
  level: level,
  school: '',
  status: status,
  innateUsesSpent: innateUsesSpent,
);

void main() {
  test('un usage par repos long', () {
    expect(InnateSpellUsage.usesPerLongRest, 1);
  });

  group('isLimited', () {
    test("statut 'inné' et niveau >= 1 : oui, du niveau 1 au niveau 9", () {
      for (var level = 1; level <= 9; level++) {
        expect(InnateSpellUsage.isLimited(_spell(level: level)), isTrue);
      }
    });

    test('sort mineur inné (niveau 0) : non, à volonté', () {
      expect(InnateSpellUsage.isLimited(_spell(level: 0)), isFalse);
    });

    test('tout autre statut : non, même avec un compteur renseigné', () {
      for (final status in ['connu', 'préparé', '', 'autre']) {
        expect(
          InnateSpellUsage.isLimited(
            _spell(status: status, innateUsesSpent: 1),
          ),
          isFalse,
          reason: status,
        );
      }
    });

    test("sort accordé par une sous-classe dont la ligne en base est 'inné' "
        "(présenté 'préparé') : non, circuit ordinaire", () {
      const granted = CharacterSpellEntry(
        id: 1,
        name: 'Test',
        level: 2,
        school: '',
        status: 'préparé',
        storedStatus: 'inné',
        grantSource: SpellGrantSource.domain,
      );
      expect(InnateSpellUsage.isLimited(granted), isFalse);
    });
  });

  group('usesRemaining / hasUseAvailable', () {
    test('aucun usage dépensé (défaut) : 1 restant, disponible', () {
      expect(InnateSpellUsage.usesRemaining(_spell()), 1);
      expect(InnateSpellUsage.hasUseAvailable(_spell()), isTrue);
    });

    test('un usage dépensé : 0 restant, épuisé', () {
      final spent = _spell(innateUsesSpent: 1);
      expect(InnateSpellUsage.usesRemaining(spent), 0);
      expect(InnateSpellUsage.hasUseAvailable(spent), isFalse);
    });

    test('valeur stockée supérieure à la fréquence (aucune borne haute en '
        'base) : 0 restant, jamais négatif', () {
      expect(InnateSpellUsage.usesRemaining(_spell(innateUsesSpent: 7)), 0);
    });

    test('valeur négative (impossible en base, contrainte check) : bornée à '
        'la fréquence', () {
      expect(InnateSpellUsage.usesRemaining(_spell(innateUsesSpent: -3)), 1);
    });
  });

  group('usageLabel', () {
    test('disponible : « 1 / 1 · repos long » (point médian U+00B7)', () {
      expect(InnateSpellUsage.usageLabel(_spell()), '1 / 1 \u00B7 repos long');
    });

    test('épuisé : « 0 / 1 · repos long »', () {
      expect(
        InnateSpellUsage.usageLabel(_spell(innateUsesSpent: 1)),
        '0 / 1 \u00B7 repos long',
      );
    });
  });

  test('copyWithInnateUsesSpent ne change que le compteur', () {
    const original = CharacterSpellEntry(
      id: 9,
      name: 'Ténèbres',
      level: 2,
      school: 'Évocation',
      status: 'inné',
      castingTime: '1 action',
      range: '18 m',
      components: {'verbal': true},
      duration: '10 minutes',
      concentration: true,
      description: 'd',
      isFavorite: true,
      isPersisted: false,
      storedStatus: 'inné',
      requiresPreparation: false,
    );
    final copy = original.copyWithInnateUsesSpent(1);
    expect(copy.innateUsesSpent, 1);
    expect(copy.id, 9);
    expect(copy.name, 'Ténèbres');
    expect(copy.level, 2);
    expect(copy.school, 'Évocation');
    expect(copy.status, 'inné');
    expect(copy.castingTime, '1 action');
    expect(copy.range, '18 m');
    expect(copy.components, {'verbal': true});
    expect(copy.duration, '10 minutes');
    expect(copy.concentration, isTrue);
    expect(copy.description, 'd');
    expect(copy.isFavorite, isTrue);
    expect(copy.grantSource, isNull);
    expect(copy.isPersisted, isFalse);
    expect(copy.storedStatus, 'inné');
    expect(copy.requiresPreparation, isFalse);
  });
}
