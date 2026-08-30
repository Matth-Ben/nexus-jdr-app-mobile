// Tests unitaires du chaînon manquant fermé par cet increment : la
// résolution des champs "codés" déjà résolus au niveau du libellé aidedd
// (increment 1) vers de vrais identifiants des tables de référence internes
// de l'app (`items.id`/`skills.id`/`alignments.id`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/alignment_catalog.dart';
import 'package:personnages/features/character_creation/domain/alignment_option.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/item_option.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/skill_option.dart';
import 'package:personnages/features/xml_import/domain/xml_character_import_resolved.dart';
import 'package:personnages/features/xml_import/domain/xml_field_resolution.dart';
import 'package:personnages/features/xml_import/domain/xml_import_save_data_resolver.dart';
import 'package:personnages/features/xml_import/domain/xml_raw_level_entry.dart';

const _race = RaceOption(id: 1, name: 'Elfe', abilityBonuses: {}, traits: []);
const _classOption = ClassOption(
  id: 2,
  name: 'Magicien',
  description: '',
  hitDie: 6,
);
const _background = BackgroundOption(
  id: 3,
  name: 'Sage',
  skillProficiencies: [],
  featureName: '',
  featureDescription: '',
);

const _itemCatalog = ItemCatalog(
  items: [
    ItemOption(id: 10, name: 'Épée longue', category: 'arme', costAmount: 15),
    ItemOption(
      id: 11,
      name: 'Sac à dos',
      category: 'equipement_general',
      costAmount: 2,
    ),
  ],
);

const _skillCatalog = SkillCatalog(
  skills: [
    SkillOption(id: 20, name: 'Arcanes', abilityId: 'int'),
    SkillOption(id: 21, name: 'Histoire', abilityId: 'int'),
  ],
);

const _alignmentCatalog = AlignmentCatalog(
  alignments: [
    AlignmentOption(id: 30, name: 'Loyal bon'),
    AlignmentOption(id: 31, name: 'Neutre'),
  ],
);

