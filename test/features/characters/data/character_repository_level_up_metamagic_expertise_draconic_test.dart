import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/level_up_metamagic_swap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Couvre les 3 mécaniques jamais câblées de ce chantier (Métamagie/
/// Expertise/Ancêtre draconique), même famille que
/// `character_repository_level_up_arcane_shots_runes_infusions_test.dart`.
///
/// Vérifie en particulier :
/// - Métamagie (aptitude de CLASSE, 3 lignes `class_features` — contrairement
///   à l'infusion, UNE seule ligne) : résolution via `.eq('class_id',
///   classId)` ET `choice_type = 'metamagie'` (jamais `choice_type` SEUL),
///   l'ancre unique étant la ligne de plus bas niveau (3), réutilisée pour
///   TOUTE écriture (nouvelles options ET échange).
/// - Expertise : AUCUNE ligne `character_class_options` pour les
///   compétences elles-mêmes — écrit directement
///   `character_skill_proficiencies.proficiency = 'expertise'`, après
///   revérification que la compétence est bien 'competente'. Aucune
///   substitution "Outils de voleur" n'existe (D104 de
///   `docs/dette-technique.md` — RAW-fausse, retirée).
/// - Ancêtre draconique : choix de SOUS-CLASSE (`class_id` NULL), résolu via
///   `choice_type` SEUL comme les manœuvres/runes.
void main() {
  late AppDatabase db;
  late ReferenceDataCache cache;
  late PendingCharacterWriteQueue pendingWrites;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cache = ReferenceDataCache(db);
    pendingWrites = PendingCharacterWriteQueue(db);
  });

  tearDown(() async {
    await db.close();
  });

  const characterId = 'char-1';
  const ownerId = 'owner-1';
  const sorcererClassId = 12;
  const bardClassId = 7;
  const roguishClassId = 9;
  const draconicBloodlineSubclassId = 20;
  const metamagicFeatureId3 = 211;
  const metamagicFeatureId10 = 214;
  const metamagicFeatureId17 = 217;
  const draconicAncestryFeatureId = 368;
  // Ligne leurre d'une AUTRE classe (Barde), même `choice_type = 'metamagie'`
  // et niveau plus bas que toutes les ancres réelles de l'Ensorceleur —
  // preuve, pour D105 de `docs/dette-technique.md`, que la résolution filtre
  // bien par `.eq('class_id', classId)` ET PAS `choice_type` seul : si ce
  // filtre était retiré du code, cette ligne (niveau le plus bas) serait
  // choisie comme ancre à la place de `metamagicFeatureId3`, faisant échouer
  // les assertions ci-dessous.
  const decoyBardMetamagicFeatureId = 500;

  Future<SupabaseCharacterRepository> repository({
    Map<String, List<Map<String, dynamic>>> rows = const {},
    List<_Recorded>? recorded,
  }) async => SupabaseCharacterRepository(
    await _buildSignedInFakeSupabaseClient(
      ownerId: ownerId,
      recorded: recorded ?? <_Recorded>[],
      tableRows: rows,
    ),
    cache,
    pendingWrites,
    _FakeConnectivityChecker(connected: true),
  );

  group('SupabaseCharacterRepository.fetchAvailableMetamagicOptions', () {
    test('résout les 3 lignes class_features via class_id + choice_type, '
        'exclut les options déjà connues (tous ids agrégés)', () async {
      final recorded = <_Recorded>[];
      final repo = await repository(
        recorded: recorded,
        rows: {
          // Déjà en ordre de niveau croissant, comme le renverrait
          // `.order('level', ascending: true)` côté serveur réel.
          'class_features': [
            {
              'id': metamagicFeatureId3,
              'class_id': sorcererClassId,
              'level': 3,
              'choice_type': 'metamagie',
            },
            {
              'id': metamagicFeatureId10,
              'class_id': sorcererClassId,
              'level': 10,
              'choice_type': 'metamagie',
            },
            {
              'id': metamagicFeatureId17,
              'class_id': sorcererClassId,
              'level': 17,
              'choice_type': 'metamagie',
            },
          ],
          // Connue sous l'ancre de niveau 10 (cas limite : l'agrégation de
          // "déjà connu" doit chercher sur les 3 ids, pas seulement l'ancre
          // de niveau 3).
          'character_class_options': [
            {
              'chosen_value': 'Sort prolongé',
              'class_feature_id': metamagicFeatureId10,
            },
          ],
          'class_options': [
            {'id': 1, 'min_level': 3},
            {'id': 2, 'min_level': 3},
          ],
          'translations': [
            {'entity_id': '1', 'value': 'Sort prolongé'},
            {'entity_id': '2', 'value': 'Sort discret'},
          ],
        },
      );

      final options = await repo.fetchAvailableMetamagicOptions(
        characterId: characterId,
        classId: sorcererClassId,
        targetLevel: 3,
      );

      // `character_class_options` est interrogé via `.inFilter(...)`, ignoré
      // par ce double de test (voir sa documentation de classe) : le
      // résultat `options` ci-dessus ne permettrait donc pas seul de
      // détecter une régression qui résoudrait `class_features` via
      // `choice_type` seul. Vérifié ici directement sur la requête GET
      // enregistrée (D105 de `docs/dette-technique.md`).
      final classFeaturesReads = recorded
          .where((r) => r.table == 'class_features' && r.method == 'GET')
          .toList();
      expect(classFeaturesReads, hasLength(1));
      expect(
        classFeaturesReads.single.query['class_id'],
        'eq.$sorcererClassId',
      );
      expect(classFeaturesReads.single.query['choice_type'], 'eq.metamagie');

      expect(options, hasLength(1));
      expect(options.single.name, 'Sort discret');
    });
  });

  // Chantier "choix d'édition 2014/2024 par personnage" : Métamagie a
  // désormais 2 jeux de lignes `class_features` par classe (niveaux 3/10/17
  // en 2014, 2/10/17 en 2024) — les niveaux 10 et 17 sont communs aux deux
  // éditions avec des `id` DISTINCTS, jamais les deux à la fois pour un même
  // personnage (voir `EditionContentResolver`).
  group('SupabaseCharacterRepository.fetchAvailableMetamagicOptions — '
      'filtre par édition (EditionContentResolver)', () {
    const metamagicFeatureId2 = 1001;
    const metamagicFeatureId10Edition2024 = 1002;
    const metamagicFeatureId17Edition2024 = 1003;

    Map<String, List<Map<String, dynamic>>> rowsFor(String edition) => {
      'characters': [
        {'id': characterId, 'edition': edition},
      ],
      'class_features': [
        {
          'id': metamagicFeatureId3,
          'class_id': sorcererClassId,
          'level': 3,
          'choice_type': 'metamagie',
          'edition': '2014',
        },
        {
          'id': metamagicFeatureId10,
          'class_id': sorcererClassId,
          'level': 10,
          'choice_type': 'metamagie',
          'edition': '2014',
        },
        {
          'id': metamagicFeatureId17,
          'class_id': sorcererClassId,
          'level': 17,
          'choice_type': 'metamagie',
          'edition': '2014',
        },
        {
          'id': metamagicFeatureId2,
          'class_id': sorcererClassId,
          'level': 2,
          'choice_type': 'metamagie',
          'edition': '2024',
        },
        {
          'id': metamagicFeatureId10Edition2024,
          'class_id': sorcererClassId,
          'level': 10,
          'choice_type': 'metamagie',
          'edition': '2024',
        },
        {
          'id': metamagicFeatureId17Edition2024,
          'class_id': sorcererClassId,
          'level': 17,
          'choice_type': 'metamagie',
          'edition': '2024',
        },
      ],
      'class_options': [
        {'id': 1, 'min_level': 2},
      ],
      'translations': [
        {'entity_id': '1', 'value': 'Sort prolongé'},
      ],
    };

    // Le double de test HTTP de ce fichier ignore les filtres de requête
    // (`.inFilter(...)` compris, voir sa documentation de classe
    // `_buildSignedInFakeSupabaseClient`) : il est donc impossible de
    // vérifier ces 3 ids via le résultat retourné par `fetchKnownMetamagicNames`
    // elle-même (`character_class_options` renverrait ses lignes quels que
    // soient les ids demandés). On vérifie à la place directement la
    // requête GET enregistrée (`_Recorded.query`), qui porte bien les 3 ids
    // RÉSOLUS par [EditionContentResolver] avant tout filtrage serveur —
    // c'est ce calcul précis que ce correctif ajoute.
    test('personnage édition 2014 : la requête character_class_options filtre '
        'sur les 3 ids edition=2014 UNIQUEMENT (jamais les ids 2024, même '
        'niveau 10/17 communs aux deux éditions)', () async {
      final recorded = <_Recorded>[];
      final repo = await repository(recorded: recorded, rows: rowsFor('2014'));

      await repo.fetchKnownMetamagicNames(
        characterId: characterId,
        classId: sorcererClassId,
      );

      final reads = recorded
          .where(
            (r) => r.table == 'character_class_options' && r.method == 'GET',
          )
          .toList();
      expect(reads, hasLength(1));
      expect(
        reads.single.query['class_feature_id'],
        'in.($metamagicFeatureId3,$metamagicFeatureId10,$metamagicFeatureId17)',
      );
    });

    test('personnage édition 2024 : la requête character_class_options filtre '
        'sur les 3 ids edition=2024 UNIQUEMENT', () async {
      final recorded = <_Recorded>[];
      final repo = await repository(recorded: recorded, rows: rowsFor('2024'));

      await repo.fetchKnownMetamagicNames(
        characterId: characterId,
        classId: sorcererClassId,
      );

      final reads = recorded
          .where(
            (r) => r.table == 'character_class_options' && r.method == 'GET',
          )
          .toList();
      expect(reads, hasLength(1));
      expect(
        reads.single.query['class_feature_id'],
        'in.($metamagicFeatureId2,$metamagicFeatureId10Edition2024,'
        '$metamagicFeatureId17Edition2024)',
      );
    });

    test('applyLevelUp écrit sur l\'ancre de PLUS BAS niveau DE L\'ÉDITION '
        'DU PERSONNAGE (niveau 2 en 2024, pas niveau 3 de 2014)', () async {
      final recorded = <_Recorded>[];
      final repo = await repository(
        recorded: recorded,
        rows: {
          ...rowsFor('2024'),
          'character_classes': [
            {'id': 'cc-1', 'class_id': sorcererClassId, 'level': 9},
          ],
          'characters': [
            {
              'id': characterId,
              'edition': '2024',
              'max_hp': 10,
              'current_hp': 10,
            },
          ],
        },
      );

      await repo.applyLevelUp(
        characterId: characterId,
        classId: sorcererClassId,
        className: 'Ensorceleur',
        isMulticlassing: false,
        hpRolled: 4,
        hpMethod: 'roll',
        hpGain: 4,
        metamagicNames: const ['Sort foudroyant'],
      );

      final inserts = recorded
          .where(
            (r) => r.table == 'character_class_options' && r.method == 'POST',
          )
          .toList();
      expect(inserts, hasLength(1));
      final insertedRows = inserts.single.body as List<dynamic>;
      expect(insertedRows, hasLength(1));
      expect(
        insertedRows.single,
        containsPair('class_feature_id', metamagicFeatureId2),
      );
    });
  });

  group('SupabaseCharacterRepository.fetchKnownMetamagicNames', () {
    test(
      'agrège les chosen_value des 3 lignes class_features (3/10/17)',
      () async {
        final repo = await repository(
          rows: {
            'class_features': [
              {
                'id': metamagicFeatureId3,
                'class_id': sorcererClassId,
                'level': 3,
                'choice_type': 'metamagie',
              },
              {
                'id': metamagicFeatureId10,
                'class_id': sorcererClassId,
                'level': 10,
                'choice_type': 'metamagie',
              },
            ],
            'character_class_options': [
              {
                'chosen_value': 'Sort discret',
                'class_feature_id': metamagicFeatureId3,
              },
            ],
          },
        );

        final names = await repo.fetchKnownMetamagicNames(
          characterId: characterId,
          classId: sorcererClassId,
        );

        expect(names, ['Sort discret']);
      },
    );

    test(
      'aucune ligne class_features pour cette classe : liste vide',
      () async {
        final repo = await repository(rows: {'class_features': const []});

        final names = await repo.fetchKnownMetamagicNames(
          characterId: characterId,
          classId: sorcererClassId,
        );

        expect(names, isEmpty);
      },
    );
  });

  group('SupabaseCharacterRepository.applyLevelUp — metamagicNames', () {
    test(
      'écrit avec l\'ancre de PLUS BAS niveau (3), même au niveau 10',
      () async {
        final recorded = <_Recorded>[];
        final repo = await repository(
          recorded: recorded,
          rows: {
            'character_classes': [
              {'id': 'cc-1', 'class_id': sorcererClassId, 'level': 9},
            ],
            'characters': [
              {'max_hp': 10, 'current_hp': 10},
            ],
            'class_features': [
              // Leurre (voir sa documentation au début du fichier) : niveau
              // plus bas que toute ancre Ensorceleur, mais d'une AUTRE
              // classe — ne doit jamais être choisi comme ancre.
              {
                'id': decoyBardMetamagicFeatureId,
                'class_id': bardClassId,
                'level': 1,
                'choice_type': 'metamagie',
              },
              {
                'id': metamagicFeatureId3,
                'class_id': sorcererClassId,
                'level': 3,
                'choice_type': 'metamagie',
              },
              {
                'id': metamagicFeatureId10,
                'class_id': sorcererClassId,
                'level': 10,
                'choice_type': 'metamagie',
              },
            ],
          },
        );

        await repo.applyLevelUp(
          characterId: characterId,
          classId: sorcererClassId,
          className: 'Ensorceleur',
          isMulticlassing: false,
          hpRolled: 4,
          hpMethod: 'roll',
          hpGain: 4,
          metamagicNames: const ['Sort prolongé'],
        );

        final inserts = recorded
            .where(
              (r) => r.table == 'character_class_options' && r.method == 'POST',
            )
            .toList();
        expect(inserts, hasLength(1));
        final insertedRows = (inserts.single.body! as List)
            .cast<Map<String, dynamic>>();
        expect(insertedRows.single, {
          'character_id': characterId,
          'class_feature_id': metamagicFeatureId3,
          'level': 10,
          'chosen_value': 'Sort prolongé',
        });
      },
    );

    test('aucune ligne class_features pour cette classe : CharacterFailure '
        'explicite', () async {
      final repo = await repository(
        rows: {
          'character_classes': [
            {'id': 'cc-1', 'class_id': sorcererClassId, 'level': 9},
          ],
          'characters': [
            {'max_hp': 10, 'current_hp': 10},
          ],
          'class_features': const [],
        },
      );

      await expectLater(
        repo.applyLevelUp(
          characterId: characterId,
          classId: sorcererClassId,
          className: 'Ensorceleur',
          isMulticlassing: false,
          hpRolled: 4,
          hpMethod: 'roll',
          hpGain: 4,
          metamagicNames: const ['Sort prolongé'],
        ),
        throwsA(isA<CharacterFailure>()),
      );
    });
  });

  group('SupabaseCharacterRepository.applyLevelUp — metamagicSwap', () {
    test('supprime la ligne connue par id puis insère la nouvelle sous '
        "l'ancre de plus bas niveau", () async {
      final recorded = <_Recorded>[];
      final repo = await repository(
        recorded: recorded,
        rows: {
          'character_classes': [
            {'id': 'cc-1', 'class_id': sorcererClassId, 'level': 4},
          ],
          'characters': [
            {'max_hp': 10, 'current_hp': 10},
          ],
          'class_features': [
            // Leurre (voir sa documentation au début du fichier) : niveau
            // plus bas que l'ancre Ensorceleur, mais d'une AUTRE classe —
            // ne doit jamais être choisi comme ancre.
            {
              'id': decoyBardMetamagicFeatureId,
              'class_id': bardClassId,
              'level': 1,
              'choice_type': 'metamagie',
            },
            {
              'id': metamagicFeatureId3,
              'class_id': sorcererClassId,
              'level': 3,
              'choice_type': 'metamagie',
            },
          ],
          'character_class_options': [
            {
              'id': 'cco-1',
              'chosen_value': 'Sort discret',
              'class_feature_id': metamagicFeatureId3,
              'level': 3,
            },
          ],
        },
      );

      final result = await repo.applyLevelUp(
        characterId: characterId,
        classId: sorcererClassId,
        className: 'Ensorceleur',
        isMulticlassing: false,
        hpRolled: 4,
        hpMethod: 'roll',
        hpGain: 4,
        metamagicSwap: const LevelUpMetamagicSwap(
          removedName: 'Sort discret',
          addedName: 'Sort prolongé',
        ),
      );

      expect(result.newLevel, 5);

      final deletes = recorded
          .where(
            (r) => r.table == 'character_class_options' && r.method == 'DELETE',
          )
          .toList();
      expect(deletes, hasLength(1));
      expect(deletes.single.query['id'], 'eq.cco-1');

      final inserts = recorded
          .where(
            (r) => r.table == 'character_class_options' && r.method == 'POST',
          )
          .toList();
      expect(inserts, hasLength(1));
      expect(inserts.single.body, {
        'character_id': characterId,
        'class_feature_id': metamagicFeatureId3,
        'level': 5,
        'chosen_value': 'Sort prolongé',
      });
    });

    test('option retirée introuvable parmi les options connues : '
        'CharacterFailure explicite, aucune écriture', () async {
      final recorded = <_Recorded>[];
      final repo = await repository(
        recorded: recorded,
        rows: {
          'character_classes': [
            {'id': 'cc-1', 'class_id': sorcererClassId, 'level': 4},
          ],
          'characters': [
            {'max_hp': 10, 'current_hp': 10},
          ],
          'class_features': [
            {
              'id': metamagicFeatureId3,
              'class_id': sorcererClassId,
              'level': 3,
              'choice_type': 'metamagie',
            },
          ],
          'character_class_options': const [],
        },
      );

      await expectLater(
        repo.applyLevelUp(
          characterId: characterId,
          classId: sorcererClassId,
          className: 'Ensorceleur',
          isMulticlassing: false,
          hpRolled: 4,
          hpMethod: 'roll',
          hpGain: 4,
          metamagicSwap: const LevelUpMetamagicSwap(
            removedName: 'Option fantôme',
            addedName: 'Sort prolongé',
          ),
        ),
        throwsA(isA<CharacterFailure>()),
      );

      final writes = recorded
          .where(
            (r) => r.table == 'character_class_options' && r.method != 'GET',
          )
          .toList();
      expect(writes, isEmpty);
    });
  });

  group('SupabaseCharacterRepository.applyLevelUp — expertiseSkillIds', () {
    test('met à jour character_skill_proficiencies en "expertise", jamais '
        'character_class_options', () async {
      final recorded = <_Recorded>[];
      final repo = await repository(
        recorded: recorded,
        rows: {
          'character_classes': [
            {'id': 'cc-1', 'class_id': bardClassId, 'level': 9},
          ],
          'characters': [
            {'max_hp': 10, 'current_hp': 10},
          ],
          'class_features': const [],
          'character_skill_proficiencies': [
            {'skill_id': 1, 'proficiency': 'competente'},
            {'skill_id': 2, 'proficiency': 'competente'},
          ],
        },
      );

      await repo.applyLevelUp(
        characterId: characterId,
        classId: bardClassId,
        className: 'Barde',
        isMulticlassing: false,
        hpRolled: 4,
        hpMethod: 'roll',
        hpGain: 4,
        expertiseSkillIds: const [1, 2],
      );

      final updates = recorded
          .where(
            (r) =>
                r.table == 'character_skill_proficiencies' &&
                r.method == 'PATCH',
          )
          .toList();
      expect(updates, hasLength(1));
      expect(updates.single.body, {'proficiency': 'expertise'});

      final classOptionWrites = recorded
          .where(
            (r) => r.table == 'character_class_options' && r.method != 'GET',
          )
          .toList();
      expect(classOptionWrites, isEmpty);
    });

    test('compétence plus "competente" : CharacterFailure explicite, '
        'aucune écriture', () async {
      final recorded = <_Recorded>[];
      final repo = await repository(
        recorded: recorded,
        rows: {
          'character_classes': [
            {'id': 'cc-1', 'class_id': bardClassId, 'level': 9},
          ],
          'characters': [
            {'max_hp': 10, 'current_hp': 10},
          ],
          'class_features': const [],
          'character_skill_proficiencies': [
            {'skill_id': 1, 'proficiency': 'expertise'},
          ],
        },
      );

      await expectLater(
        repo.applyLevelUp(
          characterId: characterId,
          classId: bardClassId,
          className: 'Barde',
          isMulticlassing: false,
          hpRolled: 4,
          hpMethod: 'roll',
          hpGain: 4,
          expertiseSkillIds: const [1],
        ),
        throwsA(isA<CharacterFailure>()),
      );

      final updates = recorded
          .where(
            (r) =>
                r.table == 'character_skill_proficiencies' &&
                r.method == 'PATCH',
          )
          .toList();
      expect(updates, isEmpty);
    });
  });

  group('SupabaseCharacterRepository.applyLevelUp — '
      'Expertise du Roublard (compétences + substitution outils de voleur, '
      'chantier "choix d\'édition 2014/2024 par personnage" — réintroduit '
      'après D104 de docs/dette-technique.md)', () {
    test('niveau 6, aucune substitution : écrit uniquement les compétences '
        'choisies, aucune ligne character_class_options pour les outils de '
        'voleur', () async {
      final recorded = <_Recorded>[];
      final repo = await repository(
        recorded: recorded,
        rows: {
          'character_classes': [
            {'id': 'cc-1', 'class_id': roguishClassId, 'level': 5},
          ],
          'characters': [
            {'max_hp': 10, 'current_hp': 10},
          ],
          'class_features': const [],
          'character_skill_proficiencies': [
            {'skill_id': 1, 'proficiency': 'competente'},
            {'skill_id': 2, 'proficiency': 'competente'},
          ],
        },
      );

      await repo.applyLevelUp(
        characterId: characterId,
        classId: roguishClassId,
        className: 'Roublard',
        isMulticlassing: false,
        hpRolled: 4,
        hpMethod: 'roll',
        hpGain: 4,
        expertiseSkillIds: const [1, 2],
      );

      final updates = recorded
          .where(
            (r) =>
                r.table == 'character_skill_proficiencies' &&
                r.method == 'PATCH',
          )
          .toList();
      expect(updates, hasLength(1));
      expect(updates.single.body, {'proficiency': 'expertise'});

      final classOptionWrites = recorded
          .where(
            (r) => r.table == 'character_class_options' && r.method != 'GET',
          )
          .toList();
      expect(classOptionWrites, isEmpty);
    });

    test('niveau 6, substitution demandée : écrit un marqueur texte libre '
        'résolu via class_id + level', () async {
      final recorded = <_Recorded>[];
      const roguishExpertiseFeatureId = 303;
      final repo = await repository(
        recorded: recorded,
        rows: {
          'character_classes': [
            {'id': 'cc-1', 'class_id': roguishClassId, 'level': 5},
          ],
          'characters': [
            {'max_hp': 10, 'current_hp': 10},
          ],
          'class_features': [
            {
              'id': roguishExpertiseFeatureId,
              'class_id': roguishClassId,
              'level': 6,
              'choice_type': 'expertise',
            },
          ],
        },
      );

      await repo.applyLevelUp(
        characterId: characterId,
        classId: roguishClassId,
        className: 'Roublard',
        isMulticlassing: false,
        hpRolled: 4,
        hpMethod: 'roll',
        hpGain: 4,
        expertiseThievesToolsSubstitution: true,
      );

      final inserts = recorded
          .where(
            (r) => r.table == 'character_class_options' && r.method == 'POST',
          )
          .toList();
      expect(inserts, hasLength(1));
      expect(inserts.single.body, {
        'character_id': characterId,
        'class_feature_id': roguishExpertiseFeatureId,
        'level': 6,
        'chosen_value': 'Outils de voleur',
      });
    });
  });

  group(
    'SupabaseCharacterRepository.fetchAvailableDraconicAncestryOptions',
    () {
      test(
        'filtre par subclass_id et ignore une ligne sans damage_type',
        () async {
          final repo = await repository(
            rows: {
              'class_options': [
                {
                  'id': 1,
                  'min_level': 1,
                  'prerequisites': {'damage_type': 'feu'},
                },
                {'id': 2, 'min_level': 1},
              ],
              'translations': [
                {'entity_id': '1', 'value': 'Dragon rouge'},
                {'entity_id': '2', 'value': 'Sans type'},
              ],
            },
          );

          final options = await repo.fetchAvailableDraconicAncestryOptions(
            subclassId: draconicBloodlineSubclassId,
          );

          expect(options, hasLength(1));
          expect(options.single.name, 'Dragon rouge');
          expect(options.single.damageType, 'feu');
        },
      );
    },
  );

  group(
    'SupabaseCharacterRepository.applyLevelUp — draconicAncestryDamageType',
    () {
      test('résout la ligne class_features via choice_type SEUL (aptitude '
          'de SOUS-CLASSE)', () async {
        final recorded = <_Recorded>[];
        final repo = await repository(
          recorded: recorded,
          rows: {
            'character_classes': [
              {'id': 'cc-1', 'class_id': sorcererClassId, 'level': 0},
            ],
            'characters': [
              {'max_hp': 10, 'current_hp': 10},
            ],
            'class_features': [
              {
                'id': draconicAncestryFeatureId,
                'class_id': null,
                'subclass_id': draconicBloodlineSubclassId,
                'choice_type': 'ancetre_draconique',
              },
            ],
          },
        );

        await repo.applyLevelUp(
          characterId: characterId,
          classId: sorcererClassId,
          className: 'Ensorceleur',
          isMulticlassing: false,
          hpRolled: 4,
          hpMethod: 'roll',
          hpGain: 4,
          draconicAncestryDamageType: 'feu',
        );

        final inserts = recorded
            .where(
              (r) => r.table == 'character_class_options' && r.method == 'POST',
            )
            .toList();
        expect(inserts, hasLength(1));
        expect(inserts.single.body, {
          'character_id': characterId,
          'class_feature_id': draconicAncestryFeatureId,
          'level': 1,
          'chosen_value': 'feu',
        });
      });

      test(
        'ligne class_features introuvable : CharacterFailure explicite',
        () async {
          final repo = await repository(
            rows: {
              'character_classes': [
                {'id': 'cc-1', 'class_id': sorcererClassId, 'level': 0},
              ],
              'characters': [
                {'max_hp': 10, 'current_hp': 10},
              ],
              'class_features': const [],
            },
          );

          await expectLater(
            repo.applyLevelUp(
              characterId: characterId,
              classId: sorcererClassId,
              className: 'Ensorceleur',
              isMulticlassing: false,
              hpRolled: 4,
              hpMethod: 'roll',
              hpGain: 4,
              draconicAncestryDamageType: 'feu',
            ),
            throwsA(isA<CharacterFailure>()),
          );
        },
      );
    },
  );
}

