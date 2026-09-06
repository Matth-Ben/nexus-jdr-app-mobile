import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/test_environment.dart';

/// Tests d'intégration des méthodes de `SupabaseCharacterRepository` ajoutées
/// pour l'écran "Montée de niveau" — `addXp`/`fetchLevelUpLevelData`/
/// `applyLevelUp` (increment 1), l'étape "Choix à faire" (increment 2 :
/// résolution des sous-classes disponibles, écriture ASI sur les deux
/// tables, `character_classes.subclass_id`, `character_class_options`) et
/// l'étape "Sorts" (increment 3 : recalcul complet de
/// `character_spell_slots`, voir `domain/spell_slot_progression.dart`) —
/// voir `character_repository_integration_test.dart` pour le rationale
/// général de ce dossier.
void main() {
  group('SupabaseCharacterRepository — montée de niveau (intégration)', () {
    late SupabaseClient client;
    late ReferenceContent reference;
    late String ownerId;
    // Base drift en mémoire : ce fichier n'exerce jamais le chemin de
    // secours "cache" de `fetchCharacterDetail` (couvert par les tests
    // unitaires de `character_repository_test.dart`), seulement le
    // constructeur de `SupabaseCharacterRepository`, qui prend désormais un
    // `ReferenceDataCache` en dépendance.
    late AppDatabase cacheDb;
    late ReferenceDataCache cache;
    late PendingCharacterWriteQueue pendingWrites;

    setUpAll(() async {
      client = createTestSupabaseClient();
      await signUpTestUser(client);
      reference = await fetchReferenceContent(client);
      ownerId = client.auth.currentUser!.id;
      cacheDb = AppDatabase(NativeDatabase.memory());
      cache = ReferenceDataCache(cacheDb);
      pendingWrites = PendingCharacterWriteQueue(cacheDb);
    });

    tearDownAll(() async {
      await cacheDb.close();
    });

    test('addXp écrit characters.xp en base', () async {
      final character = await client
          .from('characters')
          .insert({
            'owner_id': ownerId,
            'name': 'Test Intégration XP',
            'xp': 100,
          })
          .select('id')
          .single();
      final characterId = character['id'] as String;
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        const AlwaysOnlineConnectivityChecker(),
      );
      await repository.addXp(characterId: characterId, newXp: 500);

      final row = await client
          .from('characters')
          .select('xp')
          .eq('id', characterId)
          .single();
      expect(row['xp'], 500);
    });

    test('fetchLevelUpLevelData reflète exactement les lignes class_features '
        '(choice_type et aptitudes automatiques) du vrai schéma, noms résolus '
        'via translations', () async {
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        const AlwaysOnlineConnectivityChecker(),
      );

      final allRows = await client
          .from('class_features')
          .select('id, level, choice_type')
          .eq('class_id', reference.classId)
          .order('level');
      expect(
        allRows,
        isNotEmpty,
        reason:
            'Classe de référence #${reference.classId} sans aucune '
            'aptitude côté seed — vérifier supabase db reset côté dépôt '
            'web.',
      );

      final targetLevel = (allRows.first['level'] as num).toInt();
      final rowsAtLevel = allRows
          .where((row) => (row['level'] as num).toInt() == targetLevel)
          .toList();
      final blockingRow = rowsAtLevel.firstWhere(
        (row) => row['choice_type'] != null,
        orElse: () => const {},
      );
      final expectedAutomaticIds = rowsAtLevel
          .where((row) => row['choice_type'] == null)
          .map((row) => row['id'] as int)
          .toSet();

      final data = await repository.fetchLevelUpLevelData(
        classId: reference.classId,
        targetLevel: targetLevel,
      );

      expect(
        data.choiceType,
        blockingRow.isEmpty ? isNull : blockingRow['choice_type'],
      );
      expect(
        data.automaticFeatures.map((feature) => feature.id).toSet(),
        expectedAutomaticIds,
      );

      if (expectedAutomaticIds.isNotEmpty) {
        final firstId = expectedAutomaticIds.first;
        final translation = await client
            .from('translations')
            .select('value')
            .eq('entity_type', 'class_feature')
            .eq('entity_id', firstId.toString())
            .eq('field_name', 'name')
            .eq('locale', 'fr')
            .maybeSingle();
        final expectedName = translation?['value'] as String?;
        if (expectedName != null) {
          final feature = data.automaticFeatures.singleWhere(
            (f) => f.id == firstId,
          );
          expect(feature.name, expectedName);
        }
      }
    });

    test('applyLevelUp incrémente character_classes.level, ajoute hpGain à '
        'max_hp/current_hp, et insère une ligne character_level_hp', () async {
      final character = await client
          .from('characters')
          .insert({
            'owner_id': ownerId,
            'name': 'Test Intégration Montée de niveau',
            'max_hp': 20,
            'current_hp': 15,
          })
          .select('id')
          .single();
      final characterId = character['id'] as String;
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      await client.from('character_classes').insert({
        'character_id': characterId,
        'class_id': reference.classId,
        'level': 3,
        'is_primary': true,
      });

      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        const AlwaysOnlineConnectivityChecker(),
      );
      final result = await repository.applyLevelUp(
        characterId: characterId,
        classId: reference.classId,
        // Nom de la classe de référence (`classes.id = 1`, "Barbare" côté
        // seed actuel) : non lanceuse de sorts, donc sans effet sur
        // `character_spell_slots` ici — ce test ne porte pas sur l'étape
        // "Sorts" (increment 3, voir le groupe dédié plus bas).
        className: reference.className,
        isMulticlassing: false,
        hpRolled: 6,
        hpMethod: 'lance',
        hpGain: 8,
      );

      expect(result.newLevel, 4);
      expect(result.newMaxHp, 28);
      expect(result.newCurrentHp, 23);

      final classRow = await client
          .from('character_classes')
          .select('level')
          .eq('character_id', characterId)
          .single();
      expect(classRow['level'], 4);

      final characterRow = await client
          .from('characters')
          .select('max_hp, current_hp')
          .eq('id', characterId)
          .single();
      expect(characterRow['max_hp'], 28);
      expect(characterRow['current_hp'], 23);

      final levelHpRows = await client
          .from('character_level_hp')
          .select('level, hp_rolled, method')
          .eq('character_id', characterId);
      expect(levelHpRows, hasLength(1));
      expect(levelHpRows.single['level'], 4);
      expect(levelHpRows.single['hp_rolled'], 6);
      expect(levelHpRows.single['method'], 'lance');
    });

    test('applyLevelUp lève une CharacterFailure si le personnage n\'a '
        'aucune ligne character_classes', () async {
      final character = await client
          .from('characters')
          .insert({'owner_id': ownerId, 'name': 'Test Intégration Sans classe'})
          .select('id')
          .single();
      final characterId = character['id'] as String;
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        const AlwaysOnlineConnectivityChecker(),
      );

      await expectLater(
        repository.applyLevelUp(
          characterId: characterId,
          classId: reference.classId,
          className: reference.className,
          isMulticlassing: false,
          hpRolled: 5,
          hpMethod: 'moyenne',
          hpGain: 5,
        ),
        throwsA(isA<CharacterFailure>()),
      );
    });

    group('étape "Choix à faire" (increment 2)', () {
      test('fetchLevelUpLevelData résout availableSubclasses et '
          "choiceClassFeatureId pour un choice_type 'sous_classe', noms "
          'résolus via translations', () async {
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );

        final subclassFeatureRow = await client
            .from('class_features')
            .select('id, class_id, level')
            .eq('choice_type', 'sous_classe')
            .limit(1)
            .maybeSingle();
        expect(
          subclassFeatureRow,
          isNotNull,
          reason:
              "Aucune ligne class_features.choice_type = 'sous_classe' côté "
              'seed — vérifier supabase db reset côté dépôt web.',
        );

        final classId = subclassFeatureRow!['class_id'] as Object;
        final targetLevel = (subclassFeatureRow['level'] as num).toInt();

        final expectedSubclassRows = await client
            .from('subclasses')
            .select('id')
            .eq('class_id', classId)
            .eq('available_from_level', targetLevel);
        expect(
          expectedSubclassRows,
          isNotEmpty,
          reason:
              'Aucune sous-classe disponible pour class_id=$classId à '
              'available_from_level=$targetLevel — incohérence entre '
              'class_features et subclasses côté seed.',
        );

        final data = await repository.fetchLevelUpLevelData(
          classId: classId,
          targetLevel: targetLevel,
        );

        expect(data.choiceType, 'sous_classe');
        expect(data.choiceClassFeatureId, subclassFeatureRow['id']);
        expect(
          data.availableSubclasses.map((option) => option.id).toSet(),
          expectedSubclassRows.map((row) => row['id'] as Object).toSet(),
        );
        for (final option in data.availableSubclasses) {
          expect(
            option.name,
            isNot(startsWith('Sous-classe #')),
            reason:
                'Traduction manquante pour la sous-classe #${option.id} '
                '— seeds du dépôt web incomplets ?',
          );
        }
      });

      test('applyLevelUp avec un choix ASI écrit character_ability_scores '
          '(score final) ET character_ability_increases (historique, '
          "source: 'asi') pour chaque caractéristique augmentée", () async {
        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration ASI',
              'max_hp': 20,
              'current_hp': 15,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': reference.classId,
          'level': 3,
          'is_primary': true,
        });
        await client.from('character_ability_scores').insert([
          {'character_id': characterId, 'ability_id': 'str', 'score': 10},
          {'character_id': characterId, 'ability_id': 'con', 'score': 12},
        ]);

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        final result = await repository.applyLevelUp(
          characterId: characterId,
          classId: reference.classId,
          className: reference.className,
          isMulticlassing: false,
          hpRolled: 6,
          hpMethod: 'lance',
          hpGain: 8,
          choice: const LevelUpChoiceSelection.abilityScoreImprovement({
            'str': 1,
            'con': 1,
          }),
        );

        expect(result.newLevel, 4);

        final scoreRows = await client
            .from('character_ability_scores')
            .select('ability_id, score')
            .eq('character_id', characterId)
            .inFilter('ability_id', ['str', 'con']);
        final scoresByAbility = {
          for (final row in scoreRows)
            row['ability_id'] as String: (row['score'] as num).toInt(),
        };
        expect(scoresByAbility, {'str': 11, 'con': 13});

        // `ascending: true` explicite : le package `postgrest` (2.9.1) a un
        // défaut `ascending: false` contre-intuitif pour `.order(...)` —
        // même piège déjà documenté sur `_buildCharacterDetailPayload`/
        // `_mapCharacterDetailPayload` de `character_repository.dart`.
        final increaseRows = await client
            .from('character_ability_increases')
            .select('level, ability_id, increase, source')
            .eq('character_id', characterId)
            .order('ability_id', ascending: true);
        expect(increaseRows, hasLength(2));
        expect(increaseRows[0]['ability_id'], 'con');
        expect(increaseRows[0]['level'], 4);
        expect(increaseRows[0]['increase'], 1);
        expect(increaseRows[0]['source'], 'asi');
        expect(increaseRows[1]['ability_id'], 'str');
        expect(increaseRows[1]['level'], 4);
        expect(increaseRows[1]['increase'], 1);
        expect(increaseRows[1]['source'], 'asi');
      });

      test('applyLevelUp avec un choix sous-classe écrit '
          'character_classes.subclass_id, combiné avec level dans le même '
          'UPDATE', () async {
        // Trié par `available_from_level` décroissant : évite de tomber sur
        // une sous-classe disponible dès le niveau 1 (`character_classes.level
        // = availableFromLevel - 1` vaudrait alors 0, hors plage valide).
        final subclassRow = await client
            .from('subclasses')
            .select('id, class_id, available_from_level')
            .order('available_from_level', ascending: false)
            .limit(1)
            .single();
        final classId = subclassRow['class_id'] as Object;
        final subclassId = subclassRow['id'] as Object;
        final availableFromLevel = (subclassRow['available_from_level'] as num)
            .toInt();

        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Sous-classe',
              'max_hp': 20,
              'current_hp': 15,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': classId,
          'level': availableFromLevel - 1,
          'is_primary': true,
        });

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        final result = await repository.applyLevelUp(
          characterId: characterId,
          classId: classId,
          // `className` n'a pas besoin de correspondre à `classId` ici :
          // seul son effet sur `character_spell_slots` en dépend (increment
          // 3), hors périmètre de ce test (sous-classe).
          className: reference.className,
          isMulticlassing: false,
          hpRolled: 5,
          hpMethod: 'moyenne',
          hpGain: 5,
          choice: LevelUpChoiceSelection.subclass(subclassId),
        );

        expect(result.newLevel, availableFromLevel);

        final classRow = await client
            .from('character_classes')
            .select('level, subclass_id')
            .eq('character_id', characterId)
            .single();
        expect(classRow['level'], availableFromLevel);
        expect(classRow['subclass_id'], subclassId);
      });

      test('applyLevelUp avec un choix de style de combat/ennemi juré '
          'insère character_class_options (class_feature_id/level/'
          'chosen_value)', () async {
        // Trié par `level` décroissant : même rationale que le test
        // sous-classe ci-dessus, évite `character_classes.level =
        // targetLevel - 1` = 0 (hors plage valide) si la 1ʳᵉ ligne trouvée
        // était à level=1 (ex. style de combat du Guerrier).
        final optionFeatureRow = await client
            .from('class_features')
            .select('id, class_id, level, choice_type')
            .inFilter('choice_type', ['style_combat', 'ennemi_jure'])
            .order('level', ascending: false)
            .limit(1)
            .maybeSingle();
        expect(
          optionFeatureRow,
          isNotNull,
          reason:
              "Aucune ligne class_features.choice_type in "
              "('style_combat', 'ennemi_jure') côté seed — vérifier "
              'supabase db reset côté dépôt web.',
        );

        final classFeatureId = (optionFeatureRow!['id'] as num).toInt();
        final classId = optionFeatureRow['class_id'] as Object;
        final targetLevel = (optionFeatureRow['level'] as num).toInt();
        final choiceType = optionFeatureRow['choice_type'] as String;
        const chosenValue = 'Duel';

        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Choix de classe',
              'max_hp': 20,
              'current_hp': 15,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': classId,
          'level': targetLevel - 1,
          'is_primary': true,
        });

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        final choice = choiceType == 'style_combat'
            ? LevelUpChoiceSelection.fightingStyle(
                classFeatureId: classFeatureId,
                chosenValue: chosenValue,
              )
            : LevelUpChoiceSelection.favoredEnemy(
                classFeatureId: classFeatureId,
                chosenValue: chosenValue,
              );

        await repository.applyLevelUp(
          characterId: characterId,
          classId: classId,
          className: reference.className,
          isMulticlassing: false,
          hpRolled: 5,
          hpMethod: 'moyenne',
          hpGain: 5,
          choice: choice,
        );

        final optionRows = await client
            .from('character_class_options')
            .select('class_feature_id, level, chosen_value')
            .eq('character_id', characterId);
        expect(optionRows, hasLength(1));
        expect(optionRows.single['class_feature_id'], classFeatureId);
        expect(optionRows.single['level'], targetLevel);
        expect(optionRows.single['chosen_value'], chosenValue);
      });
    });

    group('étape "Sorts" (increment 3)', () {
      /// `classes.id` dont le nom traduit `fr` vaut exactement [name] —
      /// contrairement à [ReferenceContent] (qui ne garantit qu'*une*
      /// classe/traduction quelconque), ces tests ont besoin d'une classe
      /// précise (`Clerc`/`Guerrier`) pour que `className` corresponde à une
      /// entrée connue de `SpellSlotProgression`. Échoue explicitement si le
      /// seed du dépôt web ne contient plus cette classe.
      Future<Object> classIdByName(String name) async {
        final translation = await client
            .from('translations')
            .select('entity_id')
            .eq('entity_type', 'class')
            .eq('field_name', 'name')
            .eq('locale', 'fr')
            .eq('value', name)
            .maybeSingle();
        expect(
          translation,
          isNotNull,
          reason:
              'Aucune classe "$name" trouvée côté seed — vérifier '
              'supabase db reset côté dépôt web (ce nom est attendu tel '
              'quel par domain/spell_slot_progression.dart).',
        );
        // `translations.entity_id` est `text` (clé générique partagée par
        // toutes les entités traduites), mais `classes.id`/
        // `character_classes.class_id` sont des `integer` côté schéma réel —
        // `applyLevelUp`/`_classIdAsInt` s'attendent à un `num`, jamais un
        // `String`, comme c'est toujours le cas en production (lu depuis une
        // colonne entière, jamais depuis `translations`). Parser ici plutôt
        // que de propager un `String` qui ferait échouer le cast interne.
        return int.parse(translation!['entity_id'] as String);
      }

      test('recalcule character_spell_slots pour un lanceur complet (Clerc) : '
          'upsert des nouveaux paliers, préserve slots_used déjà présent tant '
          "qu'il reste cohérent avec le nouveau total", () async {
        final clercId = await classIdByName('Clerc');

        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Sorts Clerc',
              'max_hp': 10,
              'current_hp': 10,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': clercId,
          'level': 1,
          'is_primary': true,
        });

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );

        // Niveau 1 -> 2 : Clerc niveau 2 = [3,0,...] (table
        // `SpellSlotProgression`). Aucune ligne `character_spell_slots`
        // préexistante : `slots_used` démarre à 0.
        await repository.applyLevelUp(
          characterId: characterId,
          classId: clercId,
          className: 'Clerc',
          isMulticlassing: false,
          hpRolled: 5,
          hpMethod: 'moyenne',
          hpGain: 5,
        );

        final afterLevel2 = await client
            .from('character_spell_slots')
            .select('slot_level, slots_total, slots_used')
            .eq('character_id', characterId)
            .order('slot_level', ascending: true);
        expect(afterLevel2, hasLength(1));
        expect(afterLevel2.single['slot_level'], 1);
        expect(afterLevel2.single['slots_total'], 3);
        expect(afterLevel2.single['slots_used'], 0);

        // Simule un joueur ayant déjà consommé 2 des 3 emplacements de
        // niveau 1 avant de monter de niveau.
        await client
            .from('character_spell_slots')
            .update({'slots_used': 2})
            .eq('character_id', characterId)
            .eq('slot_level', 1);

        // Niveau 2 -> 3 : Clerc niveau 3 = [4,2,...] — le palier 1 se
        // renforce (3 -> 4, `slots_used` doit rester 2, pas réinitialisé à
        // 0), le palier 2 se débloque (0 -> 2, `slots_used` démarre à 0,
        // aucune ligne préexistante).
        await repository.applyLevelUp(
          characterId: characterId,
          classId: clercId,
          className: 'Clerc',
          isMulticlassing: false,
          hpRolled: 5,
          hpMethod: 'moyenne',
          hpGain: 5,
        );

        final afterLevel3 = await client
            .from('character_spell_slots')
            .select('slot_level, slots_total, slots_used')
            .eq('character_id', characterId)
            .order('slot_level', ascending: true);
        expect(afterLevel3, hasLength(2));
        expect(afterLevel3[0]['slot_level'], 1);
        expect(afterLevel3[0]['slots_total'], 4);
        expect(afterLevel3[0]['slots_used'], 2);
        expect(afterLevel3[1]['slot_level'], 2);
        expect(afterLevel3[1]['slots_total'], 2);
        expect(afterLevel3[1]['slots_used'], 0);
      });

      test('replie slots_used sur le nouveau slots_total si un slots_used '
          'existant le dépasse (filet de sécurité, ne devrait jamais arriver '
          'en pratique)', () async {
        final clercId = await classIdByName('Clerc');

        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Sorts Clerc Filet',
              'max_hp': 10,
              'current_hp': 10,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': clercId,
          'level': 1,
          'is_primary': true,
        });

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        await repository.applyLevelUp(
          characterId: characterId,
          classId: clercId,
          className: 'Clerc',
          isMulticlassing: false,
          hpRolled: 5,
          hpMethod: 'moyenne',
          hpGain: 5,
        );

        // Valeur artificiellement incohérente (ne devrait jamais arriver en
        // conditions normales, les totaux ne font que croître) : simule le
        // cas défensif documenté sur `_upsertSpellSlots`.
        await client
            .from('character_spell_slots')
            .update({'slots_used': 10})
            .eq('character_id', characterId)
            .eq('slot_level', 1);

        await repository.applyLevelUp(
          characterId: characterId,
          classId: clercId,
          className: 'Clerc',
          isMulticlassing: false,
          hpRolled: 5,
          hpMethod: 'moyenne',
          hpGain: 5,
        );

        final row = await client
            .from('character_spell_slots')
            .select('slots_total, slots_used')
            .eq('character_id', characterId)
            .eq('slot_level', 1)
            .single();
        // Clerc niveau 3 : palier 1 = 4.
        expect(row['slots_total'], 4);
        expect(row['slots_used'], 4);
      });

      test("n'écrit aucune ligne character_spell_slots pour une classe non "
          'lanceuse de sorts (Guerrier)', () async {
        final guerrierId = await classIdByName('Guerrier');

        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Sorts Guerrier',
              'max_hp': 10,
              'current_hp': 10,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': guerrierId,
          'level': 1,
          'is_primary': true,
        });

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        await repository.applyLevelUp(
          characterId: characterId,
          classId: guerrierId,
          className: 'Guerrier',
          isMulticlassing: false,
          hpRolled: 8,
          hpMethod: 'lance',
          hpGain: 8,
        );

        final rows = await client
            .from('character_spell_slots')
            .select('slot_level')
            .eq('character_id', characterId);
        expect(rows, isEmpty);
      });
    });

    group('isolation cross-utilisateur (RLS + filtre owner_id)', () {
      // Même rationale que le groupe équivalent de
      // `character_detail_repository_integration_test.dart` : un échec
      // explicite (RLS) est acceptable, mais le personnage de *l'autre*
      // joueur ne doit jamais être modifié.
      late SupabaseClient otherClient;
      late String characterId;

      setUpAll(() async {
        otherClient = createTestSupabaseClient();
        await signUpTestUser(otherClient);
      });

      setUp(() async {
        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Isolation Montée de niveau',
              'xp': 100,
              'max_hp': 20,
              'current_hp': 15,
            })
            .select('id')
            .single();
        characterId = character['id'] as String;
        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': reference.classId,
          'level': 3,
          'is_primary': true,
        });
      });

      tearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      test('addXp appelé depuis la session d\'un autre joueur ne modifie '
          'jamais le personnage visé', () async {
        final otherRepository = SupabaseCharacterRepository(
          otherClient,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        try {
          await otherRepository.addXp(characterId: characterId, newXp: 99999);
        } catch (_) {
          // Idem — voir la documentation du groupe.
        }

        final row = await client
            .from('characters')
            .select('xp')
            .eq('id', characterId)
            .single();
        expect(row['xp'], 100);
      });

      test('applyLevelUp appelé depuis la session d\'un autre joueur ne '
          'modifie jamais le personnage visé', () async {
        final otherRepository = SupabaseCharacterRepository(
          otherClient,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        try {
          await otherRepository.applyLevelUp(
            characterId: characterId,
            classId: reference.classId,
            className: reference.className,
            isMulticlassing: false,
            hpRolled: 8,
            hpMethod: 'lance',
            hpGain: 8,
          );
        } catch (_) {
          // Idem — voir la documentation du groupe.
        }

        final characterRow = await client
            .from('characters')
            .select('max_hp, current_hp')
            .eq('id', characterId)
            .single();
        expect(characterRow['max_hp'], 20);
        expect(characterRow['current_hp'], 15);

        final classRow = await client
            .from('character_classes')
            .select('level')
            .eq('character_id', characterId)
            .single();
        expect(classRow['level'], 3);
      });

      // Les 3 tests suivants complètent la couverture d'isolation pour les
      // écritures ajoutées à l'increment 2 (étape "Choix à faire") : le
      // groupe existant ci-dessus n'appelait `applyLevelUp` qu'avec `choice:
      // null` (increment 1), jamais avec une sélection concrète. En pratique
      // ces 3 scénarios n'atteignent jamais `_applyChoice`
      // (`character_repository.dart`) : le `SELECT character_classes` fait
      // tout en haut d'`applyLevelUp` renvoie 0 ligne pour `otherClient`
      // (RLS `owns_character`, vérifié via `\d character_classes` sur le
      // stack local), donc l'appel échoue avant même d'atteindre le choix.
      // Ajoutés quand même pour couvrir explicitement ces 3 tables plutôt
      // que de compter implicitement sur ce détail d'ordonnancement des
      // écritures — si `applyLevelUp` était un jour réordonné, ces tests
      // détecteraient immédiatement une régression que le test générique
      // ci-dessus ne peut pas voir (il ne passe jamais de `choice`).
      test("applyLevelUp avec un choix ASI, appelé depuis la session d'un "
          "autre joueur, ne modifie jamais character_ability_scores/"
          "character_ability_increases du personnage visé", () async {
        await client.from('character_ability_scores').insert({
          'character_id': characterId,
          'ability_id': 'str',
          'score': 10,
        });

        final otherRepository = SupabaseCharacterRepository(
          otherClient,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        try {
          await otherRepository.applyLevelUp(
            characterId: characterId,
            classId: reference.classId,
            className: reference.className,
            isMulticlassing: false,
            hpRolled: 8,
            hpMethod: 'lance',
            hpGain: 8,
            choice: const LevelUpChoiceSelection.abilityScoreImprovement({
              'str': 2,
            }),
          );
        } catch (_) {
          // Idem — voir la documentation du groupe.
        }

        final scoreRow = await client
            .from('character_ability_scores')
            .select('score')
            .eq('character_id', characterId)
            .eq('ability_id', 'str')
            .single();
        expect(scoreRow['score'], 10);

        final increaseRows = await client
            .from('character_ability_increases')
            .select('id')
            .eq('character_id', characterId);
        expect(increaseRows, isEmpty);
      });

      test("applyLevelUp avec un choix de sous-classe, appelé depuis la "
          "session d'un autre joueur, ne modifie jamais "
          "character_classes.subclass_id du personnage visé", () async {
        final subclassRow = await client
            .from('subclasses')
            .select('id')
            .limit(1)
            .single();

        final otherRepository = SupabaseCharacterRepository(
          otherClient,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        try {
          await otherRepository.applyLevelUp(
            characterId: characterId,
            classId: reference.classId,
            className: reference.className,
            isMulticlassing: false,
            hpRolled: 8,
            hpMethod: 'lance',
            hpGain: 8,
            choice: LevelUpChoiceSelection.subclass(subclassRow['id']),
          );
        } catch (_) {
          // Idem — voir la documentation du groupe.
        }

        final classRow = await client
            .from('character_classes')
            .select('level, subclass_id')
            .eq('character_id', characterId)
            .single();
        expect(classRow['level'], 3);
        expect(classRow['subclass_id'], isNull);
      });

      test("applyLevelUp avec un choix de style de combat, appelé depuis la "
          "session d'un autre joueur, n'insère jamais de ligne "
          "character_class_options pour le personnage visé", () async {
        final featureRow = await client
            .from('class_features')
            .select('id')
            .eq('choice_type', 'style_combat')
            .limit(1)
            .single();

        final otherRepository = SupabaseCharacterRepository(
          otherClient,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        try {
          await otherRepository.applyLevelUp(
            characterId: characterId,
            classId: reference.classId,
            className: reference.className,
            isMulticlassing: false,
            hpRolled: 8,
            hpMethod: 'lance',
            hpGain: 8,
            choice: LevelUpChoiceSelection.fightingStyle(
              classFeatureId: (featureRow['id'] as num).toInt(),
              chosenValue: 'Duel',
            ),
          );
        } catch (_) {
          // Idem — voir la documentation du groupe.
        }

        final optionRows = await client
            .from('character_class_options')
            .select('id')
            .eq('character_id', characterId);
        expect(optionRows, isEmpty);
      });

      // Ajouté pour la même raison que les 3 tests ci-dessus (increment 2) :
      // `character_spell_slots` est une table introduite par cet increment 3,
      // couverte explicitement plutôt que de compter implicitement sur le
      // fait que le `SELECT character_classes` du tout début d'`applyLevelUp`
      // bloque déjà tout pour `otherClient` (RLS `owns_character`). Le
      // personnage de ce groupe utilise `reference.classId`
      // (`Barbare`, non lanceur de sorts, voir la doc de `ReferenceContent`)
      // : reclassé en Clerc ici, sinon `_upsertSpellSlots` retournerait tôt
      // (`nonZeroLevels` vide) même si l'isolation échouait, et ce test ne
      // prouverait rien.
      test("applyLevelUp avec une classe lanceuse de sorts (Clerc), appelé "
          "depuis la session d'un autre joueur, n'insère/ne modifie jamais "
          "de ligne character_spell_slots pour le personnage visé", () async {
        final clercTranslation = await client
            .from('translations')
            .select('entity_id')
            .eq('entity_type', 'class')
            .eq('field_name', 'name')
            .eq('locale', 'fr')
            .eq('value', 'Clerc')
            .maybeSingle();
        expect(
          clercTranslation,
          isNotNull,
          reason:
              'Aucune classe "Clerc" trouvée côté seed — vérifier '
              'supabase db reset côté dépôt web.',
        );
        // `entity_id` est `text` (voir la note équivalente sur
        // `classIdByName` plus haut) — parsé en `int` pour rester cohérent
        // avec `classes.id`/`character_classes.class_id`, même si ce test
        // précis n'aurait pas détecté l'incohérence (l'exception attendue,
        // due à l'isolation, aurait masqué un éventuel échec de cast).
        final clercId = int.parse(clercTranslation!['entity_id'] as String);

        await client
            .from('character_classes')
            .update({'class_id': clercId})
            .eq('character_id', characterId);

        final otherRepository = SupabaseCharacterRepository(
          otherClient,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        try {
          await otherRepository.applyLevelUp(
            characterId: characterId,
            classId: clercId,
            className: 'Clerc',
            isMulticlassing: false,
            hpRolled: 8,
            hpMethod: 'lance',
            hpGain: 8,
          );
        } catch (_) {
          // Idem — voir la documentation du groupe.
        }

        final slotRows = await client
            .from('character_spell_slots')
            .select('slot_level')
            .eq('character_id', characterId);
        expect(slotRows, isEmpty);
      });
    });

    group('multiclassage (intégration)', () {
      // `otherClient` propre à ce groupe (pas partagé avec le groupe
      // "isolation cross-utilisateur" ci-dessus, qui le scope à lui-même) —
      // seul le dernier test de ce groupe en a besoin.
      late SupabaseClient otherClient;

      setUpAll(() async {
        otherClient = createTestSupabaseClient();
        await signUpTestUser(otherClient);
      });

      /// Même rationale que `classIdByName` du groupe "Sorts" ci-dessus
      /// (`translations.entity_id` est `text`, `applyLevelUp` attend un
      /// `num`) — dupliqué ici plutôt que promu en helper partagé, cohérent
      /// avec le choix déjà fait de scoper ce genre d'utilitaire par groupe
      /// plutôt que globalement dans ce fichier.
      Future<int> classIdByName(String name) async {
        final translation = await client
            .from('translations')
            .select('entity_id')
            .eq('entity_type', 'class')
            .eq('field_name', 'name')
            .eq('locale', 'fr')
            .eq('value', name)
            .maybeSingle();
        expect(
          translation,
          isNotNull,
          reason:
              'Aucune classe "$name" trouvée côté seed — vérifier '
              'supabase db reset côté dépôt web.',
        );
        return int.parse(translation!['entity_id'] as String);
      }

      Future<String> createCharacterWithClass({
        required int classId,
        required int level,
        required Map<String, int> abilityScores,
      }) async {
        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Multiclassage',
              'max_hp': 10,
              'current_hp': 10,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': classId,
          'level': level,
          'is_primary': true,
        });

        await client.from('character_ability_scores').insert([
          for (final entry in abilityScores.entries)
            {
              'character_id': characterId,
              'ability_id': entry.key,
              'score': entry.value,
            },
        ]);

        return characterId;
      }

      test('multiclasser dans une nouvelle classe insère une ligne '
          'character_classes niveau 1 (is_primary: false, hit_dice_spent: '
          '0), sans toucher à la classe existante, et incrémente le niveau '
          'total du personnage', () async {
        final guerrierId = await classIdByName('Guerrier');
        final roublardId = await classIdByName('Roublard');
        final characterId = await createCharacterWithClass(
          classId: guerrierId,
          level: 3,
          // Guerrier : Force 13 OU Dextérité 13 (ici les deux, sans
          // conséquence) ; Roublard : Dextérité 13.
          abilityScores: {'str': 15, 'dex': 14},
        );

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        final result = await repository.applyLevelUp(
          characterId: characterId,
          classId: roublardId,
          className: 'Roublard',
          isMulticlassing: true,
          hpRolled: 6,
          hpMethod: 'lance',
          hpGain: 6,
        );

        expect(
          result.newLevel,
          4,
        ); // 3 (Guerrier) + 1 (Roublard) = niveau total 4.

        final classRows = await client
            .from('character_classes')
            .select('class_id, level, is_primary, hit_dice_spent')
            .eq('character_id', characterId)
            .order('level', ascending: false);
        expect(classRows, hasLength(2));
        final guerrierRow = classRows.firstWhere(
          (row) => row['class_id'] == guerrierId,
        );
        expect(guerrierRow['level'], 3, reason: 'classe existante inchangée');
        expect(guerrierRow['is_primary'], true);
        final roublardRow = classRows.firstWhere(
          (row) => row['class_id'] == roublardId,
        );
        expect(roublardRow['level'], 1);
        expect(roublardRow['is_primary'], false);
        expect(roublardRow['hit_dice_spent'], 0);

        final levelHpRow = await client
            .from('character_level_hp')
            .select('level')
            .eq('character_id', characterId)
            .single();
        expect(levelHpRow['level'], 4);
      });

      test('rejette le multiclassage si le prérequis de caractéristique de '
          'la NOUVELLE classe n\'est pas rempli (défense en profondeur, pas '
          'seulement côté UI) : aucune écriture', () async {
        final guerrierId = await classIdByName('Guerrier');
        final magicienId = await classIdByName('Magicien');
        final characterId = await createCharacterWithClass(
          classId: guerrierId,
          level: 2,
          abilityScores: {'str': 15, 'int': 8}, // Magicien exige Int 13.
        );

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );

        await expectLater(
          repository.applyLevelUp(
            characterId: characterId,
            classId: magicienId,
            className: 'Magicien',
            isMulticlassing: true,
            hpRolled: 4,
            hpMethod: 'lance',
            hpGain: 4,
          ),
          throwsA(isA<CharacterFailure>()),
        );

        final classRows = await client
            .from('character_classes')
            .select('class_id')
            .eq('character_id', characterId);
        expect(
          classRows,
          hasLength(1),
          reason: 'aucune nouvelle classe insérée',
        );

        final characterRow = await client
            .from('characters')
            .select('max_hp, current_hp')
            .eq('id', characterId)
            .single();
        expect(characterRow['max_hp'], 10, reason: 'PV jamais touchés');
      });

      test('rejette le multiclassage si le prérequis d\'une classe DÉJÀ '
          'possédée n\'est plus rempli (cas rare, ex. score de '
          'caractéristique redescendu depuis) — même si le prérequis de la '
          'nouvelle classe est rempli', () async {
        final roublardId = await classIdByName('Roublard');
        final guerrierId = await classIdByName('Guerrier');
        final characterId = await createCharacterWithClass(
          classId: roublardId,
          level: 2,
          abilityScores: {'dex': 13, 'str': 15},
        );
        // Le score de Dextérité redescend sous le prérequis du Roublard
        // (13) après coup — scénario défensif rare mais réel (drain de
        // caractéristique, erreur de saisie corrigée...).
        await client
            .from('character_ability_scores')
            .update({'score': 10})
            .eq('character_id', characterId)
            .eq('ability_id', 'dex');

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );

        await expectLater(
          repository.applyLevelUp(
            characterId: characterId,
            classId: guerrierId,
            className: 'Guerrier',
            isMulticlassing: true,
            hpRolled: 6,
            hpMethod: 'lance',
            hpGain: 6,
          ),
          throwsA(
            isA<CharacterFailure>().having(
              (f) => f.message,
              'message',
              contains('Roublard'),
            ),
          ),
        );

        final classRows = await client
            .from('character_classes')
            .select('class_id')
            .eq('character_id', characterId);
        expect(
          classRows,
          hasLength(1),
          reason: 'aucune nouvelle classe insérée',
        );
      });

      test('multiclasser dans une classe "à sorts connus" écrit les sorts de '
          'départ (character_spells, status "connu", source_class_id de la '
          'nouvelle classe)', () async {
        final guerrierId = await classIdByName('Guerrier');
        final bardeId = await classIdByName('Barde');
        final characterId = await createCharacterWithClass(
          classId: guerrierId,
          level: 2,
          abilityScores: {'str': 15, 'cha': 14}, // Barde exige Charisme 13.
        );
        final spellRows = await client
            .from('spells')
            .select('id')
            .eq('level', 0)
            .limit(2);
        final spellIds = [for (final row in spellRows) row['id'] as int];
        expect(
          spellIds,
          hasLength(2),
          reason: 'au moins 2 sorts mineurs attendus côté seed',
        );

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        await repository.applyLevelUp(
          characterId: characterId,
          classId: bardeId,
          className: 'Barde',
          isMulticlassing: true,
          hpRolled: 5,
          hpMethod: 'lance',
          hpGain: 5,
          initialSpellIds: spellIds,
        );

        final spellRowsWritten = await client
            .from('character_spells')
            .select('spell_id, status, source_class_id')
            .eq('character_id', characterId);
        expect(spellRowsWritten, hasLength(2));
        for (final row in spellRowsWritten) {
          expect(row['status'], 'connu');
          expect(row['source_class_id'], bardeId);
          expect(spellIds, contains(row['spell_id']));
        }
      });

      test('emplacements de sorts combinés multiclasse : demi-lanceur '
          'existant (Paladin niveau 4) + lanceur complet fraîchement '
          'multiclassé (Clerc niveau 1) -> niveau de lanceur combiné 3 '
          '(floor(4/2) + 1), table lanceur complet standard', () async {
        final paladinId = await classIdByName('Paladin');
        final clercId = await classIdByName('Clerc');
        final characterId = await createCharacterWithClass(
          classId: paladinId,
          level: 4,
          // Paladin : Force 13 ET Charisme 13. Clerc : Sagesse 13.
          abilityScores: {'str': 13, 'cha': 13, 'wis': 14},
        );

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        await repository.applyLevelUp(
          characterId: characterId,
          classId: clercId,
          className: 'Clerc',
          isMulticlassing: true,
          hpRolled: 5,
          hpMethod: 'lance',
          hpGain: 5,
        );

        final slotRows = await client
            .from('character_spell_slots')
            .select('slot_level, slots_total')
            .eq('character_id', characterId)
            .order('slot_level');
        // Niveau de lanceur combiné 3 -> table lanceur complet : [4, 2, 0...].
        final totalsByLevel = {
          for (final row in slotRows)
            (row['slot_level'] as num).toInt(): (row['slots_total'] as num)
                .toInt(),
        };
        expect(totalsByLevel[1], 4);
        expect(totalsByLevel[2], 2);
        expect(totalsByLevel.containsKey(3), isFalse);
      });

      test("applyLevelUp(isMulticlassing: true) appelé depuis la session "
          "d'un autre joueur n'insère jamais de nouvelle ligne "
          'character_classes pour le personnage visé', () async {
        final guerrierId = await classIdByName('Guerrier');
        final roublardId = await classIdByName('Roublard');
        final characterId = await createCharacterWithClass(
          classId: guerrierId,
          level: 2,
          abilityScores: {'str': 15, 'dex': 14},
        );

        final otherRepository = SupabaseCharacterRepository(
          otherClient,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        try {
          await otherRepository.applyLevelUp(
            characterId: characterId,
            classId: roublardId,
            className: 'Roublard',
            isMulticlassing: true,
            hpRolled: 6,
            hpMethod: 'lance',
            hpGain: 6,
          );
        } catch (_) {
          // Attendu : la RLS `owns_character` bloque déjà le SELECT
          // `character_classes` en tout début d'`applyLevelUp` pour
          // `otherClient` — peu importe l'exception précise, seul compte
          // qu'aucune écriture n'a eu lieu (assertions ci-dessous).
        }

        final classRows = await client
            .from('character_classes')
            .select('class_id')
            .eq('character_id', characterId);
        expect(
          classRows,
          hasLength(1),
          reason: 'aucune classe ajoutée par un autre utilisateur',
        );
      });
    });

    group('sorts/dons/invocations (intégration)', () {
      late SupabaseClient otherClient;

      setUpAll(() async {
        otherClient = createTestSupabaseClient();
        await signUpTestUser(otherClient);
      });

      Future<int> classIdByName(String name) async {
        final translation = await client
            .from('translations')
            .select('entity_id')
            .eq('entity_type', 'class')
            .eq('field_name', 'name')
            .eq('locale', 'fr')
            .eq('value', name)
            .maybeSingle();
        expect(
          translation,
          isNotNull,
          reason:
              'Aucune classe "$name" trouvée côté seed — vérifier '
              'supabase db reset côté dépôt web.',
        );
        return int.parse(translation!['entity_id'] as String);
      }

      Future<String> createCharacterWithClass({
        required int classId,
        required int level,
      }) async {
        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Sorts/Dons/Invocations',
              'max_hp': 10,
              'current_hp': 10,
            })
            .select('id')
            .single();
        final characterId = character['id'] as String;
        addTearDown(() async {
          await client.from('characters').delete().eq('id', characterId);
        });

        await client.from('character_classes').insert({
          'character_id': characterId,
          'class_id': classId,
          'level': level,
          'is_primary': true,
        });

        return characterId;
      }

      test('choisir un don en alternative à l\'ASI écrit character_feats '
          '(level_taken correct), jamais character_ability_scores', () async {
        final guerrierId = await classIdByName('Guerrier');
        final characterId = await createCharacterWithClass(
          classId: guerrierId,
          level: 3,
        );
        final featRow = await client
            .from('feats')
            .select('id')
            .limit(1)
            .single();
        final featId = (featRow['id'] as num).toInt();

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        await repository.applyLevelUp(
          characterId: characterId,
          classId: guerrierId,
          className: 'Guerrier',
          isMulticlassing: false,
          hpRolled: 7,
          hpMethod: 'lance',
          hpGain: 7,
          choice: LevelUpChoiceSelection.feat(featId),
        );

        final featRows = await client
            .from('character_feats')
            .select('feat_id, level_taken')
            .eq('character_id', characterId);
        expect(featRows, hasLength(1));
        expect(featRows.single['feat_id'], featId);
        expect(featRows.single['level_taken'], 4);

        final scoreRows = await client
            .from('character_ability_scores')
            .select('ability_id')
            .eq('character_id', characterId);
        expect(
          scoreRows,
          isEmpty,
          reason: 'ASI et don sont mutuellement exclusifs',
        );
      });

      test('fetchAvailableFeats exclut les dons déjà possédés', () async {
        final guerrierId = await classIdByName('Guerrier');
        final characterId = await createCharacterWithClass(
          classId: guerrierId,
          level: 4,
        );
        final allFeats = await client.from('feats').select('id');
        expect(allFeats.length, greaterThanOrEqualTo(2));
        final ownedFeatId = (allFeats.first['id'] as num).toInt();
        await client.from('character_feats').insert({
          'character_id': characterId,
          'feat_id': ownedFeatId,
          'level_taken': 4,
        });

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        final available = await repository.fetchAvailableFeats(
          characterId: characterId,
        );

        expect(
          available.any((f) => f.id == ownedFeatId),
          isFalse,
          reason: 'le don déjà possédé ne doit plus apparaître',
        );
        expect(available.length, allFeats.length - 1);
      });

      test(
        'choisir une invocation occultiste écrit character_invocations',
        () async {
          final occultisteId = await classIdByName('Occultiste');
          final characterId = await createCharacterWithClass(
            classId: occultisteId,
            level: 4,
          );
          final invocationRow = await client
              .from('invocations')
              .select('id')
              .limit(1)
              .single();
          final invocationId = (invocationRow['id'] as num).toInt();

          final repository = SupabaseCharacterRepository(
            client,
            cache,
            pendingWrites,
            const AlwaysOnlineConnectivityChecker(),
          );
          await repository.applyLevelUp(
            characterId: characterId,
            classId: occultisteId,
            className: 'Occultiste',
            isMulticlassing: false,
            hpRolled: 5,
            hpMethod: 'lance',
            hpGain: 5,
            invocationIds: [invocationId],
          );

          final rows = await client
              .from('character_invocations')
              .select('invocation_id')
              .eq('character_id', characterId);
          expect(rows, hasLength(1));
          expect(rows.single['invocation_id'], invocationId);
        },
      );

      test(
        'fetchAvailableInvocations exclut les invocations déjà connues',
        () async {
          final occultisteId = await classIdByName('Occultiste');
          final characterId = await createCharacterWithClass(
            classId: occultisteId,
            level: 4,
          );
          final allInvocations = await client.from('invocations').select('id');
          expect(allInvocations.length, greaterThanOrEqualTo(2));
          final knownId = (allInvocations.first['id'] as num).toInt();
          await client.from('character_invocations').insert({
            'character_id': characterId,
            'invocation_id': knownId,
          });

          final repository = SupabaseCharacterRepository(
            client,
            cache,
            pendingWrites,
            const AlwaysOnlineConnectivityChecker(),
          );
          final available = await repository.fetchAvailableInvocations(
            characterId: characterId,
          );

          expect(available.any((i) => i.id == knownId), isFalse);
          expect(available.length, allInvocations.length - 1);
        },
      );

      test('nouveaux sorts appris à une montée de niveau > 1 (pas un '
          'multiclassage) écrivent character_spells avec le bon '
          'source_class_id/status', () async {
        final bardeId = await classIdByName('Barde');
        final characterId = await createCharacterWithClass(
          classId: bardeId,
          level: 1,
        );
        final spellRows = await client
            .from('spells')
            .select('id')
            .eq('level', 1)
            .limit(1);
        final spellId = (spellRows.single['id'] as num).toInt();

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        // Barde niveau 1 -> 2 : continuation normale, PAS un multiclassage —
        // vérifie que le mécanisme d'écriture des sorts (généralisé par ce
        // chantier, plus seulement pour le niveau 1 d'une classe
        // multiclassée) fonctionne aussi sur ce chemin.
        await repository.applyLevelUp(
          characterId: characterId,
          classId: bardeId,
          className: 'Barde',
          isMulticlassing: false,
          hpRolled: 5,
          hpMethod: 'lance',
          hpGain: 5,
          initialSpellIds: [spellId],
        );

        final rows = await client
            .from('character_spells')
            .select('spell_id, status, source_class_id')
            .eq('character_id', characterId);
        expect(rows, hasLength(1));
        expect(rows.single['spell_id'], spellId);
        expect(rows.single['status'], 'connu');
        expect(rows.single['source_class_id'], bardeId);
      });

      test("applyLevelUp avec un choix de don, appelé depuis la session "
          "d'un autre joueur, n'insère jamais de ligne character_feats pour "
          'le personnage visé', () async {
        final guerrierId = await classIdByName('Guerrier');
        final characterId = await createCharacterWithClass(
          classId: guerrierId,
          level: 3,
        );
        final featRow = await client
            .from('feats')
            .select('id')
            .limit(1)
            .single();
        final featId = (featRow['id'] as num).toInt();

        final otherRepository = SupabaseCharacterRepository(
          otherClient,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        try {
          await otherRepository.applyLevelUp(
            characterId: characterId,
            classId: guerrierId,
            className: 'Guerrier',
            isMulticlassing: false,
            hpRolled: 7,
            hpMethod: 'lance',
            hpGain: 7,
            choice: LevelUpChoiceSelection.feat(featId),
          );
        } catch (_) {
          // Attendu : RLS `owns_character` bloque déjà le SELECT
          // `character_classes` en tout début d'`applyLevelUp` pour
          // `otherClient` — seul compte qu'aucune écriture n'a eu lieu.
        }

        final rows = await client
            .from('character_feats')
            .select('feat_id')
            .eq('character_id', characterId);
        expect(rows, isEmpty);
      });
    });
  });
}
