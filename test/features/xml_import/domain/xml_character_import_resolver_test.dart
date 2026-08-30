// Tests de la résolution complète (`XmlCharacterImportResolver`) contre les
// deux fixtures réelles (`test/fixtures/xml_import/`), plus quelques cas
// synthétiques pour les branches "non reconnu"/sous-classe/invocation non
// couvertes par ces deux fixtures (personnages niveau 2, sans sous-classe ni
// invocation). Valeurs attendues vérifiées contre
// `docs/xml-import-reference-mapping.md`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_option.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_option.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_option.dart';
import 'package:personnages/features/xml_import/data/xml_character_import_parser.dart';
import 'package:personnages/features/xml_import/domain/xml_character_import_raw.dart';
import 'package:personnages/features/xml_import/domain/xml_character_import_resolver.dart';
import 'package:personnages/features/xml_import/domain/xml_field_resolution.dart';
import 'package:personnages/features/xml_import/domain/xml_import_parse_result.dart';
import 'package:personnages/features/xml_import/domain/xml_named_option.dart';

String _readFixture(String fileName) =>
    File('test/fixtures/xml_import/$fileName').readAsStringSync();

XmlCharacterImportRaw _parse(String fileName) {
  final result = XmlCharacterImportParser.parse(_readFixture(fileName));
  return (result as XmlImportParseSuccess).character;
}

/// Catalogues minimaux mais réalistes, couvrant tous les noms "en clair"
/// des deux fixtures réelles — même rôle que les catalogues déjà chargés
/// par `SummaryStepScreen` à l'étape 9/9 de l'assistant de création, voir la
/// documentation de `XmlCharacterImportResolver`.
const _raceCatalog = RaceCatalog(
  races: [
    RaceOption(id: 1, name: 'Aasimar', abilityBonuses: {}, traits: []),
    RaceOption(id: 2, name: 'Conil', abilityBonuses: {}, traits: []),
  ],
  subraces: [],
);

const _classCatalog = ClassCatalog(
  classes: [
    ClassOption(id: 1, name: 'Paladin', description: '', hitDie: 10),
    ClassOption(id: 2, name: 'Barde', description: '', hitDie: 8),
  ],
);

const _backgroundCatalog = BackgroundCatalog(
  backgrounds: [
    BackgroundOption(
      id: 1,
      name: 'Héros du peuple',
      skillProficiencies: [],
      featureName: '',
      featureDescription: '',
    ),
    BackgroundOption(
      id: 2,
      name: 'Grand voyageur',
      skillProficiencies: [],
      featureName: '',
      featureDescription: '',
    ),
  ],
);

const _toolCatalog = ToolCatalog(
  tools: [
    ToolOption(id: 1, name: 'Matériel de peintre', category: 'outils_artisan'),
    ToolOption(id: 2, name: 'Véhicules (terrestres)', category: 'autre'),
    ToolOption(id: 3, name: 'Flûte', category: 'instrument'),
    ToolOption(id: 4, name: 'Luth', category: 'instrument'),
    ToolOption(id: 5, name: 'Tambour', category: 'instrument'),
  ],
);

const _languageCatalog = LanguageCatalog(
  languages: [
    LanguageOption(id: 1, name: 'Commun', type: 'standard'),
    LanguageOption(id: 2, name: 'Céleste', type: 'exotique'),
    LanguageOption(id: 3, name: 'Sylvestre', type: 'exotique'),
    LanguageOption(id: 4, name: 'Elfique', type: 'standard'),
  ],
);

