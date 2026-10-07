import 'package:flutter_test/flutter_test.dart';
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
  int backgroundId = 1,
  int maxHp = 44,
  int currentHp = 30,
  List<int> skillIds = const [1, 3, 5, 6, 7],
  List<int> languageIds = const [10],
  List<int> spellIds = const [],
  List<int> innateSpellIds = const [],
}) {
  return CharacterEditSnapshot(
    characterId: 'c1',
    name: 'Brunhilde',
    primaryClassId: classId,
    primaryClassLevel: totalLevel,
    totalLevel: totalLevel,
    maxHp: maxHp,
    currentHp: currentHp,
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
      for (final id in skillIds) (skillId: id, proficiency: 'competente'),
    ],
    languageIds: languageIds,
    spells: [
      for (final id in innateSpellIds) (spellId: id, status: 'inné'),
      for (final id in spellIds) (spellId: id, status: 'préparé'),
    ],
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
        (spellId: 100, status: 'préparé'),
        (spellId: 101, status: 'connu'),
      ]);
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
        expect(plan.spellInserts, [(spellId: 103, status: 'préparé')]);
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
  });
}