/// Une requête PostgREST observée par le double de test.
class _Recorded {
  _Recorded({
    required this.method,
    required this.table,
    required this.query,
    required this.body,
  });

  final String method;
  final String table;
  final Map<String, String> query;

  /// Corps JSON décodé, `null` pour une requête sans corps.
  final Object? body;

  @override
  String toString() => '$method $table $query $body';
}

class _FakeConnectivityChecker implements ConnectivityChecker {
  _FakeConnectivityChecker({required this.connected});

  final bool connected;

  @override
  Future<bool> hasConnection() async => connected;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}

/// Double « léger » (même principe que
/// `character_repository_level_up_arcane_shots_runes_infusions_test.dart`) :
/// les lignes configurées via [tableRows] sont retournées pour une requête
/// `GET` sur la table correspondante SI ELLES PASSENT les filtres `.eq(...)`
/// réellement envoyés (voir [_rowMatchesEqFilters] — D105 de
/// `docs/dette-technique.md`, corrigé : avant cette correction, TOUS les
/// filtres étaient ignorés, y compris `.eq('class_id', classId)`). Les
/// filtres non `.eq(...)` (`.order(...)`, `.lte(...)`, `.inFilter(...)`)
/// restent ignorés — les fixtures de ce fichier fournissent donc déjà les
/// lignes `class_features` triées par `level` croissant, exactement comme le
/// ferait le serveur réel.
Future<SupabaseClient> _buildSignedInFakeSupabaseClient({
  required String ownerId,
  required List<_Recorded> recorded,
  Map<String, List<Map<String, dynamic>>> tableRows = const {},
}) async {
  Future<http.Response> handler(http.Request request) async {
    final table = request.url.pathSegments.last;
    recorded.add(
      _Recorded(
        method: request.method,
        table: table,
        query: request.url.queryParameters,
        body: request.body.isEmpty ? null : jsonDecode(request.body),
      ),
    );
    final configuredRows = tableRows[table] ?? const <Map<String, dynamic>>[];
    final rows = request.method == 'GET'
        ? configuredRows
              .where(
                (row) => _rowMatchesEqFilters(row, request.url.queryParameters),
              )
              .toList()
        : const <Map<String, dynamic>>[];
    return http.Response(
      jsonEncode(rows),
      200,
      request: request,
      headers: {'content-type': 'application/json; charset=utf-8'},
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

/// Un filtre `.eq(colonne, valeur)` PostgREST s'encode `colonne=eq.valeur`
/// dans la query string (ex. `.eq('class_id', 12)` devient `class_id=eq.12`)
/// — reconnu ici via le préfixe `eq.`. Une ligne qui NE DÉCLARE PAS la
/// colonne filtrée est considérée comme passant le filtre (beaucoup de
/// fixtures de ce fichier omettent délibérément les colonnes non pertinentes
/// pour leur scénario, ex. `option_type`/`class_id` sur des lignes
/// `class_options` — ne pas les exiger évite de devoir réécrire toutes les
/// fixtures existantes) ; une ligne qui déclare la colonne doit avoir
/// exactement la valeur demandée. Les filtres `.inFilter(...)` (encodés
/// `in.(...)`), `.lte(...)`, `.order(...)` restent ignorés (hors périmètre
/// de D105).
///
/// **Divergence délibérée** par rapport à `_matchesEq` de
/// `character_repository_level_up_elemental_disciplines_test.dart`, qui
/// implémente la sémantique SQL/PostgREST EXACTE d'un `eq` (une colonne
/// absente/NULL ne correspond JAMAIS à un filtre `.eq(...)`, précisément le
/// comportement qui a produit la régression D86) : ici, une colonne ABSENTE
/// passe le filtre. Conséquence directe pour tout futur scénario de ce
/// fichier : une nouvelle ligne `class_features` DOIT déclarer explicitement
/// `class_id`/`choice_type` (même `null`) pour rester couverte par ce
/// filtrage — l'omettre repasse silencieusement cette ligne en mode
/// permissif et rouvre le trou que D105 vient de fermer.
bool _rowMatchesEqFilters(Map<String, dynamic> row, Map<String, String> query) {
  for (final entry in query.entries) {
    if (!entry.value.startsWith('eq.')) continue;
    if (!row.containsKey(entry.key)) continue;
    final expected = entry.value.substring(3);
    if (row[entry.key]?.toString() != expected) return false;
  }
  return true;
}
