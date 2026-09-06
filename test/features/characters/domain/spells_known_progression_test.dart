import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/spells_known_progression.dart';

void main() {
  group('SpellsKnownProgression.newCantripsAt', () {
    test('Barde : 2 au niveau 1 (delta depuis 0), puis 0 jusqu\'au palier '
        'suivant (niveau 4)', () {
      expect(SpellsKnownProgression.newCantripsAt('Barde', 1), 2);
      expect(SpellsKnownProgression.newCantripsAt('Barde', 2), 0);
      expect(SpellsKnownProgression.newCantripsAt('Barde', 3), 0);
      expect(SpellsKnownProgression.newCantripsAt('Barde', 4), 1);
      expect(SpellsKnownProgression.newCantripsAt('Barde', 10), 1);
    });

    test('Ensorceleur : 4 au niveau 1, +1 aux niveaux 4 et 10', () {
      expect(SpellsKnownProgression.newCantripsAt('Ensorceleur', 1), 4);
      expect(SpellsKnownProgression.newCantripsAt('Ensorceleur', 4), 1);
      expect(SpellsKnownProgression.newCantripsAt('Ensorceleur', 10), 1);
      expect(SpellsKnownProgression.newCantripsAt('Ensorceleur', 2), 0);
    });

    test('Occultiste : même paliers que le Barde (2 puis +1 aux niveaux 4 '
        'et 10)', () {
      expect(SpellsKnownProgression.newCantripsAt('Occultiste', 1), 2);
      expect(SpellsKnownProgression.newCantripsAt('Occultiste', 4), 1);
      expect(SpellsKnownProgression.newCantripsAt('Occultiste', 10), 1);
    });

    test('Rôdeur : toujours 0, à tout niveau (RAW : aucun cantrip jamais)', () {
      for (var level = 1; level <= 20; level++) {
        expect(
          SpellsKnownProgression.newCantripsAt('Rôdeur', level),
          0,
          reason: 'niveau $level',
        );
      }
    });

    test('classe non concernée (ex. Guerrier) : toujours 0', () {
      expect(SpellsKnownProgression.newCantripsAt('Guerrier', 4), 0);
    });

    test('niveau hors plage 1-20 : 0 (défensif)', () {
      expect(SpellsKnownProgression.newCantripsAt('Barde', 0), 0);
      expect(SpellsKnownProgression.newCantripsAt('Barde', 21), 0);
    });
  });

  group('SpellsKnownProgression.newSpellsKnownAt', () {
    test('Barde : 4 au niveau 1, puis +1 à chaque niveau jusqu\'à un '
        'plateau (paliers 11->12, 15->16, 18->19 à delta nul)', () {
      expect(SpellsKnownProgression.newSpellsKnownAt('Barde', 1), 4);
      expect(SpellsKnownProgression.newSpellsKnownAt('Barde', 2), 1);
      expect(SpellsKnownProgression.newSpellsKnownAt('Barde', 12), 0);
      expect(SpellsKnownProgression.newSpellsKnownAt('Barde', 16), 0);
      expect(SpellsKnownProgression.newSpellsKnownAt('Barde', 19), 0);
      expect(SpellsKnownProgression.newSpellsKnownAt('Barde', 20), 0);
    });

    test('Ensorceleur : 2 au niveau 1, plateaux en 12/14/19-20', () {
      expect(SpellsKnownProgression.newSpellsKnownAt('Ensorceleur', 1), 2);
      expect(SpellsKnownProgression.newSpellsKnownAt('Ensorceleur', 12), 0);
      expect(SpellsKnownProgression.newSpellsKnownAt('Ensorceleur', 14), 0);
      expect(SpellsKnownProgression.newSpellsKnownAt('Ensorceleur', 19), 0);
      expect(SpellsKnownProgression.newSpellsKnownAt('Ensorceleur', 20), 0);
    });

    test('Occultiste : plateaux en 10/12/19-20 (table distincte de '
        'l\'Ensorceleur malgré un total identique au niveau 1)', () {
      expect(SpellsKnownProgression.newSpellsKnownAt('Occultiste', 1), 2);
      expect(SpellsKnownProgression.newSpellsKnownAt('Occultiste', 10), 0);
      expect(SpellsKnownProgression.newSpellsKnownAt('Occultiste', 12), 0);
      expect(SpellsKnownProgression.newSpellsKnownAt('Occultiste', 19), 1);
      expect(SpellsKnownProgression.newSpellsKnownAt('Occultiste', 20), 0);
    });

    test('Rôdeur : RAW 0 au niveau 1 (contrairement au quota de CRÉATION de '
        '`SpellcastingRules`, simplification documentée propre à la '
        'création), puis 2 au niveau 2', () {
      expect(SpellsKnownProgression.newSpellsKnownAt('Rôdeur', 1), 0);
      expect(SpellsKnownProgression.newSpellsKnownAt('Rôdeur', 2), 2);
      expect(SpellsKnownProgression.newSpellsKnownAt('Rôdeur', 4), 0);
      expect(SpellsKnownProgression.newSpellsKnownAt('Rôdeur', 20), 0);
    });

    test('classe non concernée : toujours 0', () {
      expect(SpellsKnownProgression.newSpellsKnownAt('Guerrier', 4), 0);
    });

    test('niveau hors plage 1-20 : 0 (défensif)', () {
      expect(SpellsKnownProgression.newSpellsKnownAt('Ensorceleur', 0), 0);
      expect(SpellsKnownProgression.newSpellsKnownAt('Ensorceleur', 21), 0);
    });
  });

  test('somme des deltas 1 à 20 == valeur finale à 20 (cohérence interne '
      'des 4 tables, cantrips ET sorts)', () {
    for (final className in ['Barde', 'Ensorceleur', 'Occultiste']) {
      var cantripSum = 0;
      var spellSum = 0;
      for (var level = 1; level <= 20; level++) {
        cantripSum += SpellsKnownProgression.newCantripsAt(className, level);
        spellSum += SpellsKnownProgression.newSpellsKnownAt(className, level);
      }
      expect(
        cantripSum,
        SpellsKnownProgression.cantripsKnownByLevel[className]![20],
        reason: '$className cantrips',
      );
      expect(
        spellSum,
        SpellsKnownProgression.spellsKnownByLevel[className]![20],
        reason: '$className sorts',
      );
    }
    var rodeurSpellSum = 0;
    for (var level = 1; level <= 20; level++) {
      rodeurSpellSum += SpellsKnownProgression.newSpellsKnownAt(
        'Rôdeur',
        level,
      );
    }
    expect(
      rodeurSpellSum,
      SpellsKnownProgression.spellsKnownByLevel['Rôdeur']![20],
    );
  });
}
