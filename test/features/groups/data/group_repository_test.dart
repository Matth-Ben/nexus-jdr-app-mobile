// Tests de `SupabaseGroupRepository` — même stratégie de double que
// `test/features/characters/data/character_repository_test.dart`
// (`SupabaseClient` réel, transport HTTP entièrement fabriqué via
// `MockClient`) : corps de requête envoyé aux 3 edge functions
// (`create-group`/`preview-group-invite`/`join-group`), mapping des
// réponses/erreurs, et écritures directes (`claim_group_treasure_currency`,
// `claimTreasureItem`), et écritures du butin (décision 91 : ajout,
// modification, retrait, monnaie conditionnelle, fiche d'un objet).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/custom_item_enrichment.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/group_character_reassignment_failure.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:personnages/features/groups/domain/group_invite_failure.dart';
import 'package:personnages/features/groups/domain/group_preview.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseGroupRepository.createGroup', () {
    test(
      'envoie {name, character_id} à create-group et mappe la réponse',
      () async {
        http.Request? capturedRequest;
        final client = _buildFakeClient(
          onRequest: (request) => capturedRequest = request,
          responses: {
            'create-group': {
              'id': 'group-1',
              'name': 'Les Lames',
              'invite_code': 'AB3F7K2M',
            },
          },
        );
        final repository = SupabaseGroupRepository(client);

        final created = await repository.createGroup(
          name: 'Les Lames',
          characterId: 'char-1',
        );

        expect(capturedRequest, isNotNull);
        expect(
          capturedRequest!.url.path,
          endsWith('/functions/v1/create-group'),
        );
        final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
        expect(body, {'name': 'Les Lames', 'character_id': 'char-1'});
        expect(created.id, 'group-1');
        expect(created.name, 'Les Lames');
        expect(created.inviteCode, 'AB3F7K2M');
      },
    );

    test(
      'erreur edge function -> GroupFailure avec le message serveur',
      () async {
        final client = _buildFakeClient(
          statusCode: 500,
          responses: {
            'create-group': {
              'error': 'internal_error',
              'message': 'Erreur serveur.',
            },
          },
        );
        final repository = SupabaseGroupRepository(client);

        await expectLater(
          repository.createGroup(name: 'Les Lames', characterId: 'char-1'),
          throwsA(
            isA<GroupFailure>().having(
              (f) => f.message,
              'message',
              'Erreur serveur.',
            ),
          ),
        );
      },
    );

    test('characterId null -> envoie {name} seul, sans character_id (MJ sans '
        'personnage)', () async {
      http.Request? capturedRequest;
      final client = _buildFakeClient(
        onRequest: (request) => capturedRequest = request,
        responses: {
          'create-group': {
            'id': 'group-1',
            'name': 'Les Lames',
            'invite_code': 'AB3F7K2M',
          },
        },
      );
      final repository = SupabaseGroupRepository(client);

      await repository.createGroup(name: 'Les Lames');

      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body, {'name': 'Les Lames'});
    });

    test('characterId vide -> envoie {name} seul, sans character_id', () async {
      http.Request? capturedRequest;
      final client = _buildFakeClient(
        onRequest: (request) => capturedRequest = request,
        responses: {
          'create-group': {
            'id': 'group-1',
            'name': 'Les Lames',
            'invite_code': 'AB3F7K2M',
          },
        },
      );
      final repository = SupabaseGroupRepository(client);

      await repository.createGroup(name: 'Les Lames', characterId: '');

      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body, {'name': 'Les Lames'});
    });
  });

  group('SupabaseGroupRepository.previewGroupInvite', () {
    test('envoie {code} et mappe {name, member_count}', () async {
      http.Request? capturedRequest;
      final client = _buildFakeClient(
        onRequest: (request) => capturedRequest = request,
        responses: {
          'preview-group-invite': {'name': 'Les Lames', 'member_count': 3},
        },
      );
      final repository = SupabaseGroupRepository(client);

      final preview = await repository.previewGroupInvite('AB3F7K2M');

      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body, {'code': 'AB3F7K2M'});
      expect(preview.name, 'Les Lames');
      expect(preview.memberCount, 3);
    });

    // Étape 4 : `story_title` (décision n° 33), jamais le résumé.
    test('mappe story_title quand la campagne est associée', () async {
      final client = _buildFakeClient(
        responses: {
          'preview-group-invite': {
            'name': 'Les Lames',
            'member_count': 3,
            'story_title': 'La Mine perdue',
          },
        },
      );

      final preview = await SupabaseGroupRepository(client)
          .previewGroupInvite('AB3F7K2M');

      expect(preview.storyTitle, 'La Mine perdue');
    });

    test('story_title null : aucune campagne', () async {
      final client = _buildFakeClient(
        responses: {
          'preview-group-invite': {
            'name': 'Les Lames',
            'member_count': 3,
            'story_title': null,
          },
        },
      );

      final preview = await SupabaseGroupRepository(client)
          .previewGroupInvite('AB3F7K2M');

      expect(preview.storyTitle, isNull);
    });

    test('story_title absent (fonction antérieure à l\'étape 4) : null, sans '
        'erreur', () async {
      final client = _buildFakeClient(
        responses: {
          'preview-group-invite': {'name': 'Les Lames', 'member_count': 3},
        },
      );

      final preview = await SupabaseGroupRepository(client)
          .previewGroupInvite('AB3F7K2M');

      expect(preview, const GroupPreview(name: 'Les Lames', memberCount: 3));
    });

    test('un résumé renvoyé par erreur n\'est jamais exposé, une valeur non '
        'textuelle est ignorée', () async {
      final client = _buildFakeClient(
        responses: {
          'preview-group-invite': {
            'name': 'Les Lames',
            'member_count': 3,
            'story_title': 42,
            'story_summary_public': 'Résumé réservé aux membres.',
          },
        },
      );

      final preview = await SupabaseGroupRepository(client)
          .previewGroupInvite('AB3F7K2M');

      expect(preview, const GroupPreview(name: 'Les Lames', memberCount: 3));
    });

    test('404 invalid_code -> GroupInviteFailureKind.invalidCode', () async {
      final client = _buildFakeClient(
        statusCode: 404,
        responses: {
          'preview-group-invite': {
            'error': 'invalid_code',
            'message': "Ce code d'invitation n'est pas valide.",
          },
        },
      );
      final repository = SupabaseGroupRepository(client);

      await expectLater(
        repository.previewGroupInvite('INVALIDE'),
        throwsA(
          isA<GroupInviteFailure>().having(
            (f) => f.kind,
            'kind',
            GroupInviteFailureKind.invalidCode,
          ),
        ),
      );
    });
  });

  group('SupabaseGroupRepository.joinGroup', () {
    test('envoie {code, character_id} et mappe {group_id, name}', () async {
      http.Request? capturedRequest;
      final client = _buildFakeClient(
        onRequest: (request) => capturedRequest = request,
        responses: {
          'join-group': {'group_id': 'group-1', 'name': 'Les Lames'},
        },
      );
      final repository = SupabaseGroupRepository(client);

      final joined = await repository.joinGroup(
        code: 'AB3F7K2M',
        characterId: 'char-1',
      );

      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body, {'code': 'AB3F7K2M', 'character_id': 'char-1'});
      expect(joined.groupId, 'group-1');
      expect(joined.name, 'Les Lames');
    });

    test(
      '409 already_in_group -> GroupInviteFailureKind.alreadyInGroup',
      () async {
        final client = _buildFakeClient(
          statusCode: 409,
          responses: {
            'join-group': {
              'error': 'already_in_group',
              'message': 'Ce personnage est déjà membre de ce groupe.',
            },
          },
        );
        final repository = SupabaseGroupRepository(client);

        await expectLater(
          repository.joinGroup(code: 'AB3F7K2M', characterId: 'char-1'),
          throwsA(
            isA<GroupInviteFailure>().having(
              (f) => f.kind,
              'kind',
              GroupInviteFailureKind.alreadyInGroup,
            ),
          ),
        );
      },
    );

    test('exception réseau (pas de réponse reçue) -> generic', () async {
      final client = _buildFakeClient(throwOnRequest: true);
      final repository = SupabaseGroupRepository(client);

      await expectLater(
        repository.joinGroup(code: 'AB3F7K2M', characterId: 'char-1'),
        throwsA(
          isA<GroupInviteFailure>().having(
            (f) => f.kind,
            'kind',
            GroupInviteFailureKind.generic,
          ),
        ),
      );
    });

    test('characterId null -> envoie {code} seul, sans character_id (MJ sans '
        'personnage)', () async {
      http.Request? capturedRequest;
      final client = _buildFakeClient(
        onRequest: (request) => capturedRequest = request,
        responses: {
          'join-group': {'group_id': 'group-1', 'name': 'Les Lames'},
        },
      );
      final repository = SupabaseGroupRepository(client);

      await repository.joinGroup(code: 'AB3F7K2M');

      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body, {'code': 'AB3F7K2M'});
    });

    test(
      '409 mj_already_assigned -> GroupInviteFailureKind.mjAlreadyAssigned',
      () async {
        final client = _buildFakeClient(
          statusCode: 409,
          responses: {
            'join-group': {
              'error': 'mj_already_assigned',
              'message': 'Ce groupe a déjà un MJ sans personnage.',
            },
          },
        );
        final repository = SupabaseGroupRepository(client);

        await expectLater(
          repository.joinGroup(code: 'AB3F7K2M'),
          throwsA(
            isA<GroupInviteFailure>().having(
              (f) => f.kind,
              'kind',
              GroupInviteFailureKind.mjAlreadyAssigned,
            ),
          ),
        );
      },
    );
  });

  group('SupabaseGroupRepository.fetchMyGroups (regression -- un groupe reste '
      'liste meme si character_id est devenu null entre-temps)', () {
    test('filtre group_members uniquement par user_id, jamais par '
        'character_id -- un membre orphelin (personnage supprime) voit '
        'toujours son groupe dans la liste', () async {
      const ownerId = 'user-orphan';
      final requests = <http.Request>[];
      final client = await _buildSignedInFakeClient(
        ownerId: ownerId,
        onRequest: requests.add,
        tableRows: {
          'group_members': [
            {
              'group_id': 'group-1',
              'groups': {
                'id': 'group-1',
                'name': "Les Lames de l'Aube",
                'owner_id': 'user-founder',
              },
            },
          ],
        },
      );
      final repository = SupabaseGroupRepository(client);

      final groups = await repository.fetchMyGroups();

      expect(groups, hasLength(1));
      expect(groups.single.id, 'group-1');
      expect(groups.single.name, "Les Lames de l'Aube");

      // Chaque requete group_members de cette methode est filtree
      // uniquement par user_id -- jamais par character_id (voir la doc
      // de GroupRepository.fetchMyGroups) : un membre dont le
      // personnage a ete supprime (character_id devenu null) continue
      // de voir son groupe, le bug corrige par ce chantier.
      final memberRequests = requests.where(
        (request) => request.url.path.endsWith('/group_members'),
      );
      expect(memberRequests, isNotEmpty);
      for (final request in memberRequests) {
        expect(
          request.url.queryParameters.keys,
          isNot(contains('character_id')),
        );
      }
    });
  });

  group('SupabaseGroupRepository.fetchMyGroups (statut vital agrege -- F03, '
      "vue group_character_status_overview)", () {
    test('interroge group_character_status_overview en une seule requete '
        'groupee (inFilter sur tous les group_id), jamais une boucle par '
        'groupe, et mappe dead_count/low_hp_count sur le GroupSummary '
        'correspondant', () async {
      const ownerId = 'user-1';
      final requests = <http.Request>[];
      final client = await _buildSignedInFakeClient(
        ownerId: ownerId,
        onRequest: requests.add,
        tableRows: {
          'group_members': [
            {
              'group_id': 'group-1',
              'groups': {
                'id': 'group-1',
                'name': 'Les Lames',
                'owner_id': ownerId,
              },
            },
            {
              'group_id': 'group-2',
              'groups': {
                'id': 'group-2',
                'name': 'Les Ombres',
                'owner_id': ownerId,
              },
            },
          ],
          'group_character_status_overview': [
            {'group_id': 'group-1', 'dead_count': 1, 'low_hp_count': 0},
            {'group_id': 'group-2', 'dead_count': 0, 'low_hp_count': 2},
          ],
        },
      );
      final repository = SupabaseGroupRepository(client);

      final groups = await repository.fetchMyGroups();

      final statusRequests = requests.where(
        (request) =>
            request.url.path.endsWith('/group_character_status_overview'),
      );
      expect(
        statusRequests,
        hasLength(1),
        reason:
            'une seule requete groupee vers la vue, jamais une requete par '
            'groupe (cout reseau explicitement proscrit par qa-testeur)',
      );
      final statusRequest = statusRequests.single;
      expect(
        statusRequest.url.queryParameters['group_id'],
        'in.("group-1","group-2")',
      );

      final byId = {for (final group in groups) group.id: group};
      expect(byId['group-1']!.deadCount, 1);
      expect(byId['group-1']!.lowHpCount, 0);
      expect(byId['group-2']!.deadCount, 0);
      expect(byId['group-2']!.lowHpCount, 2);
    });

    test('aucune ligne de statut renvoyee pour un groupe (vue vide) -> '
        'deadCount/lowHpCount par defaut a 0, jamais une erreur', () async {
      const ownerId = 'user-1';
      final client = await _buildSignedInFakeClient(
        ownerId: ownerId,
        tableRows: {
          'group_members': [
            {
              'group_id': 'group-1',
              'groups': {
                'id': 'group-1',
                'name': 'Les Lames',
                'owner_id': ownerId,
              },
            },
          ],
          // Pas d'entree 'group_character_status_overview' : la vue
          // retourne [] (via le repli par defaut de
          // `_buildSignedInFakeClient`, voir sa doc de classe).
        },
      );
      final repository = SupabaseGroupRepository(client);

      final groups = await repository.fetchMyGroups();

      expect(groups.single.deadCount, 0);
      expect(groups.single.lowHpCount, 0);
    });

    test('la requete group_character_status_overview echoue (ex. vue '
        'temporairement inaccessible) -> fetchMyGroups retourne quand meme '
        'la liste des groupes, deadCount/lowHpCount a 0, sans lever '
        "d'exception (point 1, repli isole)", () async {
      const ownerId = 'user-1';
      final client = await _buildSignedInFakeClient(
        ownerId: ownerId,
        tableRows: {
          'group_members': [
            {
              'group_id': 'group-1',
              'groups': {
                'id': 'group-1',
                'name': 'Les Lames',
                'owner_id': ownerId,
              },
            },
            {
              'group_id': 'group-2',
              'groups': {
                'id': 'group-2',
                'name': 'Les Ombres',
                'owner_id': ownerId,
              },
            },
          ],
        },
        failingTables: {'group_character_status_overview'},
      );
      final repository = SupabaseGroupRepository(client);

      final groups = await repository.fetchMyGroups();

      expect(groups, hasLength(2));
      for (final group in groups) {
        expect(group.deadCount, 0);
        expect(group.lowHpCount, 0);
      }
    });

    test(
      'aucun groupe (groupIds vide) -> retourne une liste vide sans '
      "jamais interroger group_character_status_overview (point 2)",
      () async {
        const ownerId = 'user-1';
        final requests = <http.Request>[];
        final client = await _buildSignedInFakeClient(
          ownerId: ownerId,
          onRequest: requests.add,
          tableRows: const {'group_members': []},
        );
        final repository = SupabaseGroupRepository(client);

        final groups = await repository.fetchMyGroups();

        expect(groups, isEmpty);
        expect(
          requests.any(
            (request) =>
                request.url.path.endsWith('/group_character_status_overview'),
          ),
          isFalse,
          reason:
              'namesById.isEmpty -> retour anticipe avant toute requete '
              'groupee (comptage des membres ou statut vital)',
        );
      },
    );
  });

  group('SupabaseGroupRepository.fetchGroupDetail', () {
    const groupId = 'group-1';
    const ownerId = 'owner-1';

    test(
      'sélectionne is_game_master et group_members_display_name (alias '
      "display_name), mappe un membre orphelin en isAwaitingCharacter",
      () async {
        final requests = <http.Request>[];
        final client = await _buildSignedInFakeClient(
          ownerId: ownerId,
          onRequest: requests.add,
          tableRows: {
            'groups': [
              {
                'id': groupId,
                'name': 'Les Lames',
                'owner_id': ownerId,
                'invite_code': 'AB3F7K2M',
              },
            ],
            'group_members': [
              {
                'character_id': null,
                'user_id': 'user-orphan',
                'role': 'membre',
                'is_game_master': false,
                'display_name': null,
                'characters': null,
              },
            ],
          },
        );
        final repository = SupabaseGroupRepository(client);

        final detail = await repository.fetchGroupDetail(groupId);

        final memberRequest = requests.firstWhere(
          (request) => request.url.path.endsWith('/group_members'),
        );
        final select = memberRequest.url.queryParameters['select'] ?? '';
        expect(select, contains('is_game_master'));
        expect(select, contains('display_name:group_members_display_name'));

        expect(detail.members, hasLength(1));
        final member = detail.members.single;
        expect(member.isAwaitingCharacter, isTrue);
        expect(member.isGameMaster, isFalse);
        expect(member.name, "En attente d'un personnage");
      },
    );

    test('sélectionne armor_class_bonus/character_ability_scores/'
        'character_inventory/character_class_options/subclass_id et calcule '
        'armorClass/armorClassBonus pour un membre avec personnage', () async {
      final requests = <http.Request>[];
      final client = await _buildSignedInFakeClient(
        ownerId: ownerId,
        onRequest: requests.add,
        tableRows: {
          'groups': [
            {
              'id': groupId,
              'name': 'Les Lames',
              'owner_id': ownerId,
              'invite_code': 'AB3F7K2M',
            },
          ],
          'group_members': [
            {
              'character_id': 'char-1',
              'user_id': ownerId,
              'role': 'owner',
              'is_game_master': false,
              'display_name': null,
              'characters': {
                'id': 'char-1',
                'name': 'Sylvi',
                'current_hp': 10,
                'max_hp': 10,
                'temporary_hp': 0,
                'is_dead': false,
                'armor_class_bonus': 1,
                // Aucune classe/race liée : les requêtes `translations`
                // correspondantes (`_fetchTranslatedNames`) ne sont jamais
                // déclenchées (ensembles d'identifiants vides), seul le
                // calcul de CA depuis les caractéristiques/l'inventaire
                // est exercé ici — voir `group_member_row_mapper_test.dart`
                // pour la couverture complète (classe/sous-classe/style de
                // combat) du mapper pur.
                'character_classes': <Map<String, dynamic>>[],
                'character_ability_scores': [
                  {'ability_id': 'dex', 'score': 14},
                ],
                'character_class_options': <Map<String, dynamic>>[],
                'character_inventory': <Map<String, dynamic>>[],
              },
            },
          ],
        },
      );
      final repository = SupabaseGroupRepository(client);

      final detail = await repository.fetchGroupDetail(groupId);

      final memberRequest = requests.firstWhere(
        (request) => request.url.path.endsWith('/group_members'),
      );
      final select = memberRequest.url.queryParameters['select'] ?? '';
      expect(select, contains('armor_class_bonus'));
      expect(select, contains('character_ability_scores'));
      expect(select, contains('character_inventory'));
      expect(select, contains('character_class_options'));
      expect(select, contains('subclass_id'));
      expect(select, contains('armor_properties'));

      final member = detail.members.single;
      // 10 (base, sans armure) + 2 (dex) + 1 (bonus manuel).
      expect(member.armorClass, 13);
      expect(member.armorClassBonus, 1);
    });

    // Étape 4 : campagne associée (`story_title`, `story_summary_public`).
    group('campagne associée', () {
      Map<String, dynamic> groupRow([Map<String, dynamic> extra = const {}]) =>
          {
            'id': groupId,
            'name': 'Les Lames',
            'owner_id': ownerId,
            'invite_code': 'AB3F7K2M',
            ...extra,
          };

      bool isGroupsRequest(http.Request request) =>
          request.url.path.endsWith('/groups');

      test(
        'sélectionne story_title/story_summary_public et les mappe',
        () async {
          final requests = <http.Request>[];
          final client = await _buildSignedInFakeClient(
            ownerId: ownerId,
            onRequest: requests.add,
            tableRows: {
              'groups': [
                groupRow({
                  'story_title': 'La Mine perdue',
                  'story_summary_public': 'Phandaline.\nUne mine.',
                }),
              ],
            },
          );

          final detail = await SupabaseGroupRepository(client)
              .fetchGroupDetail(groupId);

          final select = requests
              .firstWhere(isGroupsRequest)
              .url
              .queryParameters['select'];
          expect(select, contains('story_title'));
          expect(select, contains('story_summary_public'));
          expect(detail.storyTitle, 'La Mine perdue');
          expect(detail.storySummaryPublic, 'Phandaline.\nUne mine.');
        },
      );

      test('colonnes à NULL : aucune campagne', () async {
        final client = await _buildSignedInFakeClient(
          ownerId: ownerId,
          tableRows: {
            'groups': [
              groupRow({'story_title': null, 'story_summary_public': null}),
            ],
          },
        );

        final detail = await SupabaseGroupRepository(client)
            .fetchGroupDetail(groupId);

        expect(detail.storyTitle, isNull);
        expect(detail.storySummaryPublic, isNull);
        expect(detail.hasCampaignCard, isFalse);
      });

      test('aucune ligne (groupe supprimé ou RLS) : groupNotFound, requête '
          'limitée à une ligne', () async {
        final requests = <http.Request>[];
        final client = await _buildSignedInFakeClient(
          ownerId: ownerId,
          onRequest: requests.add,
        );

        await expectLater(
          SupabaseGroupRepository(client).fetchGroupDetail(groupId),
          throwsA(
            isA<GroupFailure>().having(
              (f) => f.code,
              'code',
              GroupErrorCode.groupNotFound,
            ),
          ),
        );
        final groupRequests = requests.where(isGroupsRequest).toList();
        expect(groupRequests, hasLength(1));
        expect(groupRequests.single.url.queryParameters['limit'], '1');
        expect(groupRequests.single.url.queryParameters['id'], 'eq.$groupId');
      });

      test('colonnes absentes de la réponse : null, sans erreur', () async {
        final client = await _buildSignedInFakeClient(
          ownerId: ownerId,
          tableRows: {
            'groups': [groupRow()],
          },
        );

        final detail = await SupabaseGroupRepository(client)
            .fetchGroupDetail(groupId);

        expect(detail.name, 'Les Lames');
        expect(detail.storyTitle, isNull);
        expect(detail.storySummaryPublic, isNull);
      });

      for (final (status, code) in const [(400, '42703'), (400, 'PGRST204')]) {
        test('colonnes inexistantes côté DeepCore ($code, retour arrière) : '
            'relit sans elles, l\'écran reste utilisable', () async {
          final groupSelects = <String>[];
          final client = await _buildSignedInFakeClient(
            ownerId: ownerId,
            tableRows: {
              'groups': [groupRow()],
            },
            respond: (request) {
              if (!isGroupsRequest(request)) return null;
              final select = request.url.queryParameters['select'] ?? '';
              groupSelects.add(select);
              if (!select.contains('story_title')) return null;
              return http.Response(
                jsonEncode({
                  'code': code,
                  'message': 'column groups.story_title does not exist',
                }),
                status,
                request: request,
                headers: {'content-type': 'application/json'},
              );
            },
          );

          final detail = await SupabaseGroupRepository(client)
              .fetchGroupDetail(groupId);

          expect(groupSelects, hasLength(2));
          expect(groupSelects.last, isNot(contains('story_title')));
          expect(detail.name, 'Les Lames');
          expect(detail.storyTitle, isNull);
        });
      }

      test(
        'une autre erreur sur groups n\'est pas masquée par le repli',
        () async {
          final requests = <http.Request>[];
          final client = await _buildSignedInFakeClient(
            ownerId: ownerId,
            onRequest: requests.add,
            failingTables: {'groups'},
            failingBody: const {
              'code': '42501',
              'message': 'permission denied',
            },
            failingStatus: 403,
          );

          await expectLater(
            SupabaseGroupRepository(client).fetchGroupDetail(groupId),
            throwsA(isA<GroupFailure>()),
          );
          expect(requests.where(isGroupsRequest), hasLength(1));
        },
      );
    });
  });

  group('SupabaseGroupRepository.setGroupCharacter', () {
    const groupId = 'group-1';
    const characterId = 'char-1';

    test('envoie {group_id, character_id} à set-group-character', () async {
      http.Request? capturedRequest;
      final client = _buildFakeClient(
        onRequest: (request) => capturedRequest = request,
        responses: {
          'set-group-character': {'group_id': groupId},
        },
      );
      final repository = SupabaseGroupRepository(client);

      await repository.setGroupCharacter(
        groupId: groupId,
        characterId: characterId,
      );

      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.url.path,
        endsWith('/functions/v1/set-group-character'),
      );
      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body, {'group_id': groupId, 'character_id': characterId});
    });

    test(
      '400 invalid_body -> GroupCharacterReassignmentFailureKind.generic',
      () async {
        final client = _buildFakeClient(
          statusCode: 400,
          responses: {
            'set-group-character': {
              'error': 'invalid_body',
              'message': 'Requête invalide.',
            },
          },
        );
        final repository = SupabaseGroupRepository(client);

        await expectLater(
          repository.setGroupCharacter(
            groupId: groupId,
            characterId: characterId,
          ),
          throwsA(
            isA<GroupCharacterReassignmentFailure>().having(
              (f) => f.kind,
              'kind',
              GroupCharacterReassignmentFailureKind.generic,
            ),
          ),
        );
      },
    );

    test('403 character_not_owned -> '
        'GroupCharacterReassignmentFailureKind.characterNotOwned', () async {
      final client = _buildFakeClient(
        statusCode: 403,
        responses: {
          'set-group-character': {
            'error': 'character_not_owned',
            'message': "Ce personnage ne t'appartient pas.",
          },
        },
      );
      final repository = SupabaseGroupRepository(client);

      await expectLater(
        repository.setGroupCharacter(
          groupId: groupId,
          characterId: characterId,
        ),
        throwsA(
          isA<GroupCharacterReassignmentFailure>().having(
            (f) => f.kind,
            'kind',
            GroupCharacterReassignmentFailureKind.characterNotOwned,
          ),
        ),
      );
    });

    test(
      '404 not_member -> GroupCharacterReassignmentFailureKind.notMember',
      () async {
        final client = _buildFakeClient(
          statusCode: 404,
          responses: {
            'set-group-character': {
              'error': 'not_member',
              'message': "Tu n'es plus membre de ce groupe.",
            },
          },
        );
        final repository = SupabaseGroupRepository(client);

        await expectLater(
          repository.setGroupCharacter(
            groupId: groupId,
            characterId: characterId,
          ),
          throwsA(
            isA<GroupCharacterReassignmentFailure>().having(
              (f) => f.kind,
              'kind',
              GroupCharacterReassignmentFailureKind.notMember,
            ),
          ),
        );
      },
    );

    test(
      '409 not_eligible -> GroupCharacterReassignmentFailureKind.notEligible',
      () async {
        final client = _buildFakeClient(
          statusCode: 409,
          responses: {
            'set-group-character': {
              'error': 'not_eligible',
              'message': 'Cette action ne te concerne plus.',
            },
          },
        );
        final repository = SupabaseGroupRepository(client);

        await expectLater(
          repository.setGroupCharacter(
            groupId: groupId,
            characterId: characterId,
          ),
          throwsA(
            isA<GroupCharacterReassignmentFailure>().having(
              (f) => f.kind,
              'kind',
              GroupCharacterReassignmentFailureKind.notEligible,
            ),
          ),
        );
      },
    );

    test('409 already_in_group -> '
        'GroupCharacterReassignmentFailureKind.alreadyInGroup', () async {
      final client = _buildFakeClient(
        statusCode: 409,
        responses: {
          'set-group-character': {
            'error': 'already_in_group',
            'message': 'Ce personnage est déjà membre de ce groupe.',
          },
        },
      );
      final repository = SupabaseGroupRepository(client);

      await expectLater(
        repository.setGroupCharacter(
          groupId: groupId,
          characterId: characterId,
        ),
        throwsA(
          isA<GroupCharacterReassignmentFailure>().having(
            (f) => f.kind,
            'kind',
            GroupCharacterReassignmentFailureKind.alreadyInGroup,
          ),
        ),
      );
    });

    test('exception réseau (pas de réponse reçue) -> generic', () async {
      final client = _buildFakeClient(throwOnRequest: true);
      final repository = SupabaseGroupRepository(client);

      await expectLater(
        repository.setGroupCharacter(
          groupId: groupId,
          characterId: characterId,
        ),
        throwsA(
          isA<GroupCharacterReassignmentFailure>().having(
            (f) => f.kind,
            'kind',
            GroupCharacterReassignmentFailureKind.generic,
          ),
        ),
      );
    });
  });

  group('SupabaseGroupRepository.claimTreasureCurrency', () {
    const groupId = 'group-1';
    const characterId = 'char-1';
    const ownerId = 'owner-1';

    test(
      'appelle la RPC avec p_character_id et retourne true (le crédit '
      'personnel est fait côté serveur, dans le même appel atomique)',
      () async {
        final requests = <http.Request>[];
        final client = await _buildSignedInFakeClient(
          ownerId: ownerId,
          onRequest: requests.add,
          rpcResults: {'claim_group_treasure_currency': true},
        );
        final repository = SupabaseGroupRepository(client);

        final claimed = await repository.claimTreasureCurrency(
          groupId: groupId,
          characterId: characterId,
          currency: CurrencyKind.gold,
          amount: 10,
        );

        expect(claimed, isTrue);
        final rpcRequest = requests.firstWhere(
          (request) =>
              request.url.path.endsWith('/rpc/claim_group_treasure_currency'),
        );
        final rpcBody = jsonDecode(rpcRequest.body) as Map<String, dynamic>;
        expect(rpcBody, {
          'p_group_id': groupId,
          'p_character_id': characterId,
          'p_currency': 'gp',
          'p_amount': 10,
        });

        // Plus aucun second appel séparé vers `characters` : la RPC crédite
        // désormais l'inventaire personnel elle-même, dans le même appel
        // atomique que la décrémentation du butin.
        expect(
          requests.any((request) => request.url.path.endsWith('/characters')),
          isFalse,
        );
      },
    );

    test('rpc false (solde insuffisant/pas membre) -> retourne false sans '
        'créditer', () async {
      final requests = <http.Request>[];
      final client = await _buildSignedInFakeClient(
        ownerId: ownerId,
        onRequest: requests.add,
        rpcResults: {'claim_group_treasure_currency': false},
      );
      final repository = SupabaseGroupRepository(client);

      final claimed = await repository.claimTreasureCurrency(
        groupId: groupId,
        characterId: characterId,
        currency: CurrencyKind.gold,
        amount: 10,
      );

      expect(claimed, isFalse);
      expect(
        requests.any(
          (request) =>
              request.url.path.endsWith('/characters') &&
              request.method == 'PATCH',
        ),
        isFalse,
        reason: 'aucune écriture personnelle si la réclamation RPC échoue',
      );
    });
  });

  group('SupabaseGroupRepository.claimTreasureItem', () {
    const groupId = 'group-1';
    const characterId = 'char-1';

    http.Request patchOf(List<http.Request> requests) => requests.firstWhere(
      (request) =>
          request.url.path.endsWith('/group_treasure') &&
          request.method == 'PATCH',
    );

    http.Request insertOf(List<http.Request> requests) => requests.firstWhere(
      (request) =>
          request.url.path.endsWith('/character_inventory') &&
          request.method == 'POST',
    );

    test('entrée ancienne, quantité partielle : décrémente items (entry_id '
        'attribué au passage), insère dans l\'inventaire personnel', () async {
      final requests = <http.Request>[];
      final client = _buildFakeClient(
        onRequest: requests.add,
        responses: {
          'group_treasure': [
            {
              'items': [
                {'item_id': 7, 'display_name': 'Potion', 'quantity': 5},
              ],
            },
          ],
        },
      );
      final repository = SupabaseGroupRepository(client);

      await repository.claimTreasureItem(
        groupId: groupId,
        characterId: characterId,
        item: const GroupTreasureItem(
          itemId: 7,
          displayName: 'Potion',
          quantity: 5,
        ),
        quantity: 2,
      );

      final updateBody =
          jsonDecode(patchOf(requests).body) as Map<String, dynamic>;
      final written = (updateBody['items'] as List).single as Map;
      expect(written['item_id'], 7);
      expect(written['quantity'], 3);
      expect(written['entry_id'], isA<String>());

      final insertBody =
          jsonDecode(insertOf(requests).body) as Map<String, dynamic>;
      expect(insertBody['character_id'], characterId);
      expect(insertBody['item_id'], 7);
      expect(insertBody['quantity'], 2);
      expect(insertBody['id'], isA<String>());
      expect(
        insertBody.keys.where((key) => key.startsWith('custom_')),
        isEmpty,
      );
    });

    test('objet personnalisé enrichi : recopie complète dans '
        'character_inventory, entrée retirée à 0', () async {
      final requests = <http.Request>[];
      final sword = GroupTreasureItem.custom(
        entryId: 'e-sword',
        name: 'Épée runique',
        quantity: 1,
        description: 'Gravée de runes.',
        damageDice: '1d8',
        damageType: 'tranchant',
        enrichment: const CustomItemEnrichment(
          kind: CustomItemKinds.weapon,
          magicBonus: 1,
          requiresAttunement: true,
        ),
      );
      final client = _buildFakeClient(
        onRequest: requests.add,
        responses: {
          'group_treasure': [
            {
              'items': [sword.toJson()],
            },
          ],
        },
      );
      final repository = SupabaseGroupRepository(client);

      await repository.claimTreasureItem(
        groupId: groupId,
        characterId: characterId,
        item: sword,
        quantity: 1,
      );

      final insertBody =
          jsonDecode(insertOf(requests).body) as Map<String, dynamic>;
      expect(insertBody, containsPair('custom_name', 'Épée runique'));
      expect(
        insertBody,
        containsPair('custom_description', 'Gravée de runes.'),
      );
      expect(insertBody, containsPair('custom_damage_dice', '1d8'));
      expect(insertBody, containsPair('custom_damage_type', 'tranchant'));
      expect(insertBody, containsPair('custom_kind', 'arme'));
      expect(insertBody, containsPair('custom_magic_bonus', 1));
      expect(insertBody, containsPair('custom_requires_attunement', true));
      final updateBody =
          jsonDecode(patchOf(requests).body) as Map<String, dynamic>;
      expect(updateBody['items'], isEmpty);
    });

    test('entrée déjà attribuée ou modifiée entre-temps : n\'écrit rien et '
        'lève treasureStale', () async {
      for (final remote in [
        <Map<String, dynamic>>[],
        [
          {'item_id': 7, 'display_name': 'Potion', 'quantity': 1},
        ],
      ]) {
        final requests = <http.Request>[];
        final client = _buildFakeClient(
          onRequest: requests.add,
          responses: {
            'group_treasure': [
              {'items': remote},
            ],
          },
        );
        final repository = SupabaseGroupRepository(client);

        await expectLater(
          repository.claimTreasureItem(
            groupId: groupId,
            characterId: characterId,
            item: const GroupTreasureItem(
              itemId: 7,
              displayName: 'Potion',
              quantity: 2,
            ),
            quantity: 1,
          ),
          throwsA(
            isA<GroupFailure>().having(
              (f) => f.code,
              'code',
              GroupErrorCode.treasureStale,
            ),
          ),
        );
        expect(
          requests.any(
            (request) => request.method == 'PATCH' || request.method == 'POST',
          ),
          isFalse,
        );
      }
    });
  });

  group('SupabaseGroupRepository : écriture des objets du butin', () {
    const groupId = 'group-1';
    final rope = GroupTreasureItem.custom(
      entryId: 'rope',
      name: 'Corde',
      quantity: 2,
    );

    List<dynamic> writtenItems(List<http.Request> requests) {
      final patch = requests.singleWhere(
        (request) =>
            request.url.path.endsWith('/group_treasure') &&
            request.method == 'PATCH',
      );
      return (jsonDecode(patch.body) as Map<String, dynamic>)['items']
          as List<dynamic>;
    }

    SupabaseClient clientWith(
      List<Map<String, dynamic>> remote,
      List<http.Request> requests,
    ) => _buildFakeClient(
      onRequest: requests.add,
      responses: {
        'group_treasure': [
          {'items': remote},
        ],
      },
    );

    test('addTreasureItems relit items puis ajoute (entrée ancienne '
        'identifiée au passage)', () async {
      final requests = <http.Request>[];
      final repository = SupabaseGroupRepository(
        clientWith([
          {'custom_name': 'Vieux', 'display_name': 'Vieux', 'quantity': 1},
        ], requests),
      );

      await repository.addTreasureItems(
        groupId: groupId,
        items: const [
          GroupTreasureItem.catalog(
            itemId: 9,
            displayName: 'Dague',
            quantity: 1,
            category: 'arme',
          ),
        ],
      );

      expect(requests.first.method, 'GET');
      final items = writtenItems(requests);
      expect(items, hasLength(2));
      expect((items.first as Map)['entry_id'], isA<String>());
      expect((items.last as Map)['item_id'], 9);
      expect((items.last as Map)['category'], 'arme');
    });

    test('updateTreasureItem remplace l\'entrée inchangée', () async {
      final requests = <http.Request>[];
      final repository = SupabaseGroupRepository(
        clientWith([rope.toJson()], requests),
      );

      await repository.updateTreasureItem(
        groupId: groupId,
        expected: rope,
        updated: GroupTreasureItem.custom(
          name: 'Corde elfique',
          quantity: 3,
          description: 'Solide.',
        ),
      );

      final written = writtenItems(requests).single as Map;
      expect(written['entry_id'], 'rope');
      expect(written['custom_name'], 'Corde elfique');
      expect(written['quantity'], 3);
      expect(written['custom_description'], 'Solide.');
    });

    test('removeTreasureItem retire l\'entrée inchangée', () async {
      final requests = <http.Request>[];
      final repository = SupabaseGroupRepository(
        clientWith([rope.toJson()], requests),
      );

      await repository.removeTreasureItem(groupId: groupId, expected: rope);

      expect(writtenItems(requests), isEmpty);
    });

    // Entrée ancienne (avant la décision 91) : ni entry_id ni catégorie.
    const legacyPotion = GroupTreasureItem(
      itemId: 7,
      displayName: 'Potion',
      quantity: 3,
    );
    // Entrée voisine enrichie : tous les champs doivent survivre à une
    // écriture qui ne la concerne pas.
    final enrichedSword = GroupTreasureItem.custom(
      entryId: 'e-sword',
      name: 'Épée runique',
      quantity: 1,
      description: 'Gravée de runes.',
      damageDice: '1d8',
      damageType: 'tranchant',
      properties: const ['polyvalente(1d10)'],
      enrichment: const CustomItemEnrichment(
        kind: CustomItemKinds.weapon,
        magicBonus: 2,
        weight: 1.5,
        requiresAttunement: true,
        weaponCategory: CustomWeaponCategories.martial,
        weaponRange: CustomWeaponRanges.melee,
      ),
      extra: const {
        'future_key': {'a': 1},
      },
    );
    const legacyRope = {
      'custom_name': 'Corde',
      'display_name': 'Corde',
      'quantity': 1,
    };

    void expectEveryEntryHasId(List<dynamic> items) {
      for (final entry in items) {
        expect(
          (entry as Map)['entry_id'],
          isA<String>().having((id) => id.isNotEmpty, 'non vide', isTrue),
          reason: '$entry',
        );
      }
    }

    test('modification d\'une entrée ancienne (sans entry_id) : retrouvée, '
        'réécrite avec un entry_id comme toutes les autres', () async {
      final requests = <http.Request>[];
      final repository = SupabaseGroupRepository(
        clientWith([legacyPotion.toJson(), legacyRope], requests),
      );

      await repository.updateTreasureItem(
        groupId: groupId,
        expected: legacyPotion,
        updated: legacyPotion.copyWith(quantity: 5),
      );

      final items = writtenItems(requests);
      expect(items, hasLength(2));
      expect((items.first as Map)['item_id'], 7);
      expect((items.first as Map)['quantity'], 5);
      expectEveryEntryHasId(items);
    });

    test('retrait d\'une entrée ancienne (sans entry_id) : retirée, les '
        'autres entrées anciennes reçoivent un entry_id', () async {
      final requests = <http.Request>[];
      final repository = SupabaseGroupRepository(
        clientWith([legacyPotion.toJson(), legacyRope], requests),
      );

      await repository.removeTreasureItem(
        groupId: groupId,
        expected: legacyPotion,
      );

      final items = writtenItems(requests);
      expect(items, hasLength(1));
      expect((items.single as Map)['custom_name'], 'Corde');
      expectEveryEntryHasId(items);
    });

    test('entrée voisine enrichie : tous ses champs (et ses clés inconnues) '
        'conservés à l\'identique par chaque écriture du tableau', () async {
      final writes =
          <String, Future<void> Function(SupabaseGroupRepository repository)>{
            'ajout': (repository) => repository.addTreasureItems(
              groupId: groupId,
              items: const [
                GroupTreasureItem.catalog(
                  itemId: 9,
                  displayName: 'Dague',
                  quantity: 1,
                ),
              ],
            ),
            'modification': (repository) => repository.updateTreasureItem(
              groupId: groupId,
              expected: legacyPotion,
              updated: legacyPotion.copyWith(quantity: 1),
            ),
            'retrait': (repository) => repository.removeTreasureItem(
              groupId: groupId,
              expected: legacyPotion,
            ),
            'attribution': (repository) => repository.claimTreasureItem(
              groupId: groupId,
              characterId: 'char-1',
              item: legacyPotion,
              quantity: 1,
            ),
          };
      for (final write in writes.entries) {
        final requests = <http.Request>[];
        final repository = SupabaseGroupRepository(
          clientWith([
            legacyPotion.toJson(),
            enrichedSword.toJson(),
            legacyRope,
          ], requests),
        );

        await write.value(repository);

        final items = writtenItems(requests);
        final sword = items.firstWhere(
          (entry) => (entry as Map)['entry_id'] == 'e-sword',
        );
        expect(sword, enrichedSword.toJson(), reason: write.key);
        // Garde-fou DeepCore à venir : jamais d'entrée sans entry_id.
        expectEveryEntryHasId(items);
      }
    });

    test('une entrée d\'un type inattendu ne fait pas échouer le chargement '
        'du butin, et sa valeur brute est réécrite telle quelle', () async {
      const odd = {
        'entry_id': 'odd',
        'custom_name': 'Truc',
        'display_name': 7,
        'quantity': '2',
        'custom_kind': 'dragon',
      };
      final requests = <http.Request>[];
      final repository = SupabaseGroupRepository(
        _buildFakeClient(
          onRequest: requests.add,
          responses: {
            'group_treasure': [
              {
                'group_id': groupId,
                'items': [odd, rope.toJson()],
              },
            ],
          },
        ),
      );

      final treasure = await repository.fetchGroupTreasure(groupId);
      expect(treasure.items, hasLength(2));
      expect(treasure.items.first.displayName, '');

      await repository.removeTreasureItem(groupId: groupId, expected: rope);
      expect(writtenItems(requests), [odd]);
    });

    test('aucune ligne modifiée (membre retiré du groupe entre la lecture et '
        'l\'écriture) : erreur, jamais un faux succès', () async {
      final client = await _buildSignedInFakeClient(
        ownerId: 'owner-1',
        tableRows: {
          'group_treasure': [
            {
              'items': [rope.toJson()],
            },
          ],
        },
        respond: (request) => request.method == 'PATCH'
            ? http.Response(
                '[]',
                200,
                request: request,
                headers: {'content-type': 'application/json'},
              )
            : null,
      );
      final repository = SupabaseGroupRepository(client);

      await expectLater(
        repository.removeTreasureItem(groupId: groupId, expected: rope),
        throwsA(
          isA<GroupFailure>().having(
            (f) => f.code,
            'code',
            GroupErrorCode.notMember,
          ),
        ),
      );
    });

    test('modifier ou retirer une entrée changée entre-temps : rien n\'est '
        'écrit, treasureStale', () async {
      final requests = <http.Request>[];
      final repository = SupabaseGroupRepository(
        clientWith([rope.copyWith(quantity: 1).toJson()], requests),
      );
      final stale = throwsA(
        isA<GroupFailure>().having(
          (f) => f.code,
          'code',
          GroupErrorCode.treasureStale,
        ),
      );

      await expectLater(
        repository.removeTreasureItem(groupId: groupId, expected: rope),
        stale,
      );
      await expectLater(
        repository.updateTreasureItem(
          groupId: groupId,
          expected: rope,
          updated: rope.copyWith(quantity: 9),
        ),
        stale,
      );
      expect(requests.any((request) => request.method == 'PATCH'), isFalse);
    });
  });

  group('SupabaseGroupRepository.setTreasureCurrency', () {
    test('mise à jour conditionnelle : soldes absolus, filtre sur les soldes '
        'vus, une ligne renvoyée = succès', () async {
      final requests = <http.Request>[];
      final client = _buildFakeClient(
        onRequest: requests.add,
        responses: {
          'group_treasure': [
            {'group_id': 'group-1'},
          ],
        },
      );
      final repository = SupabaseGroupRepository(client);

      await repository.setTreasureCurrency(
        groupId: 'group-1',
        expected: {CurrencyKind.gold: 12},
        newTotals: {CurrencyKind.gold: 17},
      );

      final patch = requests.single;
      expect(patch.method, 'PATCH');
      expect(jsonDecode(patch.body), {'currency_gp': 17});
      expect(patch.url.queryParameters['group_id'], 'eq.group-1');
      expect(patch.url.queryParameters['currency_gp'], 'eq.12');
    });

    test(
      'aucune ligne renvoyée (solde changé entre-temps) : treasureStale',
      () {
        final client = _buildFakeClient(
          responses: {'group_treasure': <Map<String, dynamic>>[]},
        );
        final repository = SupabaseGroupRepository(client);

        expect(
          repository.setTreasureCurrency(
            groupId: 'group-1',
            expected: {CurrencyKind.gold: 12, CurrencyKind.silver: 0},
            newTotals: {CurrencyKind.gold: 11, CurrencyKind.silver: 10},
          ),
          throwsA(
            isA<GroupFailure>().having(
              (f) => f.code,
              'code',
              GroupErrorCode.treasureStale,
            ),
          ),
        );
      },
    );
  });

  group('SupabaseGroupRepository.fetchTreasureItemDetails', () {
    test(
      'objet du catalogue : ligne items par id et description traduite',
      () async {
        final requests = <http.Request>[];
        final client = _buildFakeClient(
          onRequest: requests.add,
          responses: {
            'items': [
              {
                'id': 9,
                'category': 'arme',
                'weight': 0.5,
                'cost': {'amount': 2, 'currency': 'gp'},
                'weapon_properties': {
                  'damage_dice': '1d4',
                  'damage_type': 'perforant',
                  'properties': ['finesse'],
                },
              },
            ],
            'translations': [
              {'entity_id': '9', 'value': 'Une lame courte.'},
            ],
          },
        );
        final repository = SupabaseGroupRepository(client);

        final item = await repository.fetchTreasureItemDetails(
          const GroupTreasureItem(itemId: 9, displayName: 'Dague', quantity: 2),
        );

        expect(item.name, 'Dague');
        expect(item.quantity, 2);
        expect(item.description, 'Une lame courte.');
        expect(item.weaponProperties?.damageDice, '1d4');
        final itemsRequest = requests.firstWhere(
          (request) => request.url.path.endsWith('/items'),
        );
        expect(itemsRequest.url.queryParameters['id'], 'eq.9');
        final translationsRequest = requests.firstWhere(
          (request) => request.url.path.endsWith('/translations'),
        );
        expect(
          translationsRequest.url.queryParameters['field_name'],
          'eq.description',
        );
      },
    );

    test('objet personnalisé : aucun appel réseau', () async {
      final requests = <http.Request>[];
      final repository = SupabaseGroupRepository(
        _buildFakeClient(onRequest: requests.add),
      );

      final item = await repository.fetchTreasureItemDetails(
        GroupTreasureItem.custom(
          name: 'Fiole',
          quantity: 1,
          description: 'Bleue.',
        ),
      );

      expect(item.description, 'Bleue.');
      expect(requests, isEmpty);
    });
  });

  group('SupabaseGroupRepository.fetchGroupNoteEntries', () {
    test(
      'mappe id/title/body/created_at, trie par created_at desc côté requête',
      () async {
        final requests = <http.Request>[];
        final client = await _buildSignedInFakeClient(
          ownerId: 'user-1',
          tableRows: {
            'group_journal_entries': [
              {
                'id': 'entry-2',
                'title': 'Chapitre 2',
                'body': 'Combat contre les gobelins.',
                'created_at': '2026-11-08T20:00:00Z',
              },
              {
                'id': 'entry-1',
                'title': null,
                'body': 'Première séance, sans titre.',
                'created_at': '2026-11-01T20:00:00Z',
              },
            ],
          },
          onRequest: requests.add,
        );
        final repository = SupabaseGroupRepository(client);

        final entries = await repository.fetchGroupNoteEntries('group-1');

        expect(entries, hasLength(2));
        expect(entries[0].id, 'entry-2');
        expect(entries[0].title, 'Chapitre 2');
        expect(entries[0].body, 'Combat contre les gobelins.');
        expect(entries[1].id, 'entry-1');
        expect(entries[1].title, isNull);

        final selectRequest = requests.firstWhere(
          (request) => request.url.path.endsWith('/group_journal_entries'),
        );
        expect(selectRequest.url.queryParameters['group_id'], 'eq.group-1');
        expect(
          selectRequest.url.queryParameters['order'],
          'created_at.desc.nullslast',
        );
      },
    );

    test(
      "aucune ligne encore enregistrée -> liste vide plutôt qu'une erreur",
      () async {
        final client = await _buildSignedInFakeClient(
          ownerId: 'user-1',
          tableRows: const {'group_journal_entries': []},
        );
        final repository = SupabaseGroupRepository(client);

        final entries = await repository.fetchGroupNoteEntries('group-1');

        expect(entries, isEmpty);
      },
    );
  });

  group('SupabaseGroupRepository.addGroupNoteEntry', () {
    test(
      'insère {group_id, user_id, title, body} sur group_journal_entries',
      () async {
        final requests = <http.Request>[];
        final client = await _buildSignedInFakeClient(
          ownerId: 'user-1',
          onRequest: requests.add,
        );
        final repository = SupabaseGroupRepository(client);

        await repository.addGroupNoteEntry(
          groupId: 'group-1',
          title: 'Chapitre 1',
          body: 'Un indice dans la crypte.',
        );

        final insertRequest = requests.firstWhere(
          (request) =>
              request.url.path.endsWith('/group_journal_entries') &&
              request.method == 'POST',
        );
        final body = jsonDecode(insertRequest.body) as Map<String, dynamic>;
        expect(body['group_id'], 'group-1');
        expect(body['user_id'], 'user-1');
        expect(body['title'], 'Chapitre 1');
        expect(body['body'], 'Un indice dans la crypte.');
      },
    );

    test('title null/vide -> insère sans la clé title', () async {
      final requests = <http.Request>[];
      final client = await _buildSignedInFakeClient(
        ownerId: 'user-1',
        onRequest: requests.add,
      );
      final repository = SupabaseGroupRepository(client);

      await repository.addGroupNoteEntry(
        groupId: 'group-1',
        body: 'Sans titre.',
      );

      final insertRequest = requests.firstWhere(
        (request) =>
            request.url.path.endsWith('/group_journal_entries') &&
            request.method == 'POST',
      );
      final body = jsonDecode(insertRequest.body) as Map<String, dynamic>;
      expect(body.containsKey('title'), isFalse);
      expect(body['body'], 'Sans titre.');
    });
  });

  group('SupabaseGroupRepository.updateGroupNoteEntry', () {
    test('update {title, body} filtré sur id', () async {
      final requests = <http.Request>[];
      final client = await _buildSignedInFakeClient(
        ownerId: 'user-1',
        onRequest: requests.add,
      );
      final repository = SupabaseGroupRepository(client);

      await repository.updateGroupNoteEntry(
        entryId: 'entry-1',
        title: 'Titre modifié',
        body: 'Corps modifié.',
      );

      final updateRequest = requests.firstWhere(
        (request) =>
            request.url.path.endsWith('/group_journal_entries') &&
            request.method == 'PATCH',
      );
      final body = jsonDecode(updateRequest.body) as Map<String, dynamic>;
      expect(body['title'], 'Titre modifié');
      expect(body['body'], 'Corps modifié.');
      expect(updateRequest.url.queryParameters['id'], 'eq.entry-1');
    });

    test('title null -> efface le titre existant (null explicite)', () async {
      final requests = <http.Request>[];
      final client = await _buildSignedInFakeClient(
        ownerId: 'user-1',
        onRequest: requests.add,
      );
      final repository = SupabaseGroupRepository(client);

      await repository.updateGroupNoteEntry(
        entryId: 'entry-1',
        body: 'Corps modifié.',
      );

      final updateRequest = requests.firstWhere(
        (request) =>
            request.url.path.endsWith('/group_journal_entries') &&
            request.method == 'PATCH',
      );
      final body = jsonDecode(updateRequest.body) as Map<String, dynamic>;
      expect(body['title'], isNull);
      expect(body.containsKey('title'), isTrue);
    });
  });

  group('SupabaseGroupRepository.deleteGroupNoteEntry', () {
    test('delete filtré sur id', () async {
      final requests = <http.Request>[];
      final client = await _buildSignedInFakeClient(
        ownerId: 'user-1',
        onRequest: requests.add,
      );
      final repository = SupabaseGroupRepository(client);

      await repository.deleteGroupNoteEntry('entry-1');

      final deleteRequest = requests.firstWhere(
        (request) =>
            request.url.path.endsWith('/group_journal_entries') &&
            request.method == 'DELETE',
      );
      expect(deleteRequest.url.queryParameters['id'], 'eq.entry-1');
    });
  });

  group('SupabaseGroupRepository.fetchGroupIdsForCharacter', () {
    test('une seule requête group_members filtrée sur user_id et '
        'character_id, lecture seule', () async {
      final requests = <http.Request>[];
      final client = await _buildSignedInFakeClient(
        ownerId: 'user-1',
        onRequest: requests.add,
        tableRows: {
          'group_members': [
            {'group_id': 'g1'},
            {'group_id': 'g2'},
          ],
        },
      );
      final repository = SupabaseGroupRepository(client);

      final ids = await repository.fetchGroupIdsForCharacter('char-1');

      expect(ids, ['g1', 'g2']);
      expect(requests, hasLength(1));
      final request = requests.single;
      expect(request.method, 'GET');
      expect(request.url.path, endsWith('/group_members'));
      expect(request.url.queryParameters['select'], 'group_id');
      expect(request.url.queryParameters['user_id'], 'eq.user-1');
      expect(request.url.queryParameters['character_id'], 'eq.char-1');
    });

    test('aucun groupe : liste vide', () async {
      final client = await _buildSignedInFakeClient(
        ownerId: 'user-1',
        tableRows: const {'group_members': []},
      );
      final repository = SupabaseGroupRepository(client);
      expect(await repository.fetchGroupIdsForCharacter('char-1'), isEmpty);
    });

    test('erreur serveur : GroupFailure', () async {
      final client = await _buildSignedInFakeClient(
        ownerId: 'user-1',
        failingTables: const {'group_members'},
      );
      final repository = SupabaseGroupRepository(client);
      await expectLater(
        repository.fetchGroupIdsForCharacter('char-1'),
        throwsA(isA<GroupFailure>()),
      );
    });
  });

  // RPC `become_group_game_master` (migration DeepCore `20261119090000`,
  // PR #49) : contrat d'appel et correspondance de chaque erreur.
  group('SupabaseGroupRepository.becomeGroupGameMaster', () {
    test('POST /rpc/become_group_game_master avec {p_group_id}, aucune autre '
        'requête', () async {
      final requests = <http.Request>[];
      final client = _buildFakeClient(
        onRequest: requests.add,
        responses: {
          // Ligne `group_members` du propriétaire, désormais MJ.
          'become_group_game_master': {
            'id': 'membership-1',
            'group_id': 'group-1',
            'user_id': 'user-1',
            'character_id': null,
            'is_game_master': true,
            'role': 'owner',
          },
        },
      );
      final repository = SupabaseGroupRepository(client);

      await repository.becomeGroupGameMaster('group-1');

      expect(requests, hasLength(1));
      final request = requests.single;
      expect(request.method, 'POST');
      expect(
        request.url.path,
        endsWith('/rest/v1/rpc/become_group_game_master'),
      );
      expect(jsonDecode(request.body), {'p_group_id': 'group-1'});
    });

    // (statut HTTP, corps d'erreur PostgREST, code attendu)
    const cases = <(int, Map<String, dynamic>, GroupErrorCode)>[
      (
        400,
        {'code': 'P0001', 'message': 'combat_active'},
        GroupErrorCode.combatActive,
      ),
      (
        400,
        {'code': 'P0001', 'message': 'mj_already_assigned'},
        GroupErrorCode.mjAlreadyAssigned,
      ),
      (
        403,
        {'code': '42501', 'message': 'not_group_owner'},
        GroupErrorCode.notGroupOwner,
      ),
      // `not_member` / `group_not_found` (P0002) arrivent en HTTP 500.
      (
        500,
        {'code': 'P0002', 'message': 'not_member'},
        GroupErrorCode.notMember,
      ),
      (
        500,
        {'code': 'P0002', 'message': 'group_not_found'},
        GroupErrorCode.groupNotFound,
      ),
      (
        401,
        {'code': '28000', 'message': 'not_authenticated'},
        GroupErrorCode.sessionExpired,
      ),
      (
        500,
        {'code': '40P01', 'message': 'deadlock detected'},
        GroupErrorCode.transientConflict,
      ),
      (
        500,
        {
          'code': '40001',
          'message': 'could not serialize access due to concurrent update',
        },
        GroupErrorCode.transientConflict,
      ),
      // Migration pas encore appliquée : PostgREST ne trouve pas la fonction.
      (
        404,
        {
          'code': 'PGRST202',
          'message':
              'Could not find the function '
              'public.become_group_game_master(p_group_id) in the schema '
              'cache',
          'hint': null,
          'details': null,
        },
        GroupErrorCode.serverOutdated,
      ),
    ];
    for (final (status, body, expected) in cases) {
      test('HTTP $status « ${body['message']} » (${body['code']}) -> '
          '$expected', () async {
        final client = _buildFakeClient(
          statusCode: status,
          responses: {'become_group_game_master': body},
        );
        final repository = SupabaseGroupRepository(client);

        await expectLater(
          repository.becomeGroupGameMaster('group-1'),
          throwsA(isA<GroupFailure>().having((f) => f.code, 'code', expected)),
        );
      });
    }

    test('pas de réseau -> GroupErrorCode.network', () async {
      final client = _buildFakeClient(throwOnRequest: true);
      final repository = SupabaseGroupRepository(client);

      await expectLater(
        repository.becomeGroupGameMaster('group-1'),
        throwsA(
          isA<GroupFailure>().having(
            (f) => f.code,
            'code',
            GroupErrorCode.network,
          ),
        ),
      );
    });
  });

  // Abonnement Realtime (canal enregistreur, aucune connexion) : `INSERT` et
  // `UPDATE` de `group_members` filtrés sur le groupe, `DELETE` sans filtre.
  // L'`UPDATE` porte « Devenir MJ » (ligne du propriétaire modifiée) : sans
  // lui, les écrans Groupe des coéquipiers restaient périmés.
  group('SupabaseGroupRepository.subscribeToMemberUpdates', () {
    test('UPDATE de group_members filtré sur le groupe : relecture', () {
      final channel = _RecordingChannel();
      final repository = SupabaseGroupRepository(_RecordingClient(channel));
      var changes = 0;

      repository.subscribeToMemberUpdates(
        groupId: 'group-1',
        characterIds: const ['char-1', 'char-2'],
        isKnownMembershipId: (_) => false,
        onChanged: () => changes++,
      );

      expect(channel.subscribed, isTrue);
      final members = channel.bindings
          .where((binding) => binding.table == 'group_members')
          .toList();
      expect(
        members.map((binding) => binding.event),
        containsAll([
          PostgresChangeEvent.insert,
          PostgresChangeEvent.update,
          PostgresChangeEvent.delete,
        ]),
      );
      for (final event in [
        PostgresChangeEvent.insert,
        PostgresChangeEvent.update,
      ]) {
        final binding = members.singleWhere((b) => b.event == event);
        expect(binding.schema, 'public', reason: '$event');
        expect(
          binding.filter?.type,
          PostgresChangeFilterType.eq,
          reason: '$event',
        );
        expect(binding.filter?.column, 'group_id', reason: '$event');
        expect(binding.filter?.value, 'group-1', reason: '$event');
      }

      // « Devenir MJ » du propriétaire, vu par un coéquipier.
      members
          .singleWhere((b) => b.event == PostgresChangeEvent.update)
          .callback(
            _payload(
              PostgresChangeEvent.update,
              newRecord: {
                'id': 'membership-1',
                'group_id': 'group-1',
                'user_id': 'user-owner',
                'character_id': null,
                'is_game_master': true,
              },
              oldRecord: {'id': 'membership-1'},
            ),
          );
      expect(changes, 1);
    });

    test('DELETE : relecture seulement pour un membre connu du groupe', () {
      final channel = _RecordingChannel();
      final repository = SupabaseGroupRepository(_RecordingClient(channel));
      var changes = 0;

      repository.subscribeToMemberUpdates(
        groupId: 'group-1',
        characterIds: const ['char-1'],
        isKnownMembershipId: (id) => id == 'membership-1',
        onChanged: () => changes++,
      );

      final delete = channel.bindings.singleWhere(
        (b) =>
            b.table == 'group_members' && b.event == PostgresChangeEvent.delete,
      );
      expect(delete.filter, isNull);
      delete.callback(
        _payload(PostgresChangeEvent.delete, oldRecord: {'id': 'autre-groupe'}),
      );
      expect(changes, 0);
      delete.callback(
        _payload(PostgresChangeEvent.delete, oldRecord: {'id': 'membership-1'}),
      );
      expect(changes, 1);
    });
  });

  // Gardes « combat actif » de DeepCore (triggers BEFORE DELETE) : le refus
  // `combat_active` de la dissolution et du départ du propriétaire.
  group('refus combat_active de la dissolution et du départ', () {
    test('dissolveGroup : DELETE groups refusé -> combatActive', () async {
      final client = _buildFakeClient(
        statusCode: 400,
        responses: {
          'groups': {'code': 'P0001', 'message': 'combat_active'},
        },
      );
      final repository = SupabaseGroupRepository(client);

      await expectLater(
        repository.dissolveGroup('group-1'),
        throwsA(
          isA<GroupFailure>().having(
            (f) => f.code,
            'code',
            GroupErrorCode.combatActive,
          ),
        ),
      );
    });

    test('leaveGroup : DELETE group_members refusé -> combatActive', () async {
      final client = await _buildSignedInFakeClient(
        ownerId: 'user-1',
        failingTables: const {'group_members'},
        failingBody: const {'code': 'P0001', 'message': 'combat_active'},
        failingStatus: 400,
      );
      final repository = SupabaseGroupRepository(client);

      await expectLater(
        repository.leaveGroup('group-1'),
        throwsA(
          isA<GroupFailure>().having(
            (f) => f.code,
            'code',
            GroupErrorCode.combatActive,
          ),
        ),
      );
    });
  });
}

