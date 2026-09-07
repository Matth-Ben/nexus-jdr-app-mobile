// Test principal de correction de `XmlCharacterExporter` : plutôt qu'un
// audit champ par champ du XML produit, on l'exporte puis on le réimporte
// via le VRAI `XmlCharacterImportParser.parse` + `XmlCharacterImportResolver`
// + `XmlImportSaveDataResolver` (jamais modifiés par ce chantier), et on
// vérifie que les données ré-importées correspondent aux données d'origine
// — aux limites de fidélité documentées près (voir la documentation de
// classe de `XmlCharacterExporter`, notamment : PV courants/temporaires
// toujours réinitialisés à pleine vie, sous-classe/invocations/style de
// combat jamais exportés car jamais lus par `CharacterDetail`, expertise et
// sorts "préparés" qui redescendent respectivement en "compétente"/"connu",
// objets hors du périmètre fixe d'aidedd.org qui perdent quantité/statut
// équipé).
//
// Trois profils couvrant les scénarios demandés par la tâche : mono-classe
// simple (Guerrier), lanceur de sorts (Magicien, sorts inné/connu/préparé),
// inventaire varié (objets reconnus + objet magique/personnalisé/arme
// exotique non reconnus par les tables aidedd.org).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/alignment_catalog.dart';
import 'package:personnages/features/character_creation/domain/alignment_option.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/item_option.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_option.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/skill_option.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_option.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_option.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/character_skill_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/xml_export/data/xml_character_exporter.dart';
import 'package:personnages/features/xml_import/data/xml_character_import_parser.dart';
import 'package:personnages/features/xml_import/domain/xml_character_import_resolver.dart';
import 'package:personnages/features/xml_import/domain/xml_import_parse_result.dart';
import 'package:personnages/features/xml_import/domain/xml_import_save_data.dart';
import 'package:personnages/features/xml_import/domain/xml_import_save_data_resolver.dart';

/// Réimporte [xml] via le vrai pipeline d'import (parse -> résolution "en
/// clair"/"codée" -> résolution "prête à écrire"), échoue le test si le parse
/// échoue (un export de [XmlCharacterExporter] doit toujours être un XML
/// valide et structurellement reconnu).
XmlImportSaveData _reimport(
  String xml, {
  required RaceCatalog raceCatalog,
  required ClassCatalog classCatalog,
  required BackgroundCatalog backgroundCatalog,
  required ToolCatalog toolCatalog,
  required LanguageCatalog languageCatalog,
  required SpellCatalog spellCatalog,
  required ItemCatalog itemCatalog,
  required SkillCatalog skillCatalog,
  required AlignmentCatalog alignmentCatalog,
}) {
  final parseResult = XmlCharacterImportParser.parse(xml);
  expect(
    parseResult,
    isA<XmlImportParseSuccess>(),
    reason: 'Export invalide ou non reconnu par le parseur : $parseResult',
  );
  final raw = (parseResult as XmlImportParseSuccess).character;

  final resolved = XmlCharacterImportResolver.resolve(
    raw: raw,
    raceCatalog: raceCatalog,
    classCatalog: classCatalog,
    backgroundCatalog: backgroundCatalog,
    toolCatalog: toolCatalog,
    languageCatalog: languageCatalog,
    spellCatalog: spellCatalog,
  );

  return XmlImportSaveDataResolver.resolve(
    resolved: resolved,
    itemCatalog: itemCatalog,
    skillCatalog: skillCatalog,
    alignmentCatalog: alignmentCatalog,
  );
}

