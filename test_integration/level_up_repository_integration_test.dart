import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/test_environment.dart';

/// Tests d'intégration des méthodes de `SupabaseCharacterRepository` ajoutées
/// pour l'écran "Montée de niveau" (increment 1) — `addXp`/
/// `fetchLevelUpLevelData`/`applyLevelUp` — voir
/// `character_repository_integration_test.dart` pour le rationale général de
/// ce dossier.
void main() {
  group('SupabaseCharacterRepository — montée de niveau (intégration)', () {
    late SupabaseClient client;
    late ReferenceContent reference;
    late String ownerId;

    setUpAll(() async {
      client = createTestSupabaseClient();
      await signUpTestUser(client);
      reference = await fetchReferenceContent(client);
      ownerId = client.auth.currentUser!.id;
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

      final repository = SupabaseCharacterRepository(client);
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
      final repository = SupabaseCharacterRepository(client);

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
        data.blockingChoiceType,
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

      final repository = SupabaseCharacterRepository(client);
      final result = await repository.applyLevelUp(
        characterId: characterId,
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

    test('applyLevelUp lève une CharacterFailure si le personnage n\'a pas '
        'exactement une ligne character_classes (aucune classe ici)', () async {
      final character = await client
          .from('characters')
          .insert({'owner_id': ownerId, 'name': 'Test Intégration Sans classe'})
          .select('id')
          .single();
      final characterId = character['id'] as String;
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      final repository = SupabaseCharacterRepository(client);

      await expectLater(
        repository.applyLevelUp(
          characterId: characterId,
          hpRolled: 5,
          hpMethod: 'moyenne',
          hpGain: 5,
        ),
        throwsA(isA<CharacterFailure>()),
      );
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
        final otherRepository = SupabaseCharacterRepository(otherClient);
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
        final otherRepository = SupabaseCharacterRepository(otherClient);
        try {
          await otherRepository.applyLevelUp(
            characterId: characterId,
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
    });
  });
}
