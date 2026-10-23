import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/character_edit_hydrator.dart';
import 'package:personnages/features/character_creation/domain/character_edit_planner.dart';
import 'package:personnages/features/character_creation/domain/character_edit_snapshot.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/class_skill_choices.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_option.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/skill_option.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_option.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';

const _skills = SkillCatalog(
  skills: [
    SkillOption(id: 1, name: 'Athlétisme', abilityId: 'str'),
    SkillOption(id: 2, name: 'Intimidation', abilityId: 'cha'),
    SkillOption(id: 3, name: 'Perception', abilityId: 'wis'),
    SkillOption(id: 4, name: 'Survie', abilityId: 'wis'),
    SkillOption(id: 5, name: 'Religion', abilityId: 'int'),
    SkillOption(id: 6, name: 'Médecine', abilityId: 'wis'),
    SkillOption(id: 7, name: 'Discrétion', abilityId: 'dex'),
  ],
);
const _tools = ToolCatalog(tools: []);
const _languages = LanguageCatalog(
  languages: [
    LanguageOption(id: 10, name: 'Elfique', type: 'standard'),
    LanguageOption(id: 11, name: 'Nain', type: 'standard'),
  ],
);

const _guerrier = ClassOption(
  id: 1,
  name: 'Guerrier',
  description: '',
  hitDie: 10,
  skillChoices: ClassSkillChoices(
    count: 2,
    choices: ['Athlétisme', 'Intimidation', 'Perception', 'Survie'],
  ),
);
const _clerc = ClassOption(
  id: 2,
  name: 'Clerc',
  description: '',
  hitDie: 8,
  skillChoices: ClassSkillChoices(count: 2, choices: ['Religion', 'Médecine']),
);

/// `classes.id = 5`, le VRAI id du Guerrier (`ClassChoiceRules
/// ::_kindByClassId`) — distinct de [_guerrier] ci-dessus (id de fixture 1,
/// sans rapport avec les ids réels) : nécessaire pour les tests du choix
/// nommé de niveau 1 (Style de combat) — correctif D102
/// (`docs/dette-technique.md`).
const _realGuerrier = ClassOption(
  id: 5,
  name: 'Guerrier',
  description: '',
  hitDie: 10,
  skillChoices: ClassSkillChoices(
    count: 2,
    choices: ['Athlétisme', 'Intimidation', 'Perception', 'Survie'],
  ),
);

/// `classes.id = 9`, le VRAI id du Roublard — correctif D102, même
/// rationale que [_realGuerrier] (l'Expertise elle-même ne dépend d'aucun
/// id de classe particulier côté `CharacterEditPlanner`, mais la
/// substitution outils de voleur a besoin de `grantedToolNames`).
const _realRoublard = ClassOption(
  id: 9,
  name: 'Roublard',
  description: '',
  hitDie: 8,
  skillChoices: ClassSkillChoices(count: 1, choices: ['Discrétion']),
  grantedToolNames: ['outils de voleur'],
);
const _ermite = BackgroundOption(
  id: 1,
  name: 'Ermite',
  skillProficiencies: ['Médecine', 'Religion'],
  featureName: 'Découverte',
  featureDescription: '',
  languageChoiceCount: 1,
);
const _soldat = BackgroundOption(
  id: 2,
  name: 'Soldat',
  skillProficiencies: ['Athlétisme', 'Intimidation'],
  featureName: 'Grade',
  featureDescription: '',
);
const _clercSpells = SpellCatalog(
  spells: [
    SpellOption(
      id: 100,
      name: 'Flamme sacrée',
      level: 0,
      school: '',
      castingTime: '',
    ),
    SpellOption(id: 101, name: 'Soins', level: 1, school: '', castingTime: ''),
    SpellOption(
      id: 102,
      name: 'Bénédiction',
      level: 1,
      school: '',
      castingTime: '',
    ),
    // Sort mineur de la liste du Clerc, qu'un Tieffelin reçoit aussi en sort
    // inné racial.
    SpellOption(
      id: 103,
      name: 'Thaumaturgie',
      level: 0,
      school: '',
      castingTime: '',
    ),
  ],
);

/// Sort inné racial absent de la liste du Clerc.
const _innateOffListSpellId = 200;

CharacterEditSnapshot _snapshot({
  int totalLevel = 5,
  int classId = 1,
  int? subclassId,
  int backgroundId = 1,
  int maxHp = 44,
  int currentHp = 30,
  String edition = '2014',
  List<int> skillIds = const [1, 3, 5, 6, 7],
  // Sous-ensemble de [skillIds] dont la maîtrise est 'expertise' plutôt que
  // 'competente' — correctif D102 (`docs/dette-technique.md`).
  List<int> expertiseSkillIds = const [],
  List<int> languageIds = const [10],
  List<int> spellIds = const [],
  List<int> innateSpellIds = const [],
  // Lignes `character_class_options` de niveau 1 déjà enrichies du
  // `choice_type`/`class_id`/`subclass_id` de leur `class_features` — voir
  // `ClassOptionRow` (correctif D102).
  List<ClassOptionRow> classOptions = const [],
}) {
  return CharacterEditSnapshot(
    characterId: 'c1',
    name: 'Brunhilde',
    primaryClassId: classId,
    subclassId: subclassId,
    primaryClassLevel: totalLevel,
    totalLevel: totalLevel,
    maxHp: maxHp,
    currentHp: currentHp,
    edition: edition,
    raceId: 3,
    backgroundId: backgroundId,
    abilityScores: const {
      'str': 16,
      'dex': 12,
      'con': 14,
      'int': 10,
      'wis': 13,
      'cha': 8,
    },
    identity: const {'sexe': 'Femme', 'age': ''},
    texts: const {'backstory_text': 'Née au pied des montagnes.'},
    skills: [
      for (final id in skillIds)
        (
          skillId: id,
          proficiency: expertiseSkillIds.contains(id)
              ? 'expertise'
              : 'competente',
        ),
    ],
    languageIds: languageIds,
    spells: [
      for (final id in innateSpellIds)
        (spellId: id, status: SpellStatus.innate),
      for (final id in spellIds) (spellId: id, status: SpellStatus.prepared),
    ],
    classOptions: classOptions,
  );
}

