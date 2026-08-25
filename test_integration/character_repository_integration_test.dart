import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/test_environment.dart';

/// Test d'intégration de `SupabaseCharacterRepository` contre un vrai stack
/// Supabase local (voir `test_integration/README.md` pour le lancer).
///
/// Preuve de concept du garde-fou ajouté après le bug constaté le
/// 25/08/2026 sur l'écran liste des personnages : `flutter test` (qui ne
/// manipule que `_FakeCharacterRepository`) restait vert alors que la vraie
/// requête PostgREST échouait (`translations.name` inexistante — la vraie
/// colonne est `value` — et un mismatch de type `entity_id` texte vs
/// `race_id`/`class_id` entiers). Ce test exécute la vraie implémentation
/// contre un vrai Postgres pour détecter ce genre de régression.
void main() {
  group('SupabaseCharacterRepository (intégration)', () {
    late SupabaseClient client;
    late ReferenceContent reference;

    setUpAll(() async {
      client = createTestSupabaseClient();
      await signUpTestUser(client);
      reference = await fetchReferenceContent(client);
    });

    test(
      'fetchCharacters résout race/classe via le vrai schéma translations',
      () async {
        final ownerId = client.auth.currentUser!.id;

        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration',
              'xp': 42,
              'race_id': reference.raceId,
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
        final characters = await repository.fetchCharacters();

        final fetched = characters.singleWhere((c) => c.id == characterId);
        expect(fetched.name, 'Test Intégration');
        expect(fetched.xp, 42);
        expect(fetched.level, 3);
        expect(fetched.raceName, reference.raceName);
        expect(fetched.className, reference.className);
      },
    );
  });
}
