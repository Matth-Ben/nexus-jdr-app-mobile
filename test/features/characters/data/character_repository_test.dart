import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ces tests couvrent la stratégie "réseau d'abord, cache en secours" du
/// cache local (`ReferenceDataCache`, `lib/core/cache/`) appliquée à
/// `SupabaseCharacterRepository.fetchCharacterDetail` — même principe que
/// `test/features/character_creation/data/character_creation_repository_test.dart`
/// pour les 8 catalogues de référence (voir la doc de classe de ce fichier
/// pour le rationale détaillé du double `SupabaseClient`/`MockClient`,
/// repris ici sous [_buildSignedInFakeSupabaseClient] plutôt que réutilisé
/// tel quel : ce fichier a en plus besoin d'un utilisateur authentifié —
/// `fetchCharacterDetail` appelle `_requireOwnerId()`, qui lit
/// `_client.auth.currentUser?.id` — alors que les 8 catalogues de référence
/// ne dépendent jamais de l'identité de l'appelant).
///
/// [_buildSignedInFakeSupabaseClient] connecte le client factice sans
/// aucune requête réseau, via
/// `GoTrueClient.recoverSession` : un jeton d'accès qui n'est pas un JWT
/// valide fait échouer silencieusement `Session._expiresAt` (`decodeJwtPayload`,
/// avalé par un `try/catch` interne au package `gotrue`), ce qui fait
/// retomber `Session.isExpired` sur `false` — la branche "session non
/// expirée" de `recoverSession` s'exécute alors entièrement en mémoire,
/// sans jamais appeler `MockClient`.
///
/// Ce comportement n'est pas contractuel côté `gotrue` (détail
/// d'implémentation, pas de l'API publique) : **si ce fichier se met à
/// échouer après une montée de version de `supabase_flutter`/`gotrue`,
/// commencer l'investigation ici**. Risque limité en pratique — si
/// `isExpired` devenait un jour `true`, `recoverSession` tenterait un
/// rafraîchissement réseau via `MockClient`, qui échouerait à parser une
/// réponse `[]` sur la route `token`, et `_buildSignedInFakeSupabaseClient`
/// lèverait une exception explicite dès le `setUp()` — un échec bruyant et
/// localisé à ce fichier, jamais un faux positif silencieux.
///
/// Point central de ce fichier, au-delà des 3 scénarios communs au chantier
/// précédent (succès réseau écrit le cache, échec réseau + cache retombe
/// dessus, échec réseau + aucun cache relance l'erreur d'origine) : la
/// **isolation par utilisateur** de la clé de cache
/// (`'character_detail:$ownerId:$characterId'`, jamais
/// `'character_detail:$characterId'` seul) — voir le dernier groupe de
/// `main()`.
void main() {
  group(
    'SupabaseCharacterRepository.fetchCharacterDetail (cache de secours)',
    () {
      late AppDatabase db;
      late ReferenceDataCache cache;

      setUp(() {
        db = AppDatabase(NativeDatabase.memory());
        cache = ReferenceDataCache(db);
      });

      tearDown(() async {
        await db.close();
      });

      const characterId = 'char-1';
      const ownerId = 'owner-1';
      final cacheKey = 'character_detail:$ownerId:$characterId';

      final tableRows = <String, List<Map<String, dynamic>>>{
        'characters': [
          {
            'id': characterId,
            'name': 'Aragorn',
            'portrait_url': null,
            'xp': 100,
            'current_hp': 10,
            'max_hp': 12,
            'temporary_hp': 0,
            'race_id': 1,
            'subrace_id': null,
            'race_custom_text': null,
            'background_id': 3,
            'alignment_id': 9,
            'sexe': null,
            'age': null,
            'height': null,
            'weight': null,
            'eyes': null,
            'skin': null,
            'hair': null,
            'currency_gp': 5,
            'currency_pp': 0,
            'currency_ep': 0,
            'currency_sp': 0,
            'currency_cp': 0,
            'appearance_text': '',
            'traits_text': '',
            'ideals_text': '',
            'bonds_text': '',
            'flaws_text': '',
            'backstory_text': '',
            'allies_text': '',
            'features_text': '',
            'treasure_text': '',
            'character_classes': [
              {
                'class_id': 2,
                'level': 5,
                'is_primary': true,
                'classes': {
                  'saving_throw_proficiencies': ['str', 'con'],
                  'hit_die': 10,
                },
              },
            ],
            'character_ability_scores': [
              {'ability_id': 'str', 'score': 16},
            ],
            'character_skill_proficiencies': [
              {'skill_id': 7, 'proficiency': 'maitrise'},
            ],
            'character_tool_proficiencies': [
              {'tool_id': 4, 'custom_text': null},
            ],
            'character_languages': [
              {'language_id': 5},
            ],
            'character_spells': [
              {'spell_id': 20, 'status': 'connu'},
            ],
            'character_spell_slots': [
              {'slot_level': 1, 'slots_total': 4, 'slots_used': 1},
            ],
            'character_feature_uses': [
              {'class_feature_id': 50, 'uses_remaining': 2},
            ],
            'character_inventory': [
              {
                'id': 'inv-1',
                'item_id': 6,
                'custom_name': null,
                'quantity': 2,
                'equipped': true,
                'items': {'category': 'arme', 'weight': 1.5},
              },
            ],
          },
        ],
        // Un seul endpoint `translations` sert toutes les résolutions de noms
        // (race/background/alignment/class/skill/class_feature/tool/language/
        // spell/item) : notre double ne filtre pas par query string (seulement
        // par table), donc tous les entity_id ci-dessous doivent coexister —
        // sans conséquence puisque chaque résolution ne va chercher que
        // l'entity_id qui la concerne, et tous les ids ci-dessous sont
        // distincts (voir `character_creation_repository_test.dart` pour le
        // même principe).
        'translations': [
          {'entity_id': '1', 'value': 'Humain'},
          {'entity_id': '3', 'value': 'Soldat'},
          {'entity_id': '9', 'value': 'Loyal bon'},
          {'entity_id': '2', 'value': 'Guerrier'},
          {'entity_id': '7', 'value': 'Perception'},
          {'entity_id': '50', 'value': 'Deuxième souffle'},
          {'entity_id': '4', 'value': 'Luth'},
          {'entity_id': '5', 'value': 'Elfique'},
          {'entity_id': '20', 'value': 'Bouclier'},
          {'entity_id': '6', 'value': 'Épée longue'},
        ],
        'skills': [
          {'id': 7, 'ability_id': 'wis'},
        ],
        'class_features': [
          {
            'id': 50,
            'class_id': 2,
            'level': 3,
            'uses_per_rest': {'amount': 2, 'rest_type': 'repos_court'},
          },
        ],
        'spells': [
          {'id': 20, 'level': 1, 'school': 'évocation'},
        ],
      };

      void verifyDetail(dynamic detail) {
        expect(detail.id, characterId);
        expect(detail.name, 'Aragorn');
        expect(detail.raceName, 'Humain');
        expect(detail.backgroundName, 'Soldat');
        expect(detail.alignmentName, 'Loyal bon');
        expect(detail.classes, hasLength(1));
        expect(detail.classes.single.className, 'Guerrier');
        expect(detail.classes.single.level, 5);
        expect(detail.skills.where((s) => s.id == 7).single.name, 'Perception');
        expect(
          detail.classFeatures.single.name,
          'Deuxième souffle',
          reason: 'aptitude de niveau 3, atteinte par une classe niveau 5',
        );
        expect(detail.toolProficiencyNames, ['Luth']);
        expect(detail.knownLanguageNames, ['Elfique']);
        expect(detail.spells.single.name, 'Bouclier');
        expect(detail.spellSlots.single.total, 4);
        expect(detail.inventory.single.name, 'Épée longue');
        expect(detail.inventory.single.totalWeight, 3.0);
        expect(detail.currencyGp, 5);
      }

      test(
        'succès réseau : écrit le cache (clé scopée par ownerId) et retourne '
        'la fiche mappée',
        () async {
          final client = await _buildSignedInFakeSupabaseClient(
            ownerId: ownerId,
            tableRows: tableRows,
          );
          final repository = SupabaseCharacterRepository(client, cache);

          final detail = await repository.fetchCharacterDetail(characterId);

          verifyDetail(detail);
          expect(
            await cache.get(cacheKey),
            isNotNull,
            reason: 'le succès réseau doit avoir peuplé le cache',
          );
        },
      );

      test('échec réseau + cache déjà présent : retombe sur le cache et '
          'produit la même fiche que le mapper direct', () async {
        final onlineClient = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          tableRows: tableRows,
        );
        final onlineRepository = SupabaseCharacterRepository(
          onlineClient,
          cache,
        );
        final expectedDetail = await onlineRepository.fetchCharacterDetail(
          characterId,
        );

        final offlineClient = await _buildSignedInFakeSupabaseClient(
          ownerId: ownerId,
          failureStatusCode: 500,
        );
        final offlineRepository = SupabaseCharacterRepository(
          offlineClient,
          cache,
        );
        final detail = await offlineRepository.fetchCharacterDetail(
          characterId,
        );

        // Pas de comparaison `expect(detail, expectedDetail)` directe :
        // `CharacterSkillRow`/`CharacterClassFeature`/`CharacterSpellEntry`/
        // `CharacterInventoryItem`/`CharacterDetailClassRow` sont
        // volontairement des classes simples (pas `freezed`, voir leur
        // documentation de classe), sans `==` structurel — deux instances
        // aux mêmes valeurs de champs mais construites séparément (une par
        // le chemin réseau, une par le chemin cache) resteraient donc
        // toujours inégales par identité, même si `CharacterDetail`
        // lui-même est `freezed`. [verifyDetail] vérifie déjà exhaustivement
        // les champs/listes issus de la fixture partagée par les deux
        // chemins ; les assertions scalaires ci-dessous complètent en
        // comparant explicitement les deux résultats entre eux plutôt qu'à
        // des valeurs figées.
        verifyDetail(detail);
        expect(detail.id, expectedDetail.id);
        expect(detail.name, expectedDetail.name);
        expect(detail.xp, expectedDetail.xp);
        expect(detail.currentHp, expectedDetail.currentHp);
        expect(detail.maxHp, expectedDetail.maxHp);
        expect(detail.currencyGp, expectedDetail.currencyGp);
        expect(detail.raceName, expectedDetail.raceName);
        expect(detail.backgroundName, expectedDetail.backgroundName);
        expect(detail.alignmentName, expectedDetail.alignmentName);
        expect(detail.totalLevel, expectedDetail.totalLevel);
      });

      test(
        'échec réseau + aucun cache : relance l\'erreur d\'origine',
        () async {
          final client = await _buildSignedInFakeSupabaseClient(
            ownerId: ownerId,
            throwOnRequest: true,
          );
          final repository = SupabaseCharacterRepository(client, cache);

          await expectLater(
            repository.fetchCharacterDetail(characterId),
            throwsA(isA<CharacterFailure>()),
          );
        },
      );

      test(
        'isolation par utilisateur : un changement de compte sur le même '
        'appareil ne peut jamais lire l\'entrée de cache d\'un autre joueur',
        () async {
          // Le joueur `owner-1` ouvre sa fiche avec succès réseau : le cache
          // ne contient que 'character_detail:owner-1:char-1'.
          final ownerOneClient = await _buildSignedInFakeSupabaseClient(
            ownerId: ownerId,
            tableRows: tableRows,
          );
          await SupabaseCharacterRepository(
            ownerOneClient,
            cache,
          ).fetchCharacterDetail(characterId);
          expect(await cache.get(cacheKey), isNotNull);

          // `owner-2` se connecte sur le même appareil, réseau indisponible au
          // moment où il ouvrirait (hypothétiquement) la même route
          // `characterId` : la clé de cache scopée par ownerId ('character_detail:
          // owner-2:char-1') n'existe pas — jamais de repli sur les données
          // d'`owner-1`, l'erreur d'origine doit être relancée telle quelle.
          const otherOwnerId = 'owner-2';
          final ownerTwoClient = await _buildSignedInFakeSupabaseClient(
            ownerId: otherOwnerId,
            throwOnRequest: true,
          );
          final ownerTwoRepository = SupabaseCharacterRepository(
            ownerTwoClient,
            cache,
          );

          await expectLater(
            ownerTwoRepository.fetchCharacterDetail(characterId),
            throwsA(isA<CharacterFailure>()),
          );
          expect(
            await cache.get('character_detail:$otherOwnerId:$characterId'),
            isNull,
            reason:
                'aucune entrée de cache ne doit jamais exister pour owner-2 : '
                'la clé est scopée par ownerId, pas partagée entre comptes',
          );
          expect(
            await cache.get(cacheKey),
            isNotNull,
            reason:
                "l'entrée d'owner-1 doit rester intacte, jamais écrasée ni "
                'lue par owner-2',
          );
        },
      );
    },
  );
}

