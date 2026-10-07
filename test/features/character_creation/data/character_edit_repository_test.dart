import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/features/character_creation/data/character_edit_repository.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_edit_hydrator.dart';
import 'package:personnages/features/character_creation/domain/character_edit_planner.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_option.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sorts innés raciaux et modification d'un personnage (D09) : ce que
/// `SupabaseCharacterEditRepository.save` envoie réellement à PostgREST sur
/// `character_spells`.
///
/// `SupabaseClient` réel dont seul le transport HTTP est fabriqué — même
/// principe que `character_creation_repository_test.dart` et
/// `subclass_choice_repository_test.dart`. Ces tests vérifient les requêtes
/// *émises*, jamais le comportement d'une base réelle.
void main() {
  const characterId = 'char-1';

  // JWT factice (exp lointain) : `recoverSession` l'accepte sans réseau.
  String jwt() {
    String part(Map<String, Object> json) =>
        base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
    return '${part({'alg': 'HS256', 'typ': 'JWT'})}.'
        '${part({'sub': 'user-1', 'exp': 4102444800})}.sig';
  }

  /// [characterRow] : réponse à la lecture de `characters`
  /// (`fetchSnapshot`, `.maybeSingle()` : un OBJET JSON, pas un tableau).
  Future<SupabaseClient> signedInClient({
    required List<http.Request> requests,
    Map<String, dynamic>? characterRow,
  }) async {
    final client = SupabaseClient(
      'https://fake.supabase.test',
      'fake-anon-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final Object body =
            request.method == 'GET' &&
                request.url.pathSegments.last == 'characters'
            ? (characterRow ?? const <String, dynamic>{})
            : const <Map<String, dynamic>>[];
        return http.Response(
          jsonEncode(body),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
      postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    await client.auth.recoverSession(
      jsonEncode({
        'access_token': jwt(),
        'refresh_token': 'r',
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': 4102444800,
        'user': {
          'id': 'user-1',
          'aud': 'authenticated',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'created_at': '2026-01-01T00:00:00Z',
        },
      }),
    );
    return client;
  }

  List<http.Request> spellRequests(List<http.Request> requests) => [
    for (final request in requests)
      if (request.url.pathSegments.last == 'character_spells') request,
  ];

  List<Map<String, dynamic>> insertedRows(http.Request request) => [
    for (final row in jsonDecode(request.body) as List)
      Map<String, dynamic>.from(row as Map),
  ];

  group('SupabaseCharacterEditRepository.save — sorts innés (D09)', () {
    test("la suppression de sorts exclut toujours les lignes 'inné'", () async {
      final requests = <http.Request>[];
      final client = await signedInClient(requests: requests);

      await SupabaseCharacterEditRepository(client).save(
        characterId: characterId,
        plan: const CharacterEditPlan(
          characterUpdate: {'name': 'Zariel'},
          spellDeletes: {103, 101},
        ),
      );

      final delete = spellRequests(requests).single;
      expect(delete.method, 'DELETE');
      final query = delete.url.queryParameters;
      expect(query['character_id'], 'eq.$characterId');
      expect(query['spell_id'], 'in.(103,101)');
      // Sans ce filtre, désélectionner côté classe un sort que le
      // personnage a AUSSI en inné emporterait la ligne innée et son
      // compteur `innate_uses_spent`.
      expect(query['status'], 'neq.inné');
    });

    test("aucune ligne 'inné' n'est insérée ni mise à jour : seuls les sorts "
        'de classe du plan sont écrits', () async {
      final requests = <http.Request>[];
      final client = await signedInClient(requests: requests);

      await SupabaseCharacterEditRepository(client).save(
        characterId: characterId,
        plan: const CharacterEditPlan(
          characterUpdate: {'name': 'Zariel'},
          classChange: (
            classId: 2,
            subclassId: null,
            hpRolled: 8,
            classChanged: true,
          ),
          spellDeletes: {150},
          spellInserts: [
            (spellId: 100, status: 'préparé'),
            (spellId: 101, status: 'préparé'),
          ],
        ),
      );

      final onSpells = spellRequests(requests);
      expect(
        onSpells.map((request) => request.method),
        ['DELETE', 'POST'],
        reason:
            'aucun PATCH sur character_spells : `innate_uses_spent` '
            "n'est jamais réécrit par une modification",
      );
      expect(onSpells.first.url.queryParameters['status'], 'neq.inné');
      expect(insertedRows(onSpells.last), [
        {
          'character_id': characterId,
          'spell_id': 100,
          'status': 'préparé',
          'source_class_id': 2,
        },
        {
          'character_id': characterId,
          'spell_id': 101,
          'status': 'préparé',
          'source_class_id': 2,
        },
      ]);
    });

    test('changement de classe : la purge des données de classe ne vise '
        'jamais character_spells', () async {
      final requests = <http.Request>[];
      final client = await signedInClient(requests: requests);

      await SupabaseCharacterEditRepository(client).save(
        characterId: characterId,
        plan: const CharacterEditPlan(
          characterUpdate: {'name': 'Zariel'},
          classChange: (
            classId: 1,
            subclassId: null,
            hpRolled: 10,
            classChanged: true,
          ),
        ),
      );

      expect(spellRequests(requests), isEmpty);
      expect(
        [
          for (final request in requests)
            if (request.method == 'DELETE') request.url.pathSegments.last,
        ],
        [
          'character_feature_uses',
          'character_class_options',
          'character_spell_slots',
          'character_pact_slots',
        ],
      );
    });
  });

  group('lecture, plan puis enregistrement — sorts innés (D09)', () {
    const guerrier = ClassOption(
      id: 1,
      name: 'Guerrier',
      description: '',
      hitDie: 10,
    );
    const clerc = ClassOption(id: 2, name: 'Clerc', description: '', hitDie: 8);
    const acolyte = BackgroundOption(
      id: 1,
      name: 'Acolyte',
      skillProficiencies: [],
      featureName: '',
      featureDescription: '',
    );
    const clercSpells = SpellCatalog(
      spells: [
        SpellOption(
          id: 100,
          name: 'Flamme sacrée',
          level: 0,
          school: '',
          castingTime: '',
        ),
        SpellOption(
          id: 101,
          name: 'Soins',
          level: 1,
          school: '',
          castingTime: '',
        ),
        SpellOption(
          id: 103,
          name: 'Thaumaturgie',
          level: 0,
          school: '',
          castingTime: '',
        ),
      ],
    );

    // Tieffelin Clerc de niveau 1 : Thaumaturgie (103) innée ET choisie en
    // classe (lignes en double), un sort inné hors liste (200) déjà dépensé,
    // deux sorts de classe.
    Map<String, dynamic> characterRow() => {
      'id': characterId,
      'name': 'Zariel',
      'max_hp': 10,
      'current_hp': 10,
      'race_id': 9,
      'background_id': 1,
      'character_classes': [
        {'class_id': 2, 'subclass_id': null, 'level': 1, 'is_primary': true},
      ],
      'character_ability_scores': [
        {'ability_id': 'con', 'score': 14},
      ],
      'character_spells': [
        {'spell_id': 103, 'status': 'inné'},
        {'spell_id': 200, 'status': 'inné'},
        {'spell_id': 103, 'status': 'préparé'},
        {'spell_id': 100, 'status': 'préparé'},
        {'spell_id': 101, 'status': 'préparé'},
      ],
    };

    Future<List<http.Request>> editAndCaptureSpellRequests({
      required ClassOption editedClass,
      required List<String> cantrips,
      required List<String> levelOneSpells,
      required SpellCatalog editedSpellCatalog,
    }) async {
      final requests = <http.Request>[];
      final client = await signedInClient(
        requests: requests,
        characterRow: characterRow(),
      );
      final repository = SupabaseCharacterEditRepository(client);

      final snapshot = await repository.fetchSnapshot(characterId);
      const skills = SkillCatalog(skills: []);
      const tools = ToolCatalog(tools: []);
      const languages = LanguageCatalog(languages: []);
      final original = CharacterEditHydrator.toDraft(
        snapshot: snapshot,
        classOption: clerc,
        backgroundOption: acolyte,
        skillCatalog: skills,
        toolCatalog: tools,
        languageCatalog: languages,
        spellCatalog: clercSpells,
      );
      expect(original.classCantripChoices, ['Thaumaturgie', 'Flamme sacrée']);

      final plan = CharacterEditPlanner.plan(
        snapshot: snapshot,
        original: original,
        edited: original.copyWith(
          classId: editedClass.id,
          classCantripChoices: cantrips,
          classLevelOneSpellChoices: levelOneSpells,
        ),
        originalClass: clerc,
        editedClass: editedClass,
        originalBackground: acolyte,
        editedBackground: acolyte,
        skillCatalog: skills,
        toolCatalog: tools,
        languageCatalog: languages,
        originalSpellCatalog: clercSpells,
        editedSpellCatalog: editedSpellCatalog,
      );
      await repository.save(characterId: characterId, plan: plan);
      return spellRequests(requests);
    }

    test('changement de classe : seules les lignes ordinaires des sorts de '
        "l'ancienne classe sont supprimées", () async {
      final onSpells = await editAndCaptureSpellRequests(
        editedClass: guerrier,
        cantrips: const [],
        levelOneSpells: const [],
        editedSpellCatalog: const SpellCatalog(spells: []),
      );

      final delete = onSpells.single;
      expect(delete.method, 'DELETE');
      // 200 (inné hors liste) n'est pas visé ; 103 l'est pour sa ligne
      // ordinaire, sa ligne innée étant écartée par le filtre de statut.
      expect(delete.url.queryParameters['spell_id'], 'in.(103,100,101)');
      expect(delete.url.queryParameters['status'], 'neq.inné');
    });

    test('classe inchangée, sort en double désélectionné côté classe : la '
        'ligne innée reste', () async {
      final onSpells = await editAndCaptureSpellRequests(
        editedClass: clerc,
        cantrips: const ['Flamme sacrée'],
        levelOneSpells: const ['Soins'],
        editedSpellCatalog: clercSpells,
      );

      final delete = onSpells.single;
      expect(delete.method, 'DELETE');
      expect(delete.url.queryParameters['spell_id'], 'in.(103)');
      expect(delete.url.queryParameters['status'], 'neq.inné');
    });

    test('classe et sorts inchangés : aucune requête sur '
        'character_spells', () async {
      final onSpells = await editAndCaptureSpellRequests(
        editedClass: clerc,
        cantrips: const ['Thaumaturgie', 'Flamme sacrée'],
        levelOneSpells: const ['Soins'],
        editedSpellCatalog: clercSpells,
      );

      expect(onSpells, isEmpty);
    });
  });
}
