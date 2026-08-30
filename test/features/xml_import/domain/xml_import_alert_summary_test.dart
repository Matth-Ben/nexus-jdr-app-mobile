// Tests unitaires de la logique de comptage/regroupement des alertes de
// l'écran de vérification de l'import XML aidedd.org — voir la consigne
// d'origine de la tâche ("tests unitaires sur la logique de comptage/
// regroupement des alertes et la distinction custom/unrecognized").

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/domain/spell_option.dart';
import 'package:personnages/features/xml_import/domain/xml_character_import_resolved.dart';
import 'package:personnages/features/xml_import/domain/xml_field_resolution.dart';
import 'package:personnages/features/xml_import/domain/xml_import_alert_summary.dart';

const _race = RaceOption(id: 1, name: 'Elfe', abilityBonuses: {}, traits: []);
const _classOption = ClassOption(
  id: 1,
  name: 'Magicien',
  description: '',
  hitDie: 6,
);
const _background = BackgroundOption(
  id: 1,
  name: 'Sage',
  skillProficiencies: [],
  featureName: '',
  featureDescription: '',
);

/// Un [XmlCharacterImportResolved] entièrement "propre" (tout reconnu ou
/// vide), pour isoler dans chaque test le ou les champs volontairement mis
/// en `unrecognized`/`custom` — voir [XmlImportAlertSummary.countUnresolved].
XmlCharacterImportResolved _cleanResolved({
  XmlFieldResolution<RaceOption>? race,
  XmlFieldResolution<ClassOption>? characterClass,
  XmlFieldResolution<BackgroundOption>? background,
  XmlFieldResolution<String>? armor,
  XmlFieldResolution<String>? shield,
  XmlFieldResolution<String>? alignment,
  XmlFieldResolution<String>? sexe,
  Map<int, List<XmlFieldResolution<String>>>? skillProficiencies,
  List<XmlQuantifiedResolution>? weapons,
  List<XmlFieldResolution<String>>? customItems,
}) {
  return XmlCharacterImportResolved(
    race: race ?? const XmlFieldResolution.recognized(_race),
    characterClass:
        characterClass ?? const XmlFieldResolution.recognized(_classOption),
    level: 1,
    background: background ?? const XmlFieldResolution.recognized(_background),
    abilityScores: const {},
    levels: const [],
    skillProficiencies: skillProficiencies ?? const {},
    toolProficiencies: const {},
    languages: const {},
    innateSpells: const [],
    knownSpells: const [],
    knownInvocations: const [],
    gp: 0,
    pp: 0,
    ep: 0,
    sp: 0,
    cp: 0,
    armor: armor ?? const XmlFieldResolution.recognized('Sans armure'),
    shield: shield ?? const XmlFieldResolution.recognized('Sans bouclier'),
    weapons: weapons ?? const [],
    toolEquipment: const [],
    items: const [],
    customItems: customItems ?? const [],
    name: 'Test',
    sexe: sexe ?? const XmlFieldResolution.recognized('Homme'),
    alignment: alignment ?? const XmlFieldResolution.recognized('Neutre'),
    appearanceText: '',
    traitsText: '',
    idealsText: '',
    bondsText: '',
    flawsText: '',
    backstoryText: '',
    alliesText: '',
    featuresText: '',
    treasureText: '',
  );
}