/// Fabrique un `SupabaseClient` réel, mais dont le transport HTTP est
/// entièrement fabriqué (`MockClient`), authentifié en mémoire (sans requête
/// réseau) pour l'utilisateur [ownerId] — voir la doc de classe en tête de ce
/// fichier pour le rationale des deux mécanismes (transport HTTP fabriqué +
/// authentification en mémoire via `recoverSession`).
///
/// [tableRows] route chaque requête par le dernier segment de son chemin
/// (`/rest/v1/<table>`), sans tenir compte du reste de la query string —
/// même principe et mêmes limites que
/// `character_creation_repository_test.dart::_buildFakeSupabaseClient`, dont
/// la documentation détaille [throwOnRequest]/[failureStatusCode].
Future<SupabaseClient> _buildSignedInFakeSupabaseClient({
  required String ownerId,
  Map<String, List<Map<String, dynamic>>> tableRows = const {},
  bool throwOnRequest = false,
  int? failureStatusCode,
}) async {
  Future<http.Response> handler(http.Request request) async {
    if (throwOnRequest) {
      throw const SocketException('Pas de réseau (double de test).');
    }
    if (failureStatusCode != null) {
      return http.Response(
        jsonEncode({
          'message': 'Erreur simulée (double de test).',
          'code': 'PGRST000',
        }),
        failureStatusCode,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }
    final table = request.url.pathSegments.last;
    final rows = tableRows[table] ?? const <Map<String, dynamic>>[];
    return http.Response(
      jsonEncode(rows),
      200,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }

  final client = SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient(handler),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );

  // Authentifie [client] sans jamais passer par `MockClient` : un
  // `access_token` qui n'est pas un JWT valide fait échouer silencieusement
  // le décodage de sa date d'expiration côté package `gotrue`
  // (`Session._expiresAt`), ce qui fait retomber `Session.isExpired` sur
  // `false` — `recoverSession` prend alors la branche "session non expirée"
  // et s'exécute entièrement en mémoire (voir la doc de classe).
  await client.auth.recoverSession(
    jsonEncode({
      'access_token': 'fake-access-token-$ownerId',
      'token_type': 'bearer',
      'user': {'id': ownerId},
    }),
  );

  return client;
}
