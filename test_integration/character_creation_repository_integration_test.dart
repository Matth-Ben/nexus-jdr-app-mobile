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
  });
}
