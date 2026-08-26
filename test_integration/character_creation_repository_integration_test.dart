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
  });
}
