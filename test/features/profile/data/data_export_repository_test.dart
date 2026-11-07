// Tests de `LocalFileDataExportRepository.exportMyData`
// (`features/profile/data/data_export_repository.dart`) : assemble le JSON
// attendu depuis un `CharacterRepository` factice (`fetchCharacters` +
// `fetchCharacterDetail`), un `GroupRepository` factice (`fetchMyGroups` +
// `fetchGroupNoteEntries`) et un `SupabaseClient` connecté
// (profil `auth.currentUser`, même double de test que
// `auth_repository_test.dart` : un vrai `SupabaseClient`/`GoTrueClient`
// tourne, seule la réponse HTTP `/token` est fabriquée via
// `package:http/testing.dart`), écrit un fichier dans le répertoire
// temporaire (`path_provider`, remplacé ici par un `PathProviderPlatform`
// factice, même principe que les autres plugins mockés de ce dépôt — jamais
// un vrai accès disque piloté par le canal de plateforme réel, indisponible
// dans `flutter test`), et propage telle quelle toute exception des
// repositories sous-jacents.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:personnages/features/groups/domain/group_note_entry.dart';
import 'package:personnages/features/groups/domain/group_summary.dart';
import 'package:personnages/features/profile/data/data_export_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.tempPath);

  final String tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

/// Double minimal — seuls `fetchCharacters`/`fetchCharacterDetail` sont
/// exercés par `DataExportRepository`, le reste lève
/// `UnimplementedError` (jamais atteint par ces tests).
class _FakeCharacterRepository implements CharacterRepository {
  List<CharacterSummary> summaries = const [];
  final Map<String, CharacterDetail> detailsById = {};
  Object? detailErrorToThrow;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => summaries;

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    final error = detailErrorToThrow;
    if (error != null) throw error;
    final detail = detailsById[characterId];
    if (detail == null) {
      throw const CharacterFailure('Personnage introuvable.');
    }
    return detail;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Double minimal — seuls `fetchMyGroups`/`fetchGroupNoteEntries` sont
/// exercés par `DataExportRepository`, le reste lève `UnimplementedError`
/// (jamais atteint par ces tests).
class _FakeGroupRepository implements GroupRepository {
  List<GroupSummary> groups = const [];
  final Map<String, List<GroupNoteEntry>> entriesByGroupId = {};
  Object? fetchMyGroupsErrorToThrow;
  Object? fetchGroupNoteEntriesErrorToThrow;

  @override
  Future<List<GroupSummary>> fetchMyGroups() async {
    final error = fetchMyGroupsErrorToThrow;
    if (error != null) throw error;
    return groups;
  }

