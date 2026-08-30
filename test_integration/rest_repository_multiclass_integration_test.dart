import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:personnages/core/cache/app_database.dart";
import "package:personnages/core/cache/reference_data_cache.dart";
import "package:personnages/features/characters/data/character_repository.dart";
import "package:personnages/features/characters/domain/rest_type.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "support/test_environment.dart";

/// Test de non-regression documentant un bug trouve en revue QA du chantier
/// "Repos court/long" (voir le rapport QA correspondant). CORRIGE dans
/// character_repository.dart (applyRest reinitialise desormais
/// character_feature_uses pour TOUTES les lignes character_classes du
/// personnage, pas seulement celle marquee is_primary, voir
/// _resetFeatureUses) — meme traitement que
/// character_detail_hp_stepper_race_test.dart.
///
/// Avant ce correctif, character_repository.dart::applyRest ne
/// reinitialisait character_feature_uses QUE pour les class_features de la
/// classe marquee is_primary = true (voir _resetFeatureUses, appele avec
/// uniquement primaryClassRows.first). Pour un personnage multiclasse
/// (character_classes contient plusieurs lignes, une seule is_primary),
/// les aptitudes rechargeables de la/les classe(s) secondaire(s) n'etaient
/// donc jamais reinitialisees par un repos, ni court ni long.
///
/// Ce n'etait pas un cas hypothetique : le modele de donnees supporte
/// explicitement le multiclassage (02-modele-donnees.md), la Phase 3
/// (import XML, roadmap.md) produira des personnages multiclasses des la
/// prochaine phase, et la lecture de la fiche (_buildCharacterDetailPayload/
/// _mapCharacterDetailPayload, character_repository.dart) gere deja
/// explicitement ce cas ("pour un
/// personnage multiclasse ou plusieurs class_id... sont melanges") -
/// applyRest suit desormais la meme regle plutot que d'ignorer
/// silencieusement les classes secondaires.
///
/// La consigne d'origine de cette tache dit explicitement "reinitialise
/// TOUS les character_feature_uses.uses_remaining du personnage" (pas "de
/// la classe primaire") pour un repos long.
void main() {
  group("SupabaseCharacterRepository.applyRest - personnage multiclasse "
      "(integration)", () {
    late SupabaseClient client;
    late String ownerId;
    // Base drift en memoire : ce fichier n'exerce jamais le chemin de
    // secours "cache" de `fetchCharacterDetail` (couvert par les tests
    // unitaires de `character_repository_test.dart`), seulement le
    // constructeur de `SupabaseCharacterRepository`, qui prend desormais un
    // `ReferenceDataCache` en dependance.
    late AppDatabase cacheDb;
    late ReferenceDataCache cache;

    late Object primaryClassId;
    late int primaryClassLevel;
    late int primaryFeatureId;
    late int primaryAmount;

    late Object secondaryClassId;
    late int secondaryClassLevel;
    late int secondaryFeatureId;
    late int secondaryAmount;

    setUpAll(() async {
      client = createTestSupabaseClient();
      await signUpTestUser(client);
      ownerId = client.auth.currentUser!.id;
      cacheDb = AppDatabase(NativeDatabase.memory());
      cache = ReferenceDataCache(cacheDb);

      final rows = await client
          .from("class_features")
          .select("class_id, level, id, uses_per_rest");

      final byClass = <Object, Map<String, dynamic>>{};
      for (final row in rows) {
        final usesPerRest = row["uses_per_rest"] as Map<String, dynamic>?;
        if (row["class_id"] == null || usesPerRest == null) continue;
        if (usesPerRest["amount"] == null) continue;
        byClass.putIfAbsent(row["class_id"] as Object, () => row);
      }

      expect(
        byClass.length,
        greaterThanOrEqualTo(2),
        reason:
            "Ce test a besoin de 2 classes distinctes ayant chacune une "
            "class_features avec uses_per_rest.amount non nul cote seed - "
            "verifier supabase db reset cote depot web.",
      );

      final entries = byClass.entries.toList();
      final primary = entries[0].value;
      final secondary = entries[1].value;

      primaryClassId = primary["class_id"] as Object;
      primaryClassLevel = (primary["level"] as num).toInt();
      primaryFeatureId = (primary["id"] as num).toInt();
      primaryAmount =
          ((primary["uses_per_rest"] as Map<String, dynamic>)["amount"] as num)
              .toInt();

      secondaryClassId = secondary["class_id"] as Object;
      secondaryClassLevel = (secondary["level"] as num).toInt();
      secondaryFeatureId = (secondary["id"] as num).toInt();
      secondaryAmount =
          ((secondary["uses_per_rest"] as Map<String, dynamic>)["amount"]
                  as num)
              .toInt();
    });

    tearDownAll(() async {
      await cacheDb.close();
    });

    test("applyRest(long) reinitialise aussi les character_feature_uses de la "
        "classe secondaire d un personnage multiclasse "
        "(CORRIGE - voir en-tete de ce fichier)", () async {
      final character = await client
          .from("characters")
          .insert({
            "owner_id": ownerId,
            "name": "Test Integration Repos Multiclasse",
            "current_hp": 10,
            "max_hp": 20,
          })
          .select("id")
          .single();
      final characterId = character["id"] as String;
      addTearDown(() async {
        await client.from("characters").delete().eq("id", characterId);
      });

      await client.from("character_classes").insert({
        "character_id": characterId,
        "class_id": primaryClassId,
        "level": primaryClassLevel,
        "is_primary": true,
      });
      await client.from("character_classes").insert({
        "character_id": characterId,
        "class_id": secondaryClassId,
        "level": secondaryClassLevel,
        "is_primary": false,
      });

      await client.from("character_feature_uses").insert({
        "character_id": characterId,
        "class_feature_id": primaryFeatureId,
        "uses_remaining": 0,
      });
      await client.from("character_feature_uses").insert({
        "character_id": characterId,
        "class_feature_id": secondaryFeatureId,
        "uses_remaining": 0,
      });

      final repository = SupabaseCharacterRepository(client, cache);
      // `className` fictif : ce test porte sur character_feature_uses
      // (multiclassage), jamais sur character_spell_slots — voir
      // `rest_repository_integration_test.dart` pour les tests dédiés au
      // recalcul des emplacements de sorts.
      await repository.applyRest(
        characterId: characterId,
        type: RestType.long,
        className: "Aucune Classe Lanceuse",
      );

      final primaryUse = await client
          .from("character_feature_uses")
          .select("uses_remaining")
          .eq("character_id", characterId)
          .eq("class_feature_id", primaryFeatureId)
          .single();
      expect(primaryUse["uses_remaining"], primaryAmount);

      final secondaryUse = await client
          .from("character_feature_uses")
          .select("uses_remaining")
          .eq("character_id", characterId)
          .eq("class_feature_id", secondaryFeatureId)
          .single();
      expect(
        secondaryUse["uses_remaining"],
        secondaryAmount,
        reason:
            "Régression : l'aptitude de la classe secondaire devrait être "
            "réinitialisée au même titre que celle de la classe primaire "
            "(applyRest itère désormais sur toutes les lignes "
            "character_classes, voir _resetFeatureUses, "
            "character_repository.dart).",
      );
    });
  });
}
