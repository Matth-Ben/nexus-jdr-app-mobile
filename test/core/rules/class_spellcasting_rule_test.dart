// Tests unitaires de `core/rules/class_spellcasting_rule.dart` — le registre
// unique des règles de lancer de sorts par classe, qui remplace les 3+3
// listes dupliquées de la dette D04 (`docs/dette-technique.md`), et modélise
// l'Artificier comme demi-lanceur qui prépare depuis D41.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/character_class.dart';
import 'package:personnages/core/rules/class_spellcasting_rule.dart';

void main() {
  group('ClassSpellcastingRegistry.ruleFor : les 13 classes', () {
    const expectedCasters = {
      CharacterClass.bard: (
        type: CasterType.full,
        mode: SpellPreparationMode.known,
        ability: 'cha',
        fullList: false,
      ),
      CharacterClass.cleric: (
        type: CasterType.full,
        mode: SpellPreparationMode.prepared,
        ability: 'wis',
        fullList: true,
      ),
      CharacterClass.druid: (
        type: CasterType.full,
        mode: SpellPreparationMode.prepared,
        ability: 'wis',
        fullList: true,
      ),
      CharacterClass.wizard: (
        type: CasterType.full,
        mode: SpellPreparationMode.prepared,
        ability: 'int',
        fullList: false,
      ),
      CharacterClass.sorcerer: (
        type: CasterType.full,
        mode: SpellPreparationMode.known,
        ability: 'cha',
        fullList: false,
      ),
      CharacterClass.paladin: (
        type: CasterType.half,
        mode: SpellPreparationMode.prepared,
        ability: 'cha',
        fullList: true,
      ),
      CharacterClass.ranger: (
        type: CasterType.half,
        mode: SpellPreparationMode.known,
        ability: 'wis',
        fullList: false,
      ),
      // D41 : décision produit du 10/10/2026.
      CharacterClass.artificer: (
        type: CasterType.half,
        mode: SpellPreparationMode.prepared,
        ability: 'int',
        fullList: true,
      ),
      CharacterClass.warlock: (
        type: CasterType.pact,
        mode: SpellPreparationMode.known,
        ability: 'cha',
        fullList: false,
      ),
    };

    const nonCasters = {
      CharacterClass.barbarian,
      CharacterClass.fighter,
      CharacterClass.monk,
      CharacterClass.rogue,
    };

    test('13 classes couvertes : 9 lanceuses + 4 non lanceuses', () {
      expect(expectedCasters.length + nonCasters.length, 13);
      expect({
        ...expectedCasters.keys,
        ...nonCasters,
      }, CharacterClass.values.toSet());
    });

    test('chaque classe lanceuse a la règle attendue', () {
      for (final entry in expectedCasters.entries) {
        final rule = ClassSpellcastingRegistry.ruleFor(entry.key);
        expect(rule.casterType, entry.value.type, reason: entry.key.name);
        expect(rule.preparationMode, entry.value.mode, reason: entry.key.name);
        expect(
          rule.spellcastingAbilityKey,
          entry.value.ability,
          reason: entry.key.name,
        );
        expect(
          rule.hasFullSpellListAccess,
          entry.value.fullList,
          reason: entry.key.name,
        );
        expect(rule.isCaster, isTrue, reason: entry.key.name);
        expect(
          rule.preparesSpells,
          entry.value.mode == SpellPreparationMode.prepared,
          reason: entry.key.name,
        );
        expect(
          rule.knowsSpellsWithoutPreparing,
          entry.value.mode == SpellPreparationMode.known,
          reason: entry.key.name,
        );
      }
    });

    test(
      'chaque classe non lanceuse retombe sur ClassSpellcastingRule.none',
      () {
        for (final characterClass in nonCasters) {
          final rule = ClassSpellcastingRegistry.ruleFor(characterClass);
          expect(rule.isCaster, isFalse, reason: characterClass.name);
          expect(rule.casterType, CasterType.none, reason: characterClass.name);
          expect(
            rule.preparationMode,
            SpellPreparationMode.none,
            reason: characterClass.name,
          );
          expect(
            rule.spellcastingAbilityKey,
            isNull,
            reason: characterClass.name,
          );
          expect(rule.preparesSpells, isFalse, reason: characterClass.name);
          expect(
            rule.knowsSpellsWithoutPreparing,
            isFalse,
            reason: characterClass.name,
          );
        }
      },
    );
  });

  group('ClassSpellcastingRegistry.ruleForFrenchName', () {
    test('délègue à ruleFor pour un nom reconnu', () {
      expect(
        ClassSpellcastingRegistry.ruleForFrenchName('Artificier').casterType,
        CasterType.half,
      );
      expect(
        ClassSpellcastingRegistry.ruleForFrenchName('Clerc').preparesSpells,
        isTrue,
      );
    });

    test('nom non reconnu ou null -> ClassSpellcastingRule.none, sûr par '
        'défaut', () {
      for (final name in [null, '', 'Classe #14', 'Inventeur']) {
        final rule = ClassSpellcastingRegistry.ruleForFrenchName(name);
        expect(rule.isCaster, isFalse, reason: '$name');
        expect(rule.preparesSpells, isFalse, reason: '$name');
        expect(rule.knowsSpellsWithoutPreparing, isFalse, reason: '$name');
      }
    });
  });

  group('ClassSpellcastingRegistry : ensembles de classification', () {
    test('fullCasterClasses : les 5 lanceurs complets', () {
      expect(ClassSpellcastingRegistry.fullCasterClasses, {
        CharacterClass.bard,
        CharacterClass.cleric,
        CharacterClass.druid,
        CharacterClass.wizard,
        CharacterClass.sorcerer,
      });
    });

    test('halfCasterClasses : Paladin, Rôdeur, et Artificier depuis D41', () {
      expect(ClassSpellcastingRegistry.halfCasterClasses, {
        CharacterClass.paladin,
        CharacterClass.ranger,
        CharacterClass.artificer,
      });
    });

    test('pactCasterClasses : seul l\'Occultiste', () {
      expect(ClassSpellcastingRegistry.pactCasterClasses, {
        CharacterClass.warlock,
      });
    });
  });
}
