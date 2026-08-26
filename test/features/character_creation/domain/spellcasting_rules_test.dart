import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/spellcasting_rules.dart';

void main() {
  group('cantripQuotaFor', () {
    test('retourne le quota de cantrips exact des 6 classes qui en ont', () {
      expect(SpellcastingRules.cantripQuotaFor('Barde'), 2);
      expect(SpellcastingRules.cantripQuotaFor('Clerc'), 3);
      expect(SpellcastingRules.cantripQuotaFor('Druide'), 2);
      expect(SpellcastingRules.cantripQuotaFor('Occultiste'), 2);
      expect(SpellcastingRules.cantripQuotaFor('Magicien'), 3);
      expect(SpellcastingRules.cantripQuotaFor('Ensorceleur'), 4);
    });

    test('retourne 0 pour Paladin/Rôdeur (aucun cantrip en 5e)', () {
      expect(SpellcastingRules.cantripQuotaFor('Paladin'), 0);
      expect(SpellcastingRules.cantripQuotaFor('Rôdeur'), 0);
    });

    test('retourne 0 pour une classe non lanceuse de sorts', () {
      expect(SpellcastingRules.cantripQuotaFor('Guerrier'), 0);
      expect(SpellcastingRules.cantripQuotaFor('Barbare'), 0);
      expect(SpellcastingRules.cantripQuotaFor('Moine'), 0);
      expect(SpellcastingRules.cantripQuotaFor('Roublard'), 0);
    });
  });

  group('levelOneSpellQuotaFor', () {
    test('retourne un quota strictement positif pour les 8 classes '
        'lanceuses', () {
      const casterClassNames = [
        'Barde',
        'Clerc',
        'Druide',
        'Paladin',
        'Rôdeur',
        'Occultiste',
        'Magicien',
        'Ensorceleur',
      ];
      for (final className in casterClassNames) {
        expect(
          SpellcastingRules.levelOneSpellQuotaFor(className),
          greaterThan(0),
          reason:
              '$className doit avoir un quota de sorts de niveau 1 '
              'strictement positif : sinon, ni son onglet "Mineurs" '
              '(Paladin/Rôdeur), ni son onglet "Niveau 1" ne serait visible, '
              'et l\'étape 6/9 serait entièrement vide pour elle malgré '
              'isSpellcastingClass -> true.',
        );
      }
    });

    test('retourne 0 pour une classe non lanceuse de sorts', () {
      expect(SpellcastingRules.levelOneSpellQuotaFor('Guerrier'), 0);
    });
  });

  group('isSpellcastingClass', () {
    test('true pour les 8 classes lanceuses de sorts', () {
      const casterClassNames = [
        'Barde',
        'Clerc',
        'Druide',
        'Paladin',
        'Rôdeur',
        'Occultiste',
        'Magicien',
        'Ensorceleur',
      ];
      for (final className in casterClassNames) {
        expect(
          SpellcastingRules.isSpellcastingClass(className),
          isTrue,
          reason: className,
        );
      }
    });

    test('false pour les 4 classes non lanceuses de sorts', () {
      const nonCasterClassNames = ['Barbare', 'Guerrier', 'Moine', 'Roublard'];
      for (final className in nonCasterClassNames) {
        expect(
          SpellcastingRules.isSpellcastingClass(className),
          isFalse,
          reason: className,
        );
      }
    });

    test('false pour un nom de classe inconnu (donnée de seed corrompue)', () {
      expect(SpellcastingRules.isSpellcastingClass('Inventeur'), isFalse);
    });
  });
}
