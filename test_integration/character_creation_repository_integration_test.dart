import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
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
  });
}