XmlCharacterImportResolved _resolved({
  XmlFieldResolution<RaceOption>? race,
  XmlFieldResolution<ClassOption>? characterClass,
  XmlFieldResolution<BackgroundOption>? background,
  Map<String, int>? abilityScores,
  List<XmlRawLevelEntry>? levels,
  Map<int, List<XmlFieldResolution<String>>>? skillProficiencies,
  List<XmlSpellResolution>? innateSpells,
  List<XmlSpellResolution>? knownSpells,
  XmlFieldResolution<String>? armor,
  XmlFieldResolution<String>? shield,
  List<XmlQuantifiedResolution>? weapons,
  List<XmlQuantifiedResolution>? toolEquipment,
  List<XmlQuantifiedResolution>? items,
  List<XmlFieldResolution<String>>? customItems,
  XmlFieldResolution<String>? alignment,
  XmlFieldResolution<String>? sexe,
  int? xp,
  String? raceCustomText,
  String? backgroundCustomText,
}) {
  return XmlCharacterImportResolved(
    race: race ?? const XmlFieldResolution.recognized(_race),
    raceCustomText: raceCustomText,
    characterClass:
        characterClass ?? const XmlFieldResolution.recognized(_classOption),
    level: 3,
    background: background ?? const XmlFieldResolution.recognized(_background),
    backgroundCustomText: backgroundCustomText,
    abilityScores: abilityScores ?? const {'con': 14},
    levels: levels ?? const [],
    skillProficiencies: skillProficiencies ?? const {},
    toolProficiencies: const {},
    languages: const {},
    innateSpells: innateSpells ?? const [],
    knownSpells: knownSpells ?? const [],
    knownInvocations: const [],
    gp: 5,
    pp: 0,
    ep: 0,
    sp: 0,
    cp: 0,
    armor: armor ?? const XmlFieldResolution.recognized('Sans armure'),
    shield: shield ?? const XmlFieldResolution.recognized('Sans bouclier'),
    weapons: weapons ?? const [],
    toolEquipment: toolEquipment ?? const [],
    items: items ?? const [],
    customItems: customItems ?? const [],
    name: 'Test',
    sexe: sexe ?? const XmlFieldResolution.recognized('Homme'),
    alignment: alignment ?? const XmlFieldResolution.recognized('Neutre'),
    xp: xp,
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
  group('XmlImportSaveDataResolver.resolve — identifiants réels', () {
    test('race/classe/historique déjà résolus (increment 1) : les ids sont '
        'repris tels quels', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.raceId, _race.id);
      expect(data.classId, _classOption.id);
      expect(data.backgroundId, _background.id);
    });

    test('raceCustomText ET backgroundCustomText (<raceCustom>/<backSpe>) '
        'sont tous les deux passés tels quels, symétriquement — régression '
        'relevée en revue (increment 2) : backgroundCustomText était résolu '
        'mais jamais persisté', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          raceCustomText: '1',
          backgroundCustomText: 'Vagabond',
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.raceCustomText, '1');
      expect(data.backgroundCustomText, 'Vagabond');
    });

    test('race/classe non reconnues -> id null, jamais bloquant', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          race: const XmlFieldResolution.unrecognized('Race Maison'),
          characterClass: const XmlFieldResolution.unrecognized(
            'Classe Maison',
          ),
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.raceId, isNull);
      expect(data.classId, isNull);
    });

    test('alignement : libellé aidedd résolu par nom vers alignments.id', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          alignment: const XmlFieldResolution.recognized('Loyal bon'),
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.alignmentId, 30);
    });

    test('alignement non reconnu au niveau aidedd -> alignmentId null, '
        'jamais bloquant', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          alignment: const XmlFieldResolution.unrecognized('99'),
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.alignmentId, isNull);
    });
  });

  group('XmlImportSaveDataResolver.resolve — compétences', () {
    test('libellé aidedd résolu par nom vers skills.id, dédoublonné entre '
        'groupes (race+classe octroient la même compétence)', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          skillProficiencies: const {
            0: [XmlFieldResolution.recognized('Arcanes')],
            1: [XmlFieldResolution.recognized('Arcanes')],
            2: [XmlFieldResolution.recognized('Histoire')],
          },
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.skillProficiencyLines.map((l) => l.skillId).toSet(), {
        20,
        21,
      });
      expect(data.skillProficiencyLines, hasLength(2));
    });

    test('libellé aidedd sans correspondance interne -> ligne omise (pas de '
        'skill_id nullable en base)', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          skillProficiencies: const {
            0: [XmlFieldResolution.recognized('Compétence inconnue')],
          },
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.skillProficiencyLines, isEmpty);
    });
  });

  group('XmlImportSaveDataResolver.resolve — points de vie', () {
    test('somme hp_brut + modificateur de Constitution par niveau atteint', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          abilityScores: const {'con': 14},
          levels: [
            const XmlRawLevelEntry(
              level: 1,
              hpBrut: 8,
              abilityIncreases: [-1, -1, -1],
            ),
            const XmlRawLevelEntry(
              level: 2,
              hpBrut: 5,
              abilityIncreases: [-1, -1, -1],
            ),
          ],
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      // Modificateur Constitution 14 -> +2. (8+2) + (5+2) = 17.
      expect(data.maxHp, 17);
      expect(data.levelHp, hasLength(2));
      expect(data.levelHp.first.hpRolled, 8);
    });
  });

  group('XmlImportSaveDataResolver.resolve — inventaire', () {
    test('"Sans armure"/"Sans bouclier" reconnus -> aucune ligne '
        'd\'inventaire (état légitime, pas un objet)', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.inventoryLines, isEmpty);
    });

    test('une arme dont le libellé aidedd matche un item réel -> item_id '
        'réel, equipped=true', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          weapons: const [
            (
              resolution: XmlFieldResolution.recognized('Épée longue'),
              quantity: 1,
            ),
          ],
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.inventoryLines, hasLength(1));
      expect(data.inventoryLines.single.itemId, 10);
      expect(data.inventoryLines.single.customName, isNull);
      expect(data.inventoryLines.single.equipped, isTrue);
    });

    test('un objet sans correspondance interne -> custom_name (le libellé '
        'aidedd lui-même), jamais perdu', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          items: const [
            (
              resolution: XmlFieldResolution.recognized('Objet introuvable'),
              quantity: 3,
            ),
          ],
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.inventoryLines, hasLength(1));
      expect(data.inventoryLines.single.itemId, isNull);
      expect(data.inventoryLines.single.customName, 'Objet introuvable');
      expect(data.inventoryLines.single.quantity, 3);
      expect(data.inventoryLines.single.equipped, isFalse);
    });

    test('un objet resté unrecognized au niveau aidedd -> le jeton brut '
        'devient le custom_name, jamais perdu silencieusement', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          items: const [
            (resolution: XmlFieldResolution.unrecognized('abc'), quantity: 1),
          ],
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.inventoryLines.single.itemId, isNull);
      expect(data.inventoryLines.single.customName, 'abc');
    });

    test('objets personnalisés (customItems, toujours custom) -> une ligne '
        'par entrée, jamais résolue vers un item_id', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          customItems: const [
            XmlFieldResolution.custom('petit sac de sable'),
            XmlFieldResolution.custom('bourse'),
          ],
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.inventoryLines, hasLength(2));
      expect(data.inventoryLines.every((line) => line.itemId == null), isTrue);
    });
  });
}