  @override
  Future<List<GroupNoteEntry>> fetchGroupNoteEntries(String groupId) async {
    final error = fetchGroupNoteEntriesErrorToThrow;
    if (error != null) throw error;
    return entriesByGroupId[groupId] ?? const [];
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Construit un `SupabaseClient` connecté (`fake-user-id`), avec les
/// métadonnées de compte [userMetadata] — même double de test que
/// `auth_repository_test.dart::_buildFakeSupabaseClient`, dupliqué ici (voir
/// le rationale de duplication de `RaceRowMapper`) pour que ce fichier reste
/// autonome.
Future<SupabaseClient> _buildSignedInClient({
  String email = 'joueur@exemple.com',
  Map<String, dynamic> userMetadata = const {},
}) async {
  final client = SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient((request) async {
      if (request.url.path.endsWith('/token')) {
        return http.Response(
          jsonEncode({
            'access_token': 'fake-access-token',
            'token_type': 'bearer',
            'expires_in': 3600,
            'refresh_token': 'fake-refresh-token',
            'user': {
              'id': 'fake-user-id',
              'aud': 'authenticated',
              'email': email,
              'app_metadata': <String, dynamic>{},
              'user_metadata': userMetadata,
              'created_at': '2026-01-01T00:00:00Z',
            },
          }),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{}', 200, request: request);
    }),
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
  await client.auth.signInWithPassword(email: email, password: 'password1234');
  return client;
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('nexus-jdr-export-test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  /// Construit un [LocalFileDataExportRepository] prêt à l'emploi — un
  /// `GroupRepository`/`SupabaseClient` par défaut (aucun groupe, aucune
  /// métadonnée de profil) quand un test ne porte pas sur eux, pour que
  /// chaque test "personnages" garde le même niveau de bruit qu'avant
  /// l'extension B1 du registre d'audit RGPD.
  Future<LocalFileDataExportRepository> buildRepository({
    required CharacterRepository characterRepository,
    GroupRepository? groupRepository,
    SupabaseClient? client,
  }) async {
    return LocalFileDataExportRepository(
      characterRepository,
      groupRepository ?? _FakeGroupRepository(),
      client ?? await _buildSignedInClient(),
    );
  }

  CharacterDetail buildDetail({required String id, required String name}) {
    return CharacterDetail(
      id: id,
      name: name,
      xp: 120,
      currentHp: 9,
      maxHp: 12,
      temporaryHp: 0,
      abilityScores: const {'str': 14, 'dex': 12},
      classes: [
        CharacterDetailClassRow(
          classId: 3,
          className: 'Guerrier',
          level: 2,
          isPrimary: true,
          savingThrowProficiencies: const ['str', 'con'],
          hitDie: 10,
        ),
      ],
      inventory: [
        const CharacterInventoryItem(
          id: 'inv-1',
          itemId: 42,
          name: 'Épée longue',
          category: 'arme',
          quantity: 1,
          equipped: true,
          totalWeight: 1.5,
        ),
      ],
      appearanceText: 'Grand et mince.',
    );
  }

  group('LocalFileDataExportRepository.exportMyData', () {
    test('assemble un JSON avec `exportedAt` et un personnage par entrée de '
        '`fetchCharacters`, écrit dans le répertoire temporaire', () async {
      final characterRepository = _FakeCharacterRepository()
        ..summaries = [
          const CharacterSummary(
            id: 'char-1',
            name: 'Aranea',
            level: 2,
            xp: 120,
          ),
        ]
        ..detailsById['char-1'] = buildDetail(id: 'char-1', name: 'Aranea');
      final repository = await buildRepository(
        characterRepository: characterRepository,
      );

      final path = await repository.exportMyData();

      expect(path, startsWith(tempDir.path));
      final file = File(path);
      expect(file.existsSync(), isTrue);

      final payload =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(payload['exportedAt'], isA<String>());
      expect(DateTime.tryParse(payload['exportedAt'] as String), isNotNull);

      final characters = payload['characters'] as List<dynamic>;
      expect(characters, hasLength(1));
      final character = characters.single as Map<String, dynamic>;
      expect(character['id'], 'char-1');
      expect(character['name'], 'Aranea');
      expect(character['xp'], 120);
      expect(character['currentHp'], 9);
      expect(character['maxHp'], 12);
      expect(
        (character['story'] as Map<String, dynamic>)['appearanceText'],
        'Grand et mince.',
      );
      final classes = character['classes'] as List<dynamic>;
      expect((classes.single as Map<String, dynamic>)['className'], 'Guerrier');
      final inventory = character['inventory'] as List<dynamic>;
      expect((inventory.single as Map<String, dynamic>)['name'], 'Épée longue');
    });

    test('sorts accordés par une sous-classe : statut stocké conservé, sort '
        'purement dérivé exclu', () async {
      final base = buildDetail(id: 'char-1', name: 'Aranea');
      final detail = base.copyWith(
        spells: const [
          CharacterSpellEntry(
            id: 1,
            name: 'Bénédiction',
            level: 1,
            school: 'Enchantement',
            status: SpellStatus.prepared,
            grantSource: SpellGrantSource.domain,
            storedStatus: SpellStatus.known,
          ),
          CharacterSpellEntry(
            id: 2,
            name: 'Soins',
            level: 1,
            school: 'Invocation',
            status: SpellStatus.prepared,
            grantSource: SpellGrantSource.domain,
            isPersisted: false,
          ),
        ],
      );
      final characterRepository = _FakeCharacterRepository()
        ..summaries = [
          const CharacterSummary(id: 'char-1', name: 'Aranea', level: 2, xp: 1),
        ]
        ..detailsById['char-1'] = detail;

      final path = await (await buildRepository(
        characterRepository: characterRepository,
      )).exportMyData();

      final payload =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final character =
          (payload['characters'] as List<dynamic>).single
              as Map<String, dynamic>;
      final spells = character['spells'] as List<dynamic>;
      expect(spells, hasLength(1));
      expect((spells.single as Map<String, dynamic>)['status'], 'connu');
    });

    test('plusieurs personnages : un élément de `characters` par personnage, '
        'dans l\'ordre de `fetchCharacters`', () async {
      final characterRepository = _FakeCharacterRepository()
        ..summaries = [
          const CharacterSummary(
            id: 'char-1',
            name: 'Aranea',
            level: 2,
            xp: 120,
          ),
          const CharacterSummary(
            id: 'char-2',
            name: 'Borin',
            level: 4,
            xp: 900,
          ),
        ]
        ..detailsById['char-1'] = buildDetail(id: 'char-1', name: 'Aranea')
        ..detailsById['char-2'] = buildDetail(id: 'char-2', name: 'Borin');
      final repository = await buildRepository(
        characterRepository: characterRepository,
      );

      final path = await repository.exportMyData();
      final payload =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final characters = payload['characters'] as List<dynamic>;

      expect(characters, hasLength(2));
      expect((characters[0] as Map<String, dynamic>)['id'], 'char-1');
      expect((characters[1] as Map<String, dynamic>)['id'], 'char-2');
    });

    test(
      'aucun personnage : `characters` vide, fichier tout de même généré',
      () async {
        final characterRepository = _FakeCharacterRepository()..summaries = [];
        final repository = await buildRepository(
          characterRepository: characterRepository,
        );

        final path = await repository.exportMyData();
        final payload =
            jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

        expect(payload['characters'], isEmpty);
      },
    );

    test('propage telle quelle une exception levée par '
        '`fetchCharacterDetail` (ex. `CharacterFailure`)', () async {
      final characterRepository = _FakeCharacterRepository()
        ..summaries = [
          const CharacterSummary(
            id: 'char-1',
            name: 'Aranea',
            level: 2,
            xp: 120,
          ),
        ]
        ..detailErrorToThrow = const CharacterFailure('Erreur serveur.');
      final repository = await buildRepository(
        characterRepository: characterRepository,
      );

      await expectLater(
        repository.exportMyData(),
        throwsA(isA<CharacterFailure>()),
      );
    });
  });

  group('LocalFileDataExportRepository.exportMyData — profil (B1)', () {
    test('profil : email/pseudo/avatar lus depuis `auth.currentUser` '
        '(`user_metadata.full_name`/`avatar_url`)', () async {
      final client = await _buildSignedInClient(
        email: 'aranea@exemple.com',
        userMetadata: const {
          'full_name': 'Aranea Nightsong',
          'avatar_url': 'https://exemple.com/avatar.png',
        },
      );
      final repository = await buildRepository(
        characterRepository: _FakeCharacterRepository(),
        client: client,
      );

      final path = await repository.exportMyData();
      final payload =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final profile = payload['profile'] as Map<String, dynamic>;

      expect(profile['email'], 'aranea@exemple.com');
      expect(profile['displayName'], 'Aranea Nightsong');
      expect(profile['avatarUrl'], 'https://exemple.com/avatar.png');
    });

    test('profil : pseudo/avatar absents de `user_metadata` -> `null`, jamais '
        "une erreur (pas encore renseignés par le joueur)", () async {
      final repository = await buildRepository(
        characterRepository: _FakeCharacterRepository(),
      );

      final path = await repository.exportMyData();
      final payload =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final profile = payload['profile'] as Map<String, dynamic>;

      expect(profile['email'], 'joueur@exemple.com');
      expect(profile['displayName'], isNull);
      expect(profile['avatarUrl'], isNull);
    });
  });

  group('LocalFileDataExportRepository.exportMyData — groupes/notes (B1, '
      'fractionnement en entrées multiples)', () {
    test('un groupe par entrée de `fetchMyGroups`, avec `id`/`name`/'
        '`memberCount`/`founderId`', () async {
      final groupRepository = _FakeGroupRepository()
        ..groups = [
          const GroupSummary(
            id: 'group-1',
            name: 'La Compagnie',
            memberCount: 3,
            founderId: 'owner-1',
          ),
        ];
      final repository = await buildRepository(
        characterRepository: _FakeCharacterRepository(),
        groupRepository: groupRepository,
      );

      final path = await repository.exportMyData();
      final payload =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final groups = payload['groups'] as List<dynamic>;

      expect(groups, hasLength(1));
      final group = groups.single as Map<String, dynamic>;
      expect(group['id'], 'group-1');
      expect(group['name'], 'La Compagnie');
      expect(group['memberCount'], 3);
      expect(group['founderId'], 'owner-1');
    });

    test('une entrée enregistrée : `notes` incluse avec id/titre/corps/date', (
      () async {
        final groupRepository = _FakeGroupRepository()
          ..groups = [
            const GroupSummary(
              id: 'group-1',
              name: 'La Compagnie',
              memberCount: 2,
              founderId: 'owner-1',
            ),
          ]
          ..entriesByGroupId['group-1'] = [
            GroupNoteEntry(
              id: 'entry-1',
              title: 'Chapitre 1 — Le donjon',
              body: 'Le MJ a mentionné une amulette maudite au donjon.',
              createdAt: DateTime.utc(2026, 11, 1, 20, 0),
            ),
          ];
        final repository = await buildRepository(
          characterRepository: _FakeCharacterRepository(),
          groupRepository: groupRepository,
        );

        final path = await repository.exportMyData();
        final payload =
            jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
        final group =
            (payload['groups'] as List<dynamic>).single
                as Map<String, dynamic>;
        final notes = group['notes'] as List<dynamic>;

        expect(notes, hasLength(1));
        final note = notes.single as Map<String, dynamic>;
        expect(note['id'], 'entry-1');
        expect(note['title'], 'Chapitre 1 — Le donjon');
        expect(
          note['body'],
          'Le MJ a mentionné une amulette maudite au donjon.',
        );
        expect(note['createdAt'], '2026-11-01T20:00:00.000Z');
      }
    ));

    test('plusieurs entrées, y compris sans titre : `notes` liste TOUTES les '
        'entrées, dans l\'ordre retourné par le repository', () async {
      final groupRepository = _FakeGroupRepository()
        ..groups = [
          const GroupSummary(
            id: 'group-1',
            name: 'La Compagnie',
            memberCount: 2,
            founderId: 'owner-1',
          ),
        ]
        ..entriesByGroupId['group-1'] = [
          GroupNoteEntry(
            id: 'entry-2',
            title: 'Chapitre 2',
            body: 'Combat contre les gobelins.',
            createdAt: DateTime.utc(2026, 11, 8),
          ),
          GroupNoteEntry(
            id: 'entry-1',
            body: 'Première séance, sans titre.',
            createdAt: DateTime.utc(2026, 11, 1),
          ),
        ];
      final repository = await buildRepository(
        characterRepository: _FakeCharacterRepository(),
        groupRepository: groupRepository,
      );

      final path = await repository.exportMyData();
      final payload =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final group =
          (payload['groups'] as List<dynamic>).single as Map<String, dynamic>;
      final notes = group['notes'] as List<dynamic>;

      expect(notes, hasLength(2));
      expect((notes[0] as Map<String, dynamic>)['id'], 'entry-2');
      expect((notes[1] as Map<String, dynamic>)['id'], 'entry-1');
      expect((notes[1] as Map<String, dynamic>)['title'], isNull);
    });

    test('aucune entrée enregistrée : la clé `notes` est omise plutôt '
        'qu\'incluse vide', () async {
      final groupRepository = _FakeGroupRepository()
        ..groups = [
          const GroupSummary(
            id: 'group-1',
            name: 'La Compagnie',
            memberCount: 2,
            founderId: 'owner-1',
          ),
        ];
      final repository = await buildRepository(
        characterRepository: _FakeCharacterRepository(),
        groupRepository: groupRepository,
      );

      final path = await repository.exportMyData();
      final payload =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final group =
          (payload['groups'] as List<dynamic>).single as Map<String, dynamic>;

      expect(group.containsKey('notes'), isFalse);
    });

    test(
      'MJ sans personnage/membre orphelin avec plusieurs entrées (régression '
      'du trou RGPD F02(a), étendue à ce fractionnement) : `notes` liste '
      'TOUTES les entrées, pas seulement la première — '
      '`fetchGroupNoteEntries` est filtrée côté RLS sur `user_id`, jamais '
      'besoin de résoudre un `characterId`',
      () async {
        final groupRepository = _FakeGroupRepository()
          ..groups = [
            const GroupSummary(
              id: 'group-1',
              name: 'La Compagnie',
              memberCount: 1,
              founderId: 'fake-user-id',
            ),
          ]
          ..entriesByGroupId['group-1'] = [
            GroupNoteEntry(
              id: 'entry-2',
              title: 'Embuscade au pont',
              body: 'Le MJ note une embuscade au pont.',
              createdAt: DateTime.utc(2026, 11, 8),
            ),
            GroupNoteEntry(
              id: 'entry-1',
              body: 'Penser à préparer la rencontre du donjon.',
              createdAt: DateTime.utc(2026, 11, 1),
            ),
          ];
        final repository = await buildRepository(
          characterRepository: _FakeCharacterRepository(),
          groupRepository: groupRepository,
        );

        final path = await repository.exportMyData();
        final payload =
            jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
        final group =
            (payload['groups'] as List<dynamic>).single
                as Map<String, dynamic>;
        final notes = group['notes'] as List<dynamic>;

        expect(
          notes,
          hasLength(2),
          reason:
              'un MJ sans personnage avec plusieurs notes doit voir TOUTES '
              'ses entrées dans son export, pas seulement la première',
        );
        expect((notes[0] as Map<String, dynamic>)['id'], 'entry-2');
        expect((notes[1] as Map<String, dynamic>)['id'], 'entry-1');
      },
    );

    test('plusieurs groupes : un élément de `groups` par groupe, dans l\'ordre '
        'de `fetchMyGroups`', () async {
      final groupRepository = _FakeGroupRepository()
        ..groups = [
          const GroupSummary(
            id: 'group-1',
            name: 'La Compagnie',
            memberCount: 2,
            founderId: 'owner-1',
          ),
          const GroupSummary(
            id: 'group-2',
            name: 'Les Rôdeurs',
            memberCount: 4,
            founderId: 'owner-2',
          ),
        ];
      final repository = await buildRepository(
        characterRepository: _FakeCharacterRepository(),
        groupRepository: groupRepository,
      );

      final path = await repository.exportMyData();
      final payload =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final groups = payload['groups'] as List<dynamic>;

      expect(groups, hasLength(2));
      expect((groups[0] as Map<String, dynamic>)['id'], 'group-1');
      expect((groups[1] as Map<String, dynamic>)['id'], 'group-2');
    });

    test('aucun groupe : `groups` vide, fichier tout de même généré', () async {
      final repository = await buildRepository(
        characterRepository: _FakeCharacterRepository(),
      );

      final path = await repository.exportMyData();
      final payload =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

      expect(payload['groups'], isEmpty);
    });

    test('propage telle quelle une exception levée par `fetchMyGroups` (ex. '
        '`GroupFailure`)', () async {
      final groupRepository = _FakeGroupRepository()
        ..fetchMyGroupsErrorToThrow = const GroupFailure('Erreur serveur.');
      final repository = await buildRepository(
        characterRepository: _FakeCharacterRepository(),
        groupRepository: groupRepository,
      );

      await expectLater(
        repository.exportMyData(),
        throwsA(isA<GroupFailure>()),
      );
    });
  });
}