const _paladinSpellCatalog = SpellCatalog(
  spells: [
    SpellOption(id: 1, name: 'Lumière', level: 0, school: '', castingTime: ''),
    SpellOption(
      id: 2,
      name: 'Bénédiction',
      level: 1,
      school: '',
      castingTime: '',
    ),
    SpellOption(
      id: 3,
      name: 'Bouclier de la foi',
      level: 1,
      school: '',
      castingTime: '',
    ),
    SpellOption(
      id: 4,
      name: 'Châtiment calcinant',
      level: 1,
      school: '',
      castingTime: '',
    ),
    SpellOption(
      id: 5,
      name: 'Détection de la magie',
      level: 1,
      school: '',
      castingTime: '',
    ),
    SpellOption(
      id: 6,
      name: 'Détection du mal et du bien',
      level: 1,
      school: '',
      castingTime: '',
    ),
    SpellOption(
      id: 7,
      name: 'Détection du poison et des maladies',
      level: 1,
      school: '',
      castingTime: '',
    ),
    SpellOption(
      id: 8,
      name: 'Faveur divine',
      level: 1,
      school: '',
      castingTime: '',
    ),
    SpellOption(
      id: 9,
      name: 'Injonction',
      level: 1,
      school: '',
      castingTime: '',
    ),
    SpellOption(
      id: 10,
      name: 'Protection contre le mal et le bien',
      level: 1,
      school: '',
      castingTime: '',
    ),
    SpellOption(id: 11, name: 'Soins', level: 1, school: '', castingTime: ''),
    SpellOption(
      id: 12,
      name: 'Cérémonie',
      level: 1,
      school: '',
      castingTime: '',
    ),
  ],
);

const _bardeSpellCatalog = SpellCatalog(
  spells: [
    SpellOption(id: 20, name: 'Amis', level: 0, school: '', castingTime: ''),
    SpellOption(id: 21, name: 'Lumière', level: 0, school: '', castingTime: ''),
    SpellOption(
      id: 22,
      name: 'Prestidigitation',
      level: 0,
      school: '',
      castingTime: '',
    ),
    SpellOption(
      id: 23,
      name: 'Main de mage',
      level: 0,
      school: '',
      castingTime: '',
    ),
    SpellOption(
      id: 24,
      name: 'Protection contre les armes',
      level: 0,
      school: '',
      castingTime: '',
    ),
    SpellOption(
      id: 25,
      name: 'Charme-personne',
      level: 1,
      school: '',
      castingTime: '',
    ),
    SpellOption(
      id: 26,
      name: 'Fou rire de Tasha',
      level: 1,
      school: '',
      castingTime: '',
    ),
    SpellOption(
      id: 27,
      name: 'Mot de guérison',
      level: 1,
      school: '',
      castingTime: '',
    ),
    SpellOption(id: 28, name: 'Soins', level: 1, school: '', castingTime: ''),
    SpellOption(
      id: 29,
      name: 'Vague tonnante',
      level: 1,
      school: '',
      castingTime: '',
    ),
    SpellOption(id: 30, name: 'Sommeil', level: 1, school: '', castingTime: ''),
    SpellOption(
      id: 31,
      name: 'Communication avec les animaux',
      level: 1,
      school: '',
      castingTime: '',
    ),
  ],
);