CharacterCreationDraft _hydrate(
  CharacterEditSnapshot snapshot, {
  ClassOption classOption = _guerrier,
  BackgroundOption backgroundOption = _ermite,
  SpellCatalog? spellCatalog,
}) => CharacterEditHydrator.toDraft(
  snapshot: snapshot,
  classOption: classOption,
  backgroundOption: backgroundOption,
  skillCatalog: _skills,
  toolCatalog: _tools,
  languageCatalog: _languages,
  spellCatalog: spellCatalog,
);

CharacterEditPlan _plan(
  CharacterEditSnapshot snapshot,
  CharacterCreationDraft original,
  CharacterCreationDraft edited, {
  ClassOption originalClass = _guerrier,
  ClassOption editedClass = _guerrier,
  BackgroundOption originalBackground = _ermite,
  BackgroundOption editedBackground = _ermite,
  SpellCatalog? originalSpellCatalog,
  SpellCatalog? editedSpellCatalog,
}) => CharacterEditPlanner.plan(
  snapshot: snapshot,
  original: original,
  edited: edited,
  originalClass: originalClass,
  editedClass: editedClass,
  originalBackground: originalBackground,
  editedBackground: editedBackground,
  skillCatalog: _skills,
  toolCatalog: _tools,
  languageCatalog: _languages,
  originalSpellCatalog: originalSpellCatalog,
  editedSpellCatalog: editedSpellCatalog,
);