void main() {
  group('XmlImportAlertSummary.summarize', () {
    test('dénombre séparément recognized/custom/unrecognized', () {
      const resolutions = [
        XmlFieldResolution<String>.recognized('Épée longue'),
        XmlFieldResolution<String>.recognized('Dague'),
        XmlFieldResolution<String>.custom('petit sac de sable'),
        XmlFieldResolution<String>.unrecognized('abc'),
      ];

      final summary = XmlImportAlertSummary.summarize(resolutions);

      expect(summary.recognizedCount, 2);
      expect(summary.customCount, 1);
      expect(summary.unrecognizedRawValues, ['abc']);
    });

    test('custom n\'est jamais confondu avec unrecognized (distinction '
        'produit actée)', () {
      const resolutions = [XmlFieldResolution<String>.custom('bourse')];

      final summary = XmlImportAlertSummary.summarize(resolutions);

      expect(summary.customCount, 1);
      expect(summary.unrecognizedRawValues, isEmpty);
    });

    test('liste vide -> tous les compteurs à zéro', () {
      final summary = XmlImportAlertSummary.summarize<String>(const []);

      expect(summary.recognizedCount, 0);
      expect(summary.customCount, 0);
      expect(summary.unrecognizedRawValues, isEmpty);
    });

    test('générique : fonctionne pour n\'importe quel T', () {
      const resolutions = [
        XmlFieldResolution<int>.recognized(42),
        XmlFieldResolution<int>.unrecognized('id-inconnu'),
      ];

      final summary = XmlImportAlertSummary.summarize(resolutions);

      expect(summary.recognizedCount, 1);
      expect(summary.unrecognizedRawValues, ['id-inconnu']);
    });
  });

  group('XmlImportAlertSummary.summarizeGrouped', () {
    test('aplatit les 4 groupes (0 à 3) dans l\'ordre', () {
      const groups = {
        0: [XmlFieldResolution<String>.recognized('Acrobaties')],
        1: [XmlFieldResolution<String>.unrecognized('200')],
        2: <XmlFieldResolution<String>>[],
        3: [XmlFieldResolution<String>.unrecognized('201')],
      };

      final summary = XmlImportAlertSummary.summarizeGrouped(groups);

      expect(summary.recognizedCount, 1);
      expect(summary.unrecognizedRawValues, ['200', '201']);
    });

    test('groupe absent de la map traité comme une liste vide', () {
      const groups = {
        1: [XmlFieldResolution<String>.recognized('Arcanes')],
      };

      final summary = XmlImportAlertSummary.summarizeGrouped(groups);

      expect(summary.recognizedCount, 1);
      expect(summary.unrecognizedRawValues, isEmpty);
    });
  });

  group('XmlImportAlertSummary.summarizeQuantified', () {
    test('la quantité n\'a aucun impact sur le dénombrement', () {
      const resolutions = [
        (
          resolution: XmlFieldResolution<String>.recognized('Bougie'),
          quantity: 10,
        ),
        (
          resolution: XmlFieldResolution<String>.unrecognized('abc'),
          quantity: 1,
        ),
      ];

      final summary = XmlImportAlertSummary.summarizeQuantified(resolutions);

      expect(summary.recognizedCount, 1);
      expect(summary.unrecognizedRawValues, ['abc']);
    });
  });

  group('XmlImportAlertSummary.summarizeSpells', () {
    test('le niveau du sort n\'a aucun impact sur le dénombrement', () {
      const amis = SpellOption(
        id: 1,
        name: 'Amis',
        level: 0,
        school: '',
        castingTime: '',
      );
      const resolutions = [
        (
          level: 0,
          resolution: XmlFieldResolution<SpellOption>.recognized(amis),
        ),
        (
          level: 1,
          resolution: XmlFieldResolution<SpellOption>.unrecognized(
            'Sort inconnu',
          ),
        ),
      ];

      final summary = XmlImportAlertSummary.summarizeSpells(resolutions);

      expect(summary.recognizedCount, 1);
      expect(summary.unrecognizedRawValues, ['Sort inconnu']);
    });
  });

  group('XmlImportAlertSummary.countUnresolved', () {
    test('personnage entièrement résolu -> 0', () {
      expect(XmlImportAlertSummary.countUnresolved(_cleanResolved()), 0);
    });

    test('race non reconnue -> compte pour 1', () {
      final resolved = _cleanResolved(
        race: const XmlFieldResolution.unrecognized('Race Maison'),
      );
      expect(XmlImportAlertSummary.countUnresolved(resolved), 1);
    });

    test('armure "Sans armure" reconnue -> ne compte jamais comme un '
        'problème (état légitime, pas un emplacement vide)', () {
      final resolved = _cleanResolved(
        armor: const XmlFieldResolution.recognized('Sans armure'),
      );
      expect(XmlImportAlertSummary.countUnresolved(resolved), 0);
    });

    test('objets personnalisés (customItems) ne comptent jamais, même en '
        'nombre — distinction produit actée custom != unrecognized', () {
      final resolved = _cleanResolved(
        customItems: const [
          XmlFieldResolution.custom('petit sac de sable'),
          XmlFieldResolution.custom('bourse'),
          XmlFieldResolution.custom('lettre de noblesse'),
        ],
      );
      expect(XmlImportAlertSummary.countUnresolved(resolved), 0);
    });

    test('plusieurs armes non reconnues consolidées : le compte reflète le '
        'nombre réel d\'entrées individuelles, pas un nombre de cartes', () {
      final resolved = _cleanResolved(
        weapons: const [
          (resolution: XmlFieldResolution.unrecognized('abc'), quantity: 1),
          (resolution: XmlFieldResolution.unrecognized('def'), quantity: 2),
          (resolution: XmlFieldResolution.recognized('Dague'), quantity: 1),
        ],
      );
      expect(XmlImportAlertSummary.countUnresolved(resolved), 2);
    });

    test('compétences non reconnues consolidées à travers les 4 groupes de '
        'sources (race/classe/historique/autres)', () {
      final resolved = _cleanResolved(
        skillProficiencies: const {
          0: [XmlFieldResolution.unrecognized('200')],
          1: [XmlFieldResolution.recognized('Arcanes')],
          2: [XmlFieldResolution.unrecognized('201')],
        },
      );
      expect(XmlImportAlertSummary.countUnresolved(resolved), 2);
    });

    test('cumule plusieurs types de champs non reconnus simultanément', () {
      final resolved = _cleanResolved(
        race: const XmlFieldResolution.unrecognized('Race Maison'),
        characterClass: const XmlFieldResolution.unrecognized('Classe Maison'),
        alignment: const XmlFieldResolution.unrecognized('99'),
      );
      expect(XmlImportAlertSummary.countUnresolved(resolved), 3);
    });
  });
}
