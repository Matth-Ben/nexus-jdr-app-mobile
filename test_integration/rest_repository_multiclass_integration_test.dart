import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:personnages/core/cache/app_database.dart";
import "package:personnages/core/cache/pending_character_write_queue.dart";
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
///
/// Second defaut de la meme famille, CORRIGE lui aussi (correctif "repos
/// long multiclasse") : applyRest recalculait character_spell_slots depuis
/// la seule classe primaire (SpellSlotProgression.slotsForLevel(className,
/// niveau de la classe primaire)). Un Guerrier / Magicien ne recuperait donc
/// jamais ses emplacements au repos long, et un Clerc / Magicien voyait ses
/// totaux multiclasses ecrases a la baisse. Le recalcul passe desormais par
/// SpellSlotProgression.totalsForClasses sur TOUTES les classes — voir le
/// second groupe de ce fichier et, cote tests unitaires (sans base),
/// test/features/characters/data/character_repository_rest_test.dart.
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
    late PendingCharacterWriteQueue pendingWrites;

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
      pendingWrites = PendingCharacterWriteQueue(cacheDb);

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

      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        const AlwaysOnlineConnectivityChecker(),
      );
      // `className` fictif pour la classe primaire : ce test porte sur
      // character_feature_uses (multiclassage). La classe secondaire, elle,
      // est nommée par le dépôt depuis `translations` : si elle est
      // lanceuse, ses emplacements sont recalculés par ce repos long (sans
      // incidence sur les assertions ci-dessous) — voir le groupe suivant
      // pour les tests dédiés aux emplacements de sorts d'un multiclassé.
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

  group("SupabaseCharacterRepository.applyRest - emplacements de sorts d un "
      "personnage multiclasse (integration)", () {
    late SupabaseClient client;
    late String ownerId;
    late AppDatabase cacheDb;
    late ReferenceDataCache cache;
    late PendingCharacterWriteQueue pendingWrites;

    setUpAll(() async {
      client = createTestSupabaseClient();
      await signUpTestUser(client);
      ownerId = client.auth.currentUser!.id;
      cacheDb = AppDatabase(NativeDatabase.memory());
      cache = ReferenceDataCache(cacheDb);
      pendingWrites = PendingCharacterWriteQueue(cacheDb);
    });

    tearDownAll(() async {
      await cacheDb.close();
    });

    /// Meme helper que `rest_repository_integration_test.dart` : les noms
    /// francais sont ceux attendus par `domain/spell_slot_progression.dart`.
    Future<Object> classIdByName(String name) async {
      final translation = await client
          .from("translations")
          .select("entity_id")
          .eq("entity_type", "class")
          .eq("field_name", "name")
          .eq("locale", "fr")
          .eq("value", name)
          .maybeSingle();
      expect(
        translation,
        isNotNull,
        reason:
            'Aucune classe "$name" trouvee cote seed - verifier '
            "supabase db reset cote depot web.",
      );
      return translation!["entity_id"] as Object;
    }

    /// Cree un personnage dont les classes sont [classes] (la premiere est
    /// la classe primaire) et les lignes character_spell_slots [slotRows]
    /// (`[niveau, total, utilises]`), applique un repos [type] avec le nom
    /// de la classe primaire (comme `character_detail_screen.dart`), puis
    /// retourne l identifiant du personnage et ses lignes
    /// character_spell_slots, triees par niveau, sous la forme
    /// `[niveau, total, utilises]`.
    Future<({String characterId, List<List<int>> slots})> restAndReadSlots({
      required String name,
      required List<({String className, int level})> classes,
      List<List<int>> slotRows = const [],
      RestType type = RestType.long,
    }) async {
      final character = await client
          .from("characters")
          .insert({
            "owner_id": ownerId,
            "name": name,
            "current_hp": 10,
            "max_hp": 20,
          })
          .select("id")
          .single();
      final characterId = character["id"] as String;
      addTearDown(() async {
        await client.from("characters").delete().eq("id", characterId);
      });

      for (var i = 0; i < classes.length; i++) {
        await client.from("character_classes").insert({
          "character_id": characterId,
          "class_id": await classIdByName(classes[i].className),
          "level": classes[i].level,
          "is_primary": i == 0,
        });
      }
      for (final row in slotRows) {
        await client.from("character_spell_slots").insert({
          "character_id": characterId,
          "slot_level": row[0],
          "slots_total": row[1],
          "slots_used": row[2],
        });
      }

      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        const AlwaysOnlineConnectivityChecker(),
      );
      await repository.applyRest(
        characterId: characterId,
        type: type,
        className: classes.first.className,
      );

      final rows = await client
          .from("character_spell_slots")
          .select("slot_level, slots_total, slots_used")
          .eq("character_id", characterId)
          .order("slot_level", ascending: true);
      return (
        characterId: characterId,
        slots: [
          for (final row in rows)
            [
              (row["slot_level"] as num).toInt(),
              (row["slots_total"] as num).toInt(),
              (row["slots_used"] as num).toInt(),
            ],
        ],
      );
    }

    test("repos long, Guerrier 5 (primaire) / Magicien 3 : les emplacements "
        "du Magicien sont restaures (avant correctif : aucune ecriture, "
        "utilises inchanges)", () async {
      final result = await restAndReadSlots(
        name: "Test Integration Repos Guerrier Magicien",
        classes: [
          (className: "Guerrier", level: 5),
          (className: "Magicien", level: 3),
        ],
        slotRows: [
          [1, 4, 3],
          [2, 2, 2],
        ],
      );

      expect(result.slots, [
        [1, 4, 0],
        [2, 2, 0],
      ]);
    });

    test("repos long, Guerrier 5 (primaire) / Magicien 3 sans aucune ligne "
        "prealable : les lignes sont creees depuis zero", () async {
      final result = await restAndReadSlots(
        name: "Test Integration Repos Guerrier Magicien (gap)",
        classes: [
          (className: "Guerrier", level: 5),
          (className: "Magicien", level: 3),
        ],
      );

      expect(result.slots, [
        [1, 4, 0],
        [2, 2, 0],
      ]);
    });

    test(
      "repos long, Clerc 3 (primaire) / Magicien 2 : niveau de lanceur "
      "combine 5, totaux multiclasses conserves et niveau 3 restaure "
      "(avant correctif : totaux du Clerc 3 seul, niveau 3 inchange)",
      () async {
        final result = await restAndReadSlots(
          name: "Test Integration Repos Clerc Magicien",
          classes: [
            (className: "Clerc", level: 3),
            (className: "Magicien", level: 2),
          ],
          slotRows: [
            [1, 4, 4],
            [2, 3, 1],
            [3, 2, 2],
          ],
        );

        expect(result.slots, [
          [1, 4, 0],
          [2, 3, 0],
          [3, 2, 0],
        ]);
      },
    );

    test("repos long, Paladin 4 (primaire, demi-lanceur) / Magicien 3 : "
        "niveau de lanceur combine 3 + 4 ~/ 2 = 5", () async {
      final result = await restAndReadSlots(
        name: "Test Integration Repos Paladin Magicien",
        classes: [
          (className: "Paladin", level: 4),
          (className: "Magicien", level: 3),
        ],
        slotRows: [
          [1, 4, 2],
          [2, 3, 3],
          [3, 2, 1],
        ],
      );

      expect(result.slots, [
        [1, 4, 0],
        [2, 3, 0],
        [3, 2, 0],
      ]);
    });

    test("repos long, Occultiste 3 (primaire) / Magicien 2 : emplacements "
        "classiques du Magicien 2 seul (la magie de pacte n entre pas dans "
        "le niveau combine), pacte restaure separement", () async {
      final result = await restAndReadSlots(
        name: "Test Integration Repos Occultiste Magicien",
        classes: [
          (className: "Occultiste", level: 3),
          (className: "Magicien", level: 2),
        ],
        slotRows: [
          [1, 3, 3],
        ],
      );

      expect(result.slots, [
        [1, 3, 0],
      ]);

      final pactRows = await client
          .from("character_pact_slots")
          .select("slot_level, slots_total, slots_used")
          .eq("character_id", result.characterId);
      expect(pactRows, hasLength(1));
      expect(pactRows.single["slot_level"], 2);
      expect(pactRows.single["slots_total"], 2);
      expect(pactRows.single["slots_used"], 0);
    });

    test("repos long, ligne existante pour un niveau hors calcul "
        "(Guerrier 5 / Magicien 3 avec une ligne de niveau 3) : jamais "
        "supprimee, total conserve, utilises remis a 0", () async {
      final result = await restAndReadSlots(
        name: "Test Integration Repos Ligne Hors Calcul",
        classes: [
          (className: "Guerrier", level: 5),
          (className: "Magicien", level: 3),
        ],
        slotRows: [
          [1, 4, 1],
          [2, 2, 0],
          [3, 2, 1],
        ],
      );

      expect(result.slots, [
        [1, 4, 0],
        [2, 2, 0],
        [3, 2, 0],
      ]);
    });

    test("repos court, Guerrier 5 / Magicien 3 : character_spell_slots "
        "strictement inchange", () async {
      final result = await restAndReadSlots(
        name: "Test Integration Repos Court Multiclasse",
        type: RestType.short,
        classes: [
          (className: "Guerrier", level: 5),
          (className: "Magicien", level: 3),
        ],
        slotRows: [
          [1, 4, 3],
          [2, 2, 2],
        ],
      );

      expect(result.slots, [
        [1, 4, 3],
        [2, 2, 2],
      ]);
    });
  });
}