void main() {
  group('solan-valerius.xml résolu', () {
    final resolved = XmlCharacterImportResolver.resolve(
      raw: _parse('solan-valerius.xml'),
      raceCatalog: _raceCatalog,
      classCatalog: _classCatalog,
      backgroundCatalog: _backgroundCatalog,
      toolCatalog: _toolCatalog,
      languageCatalog: _languageCatalog,
      spellCatalog: _paladinSpellCatalog,
    );

    test('race/classe/historique reconnus par nom', () {
      expect(resolved.race.isRecognized, isTrue);
      expect(
        (resolved.race as XmlFieldResolutionRecognized<RaceOption>).value.name,
        'Aasimar',
      );
      expect(
        (resolved.characterClass as XmlFieldResolutionRecognized<ClassOption>)
            .value
            .name,
        'Paladin',
      );
      expect(
        (resolved.background as XmlFieldResolutionRecognized<BackgroundOption>)
            .value
            .name,
        'Héros du peuple',
      );
    });

    test('pas de sous-classe (classPath absent du XML niveau 2)', () {
      expect(resolved.subclass, isNull);
    });

    test('armure/bouclier codés', () {
      expect(
        resolved.armor,
        const XmlFieldResolution<String>.recognized('Cotte de mailles'),
      );
      expect(
        resolved.shield,
        const XmlFieldResolution<String>.recognized('Bouclier'),
      );
    });

    test('armes : weapon+weaponQ -> 1 Épée longue + 5 Javelines', () {
      expect(resolved.weapons, hasLength(2));
      expect(
        resolved.weapons[0].resolution,
        const XmlFieldResolution<String>.recognized('Épée longue'),
      );
      expect(resolved.weapons[0].quantity, 1);
      expect(
        resolved.weapons[1].resolution,
        const XmlFieldResolution<String>.recognized('Javeline'),
      );
      expect(resolved.weapons[1].quantity, 5);
    });

    test('outils physiques (tools) : emplacement vide filtré', () {
      expect(resolved.toolEquipment, hasLength(1));
      expect(
        resolved.toolEquipment.single.resolution,
        const XmlFieldResolution<String>.recognized('Outils de menuisier'),
      );
      expect(resolved.toolEquipment.single.quantity, 1);
    });

    test('objets d\'équipement codés (item+itemQ)', () {
      expect(resolved.items, hasLength(11));
      expect(
        resolved.items.first.resolution,
        const XmlFieldResolution<String>.recognized('20 carreaux'),
      );
      expect(resolved.items.first.quantity, 1);
      expect(
        resolved.items[4].resolution,
        const XmlFieldResolution<String>.recognized('Bougie'),
      );
      expect(resolved.items[4].quantity, 10);
      expect(
        resolved.items.last.resolution,
        const XmlFieldResolution<String>.recognized('Vêtements communs'),
      );
    });

    test(
      'objets personnalisés (itemX) -> toujours custom, jamais unrecognized',
      () {
        expect(resolved.customItems, hasLength(5));
        for (final item in resolved.customItems) {
          expect(item, isA<XmlFieldResolutionCustom<String>>());
        }
        expect(
          resolved.customItems.first,
          const XmlFieldResolution<String>.custom('boîte pour l\'aumône'),
        );
      },
    );

    test('alignement et sexe', () {
      expect(
        resolved.alignment,
        const XmlFieldResolution<String>.recognized('Loyal bon'),
      );
      expect(
        resolved.sexe,
        const XmlFieldResolution<String>.recognized('Homme'),
      );
    });

    test('paquetage de départ (pack, traçabilité)', () {
      expect(
        resolved.pack,
        const XmlFieldResolution<String>.recognized('Pack (a) de paladin'),
      );
    });

    test('compétences par source (skillsProf)', () {
      final classe = resolved.skillProficiencies[1]!;
      expect(classe, [
        const XmlFieldResolution<String>.recognized('Religion'),
        const XmlFieldResolution<String>.recognized('Intuition'),
      ]);
      final historique = resolved.skillProficiencies[2]!;
      expect(historique, [
        const XmlFieldResolution<String>.recognized('Dressage'),
        const XmlFieldResolution<String>.recognized('Survie'),
      ]);
      expect(resolved.skillProficiencies[0], isEmpty);
      expect(resolved.skillProficiencies[3], isEmpty);
    });

    test('outils de maîtrise (toolsProf, texte clair, résolu par nom)', () {
      final historique = resolved.toolProficiencies[2]!;
      expect(historique, hasLength(2));
      expect(historique.every((r) => r.isRecognized), isTrue);
      expect(
        historique
            .map(
              (r) => (r as XmlFieldResolutionRecognized<ToolOption>).value.name,
            )
            .toSet(),
        {'Matériel de peintre', 'Véhicules (terrestres)'},
      );
    });

    test('langues (texte clair, résolu par nom)', () {
      final race = resolved.languages[0]!;
      expect(
        race.map(
          (r) => (r as XmlFieldResolutionRecognized<LanguageOption>).value.name,
        ),
        ['Commun', 'Céleste'],
      );
    });

    test('sorts innés et connus résolus par nom', () {
      expect(resolved.innateSpells, hasLength(1));
      expect(resolved.innateSpells.single.level, 0);
      expect(
        (resolved.innateSpells.single.resolution
                as XmlFieldResolutionRecognized<SpellOption>)
            .value
            .name,
        'Lumière',
      );

      expect(resolved.knownSpells, hasLength(11));
      expect(
        resolved.knownSpells.every((s) => s.resolution.isRecognized),
        isTrue,
      );
    });

    test('aucune invocation (Paladin)', () {
      expect(resolved.knownInvocations, isEmpty);
    });

    test('raceCustomText/backgroundCustomText passthrough, styleCombat1 '
        "numérique -> unrecognized (table non reconstituée, voir "
        'xml-import-reference-mapping.md)', () {
      expect(resolved.raceCustomText, '1');
      expect(
        resolved.backgroundCustomText,
        "Recruté dans l'armée d'un seigneur, je suis devenu un leader "
        "et j'ai été félicité pour mon héroïsme",
      );
      expect(
        resolved.styleCombat1,
        const XmlFieldResolution<String>.unrecognized('11'),
      );
      expect(resolved.styleCombat2, isNull);
      expect(resolved.favoredEnemy0, isNull);
      expect(resolved.favoredEnemy6, isNull);
      expect(resolved.favoredEnemy14, isNull);
    });
  });

  group('pip.xml résolu', () {
    final resolved = XmlCharacterImportResolver.resolve(
      raw: _parse('pip.xml'),
      raceCatalog: _raceCatalog,
      classCatalog: _classCatalog,
      backgroundCatalog: _backgroundCatalog,
      toolCatalog: _toolCatalog,
      languageCatalog: _languageCatalog,
      spellCatalog: _bardeSpellCatalog,
    );

    test('race/classe/historique reconnus par nom', () {
      expect(
        (resolved.race as XmlFieldResolutionRecognized<RaceOption>).value.name,
        'Conil',
      );
      expect(
        (resolved.characterClass as XmlFieldResolutionRecognized<ClassOption>)
            .value
            .name,
        'Barde',
      );
      expect(
        (resolved.background as XmlFieldResolutionRecognized<BackgroundOption>)
            .value
            .name,
        'Grand voyageur',
      );
    });

    test('armure/bouclier codés (bouclier = 0 = valeur légitime)', () {
      expect(
        resolved.armor,
        const XmlFieldResolution<String>.recognized('Armure de cuir'),
      );
      expect(
        resolved.shield,
        const XmlFieldResolution<String>.recognized('Sans bouclier'),
      );
    });

    test('armes : 1 Rapière + 1 Dague', () {
      expect(resolved.weapons, [
        (
          resolution: const XmlFieldResolution<String>.recognized('Rapière'),
          quantity: 1,
        ),
        (
          resolution: const XmlFieldResolution<String>.recognized('Dague'),
          quantity: 1,
        ),
      ]);
    });

    test('outils physiques : Luth + Flûte', () {
      expect(resolved.toolEquipment.map((line) => line.resolution).toList(), [
        const XmlFieldResolution<String>.recognized('Luth'),
        const XmlFieldResolution<String>.recognized('Flûte'),
      ]);
    });

    test('objets d\'équipement codés', () {
      expect(resolved.items, hasLength(12));
      expect(
        resolved.items.first.resolution,
        const XmlFieldResolution<String>.recognized('Coffre'),
      );
      expect(
        resolved.items.last.resolution,
        const XmlFieldResolution<String>.recognized('Vêtements de voyage'),
      );
    });

    test('objets personnalisés', () {
      expect(resolved.customItems, hasLength(2));
    });

    test('alignement et sexe', () {
      expect(
        resolved.alignment,
        const XmlFieldResolution<String>.recognized('Chaotique bon'),
      );
      expect(
        resolved.sexe,
        const XmlFieldResolution<String>.recognized('Homme'),
      );
    });

    test('paquetage de départ', () {
      expect(
        resolved.pack,
        const XmlFieldResolution<String>.recognized('Pack (a) de barde'),
      );
    });

    test('compétences par source', () {
      expect(resolved.skillProficiencies[0], [
        const XmlFieldResolution<String>.recognized('Perception'),
      ]);
      expect(resolved.skillProficiencies[1], [
        const XmlFieldResolution<String>.recognized('Tromperie'),
        const XmlFieldResolution<String>.recognized('Survie'),
        const XmlFieldResolution<String>.recognized('Acrobaties'),
      ]);
      expect(resolved.skillProficiencies[2], [
        const XmlFieldResolution<String>.recognized('Intuition'),
        const XmlFieldResolution<String>.recognized('Tromperie'),
      ]);
    });

    test('outils de maîtrise (toolsProf)', () {
      final classe = resolved.toolProficiencies[1]!;
      expect(
        classe
            .map(
              (r) => (r as XmlFieldResolutionRecognized<ToolOption>).value.name,
            )
            .toList(),
        ['Flûte', 'Luth', 'Tambour'],
      );
    });

    test('langues', () {
      expect(
        resolved.languages[0]!
            .map(
              (r) => (r as XmlFieldResolutionRecognized<LanguageOption>)
                  .value
                  .name,
            )
            .toList(),
        ['Commun', 'Sylvestre'],
      );
      expect(
        resolved.languages[2]!
            .map(
              (r) => (r as XmlFieldResolutionRecognized<LanguageOption>)
                  .value
                  .name,
            )
            .toList(),
        ['Elfique'],
      );
    });

    test('sorts : 5 mineurs + 7 de niveau 1, tous résolus', () {
      expect(resolved.knownSpells, hasLength(12));
      expect(
        resolved.knownSpells.every((s) => s.resolution.isRecognized),
        isTrue,
      );
    });

    test('aucune invocation (Barde)', () {
      expect(resolved.knownInvocations, isEmpty);
    });

    test('raceCustomText null (raceCustom vide), styleCombat/favoredEnemy '
        'tous absents -> null', () {
      expect(resolved.raceCustomText, isNull);
      expect(resolved.backgroundCustomText, 'Vagabond');
      expect(resolved.styleCombat1, isNull);
      expect(resolved.styleCombat2, isNull);
      expect(resolved.favoredEnemy0, isNull);
      expect(resolved.favoredEnemy6, isNull);
      expect(resolved.favoredEnemy14, isNull);
    });
  });

  group('champs non reconnus (synthétique, hors périmètre des 2 fixtures)', () {
    XmlCharacterImportRaw baseRaw({
      String race = 'Aasimar',
      String characterClass = 'Paladin',
      String? classPath,
      String background = 'Héros du peuple',
      Map<int, List<String>> skillsProf = const {},
      int? armor,
      List<String> weaponIds = const [],
      List<int> weaponQuantities = const [],
      List<String> itemIds = const [],
      List<int> itemQuantities = const [],
      List<String> knownInvocations = const [],
      String? styleCombat1,
      String? styleCombat2,
      String? favoredEnemy0,
      String? favoredEnemy6,
      String? favoredEnemy14,
    }) {
      return XmlCharacterImportRaw(
        race: race,
        characterClass: characterClass,
        classPath: classPath,
        level: 1,
        background: background,
        abilityScores: const {},
        levels: const [],
        skillsProf: skillsProf,
        toolsProf: const {},
        languages: const {},
        knownInvocations: knownInvocations,
        gp: 0,
        pp: 0,
        ep: 0,
        sp: 0,
        cp: 0,
        armor: armor,
        weaponIds: weaponIds,
        weaponQuantities: weaponQuantities,
        itemIds: itemIds,
        itemQuantities: itemQuantities,
        styleCombat1: styleCombat1,
        styleCombat2: styleCombat2,
        favoredEnemy0: favoredEnemy0,
        favoredEnemy6: favoredEnemy6,
        favoredEnemy14: favoredEnemy14,
        name: 'Test',
      );
    }

    test('nom de race homebrew -> unrecognized, pas d\'exception', () {
      final resolved = XmlCharacterImportResolver.resolve(
        raw: baseRaw(race: 'Race Maison Inventée'),
        raceCatalog: _raceCatalog,
        classCatalog: _classCatalog,
        backgroundCatalog: _backgroundCatalog,
        toolCatalog: _toolCatalog,
        languageCatalog: _languageCatalog,
        spellCatalog: _paladinSpellCatalog,
      );
      expect(resolved.race.isUnrecognized, isTrue);
      expect(
        (resolved.race as XmlFieldResolutionUnrecognized<RaceOption>).rawValue,
        'Race Maison Inventée',
      );
    });

    test('identifiant d\'armure hors table -> unrecognized', () {
      final resolved = XmlCharacterImportResolver.resolve(
        raw: baseRaw(armor: 999),
        raceCatalog: _raceCatalog,
        classCatalog: _classCatalog,
        backgroundCatalog: _backgroundCatalog,
        toolCatalog: _toolCatalog,
        languageCatalog: _languageCatalog,
        spellCatalog: _paladinSpellCatalog,
      );
      expect(
        resolved.armor,
        const XmlFieldResolution<String>.unrecognized('999'),
      );
    });

    test(
      'identifiant de compétence hors table -> unrecognized dans le groupe',
      () {
        final resolved = XmlCharacterImportResolver.resolve(
          raw: baseRaw(
            skillsProf: const {
              1: ['200'],
            },
          ),
          raceCatalog: _raceCatalog,
          classCatalog: _classCatalog,
          backgroundCatalog: _backgroundCatalog,
          toolCatalog: _toolCatalog,
          languageCatalog: _languageCatalog,
          spellCatalog: _paladinSpellCatalog,
        );
        expect(resolved.skillProficiencies[1], [
          const XmlFieldResolution<String>.unrecognized('200'),
        ]);
      },
    );

    test('arme id=0 (emplacement vide) filtrée, jamais résolue', () {
      final resolved = XmlCharacterImportResolver.resolve(
        raw: baseRaw(
          weaponIds: const ['0', '3'],
          weaponQuantities: const [1, 1],
        ),
        raceCatalog: _raceCatalog,
        classCatalog: _classCatalog,
        backgroundCatalog: _backgroundCatalog,
        toolCatalog: _toolCatalog,
        languageCatalog: _languageCatalog,
        spellCatalog: _paladinSpellCatalog,
      );
      expect(resolved.weapons, hasLength(1));
      expect(
        resolved.weapons.single.resolution,
        const XmlFieldResolution<String>.recognized('Dague'),
      );
    });

    test("jeton corrompu ('abc') dans une liste positionnelle codée -> "
        "unrecognized('abc'), ne disparaît PAS de l'import (régression QA "
        "increment 1 : un ancien repli 'int.tryParse(...) ?? 0' confondait ce "
        "jeton avec l'identifiant 0 = emplacement vide, faisant disparaître "
        "l'objet corrompu silencieusement)", () {
      final resolved = XmlCharacterImportResolver.resolve(
        raw: baseRaw(
          itemIds: const ['12', 'abc', '5'],
          itemQuantities: const [1, 1, 1],
        ),
        raceCatalog: _raceCatalog,
        classCatalog: _classCatalog,
        backgroundCatalog: _backgroundCatalog,
        toolCatalog: _toolCatalog,
        languageCatalog: _languageCatalog,
        spellCatalog: _paladinSpellCatalog,
      );

      // Les 3 jetons ressortent bien (rien de silencieusement perdu),
      // dans le même ordre, avec la bonne quantité positionnelle.
      expect(resolved.items, hasLength(3));
      expect(
        resolved.items[0].resolution,
        const XmlFieldResolution<String>.recognized('Chevalière'),
      );
      expect(
        resolved.items[1].resolution,
        const XmlFieldResolution<String>.unrecognized('abc'),
      );
      expect(resolved.items[1].quantity, 1);
      expect(
        resolved.items[2].resolution,
        const XmlFieldResolution<String>.recognized('Boite d\'allume-feu'),
      );
    });

    test('styleCombat1 numérique présent, sans candidats/table -> unrecognized '
        '(jamais deviné, jamais custom)', () {
      final resolved = XmlCharacterImportResolver.resolve(
        raw: baseRaw(styleCombat1: '11'),
        raceCatalog: _raceCatalog,
        classCatalog: _classCatalog,
        backgroundCatalog: _backgroundCatalog,
        toolCatalog: _toolCatalog,
        languageCatalog: _languageCatalog,
        spellCatalog: _paladinSpellCatalog,
      );
      expect(
        resolved.styleCombat1,
        const XmlFieldResolution<String>.unrecognized('11'),
      );
      expect(
        resolved.styleCombat1,
        isNot(isA<XmlFieldResolutionCustom<String>>()),
      );
    });

    test('favoredEnemy0/6/14 absents -> null (pas unrecognized)', () {
      final resolved = XmlCharacterImportResolver.resolve(
        raw: baseRaw(),
        raceCatalog: _raceCatalog,
        classCatalog: _classCatalog,
        backgroundCatalog: _backgroundCatalog,
        toolCatalog: _toolCatalog,
        languageCatalog: _languageCatalog,
        spellCatalog: _paladinSpellCatalog,
      );
      expect(resolved.favoredEnemy0, isNull);
      expect(resolved.favoredEnemy6, isNull);
      expect(resolved.favoredEnemy14, isNull);
    });

    test('favoredEnemy6 numérique présent -> unrecognized', () {
      final resolved = XmlCharacterImportResolver.resolve(
        raw: baseRaw(favoredEnemy6: '3'),
        raceCatalog: _raceCatalog,
        classCatalog: _classCatalog,
        backgroundCatalog: _backgroundCatalog,
        toolCatalog: _toolCatalog,
        languageCatalog: _languageCatalog,
        spellCatalog: _paladinSpellCatalog,
      );
      expect(
        resolved.favoredEnemy6,
        const XmlFieldResolution<String>.unrecognized('3'),
      );
    });

    test(
      'sous-classe : classPath présent, candidats fournis -> recognized',
      () {
        final resolved = XmlCharacterImportResolver.resolve(
          raw: baseRaw(classPath: 'Serment des anciens'),
          raceCatalog: _raceCatalog,
          classCatalog: _classCatalog,
          backgroundCatalog: _backgroundCatalog,
          toolCatalog: _toolCatalog,
          languageCatalog: _languageCatalog,
          spellCatalog: _paladinSpellCatalog,
          subclassCandidates: const [
            XmlNamedOption(id: 1, name: 'Serment des anciens'),
          ],
        );
        expect(resolved.subclass, isNotNull);
        expect(resolved.subclass!.isRecognized, isTrue);
      },
    );

    test('sous-classe : classPath présent mais aucun candidat fourni -> unrecognized', () {
      final resolved = XmlCharacterImportResolver.resolve(
        raw: baseRaw(classPath: 'Serment des anciens'),
        raceCatalog: _raceCatalog,
        classCatalog: _classCatalog,
        backgroundCatalog: _backgroundCatalog,
        toolCatalog: _toolCatalog,
        languageCatalog: _languageCatalog,
        spellCatalog: _paladinSpellCatalog,
      );
      expect(resolved.subclass!.isUnrecognized, isTrue);
    });

    test('invocation : candidats fournis -> recognized', () {
      final resolved = XmlCharacterImportResolver.resolve(
        raw: baseRaw(knownInvocations: const ['Armure d\'ombres']),
        raceCatalog: _raceCatalog,
        classCatalog: _classCatalog,
        backgroundCatalog: _backgroundCatalog,
        toolCatalog: _toolCatalog,
        languageCatalog: _languageCatalog,
        spellCatalog: _paladinSpellCatalog,
        invocationCandidates: const [
          XmlNamedOption(id: 1, name: 'Armure d\'ombres'),
        ],
      );
      expect(resolved.knownInvocations.single.isRecognized, isTrue);
    });
  });
}