void main() {
  group('profil mono-classe simple (Guerrier)', () {
    const raceCatalog = RaceCatalog(
      races: [RaceOption(id: 1, name: 'Nain', abilityBonuses: {}, traits: [])],
      subraces: [],
    );
    const classCatalog = ClassCatalog(
      classes: [
        ClassOption(id: 10, name: 'Guerrier', description: '', hitDie: 10),
      ],
    );
    const backgroundCatalog = BackgroundCatalog(
      backgrounds: [
        BackgroundOption(
          id: 20,
          name: 'Soldat',
          skillProficiencies: [],
          featureName: '',
          featureDescription: '',
        ),
      ],
    );
    const toolCatalog = ToolCatalog(
      tools: [
        ToolOption(
          id: 30,
          name: 'Outils de forgeron',
          category: 'outils_artisan',
        ),
      ],
    );
    const languageCatalog = LanguageCatalog(
      languages: [
        LanguageOption(id: 40, name: 'Commun', type: 'standard'),
        LanguageOption(id: 41, name: 'Nain', type: 'standard'),
      ],
    );
    const spellCatalog = SpellCatalog(spells: []);
    const itemCatalog = ItemCatalog(
      items: [
        ItemOption(
          id: 50,
          name: 'Épée longue',
          category: 'arme',
          costAmount: 15,
        ),
        ItemOption(
          id: 51,
          name: 'Cotte de mailles',
          category: 'armure',
          costAmount: 75,
        ),
        ItemOption(
          id: 52,
          name: 'Bouclier',
          category: 'bouclier',
          costAmount: 10,
        ),
        ItemOption(
          id: 53,
          name: 'Sac à dos',
          category: 'equipement_general',
          costAmount: 2,
        ),
        ItemOption(
          id: 54,
          name: 'Torche',
          category: 'equipement_general',
          costAmount: 1,
        ),
      ],
    );
    const skillCatalog = SkillCatalog(
      skills: [
        SkillOption(id: 60, name: 'Athlétisme', abilityId: 'str'),
        SkillOption(id: 61, name: 'Intimidation', abilityId: 'cha'),
      ],
    );
    const alignmentCatalog = AlignmentCatalog(
      alignments: [AlignmentOption(id: 70, name: 'Loyal bon')],
    );

    CharacterDetail buildDetail() {
      return const CharacterDetail(
        id: 'char-1',
        name: 'Thoradin Forgefer',
        raceName: 'Nain',
        backgroundName: 'Soldat',
        alignmentName: 'Loyal bon',
        classes: [
          CharacterDetailClassRow(
            classId: 10,
            className: 'Guerrier',
            level: 5,
            isPrimary: true,
            savingThrowProficiencies: ['str', 'con'],
            hitDie: 10,
          ),
        ],
        xp: 6500,
        currentHp: 30,
        maxHp: 44,
        temporaryHp: 5,
        abilityScores: {
          'str': 16,
          'dex': 12,
          'con': 14,
          'int': 10,
          'wis': 11,
          'cha': 8,
        },
        skills: [
          CharacterSkillRow(
            id: 60,
            name: 'Athlétisme',
            abilityId: 'str',
            proficiency: 'competente',
          ),
          CharacterSkillRow(
            id: 61,
            name: 'Intimidation',
            abilityId: 'cha',
            proficiency: 'competente',
          ),
        ],
        toolProficiencyNames: ['Outils de forgeron'],
        knownLanguageNames: ['Commun', 'Nain'],
        currencyGp: 15,
        currencySp: 5,
        inventory: [
          CharacterInventoryItem(
            id: 'inv-1',
            itemId: 50,
            name: 'Épée longue',
            category: 'arme',
            quantity: 1,
            equipped: true,
          ),
          CharacterInventoryItem(
            id: 'inv-2',
            itemId: 51,
            name: 'Cotte de mailles',
            category: 'armure',
            quantity: 1,
            equipped: true,
          ),
          CharacterInventoryItem(
            id: 'inv-3',
            itemId: 52,
            name: 'Bouclier',
            category: 'bouclier',
            quantity: 1,
            equipped: true,
          ),
          CharacterInventoryItem(
            id: 'inv-4',
            itemId: 53,
            name: 'Sac à dos',
            category: 'equipement_general',
            quantity: 1,
            equipped: false,
          ),
          CharacterInventoryItem(
            id: 'inv-5',
            itemId: 54,
            name: 'Torche',
            category: 'equipement_general',
            quantity: 3,
            equipped: false,
          ),
        ],
        sexe: 'Homme',
        age: '45',
        height: '1,40 m',
        weight: '70 kg',
        eyes: 'Bruns',
        skin: 'Tanné',
        hair: 'Roux',
        appearanceText: 'Trapu et barbu.',
        traitsText: 'Direct, loyal.',
        idealsText: "L'honneur avant tout.",
        bondsText: 'Son clan.',
        flawsText: 'Trop têtu.',
        backstoryText: "Ancien soldat d'une garnison naine.",
        alliesText: 'La garde de la cité.',
        featuresText: 'Insigne militaire.',
        treasureText: 'Une pièce de monnaie ancienne.',
      );
    }

    test('aller-retour exact sur race/classe/historique/niveau/xp/PV max', () {
      final detail = buildDetail();
      expect(XmlCharacterExporter.hasUnsupportedMulticlass(detail), isFalse);

      final xml = XmlCharacterExporter.export(detail);
      final data = _reimport(
        xml,
        raceCatalog: raceCatalog,
        classCatalog: classCatalog,
        backgroundCatalog: backgroundCatalog,
        toolCatalog: toolCatalog,
        languageCatalog: languageCatalog,
        spellCatalog: spellCatalog,
        itemCatalog: itemCatalog,
        skillCatalog: skillCatalog,
        alignmentCatalog: alignmentCatalog,
      );

      expect(data.raceId, 1);
      expect(data.classId, 10);
      expect(data.backgroundId, 20);
      expect(data.alignmentId, 70);
      expect(data.level, 5);
      expect(data.xp, 6500);
      // PV maximum retrouvé exactement malgré l'historique par niveau
      // synthétique à une seule entrée — voir la documentation de classe de
      // `XmlCharacterExporter._writeLevels`.
      expect(data.maxHp, 44);
      expect(data.abilityScores, {
        'str': 16,
        'dex': 12,
        'con': 14,
        'int': 10,
        'wis': 11,
        'cha': 8,
      });
      expect(data.currencyGp, 15);
      expect(data.currencySp, 5);
      expect(data.sexe, 'Homme');
      expect(data.age, 45);
      expect(data.height, '1,40 m');
      expect(data.weight, '70 kg');
      expect(data.eyes, 'Bruns');
      expect(data.skin, 'Tanné');
      expect(data.hair, 'Roux');
      expect(data.appearanceText, 'Trapu et barbu.');
      expect(data.backstoryText, "Ancien soldat d'une garnison naine.");
    });

    test('compétences/outils/langues retrouvés (regroupés sous "Autres")', () {
      final xml = XmlCharacterExporter.export(buildDetail());
      final data = _reimport(
        xml,
        raceCatalog: raceCatalog,
        classCatalog: classCatalog,
        backgroundCatalog: backgroundCatalog,
        toolCatalog: toolCatalog,
        languageCatalog: languageCatalog,
        spellCatalog: spellCatalog,
        itemCatalog: itemCatalog,
        skillCatalog: skillCatalog,
        alignmentCatalog: alignmentCatalog,
      );

      expect(data.skillProficiencyLines.map((line) => line.skillId).toSet(), {
        60,
        61,
      });
      expect(data.toolProficiencyLines, [(toolId: 30, customText: null)]);
      expect(data.languageIds.toSet(), {40, 41});
    });

    test('inventaire : armure/bouclier/arme équipés, quantité exacte pour la '
        'torche (x3)', () {
      final xml = XmlCharacterExporter.export(buildDetail());
      final data = _reimport(
        xml,
        raceCatalog: raceCatalog,
        classCatalog: classCatalog,
        backgroundCatalog: backgroundCatalog,
        toolCatalog: toolCatalog,
        languageCatalog: languageCatalog,
        spellCatalog: spellCatalog,
        itemCatalog: itemCatalog,
        skillCatalog: skillCatalog,
        alignmentCatalog: alignmentCatalog,
      );

      bool hasLine({
        required int itemId,
        required int quantity,
        required bool equipped,
      }) => data.inventoryLines.any(
        (line) =>
            line.itemId == itemId &&
            line.quantity == quantity &&
            line.equipped == equipped,
      );

      expect(hasLine(itemId: 50, quantity: 1, equipped: true), isTrue);
      expect(hasLine(itemId: 51, quantity: 1, equipped: true), isTrue);
      expect(hasLine(itemId: 52, quantity: 1, equipped: true), isTrue);
      expect(hasLine(itemId: 53, quantity: 1, equipped: false), isTrue);
      expect(hasLine(itemId: 54, quantity: 3, equipped: false), isTrue);
      expect(data.inventoryLines, hasLength(5));
    });
  });

  group('profil lanceur de sorts (Magicien)', () {
    const raceCatalog = RaceCatalog(
      races: [RaceOption(id: 2, name: 'Elfe', abilityBonuses: {}, traits: [])],
      subraces: [],
    );
    const classCatalog = ClassCatalog(
      classes: [
        ClassOption(id: 11, name: 'Magicien', description: '', hitDie: 6),
      ],
    );
    const backgroundCatalog = BackgroundCatalog(
      backgrounds: [
        BackgroundOption(
          id: 21,
          name: 'Sage',
          skillProficiencies: [],
          featureName: '',
          featureDescription: '',
        ),
      ],
    );
    const toolCatalog = ToolCatalog(tools: []);
    const languageCatalog = LanguageCatalog(
      languages: [LanguageOption(id: 42, name: 'Commun', type: 'standard')],
    );
    const spellCatalog = SpellCatalog(
      spells: [
        SpellOption(
          id: 80,
          name: 'Lumière',
          level: 0,
          school: '',
          castingTime: '',
        ),
        SpellOption(
          id: 81,
          name: 'Projectile magique',
          level: 1,
          school: '',
          castingTime: '',
        ),
        SpellOption(
          id: 82,
          name: 'Détection de la magie',
          level: 1,
          school: '',
          castingTime: '',
        ),
      ],
    );
    const itemCatalog = ItemCatalog(items: []);
    const skillCatalog = SkillCatalog(
      skills: [SkillOption(id: 62, name: 'Arcanes', abilityId: 'int')],
    );
    const alignmentCatalog = AlignmentCatalog(alignments: []);

    CharacterDetail buildDetail() {
      return const CharacterDetail(
        id: 'char-2',
        name: 'Elowen',
        raceName: 'Elfe',
        backgroundName: 'Sage',
        classes: [
          CharacterDetailClassRow(
            classId: 11,
            className: 'Magicien',
            level: 3,
            isPrimary: true,
            savingThrowProficiencies: ['int', 'wis'],
            hitDie: 6,
          ),
        ],
        xp: 900,
        currentHp: 12,
        maxHp: 18,
        temporaryHp: 0,
        abilityScores: {
          'str': 8,
          'dex': 14,
          'con': 12,
          'int': 17,
          'wis': 10,
          'cha': 11,
        },
        skills: [
          CharacterSkillRow(
            id: 62,
            name: 'Arcanes',
            abilityId: 'int',
            proficiency: 'competente',
          ),
        ],
        knownLanguageNames: ['Commun'],
        spells: [
          CharacterSpellEntry(
            id: 80,
            name: 'Lumière',
            level: 0,
            school: '',
            status: 'inné',
          ),
          CharacterSpellEntry(
            id: 81,
            name: 'Projectile magique',
            level: 1,
            school: '',
            status: 'connu',
          ),
          CharacterSpellEntry(
            id: 82,
            name: 'Détection de la magie',
            level: 1,
            school: '',
            status: 'préparé',
          ),
        ],
      );
    }

    test('les 3 sorts sont retrouvés ; un sort "préparé" redescend en "connu" '
        '(limite du format aidedd.org, pas de cet export)', () {
      final detail = buildDetail();
      final xml = XmlCharacterExporter.export(detail);
      final data = _reimport(
        xml,
        raceCatalog: raceCatalog,
        classCatalog: classCatalog,
        backgroundCatalog: backgroundCatalog,
        toolCatalog: toolCatalog,
        languageCatalog: languageCatalog,
        spellCatalog: spellCatalog,
        itemCatalog: itemCatalog,
        skillCatalog: skillCatalog,
        alignmentCatalog: alignmentCatalog,
      );

      expect(data.spellLines, hasLength(3));
      expect(
        data.spellLines.firstWhere((line) => line.spellId == 80).status,
        'inné',
      );
      expect(
        data.spellLines.firstWhere((line) => line.spellId == 81).status,
        'connu',
      );
      // Le sort "préparé" d'origine ressort bien en base, mais avec le
      // statut "connu" (le format aidedd.org ne distingue pas "connu" de
      // "préparé", voir la documentation de classe de
      // `XmlCharacterExporter`).
      expect(
        data.spellLines.firstWhere((line) => line.spellId == 82).status,
        'connu',
      );
    });

    test(
      'PV maximum retrouvé exactement pour un modificateur de Con positif',
      () {
        final xml = XmlCharacterExporter.export(buildDetail());
        final data = _reimport(
          xml,
          raceCatalog: raceCatalog,
          classCatalog: classCatalog,
          backgroundCatalog: backgroundCatalog,
          toolCatalog: toolCatalog,
          languageCatalog: languageCatalog,
          spellCatalog: spellCatalog,
          itemCatalog: itemCatalog,
          skillCatalog: skillCatalog,
          alignmentCatalog: alignmentCatalog,
        );
        expect(data.maxHp, 18);
      },
    );
  });

  group('profil inventaire varié', () {
    const raceCatalog = RaceCatalog(
      races: [
        RaceOption(id: 3, name: 'Humain', abilityBonuses: {}, traits: []),
      ],
      subraces: [],
    );
    const classCatalog = ClassCatalog(
      classes: [
        ClassOption(id: 12, name: 'Roublard', description: '', hitDie: 8),
      ],
    );
    const backgroundCatalog = BackgroundCatalog(
      backgrounds: [
        BackgroundOption(
          id: 22,
          name: 'Criminel',
          skillProficiencies: [],
          featureName: '',
          featureDescription: '',
        ),
      ],
    );
    const toolCatalog = ToolCatalog(
      tools: [ToolOption(id: 31, name: 'Outils de voleur', category: 'autre')],
    );
    const languageCatalog = LanguageCatalog(languages: []);
    const spellCatalog = SpellCatalog(spells: []);
    const itemCatalog = ItemCatalog(
      items: [
        ItemOption(
          id: 55,
          name: 'Rations/1 jour',
          category: 'equipement_general',
          costAmount: 0.5,
        ),
        ItemOption(id: 56, name: 'Dague', category: 'arme', costAmount: 2),
      ],
    );
    const skillCatalog = SkillCatalog(skills: []);
    const alignmentCatalog = AlignmentCatalog(alignments: []);

    CharacterDetail buildDetail() {
      return const CharacterDetail(
        id: 'char-3',
        name: 'Rix',
        raceName: 'Humain',
        backgroundName: 'Criminel',
        classes: [
          CharacterDetailClassRow(
            classId: 12,
            className: 'Roublard',
            level: 4,
            isPrimary: true,
            savingThrowProficiencies: ['dex', 'int'],
            hitDie: 8,
          ),
        ],
        xp: 2700,
        currentHp: 20,
        maxHp: 28,
        temporaryHp: 0,
        abilityScores: {
          'str': 10,
          'dex': 16,
          'con': 12,
          'int': 12,
          'wis': 10,
          'cha': 14,
        },
        toolProficiencyNames: ['Outils de voleur'],
        inventory: [
          // Reconnu par les tables aidedd.org : quantité exacte préservée.
          CharacterInventoryItem(
            id: 'inv-1',
            itemId: 55,
            name: 'Rations/1 jour',
            category: 'equipement_general',
            quantity: 5,
            equipped: false,
          ),
          CharacterInventoryItem(
            id: 'inv-2',
            itemId: 56,
            name: 'Dague',
            category: 'arme',
            quantity: 2,
            equipped: true,
          ),
          // Non reconnu (variante magique) : repli `<itemX>`, quantité/statut
          // équipé non préservés (limite documentée du format aidedd.org).
          CharacterInventoryItem(
            id: 'inv-3',
            itemId: 57,
            name: 'Épée longue +1',
            category: 'arme',
            quantity: 1,
            equipped: true,
          ),
          // Objet magique hors du catalogue fixe des 99 objets aidedd.org.
          CharacterInventoryItem(
            id: 'inv-4',
            itemId: 58,
            name: 'Anneau de protection',
            category: 'objet_magique',
            quantity: 1,
            equipped: false,
          ),
          // Objet personnalisé (hors catalogue de l'app elle-même).
          CharacterInventoryItem(
            id: 'inv-5',
            itemId: null,
            name: 'Amulette de grand-mère',
            category: null,
            quantity: 1,
            equipped: false,
          ),
        ],
      );
    }

    test('objets reconnus : quantité exacte ; objets non reconnus : présents '
        'en texte libre (repli `<itemX>`), quantité/statut équipé perdus', () {
      final detail = buildDetail();
      final xml = XmlCharacterExporter.export(detail);
      final data = _reimport(
        xml,
        raceCatalog: raceCatalog,
        classCatalog: classCatalog,
        backgroundCatalog: backgroundCatalog,
        toolCatalog: toolCatalog,
        languageCatalog: languageCatalog,
        spellCatalog: spellCatalog,
        itemCatalog: itemCatalog,
        skillCatalog: skillCatalog,
        alignmentCatalog: alignmentCatalog,
      );

      // Rations/1 jour x5 : reconnues par `AideddReferenceTables.items`,
      // quantité exacte préservée.
      expect(
        data.inventoryLines.any(
          (line) => line.itemId == 55 && line.quantity == 5 && !line.equipped,
        ),
        isTrue,
      );
      // Dague x2, équipée : reconnue par `AideddReferenceTables.weapons`.
      expect(
        data.inventoryLines.any(
          (line) => line.itemId == 56 && line.quantity == 2 && line.equipped,
        ),
        isTrue,
      );

      // Les 3 objets non reconnus par les tables aidedd.org (arme +1,
      // objet magique, objet personnalisé) ressortent en `custom_name`
      // avec le nom d'origine préservé, mais toujours quantité 1 / non
      // équipé (limite du format, voir la documentation de classe de
      // `XmlCharacterExporter`).
      for (final name in [
        'Épée longue +1',
        'Anneau de protection',
        'Amulette de grand-mère',
      ]) {
        final line = data.inventoryLines.firstWhere(
          (line) => line.customName == name,
        );
        expect(line.itemId, isNull);
        expect(line.quantity, 1);
        expect(line.equipped, isFalse);
      }

      expect(data.inventoryLines, hasLength(5));
    });

    test('maîtrise d\'outil retrouvée', () {
      final xml = XmlCharacterExporter.export(buildDetail());
      final data = _reimport(
        xml,
        raceCatalog: raceCatalog,
        classCatalog: classCatalog,
        backgroundCatalog: backgroundCatalog,
        toolCatalog: toolCatalog,
        languageCatalog: languageCatalog,
        spellCatalog: spellCatalog,
        itemCatalog: itemCatalog,
        skillCatalog: skillCatalog,
        alignmentCatalog: alignmentCatalog,
      );
      expect(data.toolProficiencyLines, [(toolId: 31, customText: null)]);
    });

    test('un nom d\'objet personnalisé contenant une virgule ne se scinde pas '
        'en deux entrées au réimport (le format aidedd.org sépare `<itemX>` '
        'par virgule sans échappement, voir _sanitizeForCommaJoin)', () {
      const detail = CharacterDetail(
        id: 'char-3b',
        name: 'Rix',
        raceName: 'Humain',
        backgroundName: 'Criminel',
        classes: [
          CharacterDetailClassRow(
            classId: 12,
            className: 'Roublard',
            level: 4,
            isPrimary: true,
            savingThrowProficiencies: ['dex', 'int'],
            hitDie: 8,
          ),
        ],
        xp: 2700,
        currentHp: 20,
        maxHp: 28,
        temporaryHp: 0,
        abilityScores: {
          'str': 10,
          'dex': 16,
          'con': 12,
          'int': 12,
          'wis': 10,
          'cha': 14,
        },
        inventory: [
          CharacterInventoryItem(
            id: 'inv-1',
            itemId: null,
            name: 'Amulette de grand-mère, héritage familial',
            category: null,
            quantity: 1,
            equipped: false,
          ),
        ],
      );

      final xml = XmlCharacterExporter.export(detail);
      final data = _reimport(
        xml,
        raceCatalog: raceCatalog,
        classCatalog: classCatalog,
        backgroundCatalog: backgroundCatalog,
        toolCatalog: toolCatalog,
        languageCatalog: languageCatalog,
        spellCatalog: spellCatalog,
        itemCatalog: itemCatalog,
        skillCatalog: skillCatalog,
        alignmentCatalog: alignmentCatalog,
      );

      expect(
        data.inventoryLines,
        hasLength(1),
        reason:
            'une virgule littérale dans le nom ne doit jamais scinder '
            'l\'objet en deux lignes `<itemX>` au réimport',
      );
      expect(
        data.inventoryLines.single.customName,
        'Amulette de grand-mère; héritage familial',
      );
    });
  });

  group('multiclassage', () {
    test('hasUnsupportedMulticlass vrai dès 2 classes', () {
      const detail = CharacterDetail(
        id: 'char-multi',
        name: 'Multi',
        xp: 0,
        currentHp: 10,
        maxHp: 10,
        temporaryHp: 0,
        abilityScores: {'con': 10},
        classes: [
          CharacterDetailClassRow(
            classId: 1,
            className: 'Guerrier',
            level: 3,
            isPrimary: true,
            savingThrowProficiencies: [],
            hitDie: 10,
          ),
          CharacterDetailClassRow(
            classId: 2,
            className: 'Roublard',
            level: 2,
            isPrimary: false,
            savingThrowProficiencies: [],
            hitDie: 8,
          ),
        ],
      );
      expect(XmlCharacterExporter.hasUnsupportedMulticlass(detail), isTrue);
    });

    test('seule la classe primaire est exportée (niveau de la classe primaire, '
        'pas le niveau total)', () {
      const detail = CharacterDetail(
        id: 'char-multi',
        name: 'Multi',
        xp: 0,
        currentHp: 10,
        maxHp: 10,
        temporaryHp: 0,
        abilityScores: {'con': 10},
        classes: [
          CharacterDetailClassRow(
            classId: 1,
            className: 'Guerrier',
            level: 3,
            isPrimary: true,
            savingThrowProficiencies: [],
            hitDie: 10,
          ),
          CharacterDetailClassRow(
            classId: 2,
            className: 'Roublard',
            level: 2,
            isPrimary: false,
            savingThrowProficiencies: [],
            hitDie: 8,
          ),
        ],
      );

      final xml = XmlCharacterExporter.export(detail);
      final raw = (XmlCharacterImportParser.parse(
        xml,
      ) as XmlImportParseSuccess).character;
      expect(raw.characterClass, 'Guerrier');
      expect(raw.level, 3);
    });
  });

  group(
    'cas limites documentés (identité, PV plancher, équipement en surplus)',
    () {
      const emptyRaceCatalog = RaceCatalog(races: [], subraces: []);
      const classCatalog = ClassCatalog(
        classes: [
          ClassOption(id: 90, name: 'Guerrier', description: '', hitDie: 10),
        ],
      );
      const emptyBackgroundCatalog = BackgroundCatalog(backgrounds: []);
      const emptyToolCatalog = ToolCatalog(tools: []);
      const emptyLanguageCatalog = LanguageCatalog(languages: []);
      const emptySpellCatalog = SpellCatalog(spells: []);
      const emptyItemCatalog = ItemCatalog(items: []);
      const emptySkillCatalog = SkillCatalog(skills: []);
      const emptyAlignmentCatalog = AlignmentCatalog(alignments: []);

      CharacterDetail baseDetail({
        String? raceName,
        String? raceCustomText,
        String age = '',
        String sexe = '',
        String? alignmentName,
        Map<String, int>? abilityScores,
        int maxHp = 10,
        List<CharacterInventoryItem> inventory = const [],
      }) {
        return CharacterDetail(
          id: 'char-edge',
          name: 'Cas Limite',
          raceName: raceName,
          raceCustomText: raceCustomText,
          alignmentName: alignmentName,
          classes: const [
            CharacterDetailClassRow(
              classId: 90,
              className: 'Guerrier',
              level: 1,
              isPrimary: true,
              savingThrowProficiencies: [],
              hitDie: 10,
            ),
          ],
          xp: 0,
          currentHp: maxHp,
          maxHp: maxHp,
          temporaryHp: 0,
          abilityScores: abilityScores ?? const {'con': 10},
          age: age,
          sexe: sexe,
          inventory: inventory,
        );
      }

      XmlImportSaveData reimport(CharacterDetail detail) => _reimport(
        XmlCharacterExporter.export(detail),
        raceCatalog: emptyRaceCatalog,
        classCatalog: classCatalog,
        backgroundCatalog: emptyBackgroundCatalog,
        toolCatalog: emptyToolCatalog,
        languageCatalog: emptyLanguageCatalog,
        spellCatalog: emptySpellCatalog,
        itemCatalog: emptyItemCatalog,
        skillCatalog: emptySkillCatalog,
        alignmentCatalog: emptyAlignmentCatalog,
      );

      test('race entièrement personnalisée : <race> ET <raceCustom> portent le '
          'texte libre, raceId ne se résout à rien au réimport', () {
        final detail = baseDetail(
          raceName: null,
          raceCustomText: 'Goblin des égouts',
        );
        final xml = XmlCharacterExporter.export(detail);
        expect(xml, contains('<race>Goblin des égouts</race>'));
        expect(xml, contains('<raceCustom>Goblin des égouts</raceCustom>'));

        final data = reimport(detail);
        expect(data.raceId, isNull);
        expect(data.raceCustomText, 'Goblin des égouts');
      });

      test(
        "âge non numérique (\"une trentaine d'années\") : <age> absent du XML, "
        'ne bloque pas le réimport (age revient à null)',
        () {
          final detail = baseDetail(age: "une trentaine d'années");
          final xml = XmlCharacterExporter.export(detail);
          expect(xml, isNot(contains('<age>')));

          final data = reimport(detail);
          expect(data.age, isNull);
        },
      );

      test('sexe non standard : tag omis ; le reimport retombe sur le jeton '
          'litteral "(absent)" du resolver import existant, jamais "Non '
          'renseigne" (chemin de secours mort en pratique dans '
          'XmlImportSaveDataResolver._resolve, signale sans etre corrige ici '
          'car hors perimetre de ce chantier export)', () {
        final detail = baseDetail(sexe: 'Autre');
        final xml = XmlCharacterExporter.export(detail);
        expect(xml, isNot(contains('<sexe>')));

        final data = reimport(detail);
        expect(data.sexe, '(absent)');
      });

      test("alignement non standard : tag omis, alignmentId reste null au "
          "réimport plutôt qu'une valeur fausse", () {
        final detail = baseDetail(alignmentName: 'Bricolé maison');
        final xml = XmlCharacterExporter.export(detail);
        expect(xml, isNot(contains('<alignment>')));

        final data = reimport(detail);
        expect(data.alignmentId, isNull);
      });

      test(
        "hp_brut plancher à 1 (modificateur de Constitution élevé par rapport "
        "à des PV maximum très bas) : ne produit jamais un hp_brut négatif ou "
        "nul, au prix documenté d'un maxHp qui ne revient plus exactement "
        "identique au réimport",
        () {
          // Con 20 -> modificateur +5, maxHp 3 : hp_brut = max(1, 3 - 5) = 1.
          final detail = baseDetail(abilityScores: const {'con': 20}, maxHp: 3);
          final xml = XmlCharacterExporter.export(detail);
          expect(xml, contains('<hp_brut>1</hp_brut>'));

          // Le réimport recalcule hp_brut + modificateur = 1 + 5 = 6, qui ne
          // correspond plus au maxHp d'origine (3) — limite documentée de
          // `XmlCharacterExporter._writeLevels`, jamais un hp_brut/maxHp
          // négatif ou une exception.
          final data = reimport(detail);
          expect(data.maxHp, 6);
        },
      );

      test("deux armures équipées : seule la première devient le tag `armor` "
          "codé, la seconde retombe sur `<itemX>` (texte libre) plutôt que "
          "d'être perdue silencieusement", () {
        final detail = baseDetail(
          inventory: const [
            CharacterInventoryItem(
              id: 'inv-armor-1',
              itemId: 100,
              name: 'Cuirasse',
              category: 'armure',
              quantity: 1,
              equipped: true,
            ),
            CharacterInventoryItem(
              id: 'inv-armor-2',
              itemId: 101,
              name: 'Demi-plate',
              category: 'armure',
              quantity: 1,
              equipped: true,
            ),
          ],
        );
        final xml = XmlCharacterExporter.export(detail);
        // "Cuirasse" = id 7 dans `AideddReferenceTables.armor`.
        expect(xml, contains('<armor>7</armor>'));
        expect(xml, contains('<itemX>Demi-plate</itemX>'));

        final data = reimport(detail);
        expect(
          data.inventoryLines.any((line) => line.customName == 'Demi-plate'),
          isTrue,
          reason:
              'La seconde armure équipée ne doit jamais disparaître, même '
              'dégradée en objet texte libre.',
        );
      });
    },
  );
}
