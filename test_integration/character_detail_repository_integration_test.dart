import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
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

    setUpAll(() async {
      client = createTestSupabaseClient();
      await signUpTestUser(client);
      reference = await fetchReferenceContent(client);
      ownerId = client.auth.currentUser!.id;
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
            .select('saving_throw_proficiencies')
            .eq('id', reference.classId)
            .single();

        final repository = SupabaseCharacterRepository(client);
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
      },
    );

    test(
      'fetchCharacterDetail lève une CharacterFailure "introuvable" pour un '
      'personnage inexistant ou appartenant à un autre joueur (RLS)',
      () async {
        final repository = SupabaseCharacterRepository(client);

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

      final repository = SupabaseCharacterRepository(client);
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

      final repository = SupabaseCharacterRepository(client);
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
      // avait déjà un test RLS (lecture, voir ci-dessus), mais rien
      // n'exerçait `updateHp`/`uploadPortrait`/`removePortrait` avec le
      // `characterId` d'un personnage appartenant à un *autre* joueur — la
      // garantie reposait uniquement sur la RLS serveur + le filtre
      // `.eq('owner_id', ownerId)` côté client
      // (`data/character_repository.dart`), jamais exercée contre le vrai
      // stack.
      //
      // Un second `SupabaseClient`, authentifié avec un second utilisateur
      // jetable, appelle chacune des 3 méthodes d'écriture sur le
      // personnage du *premier* utilisateur (`characterId` ci-dessous,
      // créé par `client`/`ownerId`). Qu'elles lèvent une erreur ou
      // échouent silencieusement (0 ligne affectée : le filtre
      // `.eq('owner_id', ownerId)` côté client utilise l'identité de
      // l'appelant, qui ne correspond jamais au vrai propriétaire — voir
      // `character_repository.dart`) est accepté indifféremment ici : seule
      // l'absence de toute modification effective en base, vérifiée en
      // relisant avec la session du premier utilisateur, fait foi.
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

      test('updateHp appelé depuis la session d\'un autre joueur ne modifie '
          'jamais le personnage visé', () async {
        final otherRepository = SupabaseCharacterRepository(otherClient);
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
        final otherRepository = SupabaseCharacterRepository(otherClient);
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

        final otherRepository = SupabaseCharacterRepository(otherClient);
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