void main() {
  group('CharacterEditSnapshot.fromRow', () {
    test('lit identifiants, classe principale, niveau total et tables '
        'enfants', () {
      final snapshot = CharacterEditSnapshot.fromRow({
        'id': 'c1',
        'name': 'Brunhilde',
        'max_hp': 44,
        'current_hp': 30,
        'race_id': 3,
        'background_id': 1,
        'alignment_id': null,
        'sexe': 'Femme',
        'backstory_text': 'Née au pied des montagnes.',
        'character_classes': [
          {'class_id': 4, 'subclass_id': null, 'level': 2, 'is_primary': false},
          {'class_id': 1, 'subclass_id': 9, 'level': 3, 'is_primary': true},
        ],
        'character_ability_scores': [
          {'ability_id': 'con', 'score': 14},
        ],
        'character_skill_proficiencies': [
          {'skill_id': 3, 'proficiency': 'expertise'},
        ],
        'character_tool_proficiencies': [
          {'tool_id': null, 'custom_text': 'Kit de voleur'},
        ],
        'character_languages': [
          {'language_id': 10},
        ],
        'character_spells': [
          {'spell_id': 100, 'status': 'connu'},
        ],
      });

      expect(snapshot.primaryClassId, 1);
      expect(snapshot.subclassId, 9);
      expect(snapshot.totalLevel, 5);
      expect(snapshot.abilityScores, {'con': 14});
      expect(snapshot.identity['sexe'], 'Femme');
      expect(snapshot.identity['hair'], '');
      expect(snapshot.texts['backstory_text'], 'Née au pied des montagnes.');
      expect(snapshot.skills.single.proficiency, 'expertise');
      expect(snapshot.tools.single.customText, 'Kit de voleur');
      expect(snapshot.languageIds, [10]);
      expect(snapshot.spells.single.spellId, 100);
    });

    test('classSpells écarte les lignes au statut inné, y compris quand le '
        'même sort a aussi une ligne ordinaire', () {
      final snapshot = CharacterEditSnapshot.fromRow({
        'id': 'c1',
        'character_spells': [
          {'spell_id': 103, 'status': 'inné'},
          {'spell_id': 100, 'status': 'inné'},
          {'spell_id': 100, 'status': 'préparé'},
          {'spell_id': 101, 'status': 'connu'},
        ],
      });

      expect(snapshot.spells, hasLength(4));
      expect(snapshot.classSpells, [
        (spellId: 100, status: SpellStatus.prepared),
        (spellId: 101, status: SpellStatus.known),
      ]);
    });

    // Chantier "choix d'édition 2014/2024 par personnage".
    test('edition absente de la ligne -> \'2014\' (repli défensif, même '
        'rationale que maxHp/currentHp)', () {
      final snapshot = CharacterEditSnapshot.fromRow({'id': 'c1'});

      expect(snapshot.edition, '2014');
    });

    test('edition = \'2024\' en base est bien remontée telle quelle', () {
      final snapshot = CharacterEditSnapshot.fromRow({
        'id': 'c1',
        'edition': '2024',
      });

      expect(snapshot.edition, '2024');
    });

    // Correctif D102 (`docs/dette-technique.md`).
    group('classOptions (choix nommés de niveau 1)', () {
      test('résout choice_type/class_id/subclass_id via classFeaturesById '
          '(requête séparée, jamais une jointure Postgrest embarquée)', () {
        final snapshot = CharacterEditSnapshot.fromRow(
          {
            'id': 'c1',
            'character_class_options': [
              {'class_feature_id': 15, 'level': 1, 'chosen_value': 'Défense'},
            ],
          },
          classFeaturesById: const {
            15: (choiceType: 'style_combat', classId: 5, subclassId: null),
          },
        );

        expect(snapshot.classOptions, [
          (
            featureClassId: 5,
            featureSubclassId: null,
            choiceType: 'style_combat',
            chosenValue: 'Défense',
          ),
        ]);
      });

      test('écarte les lignes de niveau != 1 (hors périmètre du brouillon '
          "de l'assistant)", () {
        final snapshot = CharacterEditSnapshot.fromRow(
          {
            'id': 'c1',
            'character_class_options': [
              {'class_feature_id': 99, 'level': 6, 'chosen_value': 'Lame'},
            ],
          },
          classFeaturesById: const {
            99: (choiceType: 'infusion', classId: 10, subclassId: null),
          },
        );

        expect(snapshot.classOptions, isEmpty);
      });

      test('une ligne class_feature_id absente de classFeaturesById (cas '
          'défensif) garde chosen_value mais choiceType/featureClassId/'
          'featureSubclassId restent null — ne correspondra ensuite à '
          'aucune résolution de `CharacterEditHydrator`', () {
        final snapshot = CharacterEditSnapshot.fromRow({
          'id': 'c1',
          'character_class_options': [
            {'class_feature_id': 404, 'level': 1, 'chosen_value': 'Défense'},
          ],
        });

        expect(snapshot.classOptions, [
          (
            featureClassId: null,
            featureSubclassId: null,
            choiceType: null,
            chosenValue: 'Défense',
          ),
        ]);
      });

      test('absence de character_class_options -> liste vide (compatibilité '
          'arrière, personnage antérieur au correctif D99/D102)', () {
        final snapshot = CharacterEditSnapshot.fromRow({'id': 'c1'});

        expect(snapshot.classOptions, isEmpty);
      });
    });
  });

  group('CharacterEditHydrator', () {
    test('ne reprend comme compétences de classe que celles de la liste de '
        'la classe, hors historique, dans la limite du quota', () {
      final draft = _hydrate(_snapshot());

      // 1 Athlétisme et 3 Perception : choix de classe ; 5/6 : historique ;
      // 7 Discrétion : obtenue autrement (jamais dans le brouillon).
      expect(draft.classSkillChoices, ['Athlétisme', 'Perception']);
      expect(draft.backgroundLanguageChoices, ['Elfique']);
      expect(draft.characterName, 'Brunhilde');
      expect(draft.sexe, 'Femme');
      expect(draft.age, isNull);
      expect(draft.abilityScores?['con'], 14);
      expect(draft.abilityScoreMethod, isNull);
    });

    test('niveau 1 lanceur : sorts mineurs et de niveau 1 repris', () {
      final draft = _hydrate(
        _snapshot(totalLevel: 1, classId: 2, spellIds: [100, 101]),
        classOption: _clerc,
        spellCatalog: _clercSpells,
      );

      expect(draft.classCantripChoices, ['Flamme sacrée']);
      expect(draft.classLevelOneSpellChoices, ['Soins']);
    });

    test("un sort inné racial présent dans la liste de la classe n'est pas "
        'repris comme choix de classe et ne consomme pas le quota', () {
      // Tieffelin Clerc : Thaumaturgie (103) innée, lue AVANT les trois
      // sorts mineurs choisis en classe (quota du Clerc : 3).
      final draft = _hydrate(
        _snapshot(
          totalLevel: 1,
          classId: 2,
          innateSpellIds: [103],
          spellIds: [100, 101],
        ),
        classOption: _clerc,
        spellCatalog: _clercSpells,
      );

      expect(draft.classCantripChoices, ['Flamme sacrée']);
      expect(draft.classLevelOneSpellChoices, ['Soins']);
    });

    test('reporte snapshot.edition telle quelle dans le brouillon (jamais le '
        'défaut \'2014\' du constructeur quand le personnage est en 2024) — '
        'chantier "choix d\'édition 2014/2024 par personnage"', () {
      final draft = _hydrate(_snapshot(edition: '2024'));

      expect(draft.edition, '2024');
    });

    // Choix nommés de niveau 1 — correctif D102 (`docs/dette-technique.md`).
    group('choix nommés de niveau 1 (correctif D102)', () {
      test('classFeatureChoiceValue pré-rempli pour un Guerrier (Style de '
          'combat) depuis character_class_options', () {
        final draft = _hydrate(
          _snapshot(
            totalLevel: 1,
            classId: 5,
            classOptions: const [
              (
                featureClassId: 5,
                featureSubclassId: null,
                choiceType: 'style_combat',
                chosenValue: 'Défense',
              ),
            ],
          ),
          classOption: _realGuerrier,
        );

        expect(draft.classFeatureChoiceValue, 'Défense');
      });

      test('classFeatureChoiceValue reste null pour une classe sans ce '
          'choix (Clerc), même si character_class_options porte une ligne '
          "d'une AUTRE classe", () {
        final draft = _hydrate(
          _snapshot(
            totalLevel: 1,
            classId: 2,
            classOptions: const [
              (
                featureClassId: 5,
                featureSubclassId: null,
                choiceType: 'style_combat',
                chosenValue: 'Défense',
              ),
            ],
          ),
          classOption: _clerc,
        );

        expect(draft.classFeatureChoiceValue, isNull);
      });

      test('subclassFeatureChoiceValue pré-rempli (Ancêtre draconique) '
          'depuis character_class_options via subclass_id', () {
        final draft = _hydrate(
          _snapshot(
            totalLevel: 1,
            classId: 6,
            subclassId: 12,
            classOptions: const [
              (
                featureClassId: null,
                featureSubclassId: 12,
                choiceType: 'ancetre_draconique',
                chosenValue: 'Dragon rouge',
              ),
            ],
          ),
          classOption: const ClassOption(
            id: 6,
            name: 'Ensorceleur',
            description: '',
            hitDie: 6,
          ),
        );

        expect(draft.subclassFeatureChoiceValue, 'Dragon rouge');
      });

      test("subclassFeatureChoiceValue reste null quand choice_type == "
          "'sous_classe' (déjà le choix de sous-classe lui-même, pas ce "
          'second choix)', () {
        final draft = _hydrate(
          _snapshot(
            totalLevel: 1,
            classId: 6,
            subclassId: 12,
            classOptions: const [
              (
                featureClassId: null,
                featureSubclassId: 12,
                choiceType: 'sous_classe',
                chosenValue: 'Lignage draconique',
              ),
            ],
          ),
        );

        expect(draft.subclassFeatureChoiceValue, isNull);
      });

      test('expertiseSkillChoices dérivé de snapshot.skills '
          "(proficiency == 'expertise'), jamais de "
          'character_class_options (purement descriptive)', () {
        final draft = _hydrate(
          _snapshot(
            totalLevel: 1,
            classId: 9,
            skillIds: const [1, 7],
            expertiseSkillIds: const [7],
          ),
          classOption: _realRoublard,
        );

        // Compétence 7 = 'Discrétion' dans [_skills] ; 1 = 'Athlétisme'
        // (maîtrisée normalement, pas en Expertise).
        expect(draft.expertiseSkillChoices, ['Discrétion']);
      });

      test('expertiseThievesToolsSubstitution résolu via '
          'character_class_options (purement descriptive, aucun bonus '
          'chiffré ne la porte)', () {
        final draft = _hydrate(
          _snapshot(
            totalLevel: 1,
            classId: 9,
            edition: '2014',
            skillIds: const [7],
            expertiseSkillIds: const [7],
            classOptions: const [
              (
                featureClassId: 9,
                featureSubclassId: null,
                choiceType: 'expertise',
                chosenValue: 'outils de voleur',
              ),
            ],
          ),
          classOption: _realRoublard,
        );

        expect(draft.expertiseThievesToolsSubstitution, isTrue);
      });

      test('expertiseThievesToolsSubstitution reste faux sans ligne '
          'character_class_options correspondante, même avec une '
          'Expertise de compétence par ailleurs', () {
        final draft = _hydrate(
          _snapshot(
            totalLevel: 1,
            classId: 9,
            skillIds: const [7],
            expertiseSkillIds: const [7],
          ),
          classOption: _realRoublard,
        );

        expect(draft.expertiseThievesToolsSubstitution, isFalse);
      });

      test('les 4 champs restent à leur valeur par défaut sans aucune '
          'ligne character_class_options ni compétence en Expertise '
          '(compatibilité arrière, personnage antérieur au correctif '
          'D102)', () {
        final draft = _hydrate(
          _snapshot(totalLevel: 1, classId: 5),
          classOption: _realGuerrier,
        );

        expect(draft.classFeatureChoiceValue, isNull);
        expect(draft.subclassFeatureChoiceValue, isNull);
        expect(draft.expertiseSkillChoices, isEmpty);
        expect(draft.expertiseThievesToolsSubstitution, isFalse);
      });
    });
  });

  group('CharacterEditPlanner', () {
    test('sans changement de jeu : seules les colonnes characters sont '
        'réécrites, avec les textes vides coalescés en chaîne vide', () {
      final snapshot = _snapshot();
      final original = _hydrate(snapshot);
      final plan = _plan(
        snapshot,
        original,
        original.copyWith(characterName: 'Brunhilde la Brave', age: '32 ans'),
      );

      expect(plan.characterUpdate['name'], 'Brunhilde la Brave');
      expect(plan.characterUpdate['age'], '32 ans');
      expect(plan.characterUpdate['traits_text'], '');
      expect(plan.characterUpdate['max_hp'], 44);
      expect(plan.characterUpdate['current_hp'], 30);
      expect(plan.classChange, isNull);
      expect(plan.abilityScores, isNull);
      expect(plan.skillDeletes, isEmpty);
      expect(plan.skillInserts, isEmpty);
      expect(plan.languageDeletes, isEmpty);
      expect(plan.languageInserts, isEmpty);
    });

    test("changer une compétence de classe ne touche pas à celle obtenue "
        "autrement", () {
      final snapshot = _snapshot();
      final original = _hydrate(snapshot);
      final plan = _plan(
        snapshot,
        original,
        original.copyWith(classSkillChoices: ['Athlétisme', 'Survie']),
      );

      expect(plan.skillDeletes, {3});
      expect(plan.skillInserts, {4});
    });

    test("changer d'historique échange ses compétences et retire ses "
        "langues au choix", () {
      final snapshot = _snapshot();
      final original = _hydrate(snapshot);
      final plan = _plan(
        snapshot,
        original,
        original.copyWith(
          backgroundId: 2,
          classSkillChoices: ['Perception', 'Survie'],
          backgroundLanguageChoices: const [],
        ),
        editedBackground: _soldat,
      );

      // Religion (5) et Médecine (6) de l'Ermite retirées ; Athlétisme (1)
      // reste (désormais via le Soldat) ; Intimidation (2) et Survie (4)
      // ajoutées ; Discrétion (7) intacte.
      expect(plan.skillDeletes, {5, 6});
      expect(plan.skillInserts, {2, 4});
      expect(plan.languageDeletes, {10});
      expect(plan.characterUpdate['background_id'], 2);
    });

    test('Constitution modifiée au niveau 5 : PV max ajustés de la '
        'différence de modificateur × niveau, dégâts subis conservés', () {
      final snapshot = _snapshot();
      final original = _hydrate(snapshot);
      final plan = _plan(
        snapshot,
        original,
        original.copyWith(
          abilityScores: {...?original.abilityScores, 'con': 16},
        ),
      );

      // +2 → +3 : +1 × 5 niveaux ; 14 PV de dégâts subis conservés.
      expect(plan.characterUpdate['max_hp'], 49);
      expect(plan.characterUpdate['current_hp'], 35);
      expect(plan.abilityScores?['con'], 16);
    });

    test('au-delà du niveau 1, un changement de classe est ignoré', () {
      final snapshot = _snapshot();
      final original = _hydrate(snapshot);
      final plan = _plan(
        snapshot,
        original,
        original.copyWith(classId: 2),
        editedClass: _clerc,
      );

      expect(plan.classChange, isNull);
      expect(plan.characterUpdate['max_hp'], 44);
    });

    test('niveau 1 : changer de classe recalcule les PV et remplace les '
        "sorts de l'ancienne classe", () {
      final snapshot = _snapshot(
        totalLevel: 1,
        classId: 2,
        maxHp: 10,
        currentHp: 10,
        spellIds: [100, 101],
      );
      final original = _hydrate(
        snapshot,
        classOption: _clerc,
        spellCatalog: _clercSpells,
      );
      final plan = _plan(
        snapshot,
        original,
        original.copyWith(
          classId: 1,
          classCantripChoices: const [],
          classLevelOneSpellChoices: const [],
        ),
        originalClass: _clerc,
        originalSpellCatalog: _clercSpells,
        editedSpellCatalog: const SpellCatalog(spells: []),
      );

      expect(plan.classChange?.classId, 1);
      expect(plan.classChange?.hpRolled, 10);
      expect(plan.classChange?.classChanged, isTrue);
      // d10 + modificateur de Constitution (+2).
      expect(plan.characterUpdate['max_hp'], 12);
      expect(plan.characterUpdate['current_hp'], 12);
      expect(plan.spellDeletes, {100, 101});
    });

    test('niveau 1 : remplacer un sort ne touche qu’à ce sort', () {
      final snapshot = _snapshot(
        totalLevel: 1,
        classId: 2,
        maxHp: 10,
        currentHp: 10,
        spellIds: [100, 101],
      );
      final original = _hydrate(
        snapshot,
        classOption: _clerc,
        spellCatalog: _clercSpells,
      );
      final plan = _plan(
        snapshot,
        original,
        original.copyWith(classLevelOneSpellChoices: ['Bénédiction']),
        originalClass: _clerc,
        editedClass: _clerc,
        originalSpellCatalog: _clercSpells,
        editedSpellCatalog: _clercSpells,
      );

      expect(plan.classChange, isNull);
      expect(plan.spellDeletes, {101});
      expect(plan.spellInserts.map((spell) => spell.spellId), [102]);
      // D40 (`docs/dette-technique.md`) : avant ce correctif,
      // `CharacterEditRepository.save` écrivait `source_class_id:
      // plan.classChange?.classId`, toujours `null` ici puisque NI la
      // classe NI la sous-classe ne changent — alors que la classe
      // d'origine (Clerc, id 2) est connue et inchangée.
      expect(plan.spellSourceClassId, 2);
    });

    // D09 : les sorts innés viennent de la race (`racial_innate_spells`),
    // aucune modification de classe ne doit les faire partir.
    group('sorts innés raciaux (D09)', () {
      test('niveau 1 : changer de classe ne supprime pas un sort inné', () {
        final snapshot = _snapshot(
          totalLevel: 1,
          classId: 2,
          maxHp: 10,
          currentHp: 10,
          innateSpellIds: [_innateOffListSpellId],
          spellIds: [100, 101],
        );
        final original = _hydrate(
          snapshot,
          classOption: _clerc,
          spellCatalog: _clercSpells,
        );
        final plan = _plan(
          snapshot,
          original,
          original.copyWith(
            classId: 1,
            classCantripChoices: const [],
            classLevelOneSpellChoices: const [],
          ),
          originalClass: _clerc,
          originalSpellCatalog: _clercSpells,
          editedSpellCatalog: const SpellCatalog(spells: []),
        );

        expect(plan.classChange?.classChanged, isTrue);
        expect(plan.spellDeletes, {100, 101});
        expect(plan.spellInserts, isEmpty);
        // Aucun sort à insérer : jamais de classe d'origine à calculer.
        expect(plan.spellSourceClassId, isNull);
      });

      test('niveau 1 : passer à une classe de lanceur ne supprime pas un '
          'sort inné de la liste de cette classe', () {
        // Tieffelin Guerrier qui devient Clerc sans choisir Thaumaturgie.
        final snapshot = _snapshot(
          totalLevel: 1,
          maxHp: 12,
          currentHp: 12,
          innateSpellIds: [103],
        );
        final original = _hydrate(snapshot);
        final plan = _plan(
          snapshot,
          original,
          original.copyWith(
            classId: 2,
            classCantripChoices: ['Flamme sacrée'],
            classLevelOneSpellChoices: ['Soins'],
          ),
          editedClass: _clerc,
          editedSpellCatalog: _clercSpells,
        );

        expect(plan.spellDeletes, isEmpty);
        expect(plan.spellInserts.map((spell) => spell.spellId), [100, 101]);
      });

      test('niveau 1, classe inchangée : un sort inné de la liste de la '
          "classe n'est ni supprimé ni réécrit", () {
        final snapshot = _snapshot(
          totalLevel: 1,
          classId: 2,
          maxHp: 10,
          currentHp: 10,
          innateSpellIds: [103],
          spellIds: [100, 101],
        );
        final original = _hydrate(
          snapshot,
          classOption: _clerc,
          spellCatalog: _clercSpells,
        );
        final plan = _plan(
          snapshot,
          original,
          original.copyWith(classLevelOneSpellChoices: ['Bénédiction']),
          originalClass: _clerc,
          editedClass: _clerc,
          originalSpellCatalog: _clercSpells,
          editedSpellCatalog: _clercSpells,
        );

        expect(plan.spellDeletes, {101});
        expect(plan.spellInserts.map((spell) => spell.spellId), [102]);
      });

      test('changer de sous-classe seule ne touche à aucun sort', () {
        final snapshot = _snapshot(
          totalLevel: 1,
          classId: 2,
          maxHp: 10,
          currentHp: 10,
          innateSpellIds: [103, _innateOffListSpellId],
          spellIds: [100, 101],
        );
        final original = _hydrate(
          snapshot,
          classOption: _clerc,
          spellCatalog: _clercSpells,
        );
        final plan = _plan(
          snapshot,
          original,
          original.copyWith(subclassId: 7),
          originalClass: _clerc,
          editedClass: _clerc,
          originalSpellCatalog: _clercSpells,
          editedSpellCatalog: _clercSpells,
        );

        expect(plan.classChange?.classChanged, isFalse);
        expect(plan.classChange?.subclassId, 7);
        expect(plan.spellDeletes, isEmpty);
        expect(plan.spellInserts, isEmpty);
      });

      test('sort en double (inné + ordinaire) désélectionné côté classe : '
          "seul l'identifiant du sort est planifié, la ligne innée étant "
          'protégée par le dépôt', () {
        final snapshot = _snapshot(
          totalLevel: 1,
          classId: 2,
          maxHp: 10,
          currentHp: 10,
          innateSpellIds: [103],
          spellIds: [103, 100, 101],
        );
        final original = _hydrate(
          snapshot,
          classOption: _clerc,
          spellCatalog: _clercSpells,
        );
        expect(original.classCantripChoices, ['Thaumaturgie', 'Flamme sacrée']);

        final plan = _plan(
          snapshot,
          original,
          original.copyWith(classCantripChoices: ['Flamme sacrée']),
          originalClass: _clerc,
          editedClass: _clerc,
          originalSpellCatalog: _clercSpells,
          editedSpellCatalog: _clercSpells,
        );

        // La ligne ordinaire part ; `SupabaseCharacterEditRepository.save`
        // exclut les lignes 'inné' de cette suppression.
        expect(plan.spellDeletes, {103});
        expect(plan.spellInserts, isEmpty);
      });

      test('choisir côté classe un sort déjà inné ajoute une ligne '
          'ordinaire sans toucher à la ligne innée', () {
        final snapshot = _snapshot(
          totalLevel: 1,
          classId: 2,
          maxHp: 10,
          currentHp: 10,
          innateSpellIds: [103],
          spellIds: [100, 101],
        );
        final original = _hydrate(
          snapshot,
          classOption: _clerc,
          spellCatalog: _clercSpells,
        );
        final plan = _plan(
          snapshot,
          original,
          original.copyWith(
            classCantripChoices: ['Flamme sacrée', 'Thaumaturgie'],
          ),
          originalClass: _clerc,
          editedClass: _clerc,
          originalSpellCatalog: _clercSpells,
          editedSpellCatalog: _clercSpells,
        );

        expect(plan.spellDeletes, isEmpty);
        expect(plan.spellInserts, [
          (spellId: 103, status: SpellStatus.prepared),
        ]);
      });

      test('au-delà du niveau 1, aucun sort planifié', () {
        final snapshot = _snapshot(
          classId: 2,
          innateSpellIds: [103, _innateOffListSpellId],
          spellIds: [100, 101],
        );
        final original = _hydrate(snapshot, classOption: _clerc);
        final plan = _plan(
          snapshot,
          original,
          original.copyWith(classId: 1),
          originalClass: _clerc,
          editedSpellCatalog: const SpellCatalog(spells: []),
        );

        expect(plan.spellDeletes, isEmpty);
        expect(plan.spellInserts, isEmpty);
      });
    });

    // D79 (`docs/dette-technique.md`) : [CharacterEditPlanner.plan] marquait
    // `'préparé'` tout le quota de sélection d'une classe à préparation
    // (Clerc, Druide, Magicien, Paladin, Artificier), sans jamais recalculer
    // le vrai modificateur de caractéristique — même règle et même plafond
    // (`PreparedSpellsLimit.limitFor`, via
    // `SpellSelectionResolver.capToPreparedLimit`) qu'à la création
    // (`CharacterCreationRepository.createCharacter`).
    group('plafond des sorts préparés (D79)', () {
      test('multiclassage niveau 1 vers un lanceur à préparation, Sagesse '
          "faible : seul le plafond RAW reste 'préparé'", () {
        final snapshot = _snapshot(
          totalLevel: 1,
          classId: 1,
          maxHp: 10,
          currentHp: 10,
        );
        final original = _hydrate(snapshot);
        final plan = _plan(
          snapshot,
          original,
          original.copyWith(
            classId: 2,
            // Sagesse 8 (mod -1) : plafond = niveau 1 + (-1) -> plancher 1
            // (`PreparedSpellsLimit.limitFor`).
            abilityScores: {...?original.abilityScores, 'wis': 8},
            classCantripChoices: const ['Flamme sacrée'],
            classLevelOneSpellChoices: const ['Soins', 'Bénédiction'],
          ),
          editedClass: _clerc,
          editedSpellCatalog: _clercSpells,
        );

        expect(plan.spellDeletes, isEmpty);
        // Quota de sélection inchangé (3 lignes écrites), mais une seule
        // (le cantrip ne comptant jamais, voir [PreparedSpellsLimit])
        // reste 'préparé' parmi les sorts de niveau 1 ; l'autre devient
        // 'connu'.
        expect(plan.spellInserts, [
          (spellId: 100, status: SpellStatus.prepared),
          (spellId: 101, status: SpellStatus.prepared),
          (spellId: 102, status: SpellStatus.known),
        ]);
      });

      test('même multiclassage, Sagesse suffisante : tout le quota '
          "sélectionné reste 'préparé'", () {
        final snapshot = _snapshot(
          totalLevel: 1,
          classId: 1,
          maxHp: 10,
          currentHp: 10,
        );
        final original = _hydrate(snapshot);
        final plan = _plan(
          snapshot,
          original,
          original.copyWith(
            classId: 2,
            // Sagesse 16 (mod +3) : plafond = niveau 1 + 3 = 4, largement
            // suffisant pour les 2 sorts de niveau 1 choisis ci-dessous.
            abilityScores: {...?original.abilityScores, 'wis': 16},
            classCantripChoices: const ['Flamme sacrée'],
            classLevelOneSpellChoices: const ['Soins', 'Bénédiction'],
          ),
          editedClass: _clerc,
          editedSpellCatalog: _clercSpells,
        );

        expect(plan.spellInserts, [
          (spellId: 100, status: SpellStatus.prepared),
          (spellId: 101, status: SpellStatus.prepared),
          (spellId: 102, status: SpellStatus.prepared),
        ]);
      });
    });

    // Choix nommés de niveau 1 — correctif D102 (`docs/dette-technique.md`).
    group('choix nommés de niveau 1 (correctif D102)', () {
      group('Style de combat/Ennemi juré (choix de CLASSE)', () {
        test('classe inchangée, SEULE la valeur change : '
            'classFeatureChoiceWrite porte la nouvelle valeur, aucun '
            'classChange', () {
          final snapshot = _snapshot(
            totalLevel: 1,
            classId: 5,
            classOptions: const [
              (
                featureClassId: 5,
                featureSubclassId: null,
                choiceType: 'style_combat',
                chosenValue: 'Défense',
              ),
            ],
          );
          final original = _hydrate(snapshot, classOption: _realGuerrier);
          expect(original.classFeatureChoiceValue, 'Défense');

          final plan = _plan(
            snapshot,
            original,
            original.copyWith(classFeatureChoiceValue: 'Duel'),
            originalClass: _realGuerrier,
            editedClass: _realGuerrier,
          );

          expect(plan.classChange, isNull);
          expect(plan.classFeatureChoiceWrite, (
            classId: 5,
            choiceType: 'style_combat',
            chosenValue: 'Duel',
          ));
        });

        test('classe ET valeur inchangées : aucune écriture (ne pas '
            'réécrire character_class_options sans rapport avec ce '
            'choix)', () {
          final snapshot = _snapshot(
            totalLevel: 1,
            classId: 5,
            classOptions: const [
              (
                featureClassId: 5,
                featureSubclassId: null,
                choiceType: 'style_combat',
                chosenValue: 'Défense',
              ),
            ],
          );
          final original = _hydrate(snapshot, classOption: _realGuerrier);

          final plan = _plan(
            snapshot,
            original,
            original.copyWith(),
            originalClass: _realGuerrier,
            editedClass: _realGuerrier,
          );

          expect(plan.classFeatureChoiceWrite, isNull);
        });

        test('changement de classe VERS le Guerrier avec une valeur : '
            'classFeatureChoiceWrite porte la classe APRÈS modification', () {
          final snapshot = _snapshot(
            totalLevel: 1,
            classId: 2,
            maxHp: 10,
            currentHp: 10,
          );
          final original = _hydrate(snapshot, classOption: _clerc);

          final plan = _plan(
            snapshot,
            original,
            original.copyWith(
              classId: 5,
              classFeatureChoiceValue: 'Défense',
              classCantripChoices: const [],
              classLevelOneSpellChoices: const [],
            ),
            originalClass: _clerc,
            editedClass: _realGuerrier,
          );

          expect(plan.classChange?.classChanged, isTrue);
          expect(plan.classFeatureChoiceWrite, (
            classId: 5,
            choiceType: 'style_combat',
            chosenValue: 'Défense',
          ));
        });

        test('changement de classe VERS une classe SANS ce choix (Clerc) : '
            'classFeatureChoiceWrite reste null', () {
          final snapshot = _snapshot(
            totalLevel: 1,
            classId: 5,
            classOptions: const [
              (
                featureClassId: 5,
                featureSubclassId: null,
                choiceType: 'style_combat',
                chosenValue: 'Défense',
              ),
            ],
          );
          final original = _hydrate(snapshot, classOption: _realGuerrier);

          final plan = _plan(
            snapshot,
            original,
            // `CharacterCreationDraftController.setClass` aurait déjà remis
            // `classFeatureChoiceValue` à `null` ici (classe différente) —
            // simulé directement, le planificateur fait confiance au
            // brouillon final.
            original.copyWith(classId: 2, classFeatureChoiceValue: null),
            originalClass: _realGuerrier,
            editedClass: _clerc,
          );

          expect(plan.classChange?.classChanged, isTrue);
          expect(plan.classFeatureChoiceWrite, isNull);
        });
      });

      group('Ancêtre draconique (second choix de SOUS-CLASSE)', () {
        const ensorceleur = ClassOption(
          id: 6,
          name: 'Ensorceleur',
          description: '',
          hitDie: 6,
        );

        test('sous-classe inchangée, SEULE la valeur change : '
            'subclassFeatureChoiceWrite porte la nouvelle valeur', () {
          final snapshot = _snapshot(
            totalLevel: 1,
            classId: 6,
            subclassId: 12,
            classOptions: const [
              (
                featureClassId: null,
                featureSubclassId: 12,
                choiceType: 'ancetre_draconique',
                chosenValue: 'Dragon rouge',
              ),
            ],
          );
          final original = _hydrate(snapshot, classOption: ensorceleur);
          expect(original.subclassFeatureChoiceValue, 'Dragon rouge');

          final plan = _plan(
            snapshot,
            original,
            original.copyWith(subclassFeatureChoiceValue: 'Dragon bleu'),
            originalClass: ensorceleur,
            editedClass: ensorceleur,
          );

          expect(plan.classChange, isNull);
          expect(plan.subclassFeatureChoiceWrite, (
            subclassId: 12,
            chosenValue: 'Dragon bleu',
          ));
        });

        test('sous-classe ET valeur inchangées : aucune écriture', () {
          final snapshot = _snapshot(
            totalLevel: 1,
            classId: 6,
            subclassId: 12,
            classOptions: const [
              (
                featureClassId: null,
                featureSubclassId: 12,
                choiceType: 'ancetre_draconique',
                chosenValue: 'Dragon rouge',
              ),
            ],
          );
          final original = _hydrate(snapshot, classOption: ensorceleur);

          final plan = _plan(
            snapshot,
            original,
            original.copyWith(),
            originalClass: ensorceleur,
            editedClass: ensorceleur,
          );

          expect(plan.subclassFeatureChoiceWrite, isNull);
        });

        test('changement de SOUS-CLASSE seule (même classe) avec une '
            'nouvelle valeur : subclassFeatureChoiceWrite porte le NOUVEAU '
            'subclassId, classChange marque un changement de sous-classe '
            'sans changement de classe', () {
          final snapshot = _snapshot(
            totalLevel: 1,
            classId: 6,
            subclassId: 12,
            classOptions: const [
              (
                featureClassId: null,
                featureSubclassId: 12,
                choiceType: 'ancetre_draconique',
                chosenValue: 'Dragon rouge',
              ),
            ],
          );
          final original = _hydrate(snapshot, classOption: ensorceleur);

          final plan = _plan(
            snapshot,
            original,
            original.copyWith(
              subclassId: 13,
              subclassFeatureChoiceValue: 'Dragon bleu',
            ),
            originalClass: ensorceleur,
            editedClass: ensorceleur,
          );

          expect(plan.classChange?.classChanged, isFalse);
          expect(plan.classChange?.subclassId, 13);
          expect(plan.subclassFeatureChoiceWrite, (
            subclassId: 13,
            chosenValue: 'Dragon bleu',
          ));
        });
      });

      group('Expertise du Roublard', () {
        test('ajoute une compétence à l\'Expertise : upgrade cette '
            "compétence, expertiseOptionsWrite porte les 2 noms (l'ancienne "
            'ET la nouvelle)', () {
          final snapshot = _snapshot(
            totalLevel: 1,
            classId: 9,
            backgroundId: 2, // `_soldat` : Athlétisme/Intimidation.
            // 1/2 déjà maîtrisées via l'historique (octroi automatique), 7
            // via la classe — cohérent avec `original`/`edited` ci-dessous,
            // qui gardent tous les deux ce même historique : évite un
            // `skillInserts` parasite (Intimidation) sans rapport avec ce
            // que ce test vérifie.
            skillIds: const [1, 2, 7],
            expertiseSkillIds: const [7],
          );
          final original = _hydrate(
            snapshot,
            classOption: _realRoublard,
            backgroundOption: _soldat,
          );
          expect(original.expertiseSkillChoices, ['Discrétion']);

          final plan = _plan(
            snapshot,
            original,
            original.copyWith(
              expertiseSkillChoices: ['Discrétion', 'Athlétisme'],
            ),
            originalClass: _realRoublard,
            editedClass: _realRoublard,
            originalBackground: _soldat,
            editedBackground: _soldat,
          );

          expect(plan.expertiseSkillUpgrades, {1});
          expect(plan.expertiseSkillDowngrades, isEmpty);
          // Comparées champ par champ plutôt que le record entier : le
          // record expose `chosenValues` en `List<String>`, qui ne
          // redéfinit pas `==` (comparaison par référence) — comparer le
          // record directement masquerait une vraie divergence de contenu
          // derrière un faux négatif, contrairement à `expect` sur une
          // `List` isolée (comparaison profonde par `equals()`).
          expect(plan.expertiseOptionsWrite?.classId, 9);
          expect(plan.expertiseOptionsWrite?.chosenValues, [
            'Discrétion',
            'Athlétisme',
          ]);
        });

        test('retire une compétence de l\'Expertise (reste maîtrisée '
            'autrement) : downgrade cette compétence à \'competente\', '
            'expertiseOptionsWrite ne porte plus que celle restante', () {
          final snapshot = _snapshot(
            totalLevel: 1,
            classId: 9,
            backgroundId: 2, // `_soldat` : Athlétisme/Intimidation.
            skillIds: const [1, 2, 7],
            expertiseSkillIds: const [1, 7],
          );
          final original = _hydrate(
            snapshot,
            classOption: _realRoublard,
            backgroundOption: _soldat,
          );

          final plan = _plan(
            snapshot,
            original,
            original.copyWith(expertiseSkillChoices: ['Discrétion']),
            originalClass: _realRoublard,
            editedClass: _realRoublard,
            originalBackground: _soldat,
            editedBackground: _soldat,
          );

          expect(plan.expertiseSkillUpgrades, isEmpty);
          expect(plan.expertiseSkillDowngrades, {1});
          expect(plan.expertiseOptionsWrite?.classId, 9);
          expect(plan.expertiseOptionsWrite?.chosenValues, ['Discrétion']);
        });

        test('aucun changement : aucune écriture, aucun upgrade/downgrade', () {
          final snapshot = _snapshot(
            totalLevel: 1,
            classId: 9,
            skillIds: const [7],
            expertiseSkillIds: const [7],
          );
          final original = _hydrate(snapshot, classOption: _realRoublard);

          final plan = _plan(
            snapshot,
            original,
            original.copyWith(),
            originalClass: _realRoublard,
            editedClass: _realRoublard,
          );

          expect(plan.expertiseOptionsWrite, isNull);
          expect(plan.expertiseSkillUpgrades, isEmpty);
          expect(plan.expertiseSkillDowngrades, isEmpty);
        });

        test('substitution outils de voleur activée (édition 2014) : '
            'expertiseOptionsWrite ajoute le nom de l\'outil, sans upgrade/'
            'downgrade de compétence (jamais un bonus chiffré, voir '
            '`ExpertiseStepSelection`)', () {
          final snapshot = _snapshot(
            totalLevel: 1,
            classId: 9,
            edition: '2014',
            skillIds: const [7],
            expertiseSkillIds: const [7],
          );
          final original = _hydrate(snapshot, classOption: _realRoublard);
          expect(original.expertiseThievesToolsSubstitution, isFalse);

          final plan = _plan(
            snapshot,
            original,
            original.copyWith(expertiseThievesToolsSubstitution: true),
            originalClass: _realRoublard,
            editedClass: _realRoublard,
          );

          expect(plan.expertiseOptionsWrite?.classId, 9);
          expect(plan.expertiseOptionsWrite?.chosenValues, [
            'Discrétion',
            'outils de voleur',
          ]);
          expect(plan.expertiseSkillUpgrades, isEmpty);
          expect(plan.expertiseSkillDowngrades, isEmpty);
        });

        test('une compétence retirée ENTIÈREMENT (plus du tout maîtrisée, '
            'déjà dans skillDeletes) : jamais de downgrade séparé, '
            'expertiseOptionsWrite reste null (aucune valeur restante à '
            'écrire)', () {
          final snapshot = _snapshot(
            totalLevel: 1,
            classId: 9,
            skillIds: const [7],
            expertiseSkillIds: const [7],
          );
          final original = _hydrate(snapshot, classOption: _realRoublard);
          expect(original.classSkillChoices, ['Discrétion']);
          expect(original.expertiseSkillChoices, ['Discrétion']);

          final plan = _plan(
            snapshot,
            original,
            original.copyWith(
              classSkillChoices: const [],
              expertiseSkillChoices: const [],
            ),
            originalClass: _realRoublard,
            editedClass: _realRoublard,
          );

          expect(plan.skillDeletes, {7});
          expect(plan.expertiseSkillDowngrades, isEmpty);
          expect(plan.expertiseSkillUpgrades, isEmpty);
          expect(plan.expertiseOptionsWrite, isNull);
        });
      });

      test('au-delà du niveau 1 (canChangeClass faux) : les 3 écritures '
          'restent nulles/vides même si le brouillon édité porte des '
          'valeurs différentes — discipline défensive, ces écrans ne '
          'devraient de toute façon jamais y être atteints', () {
        final snapshot = _snapshot(
          totalLevel: 5,
          classId: 5,
          classOptions: const [
            (
              featureClassId: 5,
              featureSubclassId: null,
              choiceType: 'style_combat',
              chosenValue: 'Défense',
            ),
          ],
        );
        final original = _hydrate(snapshot, classOption: _realGuerrier);

        final plan = _plan(
          snapshot,
          original,
          original.copyWith(classFeatureChoiceValue: 'Duel'),
          originalClass: _realGuerrier,
          editedClass: _realGuerrier,
        );

        expect(plan.classFeatureChoiceWrite, isNull);
        expect(plan.subclassFeatureChoiceWrite, isNull);
        expect(plan.expertiseOptionsWrite, isNull);
        expect(plan.expertiseSkillUpgrades, isEmpty);
        expect(plan.expertiseSkillDowngrades, isEmpty);
      });
    });
  });
}
