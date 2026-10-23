import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/rules/spell_status.dart';
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
  /// [classFeatureRows] : réponse à la résolution `class_feature_id` —
  /// correctif D102 (`docs/dette-technique.md`), `save` l'interroge pour
  /// `classFeatureChoiceWrite`/`subclassFeatureChoiceWrite`/
  /// `expertiseOptionsWrite` (même requête que `createCharacter`). Vide par
  /// défaut, même rationale que [characterRow] pour les autres tables.
  Future<SupabaseClient> signedInClient({
    required List<http.Request> requests,
    Map<String, dynamic>? characterRow,
    List<Map<String, dynamic>>? classFeatureRows,
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
            : request.method == 'GET' &&
                  request.url.pathSegments.last == 'class_features'
            ? (classFeatureRows ?? const <Map<String, dynamic>>[])
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

  /// Requêtes visant la table [table] — correctif D102
  /// (`docs/dette-technique.md`), même principe que [spellRequests] en
  /// générique.
  List<http.Request> requestsOn(List<http.Request> requests, String table) => [
    for (final request in requests)
      if (request.url.pathSegments.last == table) request,
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
            (spellId: 100, status: SpellStatus.prepared),
            (spellId: 101, status: SpellStatus.prepared),
          ],
          // Toujours calculé par `CharacterEditPlanner.plan` dès que
          // `spellInserts` est non vide (D40, `docs/dette-technique.md`) —
          // ici la classe APRÈS changement (classId 2), simulé à la main
          // comme le reste de ce plan de test.
          spellSourceClassId: 2,
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

  group('SupabaseCharacterEditRepository.save — choix nommés de niveau 1 '
      '(correctif D102, docs/dette-technique.md)', () {
    Map<String, dynamic> insertedRow(http.Request request) =>
        Map<String, dynamic>.from(jsonDecode(request.body) as Map);

    test('classFeatureChoiceWrite : résout class_feature_id via class_id + '
        'level=1 + choice_type, supprime l\'ancienne ligne PUIS réinsère '
        'la nouvelle', () async {
      final requests = <http.Request>[];
      final client = await signedInClient(
        requests: requests,
        classFeatureRows: [
          {'id': 15},
        ],
      );

      await SupabaseCharacterEditRepository(client).save(
        characterId: characterId,
        plan: const CharacterEditPlan(
          characterUpdate: {'name': 'Brasc'},
          classFeatureChoiceWrite: (
            classId: 5,
            choiceType: 'style_combat',
            chosenValue: 'Duel',
          ),
        ),
      );

      final featureQuery = requestsOn(requests, 'class_features').single;
      expect(featureQuery.method, 'GET');
      expect(featureQuery.url.queryParameters['class_id'], 'eq.5');
      expect(featureQuery.url.queryParameters['level'], 'eq.1');
      expect(
        featureQuery.url.queryParameters['choice_type'],
        'eq.style_combat',
      );

      final onOptions = requestsOn(requests, 'character_class_options');
      expect(onOptions.map((request) => request.method), ['DELETE', 'POST']);
      expect(onOptions.first.url.queryParameters['class_feature_id'], 'eq.15');
      expect(insertedRow(onOptions.last), {
        'character_id': characterId,
        'class_feature_id': 15,
        'level': 1,
        'chosen_value': 'Duel',
      });
    });

    test('classFeatureChoiceWrite : aucune ligne class_features '
        'correspondante (cas défensif) -> aucune écriture sur '
        'character_class_options', () async {
      final requests = <http.Request>[];
      final client = await signedInClient(requests: requests);

      await SupabaseCharacterEditRepository(client).save(
        characterId: characterId,
        plan: const CharacterEditPlan(
          characterUpdate: {'name': 'Brasc'},
          classFeatureChoiceWrite: (
            classId: 99,
            choiceType: 'style_combat',
            chosenValue: 'Duel',
          ),
        ),
      );

      expect(requestsOn(requests, 'character_class_options'), isEmpty);
    });

    test('subclassFeatureChoiceWrite : résout via subclass_id + level=1 + '
        'choice_type non nul ET différent de sous_classe (2 filtres sur la '
        'même colonne, jamais un seul écrasant l\'autre)', () async {
      final requests = <http.Request>[];
      final client = await signedInClient(
        requests: requests,
        classFeatureRows: [
          {'id': 368},
        ],
      );

      await SupabaseCharacterEditRepository(client).save(
        characterId: characterId,
        plan: const CharacterEditPlan(
          characterUpdate: {'name': 'Zaltar'},
          subclassFeatureChoiceWrite: (
            subclassId: 12,
            chosenValue: 'Dragon rouge',
          ),
        ),
      );

      final featureQuery = requestsOn(requests, 'class_features').single;
      expect(featureQuery.url.queryParameters['subclass_id'], 'eq.12');
      expect(featureQuery.url.queryParameters['level'], 'eq.1');
      // `.not('choice_type', 'is', null).neq('choice_type', 'sous_classe')`
      // ajoute 2 valeurs À LA MÊME clé de requête (`queryParametersAll`,
      // jamais `queryParameters` qui n'en garderait que la dernière).
      expect(featureQuery.url.queryParametersAll['choice_type'], [
        'not.is.null',
        'neq.sous_classe',
      ]);

      final onOptions = requestsOn(requests, 'character_class_options');
      expect(onOptions.map((request) => request.method), ['DELETE', 'POST']);
      expect(onOptions.first.url.queryParameters['class_feature_id'], 'eq.368');
      expect(insertedRow(onOptions.last), {
        'character_id': characterId,
        'class_feature_id': 368,
        'level': 1,
        'chosen_value': 'Dragon rouge',
      });
    });

    test('expertiseOptionsWrite : résout via class_id + level=1 + '
        "choice_type='expertise', supprime puis réinsère UNE ligne par "
        'valeur (compétences + substitution outils)', () async {
      final requests = <http.Request>[];
      final client = await signedInClient(
        requests: requests,
        classFeatureRows: [
          {'id': 40},
        ],
      );

      await SupabaseCharacterEditRepository(client).save(
        characterId: characterId,
        plan: const CharacterEditPlan(
          characterUpdate: {'name': 'Lira'},
          expertiseOptionsWrite: (
            classId: 9,
            chosenValues: ['Discrétion', 'outils de voleur'],
          ),
        ),
      );

      final featureQuery = requestsOn(requests, 'class_features').single;
      expect(featureQuery.url.queryParameters['class_id'], 'eq.9');
      expect(featureQuery.url.queryParameters['choice_type'], 'eq.expertise');

      final onOptions = requestsOn(requests, 'character_class_options');
      expect(onOptions.map((request) => request.method), ['DELETE', 'POST']);
      expect(insertedRows(onOptions.last), [
        {
          'character_id': characterId,
          'class_feature_id': 40,
          'level': 1,
          'chosen_value': 'Discrétion',
        },
        {
          'character_id': characterId,
          'class_feature_id': 40,
          'level': 1,
          'chosen_value': 'outils de voleur',
        },
      ]);
    });

    test('expertiseSkillUpgrades/Downgrades : PATCH character_skill_'
        "proficiencies vers 'expertise'/'competente', toujours APRÈS les "
        'éventuels skillInserts (une compétence nouvellement choisie ET '
        'mise en Expertise doit déjà exister en base)', () async {
      final requests = <http.Request>[];
      final client = await signedInClient(requests: requests);

      await SupabaseCharacterEditRepository(client).save(
        characterId: characterId,
        plan: const CharacterEditPlan(
          characterUpdate: {'name': 'Lira'},
          skillInserts: {1},
          expertiseSkillUpgrades: {1},
          expertiseSkillDowngrades: {7},
        ),
      );

      final onSkills = requestsOn(requests, 'character_skill_proficiencies');
      expect(onSkills.map((request) => request.method), [
        'POST',
        'PATCH',
        'PATCH',
      ]);
      expect(insertedRows(onSkills[0]), [
        {
          'character_id': characterId,
          'skill_id': 1,
          'proficiency': 'competente',
        },
      ]);
      expect(insertedRow(onSkills[1]), {'proficiency': 'expertise'});
      expect(onSkills[1].url.queryParameters['skill_id'], 'in.(1)');
      expect(insertedRow(onSkills[2]), {'proficiency': 'competente'});
      expect(onSkills[2].url.queryParameters['skill_id'], 'in.(7)');
    });

    test('classChange (classChanged: true) ET classFeatureChoiceWrite dans '
        'le même plan : la purge en bloc de character_class_options '
        '(classChange.classChanged) précède toujours la résolution/'
        'réinsertion de la nouvelle valeur nommée (GET class_features -> '
        'DELETE scopé par class_feature_id -> POST)', () async {
      final requests = <http.Request>[];
      final client = await signedInClient(
        requests: requests,
        classFeatureRows: [
          {'id': 15},
        ],
      );

      await SupabaseCharacterEditRepository(client).save(
        characterId: characterId,
        plan: const CharacterEditPlan(
          characterUpdate: {'name': 'Brasc'},
          classChange: (
            classId: 5,
            subclassId: null,
            hpRolled: 10,
            classChanged: true,
          ),
          classFeatureChoiceWrite: (
            classId: 5,
            choiceType: 'style_combat',
            chosenValue: 'Duel',
          ),
        ),
      );

      // Purge en bloc : le seul DELETE sur character_class_options SANS
      // filtre class_feature_id (déclenchée par classChange.classChanged,
      // AVANT toute résolution de choix nommé).
      final bulkPurgeIndex = requests.indexWhere(
        (request) =>
            request.method == 'DELETE' &&
            request.url.pathSegments.last == 'character_class_options' &&
            !request.url.queryParameters.containsKey('class_feature_id'),
      );
      final featureQueryIndex = requests.indexWhere(
        (request) => request.url.pathSegments.last == 'class_features',
      );
      final scopedDeleteIndex = requests.indexWhere(
        (request) =>
            request.method == 'DELETE' &&
            request.url.pathSegments.last == 'character_class_options' &&
            request.url.queryParameters['class_feature_id'] == 'eq.15',
      );
      final insertIndex = requests.indexWhere(
        (request) =>
            request.method == 'POST' &&
            request.url.pathSegments.last == 'character_class_options',
      );

      expect(bulkPurgeIndex, isNot(-1));
      expect(featureQueryIndex, isNot(-1));
      expect(scopedDeleteIndex, isNot(-1));
      expect(insertIndex, isNot(-1));
      // Ordre réel attendu : purge en bloc -> GET class_features -> DELETE
      // scopé -> POST. Sans cet ordre, la purge en bloc (déclenchée par le
      // changement de classe) pourrait effacer la ligne que la résolution
      // du choix nommé vient d'insérer pour la NOUVELLE classe.
      expect(bulkPurgeIndex, lessThan(featureQueryIndex));
      expect(featureQueryIndex, lessThan(scopedDeleteIndex));
      expect(scopedDeleteIndex, lessThan(insertIndex));
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
