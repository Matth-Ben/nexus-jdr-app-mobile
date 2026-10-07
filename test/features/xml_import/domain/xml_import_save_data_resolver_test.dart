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
import 'package:personnages/features/character_creation/domain/spell_option.dart';
import 'package:personnages/features/character_creation/domain/subrace_option.dart';
import 'package:personnages/features/xml_import/domain/xml_character_import_resolved.dart';
import 'package:personnages/features/xml_import/domain/xml_field_resolution.dart';
import 'package:personnages/features/xml_import/domain/xml_import_save_data.dart';
import 'package:personnages/features/xml_import/domain/xml_import_save_data_resolver.dart';
import 'package:personnages/features/xml_import/domain/xml_raw_level_entry.dart';

const _race = RaceOption(
  id: 1,
  name: 'Elfe',
  abilityBonuses: {},
  traits: [],
  source: '',
);
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

// Lanceur à liste complète (voir `prepared_caster_spell_list.dart`) : sert à
// vérifier que le statut écrit à l'import ne dépend pas de la classe.
const _paladinClass = ClassOption(
  id: 7,
  name: 'Paladin',
  description: '',
  hitDie: 10,
);

const _spellA = SpellOption(
  id: 100,
  name: 'Bénédiction',
  level: 1,
  school: 'Enchantement',
  castingTime: '1 action',
);
const _spellB = SpellOption(
  id: 101,
  name: 'Lumière',
  level: 0,
  school: 'Évocation',
  castingTime: '1 action',
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

  group('XmlImportSaveDataResolver.resolve — sorts (D10)', () {
    test('sort connu écrit avec le statut "connu" et la classe d\'origine, '
        "même pour un lanceur à liste complète (Clerc/Druide/Paladin) : "
        "l'export aidedd.org ne distingue pas les sorts accessibles des "
        'sorts réellement préparés pour ces classes, voir la documentation '
        'de `_resolveSpellLines` — ce n\'est pas une perte de donnée, rien '
        "n'indique un statut de préparation dans le fichier source", () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          characterClass: const XmlFieldResolution.recognized(_paladinClass),
          knownSpells: const [
            (level: 1, resolution: XmlFieldResolution.recognized(_spellA)),
          ],
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.spellLines, hasLength(1));
      expect(data.spellLines.single.spellId, _spellA.id);
      expect(data.spellLines.single.status, 'connu');
      expect(data.spellLines.single.sourceClassId, _paladinClass.id);
    });

    test('sort connu ecrit avec le statut connu pour un Magicien aussi '
        '(grimoire, pas liste de classe complete comme Clerc, Druide ou '
        'Paladin) : ce resolveur ne differencie aucune classe (voir '
        '_resolveSpellLines), la regle est la meme, verifiee ici '
        'specifiquement pour ne pas la confondre avec le cas Paladin '
        'ci-dessus', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          characterClass: const XmlFieldResolution.recognized(_classOption),
          knownSpells: const [
            (level: 1, resolution: XmlFieldResolution.recognized(_spellA)),
          ],
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.spellLines, hasLength(1));
      expect(data.spellLines.single.spellId, _spellA.id);
      expect(data.spellLines.single.status, 'connu');
      expect(data.spellLines.single.sourceClassId, _classOption.id);
    });

    test('sort inné écrit avec le statut "inné" et la classe d\'origine', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          innateSpells: const [
            (level: 0, resolution: XmlFieldResolution.recognized(_spellB)),
          ],
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.spellLines, hasLength(1));
      expect(data.spellLines.single.spellId, _spellB.id);
      expect(data.spellLines.single.status, 'inné');
      expect(data.spellLines.single.sourceClassId, _classOption.id);
    });

    test('un même sort à la fois inné et connu (sort de départ retrouvé '
        'dans la liste de sorts connus) produit deux lignes distinctes, '
        'volontairement non dédoublonnées', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          innateSpells: const [
            (level: 1, resolution: XmlFieldResolution.recognized(_spellA)),
          ],
          knownSpells: const [
            (level: 1, resolution: XmlFieldResolution.recognized(_spellA)),
          ],
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.spellLines, hasLength(2));
      expect(
        data.spellLines.every((line) => line.spellId == _spellA.id),
        isTrue,
      );
      expect(data.spellLines.map((line) => line.status).toSet(), {
        'inné',
        'connu',
      });
    });

    test('un sort non reconnu au niveau aidedd est omis (spell_id non '
        'nullable en base)', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          knownSpells: const [
            (
              level: 1,
              resolution: XmlFieldResolution.unrecognized('Sort maison'),
            ),
          ],
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.spellLines, isEmpty);
    });
  });

  group('XmlImportSaveDataResolver.resolve — sexe', () {
    test('sexe reconnu -> le libellé aidedd tel quel', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(sexe: const XmlFieldResolution.recognized('Femme')),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.sexe, 'Femme');
    });

    test('sexe non résolu avec un jeton brut réel -> le jeton brut, jamais '
        'perdu', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          sexe: const XmlFieldResolution.unrecognized('Autre'),
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.sexe, 'Autre');
    });

    test('sexe absent du XML (jeton technique "(absent)" de '
        'XmlCodedFieldResolver) -> "Non renseigné", jamais la chaîne '
        'technique brute — régression trouvée en construisant l\'export XML '
        '(voir README) : le repli "Non renseigné" était du code mort, '
        '_rawValueOf ne renvoyant jamais null pour ce cas', () {
      final data = XmlImportSaveDataResolver.resolve(
        resolved: _resolved(
          sexe: const XmlFieldResolution.unrecognized('(absent)'),
        ),
        itemCatalog: _itemCatalog,
        skillCatalog: _skillCatalog,
        alignmentCatalog: _alignmentCatalog,
      );

      expect(data.sexe, 'Non renseigné');
    });
  });

  group('XmlImportSaveDataResolver.resolve — sous-race, bonus raciaux, PV', () {
    const nain = RaceOption(
      id: 5,
      name: 'Nain',
      abilityBonuses: {'con': 2},
      traits: [],
      source: '',
    );
    const nainCollines = SubraceOption(
      id: 50,
      raceId: 5,
      name: 'Nain des collines',
      abilityBonuses: {'wis': 1},
      traits: [],
    );
    const flexible = RaceOption(
      id: 6,
      name: 'Conil',
      abilityBonuses: {'choice_flexible': true},
      traits: [],
      source: '',
    );
    const baseScores = {
      'str': 15,
      'dex': 14,
      'con': 13,
      'int': 12,
      'wis': 10,
      'cha': 8,
    };
    const levels = [
      XmlRawLevelEntry(level: 1, hpBrut: 6, abilityIncreases: [-1, -1, -1]),
      XmlRawLevelEntry(level: 2, hpBrut: 4, abilityIncreases: [-1, -1, -1]),
      XmlRawLevelEntry(level: 3, hpBrut: 4, abilityIncreases: [-1, -1, -1]),
    ];

    XmlImportSaveData resolve(XmlCharacterImportResolved resolved) =>
        XmlImportSaveDataResolver.resolve(
          resolved: resolved,
          itemCatalog: _itemCatalog,
          skillCatalog: _skillCatalog,
          alignmentCatalog: _alignmentCatalog,
        );

    test('export aidedd.org : sous-race enregistrée, bonus fixes de la race '
        'et de la sous-race ajoutés, Robustesse naine dans les PV', () {
      final data = resolve(
        _resolved(
          race: const XmlFieldResolution.recognized(nain),
          abilityScores: baseScores,
          levels: levels,
        ).copyWith(subrace: nainCollines),
      );

      expect(data.raceId, nain.id);
      expect(data.subraceId, nainCollines.id);
      expect(data.abilityScores['con'], 15); // 13 + 2
      expect(data.abilityScores['wis'], 11); // 10 + 1
      // (6 + 4 + 4) + 3 × Con +2 + 3 × Nain des collines +1
      expect(data.maxHp, 14 + 6 + 3);
    });

    test('race à bonus flexibles : bonus au choix ajoutés', () {
      final data = resolve(
        _resolved(
          race: const XmlFieldResolution.recognized(flexible),
          abilityScores: baseScores,
        ).copyWith(racialBonusChoices: {'str': 2, 'dex': 1}),
      );

      expect(data.abilityScores['str'], 17);
      expect(data.abilityScores['dex'], 15);
      expect(data.subraceId, isNull);
    });

    test('export de l\'app (<nexusFinalScores>) : scores et PV déjà '
        'définitifs, rien n\'est ajouté', () {
      final data = resolve(
        _resolved(
          race: const XmlFieldResolution.recognized(nain),
          abilityScores: baseScores,
          levels: levels,
        ).copyWith(subrace: nainCollines, scoresIncludeRacialBonuses: true),
      );

      expect(data.abilityScores, baseScores);
      expect(data.maxHp, 14 + 3); // Con 13 : +1 × 3, aucun bonus ajouté
    });

    test('sous-race d\'une autre race que la race retenue : ignorée', () {
      final data = resolve(
        _resolved(abilityScores: baseScores).copyWith(subrace: nainCollines),
      );

      expect(data.subraceId, isNull);
      expect(data.abilityScores['wis'], 10);
    });
  });
}