/// Liaison `postgres_changes` enregistrée par [_RecordingChannel].
class _RecordedBinding {
  _RecordedBinding({
    required this.event,
    required this.schema,
    required this.table,
    required this.filter,
    required this.callback,
  });

  final PostgresChangeEvent event;
  final String? schema;
  final String? table;
  final PostgresChangeFilter? filter;
  final void Function(PostgresChangePayload payload) callback;
}

/// Canal Realtime enregistreur : garde les liaisons déclarées, ne se connecte
/// jamais (aucun WebSocket en test).
class _RecordingChannel extends Fake implements RealtimeChannel {
  final List<_RecordedBinding> bindings = [];
  bool subscribed = false;

  @override
  RealtimeChannel onPostgresChanges({
    required PostgresChangeEvent event,
    String? schema,
    String? table,
    PostgresChangeFilter? filter,
    List<PostgresChangeFilter>? filters,
    List<String>? select,
    required void Function(PostgresChangePayload payload) callback,
  }) {
    bindings.add(
      _RecordedBinding(
        event: event,
        schema: schema,
        table: table,
        filter: filter,
        callback: callback,
      ),
    );
    return this;
  }

  @override
  RealtimeChannel subscribe([
    void Function(RealtimeSubscribeStatus status, Object? error)? callback,
    Duration? timeout,
  ]) {
    subscribed = true;
    return this;
  }
}

