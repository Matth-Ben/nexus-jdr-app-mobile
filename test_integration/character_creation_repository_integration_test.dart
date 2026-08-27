import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/equipment_choice_tab.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/spellcasting_rules.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/test_environment.dart';

void main() {
  group('SupabaseCharacterCreationRepository (intégration)', () {
    late SupabaseClient client;
    late ReferenceContent reference;

    setUpAll(() async {
      client = createTestSupabaseClient();
      await signUpTestUser(client);
      reference = await fetchReferenceContent(client);
    });

    test(
      'fetchRaceCatalog résout les noms de race/sous-race via translations',
      () async {
        final repository = SupabaseCharacterCreationRepository(client);

        final catalog = await repository.fetchRaceCatalog();

        final race = catalog.races.singleWhere((r) => r.id == reference.raceId);
        expect(race.name, reference.raceName);
      },
    );

    test('fetchRaceCatalog retourne races/sous-races triées par id croissant '
        '(`.order(\'id\', ascending: true)` — le défaut du package postgrest '
        '2.9.1 est `ascending: false`, voir la note de '
        'SupabaseCharacterCreationRepository.fetchRaceCatalog)', () async {
      final repository = SupabaseCharacterCreationRepository(client);

      final catalog = await repository.fetchRaceCatalog();

      final raceIds = catalog.races.map((r) => r.id).toList();
      expect(raceIds, List<int>.from(raceIds)..sort());
      final subraceIds = catalog.subraces.map((s) => s.id).toList();
      expect(subraceIds, List<int>.from(subraceIds)..sort());
    });

    test('fetchClassCatalog résout le nom et la description de classe via '
        'translations', () async {
      final repository = SupabaseCharacterCreationRepository(client);

      final catalog = await repository.fetchClassCatalog();

      final characterClass = catalog.classes.singleWhere(
        (c) => c.id == reference.classId,
      );
      expect(characterClass.name, reference.className);
      expect(characterClass.description, isNotEmpty);
      expect(characterClass.hitDie, greaterThan(0));
    });

    test('fetchBackgroundCatalog résout le nom, l\'aptitude et les '
        'compétences d\'historique via translations', () async {
      final repository = SupabaseCharacterCreationRepository(client);

      final catalog = await repository.fetchBackgroundCatalog();

      final background = catalog.backgrounds.singleWhere(
        (b) => b.id == reference.backgroundId,
      );
      expect(background.name, reference.backgroundName);
      expect(background.featureName, isNotEmpty);
      expect(background.featureDescription, isNotEmpty);
      expect(background.skillProficiencies, isNotEmpty);
    });

    test(
      'fetchBackgroundCatalog expose `equipment` (étape 7/9 "Équipement de '
      'départ") avec une ligne "Bourse (N po)" pour chaque historique peuplé',
      () async {
        final repository = SupabaseCharacterCreationRepository(client);

        final catalog = await repository.fetchBackgroundCatalog();

        final background = catalog.backgrounds.singleWhere(
          (b) => b.id == reference.backgroundId,
        );
        expect(background.equipment, isNotEmpty);
        expect(
          background.equipment.any(
            (line) => RegExp(r'^Bourse \(\d+ po\)$').hasMatch(line),
          ),
          isTrue,
          reason:
              'Chaque historique peuplé porte une ligne "Bourse (N po)" '
              '(voir la consigne de la tâche qui a produit ce test).',
        );
      },
    );

    test('fetchToolCatalog résout le nom d\'outil/instrument via translations '
        '(entity_type=\'tool\') — étape 5/9 "Compétences et outils"', () async {
      final repository = SupabaseCharacterCreationRepository(client);

      final catalog = await repository.fetchToolCatalog();

      final tool = catalog.tools.singleWhere((t) => t.id == reference.toolId);
      expect(tool.name, reference.toolName);
      expect(tool.category, isNotEmpty);
    });

    test(
      'fetchLanguageCatalog résout le nom de langue via translations '
      '(entity_type=\'language\') — étape 5/9 "Compétences et outils"',
      () async {
        final repository = SupabaseCharacterCreationRepository(client);

        final catalog = await repository.fetchLanguageCatalog();

        final language = catalog.languages.singleWhere(
          (l) => l.id == reference.languageId,
        );
        expect(language.name, reference.languageName);
        expect(language.type, isNotEmpty);
      },
    );

    test('fetchSpellCatalog résout le nom de sort via translations '
        '(entity_type=\'spell\') pour une classe lanceuse de sorts — étape '
        '6/9 "Sorts"', () async {
      final repository = SupabaseCharacterCreationRepository(client);

      final catalog = await repository.fetchSpellCatalog(
        classId: reference.spellcastingClassId as int,
      );

      final spell = catalog.spells.singleWhere(
        (s) => s.id == reference.spellId,
      );
      expect(spell.name, reference.spellName);
      expect(spell.level, inInclusiveRange(0, 9));
      expect(spell.school, isNotEmpty);
      expect(spell.castingTime, isNotEmpty);
    });

    test('fetchSpellCatalog retourne un catalogue vide pour une classe sans '
        'aucune ligne spell_classes (non lanceuse de sorts) plutôt que '
        'd\'échouer', () async {
      final repository = SupabaseCharacterCreationRepository(client);

      // Un identifiant très au-delà de la plage peuplée par les seeds :
      // aucune ligne `spell_classes` ne peut exister pour lui, même
      // rationale qu'un id de classe non lanceuse (Barbare/Guerrier/
      // Moine/Roublard) sans dépendre de savoir lequel des 12 ids réels
      // correspond à l'une de ces 4 classes.
      final catalog = await repository.fetchSpellCatalog(classId: 999999);

      expect(catalog.spells, isEmpty);
    });

    test('fetchItemCatalog résout le nom et la catégorie d\'objet via '
        'translations (entity_type=\'item\') — étape 7/9 "Équipement de '
        'départ"', () async {
      final repository = SupabaseCharacterCreationRepository(client);

      final catalog = await repository.fetchItemCatalog();

      final item = catalog.items.singleWhere((i) => i.id == reference.itemId);
      expect(item.name, reference.itemName);
      expect(item.category, reference.itemCategory);
      expect(item.costAmount, greaterThanOrEqualTo(0));
    });

    test('fetchSkillCatalog résout le nom de compétence via translations '
        '(entity_type=\'skill\') — étape 9/9 "Récapitulatif"', () async {
      final repository = SupabaseCharacterCreationRepository(client);

      final catalog = await repository.fetchSkillCatalog();

      expect(catalog.skills, isNotEmpty);
      final skill = catalog.skills.first;
      expect(skill.name, isNotEmpty);
      expect(skill.abilityId, isNotEmpty);
    });

    test('fetchClassCatalog/fetchBackgroundCatalog/fetchToolCatalog/'
        'fetchLanguageCatalog/fetchItemCatalog/fetchSkillCatalog retournent '
        'chacun leurs lignes triées par id croissant (même garde-fou que '
        'fetchRaceCatalog ci-dessus contre le défaut `ascending: false` du '
        'package postgrest 2.9.1)', () async {
      final repository = SupabaseCharacterCreationRepository(client);

      Iterable<int> sortedCopy(Iterable<int> ids) =>
          List<int>.from(ids)..sort();

      final classIds = (await repository.fetchClassCatalog()).classes
          .map((c) => c.id)
          .toList();
      expect(classIds, sortedCopy(classIds));

      final backgroundIds = (await repository.fetchBackgroundCatalog())
          .backgrounds
          .map((b) => b.id)
          .toList();
      expect(backgroundIds, sortedCopy(backgroundIds));

      final toolIds = (await repository.fetchToolCatalog()).tools
          .map((t) => t.id)
          .toList();
      expect(toolIds, sortedCopy(toolIds));

      final languageIds = (await repository.fetchLanguageCatalog()).languages
          .map((l) => l.id)
          .toList();
      expect(languageIds, sortedCopy(languageIds));

      final itemIds = (await repository.fetchItemCatalog()).items
          .map((i) => i.id)
          .toList();
      expect(itemIds, sortedCopy(itemIds));

      final skillIds = (await repository.fetchSkillCatalog()).skills
          .map((s) => s.id)
          .toList();
      expect(skillIds, sortedCopy(skillIds));
    });

    test('createCharacter crée un personnage lanceur de sorts complet (choix '
        'd\'équipement d\'historique) et peuple toutes les tables enfants '
        'attendues', () async {
      final repository = SupabaseCharacterCreationRepository(client);

      final raceCatalog = await repository.fetchRaceCatalog();
      final classCatalog = await repository.fetchClassCatalog();
      final backgroundCatalog = await repository.fetchBackgroundCatalog();
      final skillCatalog = await repository.fetchSkillCatalog();
      final toolCatalog = await repository.fetchToolCatalog();
      final languageCatalog = await repository.fetchLanguageCatalog();
      final itemCatalog = await repository.fetchItemCatalog();

      final classOption = classCatalog.classes.singleWhere(
        (c) => c.id == reference.spellcastingClassId,
      );
      final spellCatalog = await repository.fetchSpellCatalog(
        classId: classOption.id,
      );
      final backgroundOption = backgroundCatalog.backgrounds.singleWhere(
        (b) => b.id == reference.backgroundId,
      );

      final classSkillName = classOption.skillChoices.choices.isNotEmpty
          ? classOption.skillChoices.choices.first
          : null;
      final languageName =
          backgroundOption.languageChoiceCount != null &&
              languageCatalog.languages.isNotEmpty
          ? languageCatalog.languages.first.name
          : null;
      final hasCantripQuota =
          SpellcastingRules.cantripQuotaFor(classOption.name) > 0;
      final cantripName =
          hasCantripQuota && spellCatalog.spells.any((s) => s.level == 0)
          ? spellCatalog.spells.firstWhere((s) => s.level == 0).name
          : null;
      final levelOneSpellName = spellCatalog.spells.any((s) => s.level == 1)
          ? spellCatalog.spells.firstWhere((s) => s.level == 1).name
          : null;

      final draft = CharacterCreationDraft(
        raceId: reference.raceId as int,
        classId: classOption.id,
        backgroundId: backgroundOption.id,
        abilityScores: const {
          'str': 15,
          'dex': 14,
          'con': 13,
          'int': 12,
          'wis': 10,
          'cha': 8,
        },
        classSkillChoices: classSkillName != null ? [classSkillName] : const [],
        backgroundLanguageChoices: languageName != null
            ? [languageName]
            : const [],
        classCantripChoices: cantripName != null ? [cantripName] : const [],
        classLevelOneSpellChoices: levelOneSpellName != null
            ? [levelOneSpellName]
            : const [],
        equipmentChoiceTab: EquipmentChoiceTab.background,
      );

      final characterId = await repository.createCharacter(
        draft: draft,
        characterName: 'Test Intégration Récapitulatif',
        raceCatalog: raceCatalog,
        classOption: classOption,
        backgroundOption: backgroundOption,
        skillCatalog: skillCatalog,
        toolCatalog: toolCatalog,
        languageCatalog: languageCatalog,
        spellCatalog: spellCatalog,
        itemCatalog: itemCatalog,
      );
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      final characterRow = await client
          .from('characters')
          .select()
          .eq('id', characterId)
          .single();
      expect(characterRow['name'], 'Test Intégration Récapitulatif');
      expect(characterRow['race_id'], reference.raceId);
      expect(characterRow['background_id'], backgroundOption.id);
      expect((characterRow['max_hp'] as num).toInt(), greaterThan(0));
      expect(characterRow['current_hp'], characterRow['max_hp']);
      expect(characterRow['temporary_hp'], 0);
      expect(
        (characterRow['currency_gp'] as num).toInt(),
        greaterThanOrEqualTo(0),
      );

      final classRows = await client
          .from('character_classes')
          .select()
          .eq('character_id', characterId);
      expect(classRows, hasLength(1));
      expect(classRows.single['class_id'], classOption.id);
      expect(classRows.single['is_primary'], isTrue);
      expect(classRows.single['level'], 1);

      final levelHpRows = await client
          .from('character_level_hp')
          .select()
          .eq('character_id', characterId);
      expect(levelHpRows, hasLength(1));
      expect(levelHpRows.single['hp_rolled'], classOption.hitDie);
      expect(levelHpRows.single['method'], 'moyenne');

      final abilityScoreRows = await client
          .from('character_ability_scores')
          .select()
          .eq('character_id', characterId);
      expect(abilityScoreRows, hasLength(6));

      final skillRows = await client
          .from('character_skill_proficiencies')
          .select()
          .eq('character_id', characterId);
      expect(
        skillRows,
        isNotEmpty,
        reason:
            'au moins la compétence de classe et/ou les compétences '
            "d'historique doivent avoir résolu vers un skill_id réel",
      );

      final inventoryRows = await client
          .from('character_inventory')
          .select()
          .eq('character_id', characterId);
      expect(
        inventoryRows,
        isNotEmpty,
        reason:
            "l'onglet Historique doit produire au moins une ligne "
            'character_inventory (voir domain/background_equipment_parser.dart)',
      );

      if (cantripName != null || levelOneSpellName != null) {
        final spellRows = await client
            .from('character_spells')
            .select()
            .eq('character_id', characterId);
        expect(spellRows, isNotEmpty);
        expect(
          spellRows.every((row) => row['source_class_id'] == classOption.id),
          isTrue,
        );
        expect(
          spellRows.every(
            (row) =>
                row['status'] == SpellcastingRules.statusFor(classOption.name),
          ),
          isTrue,
        );
      }
    });

    test('createCharacter peuple aussi character_tool_proficiencies pour un '
        'choix interactif d\'outil de classe (gap de couverture identifié en '
        'revue QA : le test "personnage complet" ci-dessus ne force jamais '
        'classToolChoices, donc n\'exerce jamais cette table enfant contre le '
        'vrai schéma — cette table a une colonne tool_id nullable + '
        'custom_text, jamais vérifiée en intégration avant ce test)', () async {
      final repository = SupabaseCharacterCreationRepository(client);

      final raceCatalog = await repository.fetchRaceCatalog();
      final classCatalog = await repository.fetchClassCatalog();
      final backgroundCatalog = await repository.fetchBackgroundCatalog();
      final skillCatalog = await repository.fetchSkillCatalog();
      final toolCatalog = await repository.fetchToolCatalog();
      final languageCatalog = await repository.fetchLanguageCatalog();
      final itemCatalog = await repository.fetchItemCatalog();

      final classOption = classCatalog.classes.singleWhere(
        (c) => c.id == reference.classId,
      );
      final backgroundOption = backgroundCatalog.backgrounds.singleWhere(
        (b) => b.id == reference.backgroundId,
      );
      final toolOption = toolCatalog.tools.singleWhere(
        (t) => t.id == reference.toolId,
      );

      final draft = CharacterCreationDraft(
        raceId: reference.raceId as int,
        classId: classOption.id,
        backgroundId: backgroundOption.id,
        abilityScores: const {
          'str': 10,
          'dex': 10,
          'con': 10,
          'int': 10,
          'wis': 10,
          'cha': 10,
        },
        // Force un choix interactif d'outil de classe résolvable vers un
        // vrai tool_id, indépendamment de ce que classOption.toolChoice
        // propose réellement (voir le rationale du test) — un nom d'outil
        // réel de toolCatalog suffit à exercer le chemin d'écriture,
        // ToolProficiencyResolver ne validant pas que ce nom appartient
        // effectivement au choix de la classe (cette validation, si elle
        // doit exister, vit à l'étape 5/9, pas dans le resolver de
        // l'étape 9/9).
        classToolChoices: [toolOption.name],
        equipmentChoiceTab: EquipmentChoiceTab.background,
      );

      final characterId = await repository.createCharacter(
        draft: draft,
        characterName: 'Test Intégration Outils',
        raceCatalog: raceCatalog,
        classOption: classOption,
        backgroundOption: backgroundOption,
        skillCatalog: skillCatalog,
        toolCatalog: toolCatalog,
        languageCatalog: languageCatalog,
        spellCatalog: const SpellCatalog(spells: []),
        itemCatalog: itemCatalog,
      );
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      final toolRows = await client
          .from('character_tool_proficiencies')
          .select()
          .eq('character_id', characterId);
      expect(toolRows, hasLength(1));
      expect(toolRows.single['tool_id'], toolOption.id);
      expect(toolRows.single['custom_text'], isNull);
    });

    test(
      'createCharacter nettoie la ligne characters (best-effort) si un '
      'insert de table enfant échoue après coup — simulé avec un class_id '
      'inexistant (violation de contrainte FK sur character_classes)',
      () async {
        final repository = SupabaseCharacterCreationRepository(client);

        final raceCatalog = await repository.fetchRaceCatalog();
        final backgroundCatalog = await repository.fetchBackgroundCatalog();
        final backgroundOption = backgroundCatalog.backgrounds.singleWhere(
          (b) => b.id == reference.backgroundId,
        );

        const bogusClassOption = ClassOption(
          id: 999999999,
          name: 'Classe inexistante',
          description: '',
          hitDie: 6,
        );
        const uniqueCharacterName = 'Test Intégration Nettoyage Échec';

        final draft = CharacterCreationDraft(
          raceId: reference.raceId as int,
          classId: bogusClassOption.id,
          backgroundId: backgroundOption.id,
          abilityScores: const {'con': 10},
          equipmentChoiceTab: EquipmentChoiceTab.background,
        );

        await expectLater(
          repository.createCharacter(
            draft: draft,
            characterName: uniqueCharacterName,
            raceCatalog: raceCatalog,
            classOption: bogusClassOption,
            backgroundOption: backgroundOption,
            skillCatalog: const SkillCatalog(skills: []),
            toolCatalog: const ToolCatalog(tools: []),
            languageCatalog: const LanguageCatalog(languages: []),
            spellCatalog: const SpellCatalog(spells: []),
            itemCatalog: const ItemCatalog(items: []),
          ),
          throwsA(isA<CharacterCreationFailure>()),
        );

        final leftoverRows = await client
            .from('characters')
            .select('id')
            .eq('name', uniqueCharacterName);
        expect(
          leftoverRows,
          isEmpty,
          reason:
              'la ligne characters créée avant l\'échec de l\'insert '
              'character_classes (class_id inexistant) doit avoir été '
              'supprimée par le nettoyage best-effort de createCharacter',
        );
      },
    );
  });
}
