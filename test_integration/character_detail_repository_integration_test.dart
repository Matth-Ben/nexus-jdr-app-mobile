import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/test_environment.dart';

/// Tests d'intégration des méthodes de `SupabaseCharacterRepository` ajoutées
/// pour la fiche personnage (`fetchCharacterDetail`/`updateHp`/
/// `uploadPortrait`/`removePortrait`) — voir `character_repository_integration_test.dart`
/// pour le rationale général de ce dossier.
void main() {
  group('SupabaseCharacterRepository — fiche personnage (intégration)', () {
    late SupabaseClient client;
    late ReferenceContent reference;
    late String ownerId;
    // Base drift en mémoire : ce fichier n'exerce jamais le chemin de
    // secours "cache" de `fetchCharacterDetail` (couvert par les tests
    // unitaires de `character_repository_test.dart`), seulement le
    // constructeur de `SupabaseCharacterRepository`, qui prend désormais un
    // `ReferenceDataCache` en dépendance. Partagée entre `client` et
    // `otherClient` (voir le groupe "isolation cross-utilisateur"
    // ci-dessous) : sans conséquence, la clé de cache reste scopée par
    // ownerId à l'intérieur du repository.
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

    test(
      'fetchCharacterDetail résout race/historique/alignement/classe via le '
      'vrai schéma translations, et les maîtrises de jets de sauvegarde de '
      'la classe primaire via la vraie relation character_classes -> classes',
      () async {
        final character = await client
            .from('characters')
            .insert({
              'owner_id': ownerId,
              'name': 'Test Intégration Fiche',
              'race_id': reference.raceId,
              'background_id': reference.backgroundId,
              'alignment_id': reference.alignmentId,
              'xp': 1200,
              'current_hp': 18,
              'max_hp': 24,
              'temporary_hp': 3,
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
          'level': 5,
          'is_primary': true,
        });
        await client.from('character_ability_scores').insert([
          {'character_id': characterId, 'ability_id': 'str', 'score': 16},
          {'character_id': characterId, 'ability_id': 'dex', 'score': 14},
        ]);

        final expectedProficiencies = await client
            .from('classes')
            .select('saving_throw_proficiencies, hit_die')
            .eq('id', reference.classId)
            .single();

        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        final detail = await repository.fetchCharacterDetail(characterId);

        expect(detail.name, 'Test Intégration Fiche');
        expect(detail.raceName, reference.raceName);
        expect(detail.backgroundName, reference.backgroundName);
        expect(detail.alignmentName, reference.alignmentName);
        expect(detail.xp, 1200);
        expect(detail.currentHp, 18);
        expect(detail.maxHp, 24);
        expect(detail.temporaryHp, 3);
        expect(detail.abilityScores, {'str': 16, 'dex': 14});

        expect(detail.classes, hasLength(1));
        expect(detail.classes.single.className, reference.className);
        expect(detail.classes.single.level, 5);
        expect(detail.classes.single.isPrimary, isTrue);
        expect(
          detail.classes.single.savingThrowProficiencies,
          (expectedProficiencies['saving_throw_proficiencies'] as List)
              .cast<String>(),
        );
        expect(
          detail.classes.single.hitDie,
          (expectedProficiencies['hit_die'] as num).toInt(),
        );
      },
    );

    test('fetchCharacterDetail résout les compétences/aptitudes de classe/'
        'maîtrises d\'outils/langues/sorts/emplacements de sorts de l\'onglet '
        '"Compétences" via le vrai schéma (character_skill_proficiencies, '
        'class_features, character_tool_proficiencies, character_languages, '
        'character_spells, character_spell_slots, character_feature_uses)', () async {
      final character = await client
          .from('characters')
          .insert({'owner_id': ownerId, 'name': 'Test Intégration Compétences'})
          .select('id')
          .single();
      final characterId = character['id'] as String;
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      // Niveau 5 dans la classe de référence : assez haut pour couvrir
      // plusieurs aptitudes de classe (`class_features.level`) sans
      // dépendre d'un contenu précis — voir la note ci-dessous sur la
      // résolution dynamique de la ligne de test.
      await client.from('character_classes').insert({
        'character_id': characterId,
        'class_id': reference.classId,
        'level': 5,
        'is_primary': true,
      });

      final skillRow = await client
          .from('skills')
          .select('id, ability_id')
          .order('id')
          .limit(1)
          .single();
      final skillId = skillRow['id'] as Object;
      await client.from('character_skill_proficiencies').insert({
        'character_id': characterId,
        'skill_id': skillId,
        'proficiency': 'expertise',
      });

      await client.from('character_tool_proficiencies').insert({
        'character_id': characterId,
        'tool_id': reference.toolId,
      });

      await client.from('character_languages').insert({
        'character_id': characterId,
        'language_id': reference.languageId,
      });

      await client.from('character_spells').insert({
        'character_id': characterId,
        'spell_id': reference.spellId,
        'status': 'connu',
      });
      final spellRow = await client
          .from('spells')
          .select('level, school')
          .eq('id', reference.spellId)
          .single();

      await client.from('character_spell_slots').insert({
        'character_id': characterId,
        'slot_level': 1,
        'slots_total': 4,
        'slots_used': 1,
      });

      // Toutes les aptitudes de niveau <= 5 de la classe de référence, pour
      // trouver dynamiquement une aptitude à usage limité (uses_per_rest
      // non nul) sans dépendre d'un contenu précis (le contenu de
      // référence peut évoluer) — le stack local peuple au moins les 12
      // classes du Manuel des Joueurs avec leurs aptitudes de niveau 1+
      // (voir `20260825090700_seed_classes_subclasses_features.sql` côté
      // dépôt web), donc au moins une aptitude est garantie ici.
      final attainedFeatureRows = await client
          .from('class_features')
          .select('id, level, uses_per_rest')
          .eq('class_id', reference.classId)
          .lte('level', 5);
      expect(
        attainedFeatureRows,
        isNotEmpty,
        reason:
            'Contenu de référence inattendu : la classe #${reference.classId} '
            'n\'a aucune aptitude de niveau <= 5 côté seed — vérifier '
            'supabase db reset côté dépôt web.',
      );
      final limitedFeatureRow = attainedFeatureRows.firstWhere(
        (row) => row['uses_per_rest'] != null,
        orElse: () => const {},
      );
      if (limitedFeatureRow.isNotEmpty) {
        await client.from('character_feature_uses').insert({
          'character_id': characterId,
          'class_feature_id': limitedFeatureRow['id'],
          'uses_remaining': 0,
        });
      }

      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        const AlwaysOnlineConnectivityChecker(),
      );
      final detail = await repository.fetchCharacterDetail(characterId);

      // Les 18 compétences sont toujours résolues (table de référence
      // complète), celle marquée 'expertise' ci-dessus doit ressortir avec
      // la bonne caractéristique.
      expect(detail.skills, hasLength(18));
      final skillResult = detail.skills.singleWhere((s) => s.id == skillId);
      expect(skillResult.proficiency, 'expertise');
      expect(skillResult.abilityId, skillRow['ability_id']);

      expect(detail.toolProficiencyNames, contains(reference.toolName));
      expect(detail.knownLanguageNames, contains(reference.languageName));

      expect(
        detail.classFeatures.map((f) => f.id),
        containsAll(attainedFeatureRows.map((r) => r['id'] as int)),
      );
      // Ordre déterministe (`.order('level')` côté requête, voir
      // `SupabaseCharacterRepository._buildCharacterDetailPayload`/
      // `_mapCharacterDetailPayload`) : les niveaux
      // affichés ne doivent jamais redescendre — signalé en revue QA
      // (dépendait auparavant de l'ordre non garanti renvoyé par
      // PostgREST).
      final levels = detail.classFeatures.map((f) => f.level).toList();
      expect(
        levels,
        List<int>.from(levels)..sort(),
        reason: 'detail.classFeatures doit être trié par level croissant.',
      );

      if (limitedFeatureRow.isNotEmpty) {
        final limitedFeature = detail.classFeatures.singleWhere(
          (f) => f.id == limitedFeatureRow['id'],
        );
        expect(limitedFeature.isPassive, isFalse);
        expect(limitedFeature.usesRemaining, 0);
        final usesPerRest =
            limitedFeatureRow['uses_per_rest'] as Map<String, dynamic>;
        expect(limitedFeature.usesMax, usesPerRest['amount']);
        expect(limitedFeature.restType, usesPerRest['rest_type']);
      }

      expect(detail.spells, hasLength(1));
      expect(detail.spells.single.name, reference.spellName);
      expect(detail.spells.single.level, spellRow['level']);
      expect(detail.spells.single.school, spellRow['school'] ?? '');

      expect(detail.spellSlots, hasLength(1));
      expect(detail.spellSlots.single.level, 1);
      expect(detail.spellSlots.single.total, 4);
      expect(detail.spellSlots.single.used, 1);
      expect(detail.spellSlots.single.remaining, 3);
    });

    test('fetchCharacterDetail résout la monnaie et l\'inventaire de '
        'l\'onglet "Inventaire" via le vrai schéma (character_inventory '
        'joint à items par une vraie relation de clé étrangère, noms '
        'd\'objets du catalogue via translations)', () async {
      final character = await client
          .from('characters')
          .insert({
            'owner_id': ownerId,
            'name': 'Test Intégration Inventaire',
            'currency_gp': 42,
            'currency_pp': 2,
            'currency_sp': 6,
            'currency_cp': 14,
          })
          .select('id')
          .single();
      final characterId = character['id'] as String;
      addTearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      final itemRow = await client
          .from('items')
          .select('weight')
          .eq('id', reference.itemId)
          .single();
      final itemWeight = (itemRow['weight'] as num?)?.toDouble();

      await client.from('character_inventory').insert([
        {
          'character_id': characterId,
          'item_id': reference.itemId,
          'quantity': 2,
          'equipped': true,
        },
        {
          'character_id': characterId,
          'custom_name': 'Petit sac de sable',
          'quantity': 1,
          'equipped': false,
        },
      ]);

      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        const AlwaysOnlineConnectivityChecker(),
      );
      final detail = await repository.fetchCharacterDetail(characterId);

      expect(detail.currencyGp, 42);
      expect(detail.currencyPp, 2);
      expect(detail.currencyEp, 0);
      expect(detail.currencySp, 6);
      expect(detail.currencyCp, 14);

      expect(detail.inventory, hasLength(2));

      final catalogLine = detail.inventory.singleWhere(
        (line) => line.itemId == reference.itemId,
      );
      expect(catalogLine.name, reference.itemName);
      expect(catalogLine.category, reference.itemCategory);
      expect(catalogLine.quantity, 2);
      expect(catalogLine.equipped, isTrue);
      expect(catalogLine.isCustom, isFalse);
      if (itemWeight != null) {
        expect(catalogLine.totalWeight, closeTo(itemWeight * 2, 0.001));
      } else {
        expect(catalogLine.totalWeight, isNull);
      }

      final customLine = detail.inventory.singleWhere(
        (line) => line.name == 'Petit sac de sable',
      );
      expect(customLine.itemId, isNull);
      expect(customLine.isCustom, isTrue);
      expect(customLine.category, isNull);
      expect(customLine.quantity, 1);
      expect(customLine.equipped, isFalse);
      // Aucune ligne `items` pour un objet personnalisé : poids toujours
      // inconnu côté schéma actuel, voir
      // `domain/character_inventory_item.dart::totalWeight`.
      expect(customLine.totalWeight, isNull);
    });

    test('fetchCharacterDetail résout les 9 champs texte de l\'onglet '
        '"Histoire" (appearance_text/traits_text/ideals_text/bonds_text/'
        'flaws_text/backstory_text/allies_text/features_text/'
        'treasure_text) directement depuis characters, et replie sur '
        'une chaîne vide (jamais null) pour un personnage qui ne les a '
        'jamais renseignés', () async {
      final character = await client
          .from('characters')
          .insert({
            'owner_id': ownerId,
            'name': 'Test Intégration Histoire',
            'appearance_text': 'Cheveux argentés tressés.',
            'traits_text': "Curieuse jusqu'à l'imprudence.",
            'ideals_text': 'Le savoir doit être partagé.',
            'bonds_text': 'Recherche le maître qui a scellé le grimoire.',
            'flaws_text': 'Incapable de résister à un mystère non résolu.',
            'backstory_text': 'Élevée dans une enclave forestière.',
            'allies_text': "L'Ordre des Archivistes.",
            'features_text': 'Une cicatrice fine sur la joue gauche.',
            'treasure_text': 'Un vieux grimoire scellé.',
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
      final detail = await repository.fetchCharacterDetail(characterId);

      expect(detail.appearanceText, 'Cheveux argentés tressés.');
      expect(detail.traitsText, "Curieuse jusqu'à l'imprudence.");
      expect(detail.idealsText, 'Le savoir doit être partagé.');
      expect(detail.bondsText, 'Recherche le maître qui a scellé le grimoire.');
      expect(
        detail.flawsText,
        'Incapable de résister à un mystère non résolu.',
      );
      expect(detail.backstoryText, 'Élevée dans une enclave forestière.');
      expect(detail.alliesText, "L'Ordre des Archivistes.");
      expect(detail.featuresText, 'Une cicatrice fine sur la joue gauche.');
      expect(detail.treasureText, 'Un vieux grimoire scellé.');

      // Second personnage sans aucun des 9 champs renseigné : colonnes
      // `not null default ''` en base (voir
      // `20260825090400_create_character_tables.sql`), jamais `null`.
      final blankCharacter = await client
          .from('characters')
          .insert({
            'owner_id': ownerId,
            'name': 'Test Intégration Histoire vide',
          })
          .select('id')
          .single();
      final blankCharacterId = blankCharacter['id'] as String;
      addTearDown(() async {
        await client.from('characters').delete().eq('id', blankCharacterId);
      });

      final blankDetail = await repository.fetchCharacterDetail(
        blankCharacterId,
      );
      expect(blankDetail.appearanceText, '');
      expect(blankDetail.traitsText, '');
      expect(blankDetail.idealsText, '');
      expect(blankDetail.bondsText, '');
      expect(blankDetail.flawsText, '');
      expect(blankDetail.backstoryText, '');
      expect(blankDetail.alliesText, '');
      expect(blankDetail.featuresText, '');
      expect(blankDetail.treasureText, '');
    });

    test('fetchCharacterDetail résout les 7 champs de la carte "Apparence '
        'physique" (sexe/age/height/weight/eyes/skin/hair) directement '
        'depuis characters, et replie sur une chaîne vide (jamais null) '
        'pour un personnage qui ne les a jamais renseignés — colonnes '
        '`text` nullables sans défaut en base, à la différence des colonnes '
        '`*_text` de l\'onglet "Histoire" testées ci-dessus', () async {
      final character = await client
          .from('characters')
          .insert({
            'owner_id': ownerId,
            'name': 'Test Intégration Apparence',
            'sexe': 'Femme',
            'age': '124 ans',
            'height': '1m70',
            'weight': '58 kg',
            'eyes': 'Argentés',
            'skin': 'Pâle',
            'hair': 'Argentés, tressés',
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
      final detail = await repository.fetchCharacterDetail(characterId);

      expect(detail.sexe, 'Femme');
      expect(detail.age, '124 ans');
      expect(detail.height, '1m70');
      expect(detail.weight, '58 kg');
      expect(detail.eyes, 'Argentés');
      expect(detail.skin, 'Pâle');
      expect(detail.hair, 'Argentés, tressés');

      // Second personnage sans aucun des 7 champs renseigné : colonnes
      // nullables sans défaut en base (voir
      // `20260825090400_create_character_tables.sql`), donc bien `null`
      // côté PostgREST — c'est au mapper de replier sur `''`.
      final blankCharacter = await client
          .from('characters')
          .insert({
            'owner_id': ownerId,
            'name': 'Test Intégration Apparence vide',
          })
          .select('id')
          .single();
      final blankCharacterId = blankCharacter['id'] as String;
      addTearDown(() async {
        await client.from('characters').delete().eq('id', blankCharacterId);
      });

      final blankDetail = await repository.fetchCharacterDetail(
        blankCharacterId,
      );
      expect(blankDetail.sexe, '');
      expect(blankDetail.age, '');
      expect(blankDetail.height, '');
      expect(blankDetail.weight, '');
      expect(blankDetail.eyes, '');
      expect(blankDetail.skin, '');
      expect(blankDetail.hair, '');
    });

    test(
      'fetchCharacterDetail lève une CharacterFailure "introuvable" pour un '
      'personnage inexistant ou appartenant à un autre joueur (RLS)',
      () async {
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );

        await expectLater(
          repository.fetchCharacterDetail(
            '00000000-0000-0000-0000-000000000000',
          ),
          throwsA(
            isA<CharacterFailure>().having(
              (failure) => failure.message,
              'message',
              'Personnage introuvable.',
            ),
          ),
        );
      },
    );

    test('updateHp écrit current_hp/temporary_hp en base', () async {
      final character = await client
          .from('characters')
          .insert({
            'owner_id': ownerId,
            'name': 'Test Intégration PV',
            'current_hp': 10,
            'max_hp': 20,
            'temporary_hp': 0,
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
      await repository.updateHp(
        characterId: characterId,
        currentHp: 5,
        temporaryHp: 8,
      );

      final row = await client
          .from('characters')
          .select('current_hp, temporary_hp')
          .eq('id', characterId)
          .single();
      expect(row['current_hp'], 5);
      expect(row['temporary_hp'], 8);
    });

    test('uploadPortrait envoie le fichier dans le bucket character-portraits '
        'et met à jour portrait_url ; removePortrait supprime le fichier et '
        'remet portrait_url à null', () async {
      final character = await client
          .from('characters')
          .insert({'owner_id': ownerId, 'name': 'Test Intégration Portrait'})
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
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      final publicUrl = await repository.uploadPortrait(
        characterId: characterId,
        bytes: bytes,
      );

      expect(publicUrl, contains('character-portraits'));
      expect(publicUrl, contains(ownerId));

      final afterUpload = await client
          .from('characters')
          .select('portrait_url')
          .eq('id', characterId)
          .single();
      expect(afterUpload['portrait_url'], publicUrl);

      await repository.removePortrait(
        characterId: characterId,
        portraitUrl: publicUrl,
      );

      final afterRemove = await client
          .from('characters')
          .select('portrait_url')
          .eq('id', characterId)
          .single();
      expect(afterRemove['portrait_url'], isNull);
    });

    group('isolation cross-utilisateur (RLS + filtre owner_id)', () {
      // Reproduit le point soulevé en revue de code : `fetchCharacterDetail`
      // n'avait qu'un test RLS avec un UUID *inexistant* (voir ci-dessus),
      // jamais un vrai personnage appartenant à un *second utilisateur réel*
      // — le seul cas qui exerce réellement la policy RLS de lecture
      // (`auth.uid() = owner_id`) plutôt que le simple "aucune ligne avec
      // cet id". Signalé en revue QA : `fetchCharacterDetail` embarque
      // désormais 6 jointures supplémentaires (compétences/aptitudes/
      // outils/langues/sorts/emplacements de sorts) jamais vérifiées sous cet
      // angle. Pareillement, rien n'exerçait `updateHp`/`uploadPortrait`/
      // `removePortrait` avec le `characterId` d'un personnage appartenant à
      // un *autre* joueur — la garantie reposait uniquement sur la RLS
      // serveur + le filtre `.eq('owner_id', ownerId)` côté client
      // (`data/character_repository.dart`), jamais exercée contre le vrai
      // stack.
      //
      // Un second `SupabaseClient`, authentifié avec un second utilisateur
      // jetable, appelle chacune des méthodes sur le personnage du *premier*
      // joueur (`characterId` ci-dessous, créé par `client`/`ownerId`).
      // Qu'elles lèvent une erreur ou échouent silencieusement (0 ligne
      // affectée : le filtre `.eq('owner_id', ownerId)` côté client utilise
      // l'identité de l'appelant, qui ne correspond jamais au vrai
      // propriétaire — voir `character_repository.dart`) est accepté
      // indifféremment ici pour les méthodes d'écriture ; pour la lecture
      // (`fetchCharacterDetail`), seule une `CharacterFailure` "introuvable"
      // est acceptable (jamais les données d'un autre joueur).
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
              'name': 'Test Intégration Isolation',
              'current_hp': 10,
              'max_hp': 20,
              'temporary_hp': 0,
            })
            .select('id')
            .single();
        characterId = character['id'] as String;
      });

      tearDown(() async {
        await client.from('characters').delete().eq('id', characterId);
      });

      test('fetchCharacterDetail appelé depuis la session d\'un autre joueur '
          'lève une CharacterFailure "introuvable", jamais les données du '
          'personnage visé', () async {
        final otherRepository = SupabaseCharacterRepository(
          otherClient,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );

        await expectLater(
          otherRepository.fetchCharacterDetail(characterId),
          throwsA(
            isA<CharacterFailure>().having(
              (failure) => failure.message,
              'message',
              'Personnage introuvable.',
            ),
          ),
        );
      });

      test('updateHp appelé depuis la session d\'un autre joueur ne modifie '
          'jamais le personnage visé', () async {
        final otherRepository = SupabaseCharacterRepository(
          otherClient,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        try {
          await otherRepository.updateHp(
            characterId: characterId,
            currentHp: 999,
            temporaryHp: 999,
          );
        } catch (_) {
          // Un échec explicite (RLS) est un résultat acceptable ici aussi
          // — voir la documentation du groupe.
        }

        final row = await client
            .from('characters')
            .select('current_hp, temporary_hp')
            .eq('id', characterId)
            .single();
        expect(row['current_hp'], 10);
        expect(row['temporary_hp'], 0);
      });

      test('uploadPortrait appelé depuis la session d\'un autre joueur ne met '
          'jamais à jour portrait_url du personnage visé', () async {
        final otherRepository = SupabaseCharacterRepository(
          otherClient,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        try {
          await otherRepository.uploadPortrait(
            characterId: characterId,
            bytes: Uint8List.fromList([1, 2, 3]),
          );
        } catch (_) {
          // Idem — voir la documentation du groupe.
        }

        final row = await client
            .from('characters')
            .select('portrait_url')
            .eq('id', characterId)
            .single();
        expect(row['portrait_url'], isNull);
      });

      test('removePortrait appelé depuis la session d\'un autre joueur ne '
          'modifie jamais le personnage visé', () async {
        const existingUrl = 'https://example.com/should-not-be-touched.png';
        await client
            .from('characters')
            .update({'portrait_url': existingUrl})
            .eq('id', characterId);

        final otherRepository = SupabaseCharacterRepository(
          otherClient,
          cache,
          pendingWrites,
          const AlwaysOnlineConnectivityChecker(),
        );
        try {
          await otherRepository.removePortrait(
            characterId: characterId,
            portraitUrl: existingUrl,
          );
        } catch (_) {
          // Idem — voir la documentation du groupe.
        }

        final row = await client
            .from('characters')
            .select('portrait_url')
            .eq('id', characterId)
            .single();
        expect(row['portrait_url'], existingUrl);
      });
    });
  });
}