/// `SupabaseClient` réel dont `channel` renvoie [_RecordingChannel].
class _RecordingClient extends SupabaseClient {
  _RecordingClient(this._channel)
    : super(
        'https://fake.supabase.test',
        'fake-anon-key',
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );

  final _RecordingChannel _channel;

  @override
  RealtimeChannel channel(
    String name, {
    RealtimeChannelConfig opts = const RealtimeChannelConfig(),
  }) => _channel;
}

PostgresChangePayload _payload(
  PostgresChangeEvent event, {
  Map<String, dynamic> newRecord = const {},
  Map<String, dynamic> oldRecord = const {},
}) => PostgresChangePayload(
  schema: 'public',
  table: 'group_members',
  commitTimestamp: DateTime.utc(2026, 11, 19),
  eventType: event,
  newRecord: newRecord,
  oldRecord: oldRecord,
  errors: null,
);

/// Fabrique un `SupabaseClient` réel dont le transport HTTP est fabriqué de
/// toutes pièces — [responses] associe un segment de chemin final (nom de
/// table ou d'edge function) à la réponse JSON déjà décodée à renvoyer :
/// une `List`/`Map` telle quelle (une table), directement encodée sans
/// enveloppe supplémentaire — même principe que
/// `character_repository_test.dart::_buildSignedInFakeSupabaseClient`, mais
/// sans authentification (les 3 edge functions et `claimTreasureItem` ne
/// lisent jamais `auth.currentUser`).
SupabaseClient _buildFakeClient({
  Map<String, dynamic> responses = const {},
  int statusCode = 200,
  bool throwOnRequest = false,
  void Function(http.Request request)? onRequest,
}) {
  Future<http.Response> handler(http.Request request) async {
    onRequest?.call(request);
    if (throwOnRequest) {
      throw const SocketException('Pas de réseau (double de test).');
    }
    final key = request.url.pathSegments.last;
    final body = responses[key] ?? const <dynamic>[];
    return http.Response(
      jsonEncode(body),
      statusCode,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }

  return SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient(handler),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
}

/// Variante authentifiée de [_buildFakeClient] — voir
/// `character_repository_test.dart::_buildSignedInFakeSupabaseClient` pour
/// le rationale complet du jeton non-JWT (`recoverSession` reste
/// entièrement en mémoire, jamais un vrai appel réseau). [rpcResults]
/// associe le nom d'une fonction Postgres à sa valeur de retour scalaire
/// brute (`true`/`false` pour `claim_group_treasure_currency`, jamais
/// enveloppée dans une liste, contrairement à une table) — PostgREST
/// renvoie la valeur de retour d'une fonction RPC telle quelle, pas comme
/// une ligne de table.
Future<SupabaseClient> _buildSignedInFakeClient({
  required String ownerId,
  Map<String, List<Map<String, dynamic>>> tableRows = const {},
  Map<String, dynamic> rpcResults = const {},
  // Tables dont la requête doit échouer (ex. `PGRST000`, 500) — simule une
  // vue/table temporairement inaccessible pour le point 1 (résilience de
  // `fetchMyGroups` face à un échec de `group_character_status_overview`).
  Set<String> failingTables = const {},
  // Corps et statut de l'erreur renvoyée pour [failingTables] (par défaut :
  // vue temporairement indisponible, `PGRST000`, 500).
  Map<String, dynamic> failingBody = const {
    'message': 'Vue temporairement indisponible (double de test).',
    'code': 'PGRST000',
  },
  int failingStatus = 500,
  void Function(http.Request request)? onRequest,
  // Réponse imposée pour une requête précise (ex. 42703 au `select` qui cite
  // une colonne absente) ; `null` : réponse habituelle.
  http.Response? Function(http.Request request)? respond,
}) async {
  Future<http.Response> handler(http.Request request) async {
    onRequest?.call(request);
    final imposed = respond?.call(request);
    if (imposed != null) return imposed;
    final key = request.url.pathSegments.last;
    if (failingTables.contains(key)) {
      return http.Response(
        jsonEncode(failingBody),
        failingStatus,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }
    if (rpcResults.containsKey(key)) {
      return http.Response(
        jsonEncode(rpcResults[key]),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }
    final rows = tableRows[key] ?? const <Map<String, dynamic>>[];
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

  await client.auth.recoverSession(
    jsonEncode({
      'access_token': 'fake-access-token-$ownerId',
      'token_type': 'bearer',
      'user': {'id': ownerId},
    }),
  );

  return client;
}
