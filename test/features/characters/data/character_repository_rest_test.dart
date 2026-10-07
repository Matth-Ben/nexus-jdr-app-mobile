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
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/spell_slot_progression.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `SupabaseCharacterRepository.applyRest` — recalcul des emplacements de
/// sorts (`character_spell_slots`) et de la magie de pacte
/// (`character_pact_slots`) au repos, personnage multiclassé inclus.
///
/// Non-régression du défaut "repos long multiclassé" : avant correctif,
/// `_resetSpellSlots` calculait les totaux depuis la seule classe primaire
/// (`SpellSlotProgression.slotsForLevel(className, niveau de la classe
/// primaire)`) — un Guerrier 5 / Magicien 3 ne récupérait donc jamais ses
/// emplacements au repos long, et un Clerc 3 / Magicien 2 voyait ses totaux
/// multiclasses écrasés à la baisse.
///
/// Même double `SupabaseClient`/`MockClient` que
/// `character_repository_test.dart` (voir sa documentation de classe pour le
/// rationale de la session factice), enrichi d'un journal des requêtes
/// d'écriture : ces tests vérifient ce qui est *envoyé* à PostgREST (aucune
/// base réelle), le comportement en base réelle relevant de
/// `test_integration/rest_repository_multiclass_integration_test.dart`.
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

  // Identifiants de classe arbitraires (seul le nom traduit compte pour
  // `SpellSlotProgression`).
  const classNamesById = <int, String>{
    1: 'Guerrier',
    2: 'Magicien',
    3: 'Clerc',
    4: 'Paladin',
    5: 'Occultiste',
    6: 'Rôdeur',
    7: 'Barde',
    8: 'Druide',
    9: 'Ensorceleur',
  };
  int idOf(String className) => classNamesById.entries
      .singleWhere((entry) => entry.value == className)
      .key;

  /// Applique un repos sur un personnage dont les classes sont [classes]
  /// (la première est la classe primaire, sauf [hasPrimary] à `false` :
  /// aucune ligne `is_primary`) et retourne le journal des requêtes émises.
  ///
  /// [untranslatedClassNames] : classes sans ligne `translations` (nom non
  /// résolu côté dépôt). [failOn] : requêtes auxquelles le double répond par
  /// une erreur 500. [journal] : journal fourni par l'appelant, pour le
  /// consulter même quand `applyRest` lève.
  Future<List<_Recorded>> applyRest({
    required List<({String className, int level})> classes,
    RestType type = RestType.long,
    List<Map<String, dynamic>> existingSlotRows = const [],
    String? classNameArgument,
    Set<String> untranslatedClassNames = const {},
    bool hasPrimary = true,
    bool Function(String method, String table)? failOn,
    List<_Recorded>? journal,
  }) async {
    final recorded = journal ?? <_Recorded>[];
    final client = await _buildSignedInFakeSupabaseClient(
      ownerId: ownerId,
      recorded: recorded,
      failOn: failOn,
      tableRows: {
        'characters': [
          {'id': characterId, 'max_hp': 30, 'current_hp': 12},
        ],
        'character_classes': [
          for (var i = 0; i < classes.length; i++)
            {
              'id': 'cc-$i',
              'class_id': idOf(classes[i].className),
              'level': classes[i].level,
              'is_primary': hasPrimary && i == 0,
              'hit_dice_spent': 0,
            },
        ],
        'translations': [
          for (final entry in classNamesById.entries)
            if (!untranslatedClassNames.contains(entry.value))
              {'entity_id': entry.key.toString(), 'value': entry.value},
        ],
        'character_spell_slots': existingSlotRows,
      },
    );
    final repository = SupabaseCharacterRepository(
      client,
      cache,
      pendingWrites,
      _OnlineConnectivityChecker(),
    );

    await repository.applyRest(
      characterId: characterId,
      type: type,
      // Même résolution que l'appelant réel
      // (`character_detail_screen.dart::_applyRest`) : le nom de la classe
      // primaire.
      className: classNameArgument ?? classes.first.className,
    );
    return recorded;
  }

  /// `{niveau d'emplacement: (total, utilisés)}` réellement upserté dans
  /// `character_spell_slots`, `null` si aucun upsert n'a été émis.
  Map<int, ({int total, int used})>? upsertedSlots(List<_Recorded> recorded) {
    final upserts = recorded
        .where((r) => r.table == 'character_spell_slots' && r.method == 'POST')
        .toList();
    if (upserts.isEmpty) return null;
    expect(
      upserts,
      hasLength(1),
      reason: 'un seul upsert character_spell_slots par repos',
    );
    final rows = (upserts.single.body as List<dynamic>)
        .cast<Map<String, dynamic>>();
    for (final row in rows) {
      expect(row['character_id'], characterId);
    }
    return {
      for (final row in rows)
        (row['slot_level'] as num).toInt(): (
          total: (row['slots_total'] as num).toInt(),
          used: (row['slots_used'] as num).toInt(),
        ),
    };
  }

  List<_Recorded> slotWrites(List<_Recorded> recorded) => recorded
      .where((r) => r.table == 'character_spell_slots' && r.method != 'GET')
      .toList();

  List<_Recorded> pactWrites(List<_Recorded> recorded) => recorded
      .where((r) => r.table == 'character_pact_slots' && r.method != 'GET')
      .toList();

  group('applyRest(long) — emplacements de sorts classiques', () {
    test('classe unique lanceuse (Magicien 5) : totaux de sa propre table, '
        'utilisés remis à 0 (non-régression)', () async {
      final recorded = await applyRest(
        classes: [(className: 'Magicien', level: 5)],
      );

      expect(upsertedSlots(recorded), {
        1: (total: 4, used: 0),
        2: (total: 3, used: 0),
        3: (total: 2, used: 0),
      });
      expect(slotWrites(recorded), hasLength(1));
    });

    test('classe unique demi-lanceuse (Rôdeur 5) : table des demi-lanceurs, '
        'pas le calcul combiné (non-régression)', () async {
      final recorded = await applyRest(
        classes: [(className: 'Rôdeur', level: 5)],
      );

      expect(upsertedSlots(recorded), {
        1: (total: 4, used: 0),
        2: (total: 2, used: 0),
      });
    });

    test('classe unique non lanceuse (Guerrier 5) : aucune écriture sur '
        'character_spell_slots, aucune erreur', () async {
      final recorded = await applyRest(
        classes: [(className: 'Guerrier', level: 5)],
      );

      expect(slotWrites(recorded), isEmpty);
      expect(pactWrites(recorded), isEmpty);
    });

    test(
      'multiclassé, primaire non lanceuse et secondaire lanceuse '
      '(Guerrier 5 / Magicien 3) : emplacements du Magicien 3 restaurés',
      () async {
        final recorded = await applyRest(
          classes: [
            (className: 'Guerrier', level: 5),
            (className: 'Magicien', level: 3),
          ],
        );

        expect(upsertedSlots(recorded), {
          1: (total: 4, used: 0),
          2: (total: 2, used: 0),
        });
      },
    );

    test('multiclassé, deux lanceuses complètes (Clerc 3 / Magicien 2) : '
        'niveau de lanceur combiné 5', () async {
      final recorded = await applyRest(
        classes: [
          (className: 'Clerc', level: 3),
          (className: 'Magicien', level: 2),
        ],
      );

      expect(upsertedSlots(recorded), {
        1: (total: 4, used: 0),
        2: (total: 3, used: 0),
        3: (total: 2, used: 0),
      });
    });

    test('multiclassé avec un demi-lanceur primaire (Paladin 4 / Magicien 3) '
        ': niveau de lanceur combiné 3 + 4 ~/ 2 = 5', () async {
      final recorded = await applyRest(
        classes: [
          (className: 'Paladin', level: 4),
          (className: 'Magicien', level: 3),
        ],
      );

      expect(upsertedSlots(recorded), {
        1: (total: 4, used: 0),
        2: (total: 3, used: 0),
        3: (total: 2, used: 0),
      });
    });

    test('multiclassé, demi-lanceur secondaire seul lanceur (Guerrier 3 / '
        'Rôdeur 5) : table propre du Rôdeur', () async {
      final recorded = await applyRest(
        classes: [
          (className: 'Guerrier', level: 3),
          (className: 'Rôdeur', level: 5),
        ],
      );

      expect(upsertedSlots(recorded), {
        1: (total: 4, used: 0),
        2: (total: 2, used: 0),
      });
    });

    test('lignes existantes hors calcul (Magicien 3, ligne de niveau 3 '
        'orpheline et total stocké supérieur au niveau 2) : la ligne '
        'orpheline garde son total mais ses utilisés repassent à 0, jamais '
        'supprimée ; les niveaux calculés sont réécrits', () async {
      final recorded = await applyRest(
        classes: [(className: 'Magicien', level: 3)],
        existingSlotRows: [
          {'slot_level': 1, 'slots_total': 4, 'slots_used': 2},
          {'slot_level': 2, 'slots_total': 5, 'slots_used': 3},
          {'slot_level': 3, 'slots_total': 2, 'slots_used': 1},
          {'slot_level': 4, 'slots_total': 1, 'slots_used': 0},
        ],
      );

      // Niveaux calculés (Magicien 3 = [4, 2]) : recalcul complet, comme
      // avant ce correctif — le total stocké 5 au niveau 2 est ramené à 2.
      expect(upsertedSlots(recorded), {
        1: (total: 4, used: 0),
        2: (total: 2, used: 0),
      });

      // Niveau 3 (hors calcul, 1 utilisé) : seul `slots_used` est remis à 0.
      // Niveau 4 (hors calcul, déjà 0 utilisé) : aucune écriture.
      final updates = recorded
          .where(
            (r) => r.table == 'character_spell_slots' && r.method == 'PATCH',
          )
          .toList();
      expect(updates, hasLength(1));
      expect(updates.single.body, {'slots_used': 0});
      expect(updates.single.query['character_id'], 'eq.$characterId');
      expect(updates.single.query['slot_level'], 'in.(3)');

      expect(
        recorded.where(
          (r) => r.table == 'character_spell_slots' && r.method == 'DELETE',
        ),
        isEmpty,
      );
    });

    test('classe unique non lanceuse avec une ligne orpheline consommée '
        '(Guerrier 5, ligne de niveau 1 à 2/2) : utilisés remis à 0, total '
        'conservé, aucun upsert', () async {
      final recorded = await applyRest(
        classes: [(className: 'Guerrier', level: 5)],
        existingSlotRows: [
          {'slot_level': 1, 'slots_total': 2, 'slots_used': 2},
        ],
      );

      expect(upsertedSlots(recorded), isNull);
      final writes = slotWrites(recorded);
      expect(writes, hasLength(1));
      expect(writes.single.method, 'PATCH');
      expect(writes.single.body, {'slots_used': 0});
      expect(writes.single.query['slot_level'], 'in.(1)');
    });
  });

  group('applyRest(long) — classe unique, non-régression exhaustive', () {
    // Oracle = formule du code d'origine (avant correctif "repos long
    // multiclassé") : `SpellSlotProgression.slotsForLevel(classe primaire,
    // niveau de la classe primaire)`, un seul upsert, aucune autre écriture.
    const singleCasterClasses = [
      'Barde',
      'Clerc',
      'Druide',
      'Ensorceleur',
      'Magicien',
      'Paladin',
      'Rôdeur',
    ];
    for (final className in singleCasterClasses) {
      for (final level in const [1, 2, 3, 5, 9, 11, 17, 20]) {
        test('$className $level : mêmes écritures que le calcul d\'origine '
            '(slotsForLevel de la classe primaire)', () async {
          final recorded = await applyRest(
            classes: [(className: className, level: level)],
          );

          final legacyTotals = SpellSlotProgression.slotsForLevel(
            className,
            level,
          );
          final expected = {
            for (var i = 0; i < legacyTotals.length; i++)
              if (legacyTotals[i] > 0) i + 1: (total: legacyTotals[i], used: 0),
          };
          expect(upsertedSlots(recorded), expected.isEmpty ? isNull : expected);
          final writes = slotWrites(recorded);
          expect(writes, hasLength(expected.isEmpty ? 0 : 1));
          for (final write in writes) {
            expect(write.method, 'POST');
            expect(write.query['on_conflict'], 'character_id,slot_level');
          }
          expect(pactWrites(recorded), isEmpty);
        });
      }
    }

    test('valeurs littérales de contrôle (indépendantes de la table codée) : '
        'Paladin 1 sans emplacement, Paladin 2, Barde 20', () async {
      final paladin1 = await applyRest(
        classes: [(className: 'Paladin', level: 1)],
      );
      expect(slotWrites(paladin1), isEmpty);

      final paladin2 = await applyRest(
        classes: [(className: 'Paladin', level: 2)],
      );
      expect(upsertedSlots(paladin2), {1: (total: 2, used: 0)});

      final barde20 = await applyRest(
        classes: [(className: 'Barde', level: 20)],
      );
      expect(upsertedSlots(barde20), {
        1: (total: 4, used: 0),
        2: (total: 3, used: 0),
        3: (total: 3, used: 0),
        4: (total: 3, used: 0),
        5: (total: 3, used: 0),
        6: (total: 2, used: 0),
        7: (total: 2, used: 0),
        8: (total: 1, used: 0),
        9: (total: 1, used: 0),
      });
    });

    test(
      'la lecture des lignes existantes est filtrée sur le personnage',
      () async {
        final recorded = await applyRest(
          classes: [(className: 'Magicien', level: 5)],
        );

        final reads = recorded
            .where(
              (r) => r.table == 'character_spell_slots' && r.method == 'GET',
            )
            .toList();
        expect(reads, hasLength(1));
        expect(reads.single.query['character_id'], 'eq.$characterId');
      },
    );
  });

  group('applyRest(long) — cas limites du multiclassage', () {
    test('trois classes lanceuses (Clerc 3 / Magicien 2 / Paladin 4) : niveau '
        'de lanceur combiné 3 + 2 + 4 ~/ 2 = 7', () async {
      final recorded = await applyRest(
        classes: [
          (className: 'Clerc', level: 3),
          (className: 'Magicien', level: 2),
          (className: 'Paladin', level: 4),
        ],
      );

      expect(upsertedSlots(recorded), {
        1: (total: 4, used: 0),
        2: (total: 3, used: 0),
        3: (total: 3, used: 0),
        4: (total: 1, used: 0),
      });
    });

    test('trois classes dont une seule lanceuse en dernière position '
        '(Guerrier 2 / Occultiste 2 / Magicien 3) : table propre du Magicien, '
        'pacte restauré à part', () async {
      final recorded = await applyRest(
        classes: [
          (className: 'Guerrier', level: 2),
          (className: 'Occultiste', level: 2),
          (className: 'Magicien', level: 3),
        ],
      );

      expect(upsertedSlots(recorded), {
        1: (total: 4, used: 0),
        2: (total: 2, used: 0),
      });
      expect(pactWrites(recorded).single.body, {
        'character_id': characterId,
        'slot_level': 1,
        'slots_total': 2,
        'slots_used': 0,
      });
    });

    test('aucune ligne is_primary (Magicien 5 non primaire) : emplacements '
        'tout de même recalculés, la classe étant nommée depuis translations '
        '(avant correctif : aucune écriture)', () async {
      final recorded = await applyRest(
        classes: [(className: 'Magicien', level: 5)],
        hasPrimary: false,
        classNameArgument: '',
      );

      expect(upsertedSlots(recorded), {
        1: (total: 4, used: 0),
        2: (total: 3, used: 0),
        3: (total: 2, used: 0),
      });
    });

    test('personnage sans aucune classe : repos appliqué sans erreur, aucune '
        'requête sur translations, character_spell_slots ni '
        'character_pact_slots', () async {
      final recorded = await applyRest(
        classes: const [],
        classNameArgument: '',
      );

      expect(
        recorded.where(
          (r) =>
              r.table == 'translations' ||
              r.table == 'character_spell_slots' ||
              r.table == 'character_pact_slots',
        ),
        isEmpty,
      );
      // Le repos lui-même aboutit : PV restaurés.
      final hpWrites = recorded
          .where((r) => r.table == 'characters' && r.method == 'PATCH')
          .toList();
      expect(hpWrites, hasLength(1));
      expect((hpWrites.single.body! as Map<String, dynamic>)['current_hp'], 30);
    });
  });

  group('applyRest(long) — classe secondaire dont la traduction manque '
      '(caractérisation du repli "chaîne vide = non lanceuse")', () {
    test('Guerrier 5 / Magicien 3 non traduit, lignes existantes : aucun '
        'recalcul, mais aucune perte — totaux conservés, utilisés remis à '
        '0, aucune suppression', () async {
      final recorded = await applyRest(
        classes: [
          (className: 'Guerrier', level: 5),
          (className: 'Magicien', level: 3),
        ],
        untranslatedClassNames: {'Magicien'},
        existingSlotRows: [
          {'slot_level': 1, 'slots_total': 4, 'slots_used': 3},
          {'slot_level': 2, 'slots_total': 2, 'slots_used': 2},
        ],
      );

      expect(upsertedSlots(recorded), isNull);
      final writes = slotWrites(recorded);
      expect(writes, hasLength(1));
      expect(writes.single.method, 'PATCH');
      expect(writes.single.body, {'slots_used': 0});
      expect(writes.single.query['slot_level'], 'in.(1,2)');
    });

    test('Guerrier 5 / Magicien 3 non traduit, aucune ligne existante : '
        'aucune écriture (les emplacements ne sont pas créés), aucune '
        'erreur', () async {
      final recorded = await applyRest(
        classes: [
          (className: 'Guerrier', level: 5),
          (className: 'Magicien', level: 3),
        ],
        untranslatedClassNames: {'Magicien'},
      );

      expect(slotWrites(recorded), isEmpty);
    });

    // Limite connue, pas une exigence : si ce test casse parce que le total
    // du niveau 2 reste à 3, c'est une amélioration ; mettre à jour
    // l'attente. Piste : quand un nom de classe manque, ne pas upserter les
    // totaux et seulement remettre les utilisés à 0.
    test('LIMITE CONNUE — Clerc 3 / Magicien 2 non traduit : repli sur le '
        'Clerc 3 seul — le total du niveau 2 est ramené de 3 à 2, la ligne '
        'de niveau 3 garde son total et n\'est jamais supprimée', () async {
      final recorded = await applyRest(
        classes: [
          (className: 'Clerc', level: 3),
          (className: 'Magicien', level: 2),
        ],
        untranslatedClassNames: {'Magicien'},
        existingSlotRows: [
          {'slot_level': 1, 'slots_total': 4, 'slots_used': 4},
          {'slot_level': 2, 'slots_total': 3, 'slots_used': 1},
          {'slot_level': 3, 'slots_total': 2, 'slots_used': 2},
        ],
      );

      expect(upsertedSlots(recorded), {
        1: (total: 4, used: 0),
        2: (total: 2, used: 0),
      });
      final patches = slotWrites(recorded)
          .where((r) => r.method == 'PATCH')
          .toList();
      expect(patches, hasLength(1));
      expect(patches.single.body, {'slots_used': 0});
      expect(patches.single.query['slot_level'], 'in.(3)');
      expect(slotWrites(recorded).where((r) => r.method == 'DELETE'), isEmpty);
    });
  });

  group('applyRest(long) — échecs d\'écriture sur character_spell_slots', () {
    test('échec de l\'upsert : CharacterFailure, et plus aucune écriture '
        'ensuite (PV non restaurés)', () async {
      final journal = <_Recorded>[];
      await expectLater(
        applyRest(
          classes: [(className: 'Magicien', level: 3)],
          failOn: (method, table) =>
              method == 'POST' && table == 'character_spell_slots',
          journal: journal,
        ),
        throwsA(isA<CharacterFailure>()),
      );

      final writes = journal.where((r) => r.method != 'GET').toList();
      expect(writes, hasLength(1));
      expect(writes.single.table, 'character_spell_slots');
      expect(writes.single.method, 'POST');
    });

    test('échec du PATCH des lignes hors calcul après un upsert réussi : '
        'CharacterFailure alors que les niveaux calculés sont déjà écrits, '
        'et plus aucune écriture ensuite (état partiel, rejouable)', () async {
      final journal = <_Recorded>[];
      await expectLater(
        applyRest(
          classes: [(className: 'Magicien', level: 3)],
          existingSlotRows: [
            {'slot_level': 3, 'slots_total': 2, 'slots_used': 1},
          ],
          failOn: (method, table) =>
              method == 'PATCH' && table == 'character_spell_slots',
          journal: journal,
        ),
        throwsA(isA<CharacterFailure>()),
      );

      final writes = journal.where((r) => r.method != 'GET').toList();
      expect(writes.map((r) => '${r.method} ${r.table}'), [
        'POST character_spell_slots',
        'PATCH character_spell_slots',
      ]);
    });
  });

  group('applyRest — magie de pacte et multiclassage', () {
    test('repos long, Occultiste 3 (primaire) / Magicien 2 : emplacements '
        'classiques = Magicien 2 seul (le pacte n\'entre pas dans le niveau '
        'combiné), pacte restauré séparément', () async {
      final recorded = await applyRest(
        classes: [
          (className: 'Occultiste', level: 3),
          (className: 'Magicien', level: 2),
        ],
      );

      expect(upsertedSlots(recorded), {1: (total: 3, used: 0)});
      final pact = pactWrites(recorded);
      expect(pact, hasLength(1));
      expect(pact.single.body, {
        'character_id': characterId,
        'slot_level': 2,
        'slots_total': 2,
        'slots_used': 0,
      });
    });

    test('repos long, Magicien 5 (primaire) / Occultiste 2 : emplacements '
        'classiques = Magicien 5 seul, pacte de niveau 1 x2', () async {
      final recorded = await applyRest(
        classes: [
          (className: 'Magicien', level: 5),
          (className: 'Occultiste', level: 2),
        ],
      );

      expect(upsertedSlots(recorded), {
        1: (total: 4, used: 0),
        2: (total: 3, used: 0),
        3: (total: 2, used: 0),
      });
      expect(pactWrites(recorded).single.body, {
        'character_id': characterId,
        'slot_level': 1,
        'slots_total': 2,
        'slots_used': 0,
      });
    });

    test('repos long, Occultiste seul : aucune écriture sur '
        'character_spell_slots, pacte restauré', () async {
      final recorded = await applyRest(
        classes: [(className: 'Occultiste', level: 5)],
      );

      expect(slotWrites(recorded), isEmpty);
      expect(pactWrites(recorded).single.body, {
        'character_id': characterId,
        'slot_level': 3,
        'slots_total': 2,
        'slots_used': 0,
      });
    });
  });

  group('applyRest(short)', () {
    test('multiclassé lanceur (Guerrier 5 / Magicien 3) : aucune requête sur '
        'character_spell_slots, ni lecture ni écriture', () async {
      final recorded = await applyRest(
        type: RestType.short,
        classes: [
          (className: 'Guerrier', level: 5),
          (className: 'Magicien', level: 3),
        ],
        existingSlotRows: [
          {'slot_level': 1, 'slots_total': 4, 'slots_used': 3},
        ],
      );

      expect(
        recorded.where((r) => r.table == 'character_spell_slots'),
        isEmpty,
      );
      expect(pactWrites(recorded), isEmpty);
    });

    test('Occultiste 3 / Magicien 2 : pacte restauré, emplacements classiques '
        'intacts', () async {
      final recorded = await applyRest(
        type: RestType.short,
        classes: [
          (className: 'Occultiste', level: 3),
          (className: 'Magicien', level: 2),
        ],
      );

      expect(
        recorded.where((r) => r.table == 'character_spell_slots'),
        isEmpty,
      );
      expect(pactWrites(recorded).single.body, {
        'character_id': characterId,
        'slot_level': 2,
        'slots_total': 2,
        'slots_used': 0,
      });
    });
  });
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

class _OnlineConnectivityChecker implements ConnectivityChecker {
  @override
  Future<bool> hasConnection() async => true;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}

/// Même principe que `_buildSignedInFakeSupabaseClient` de
/// `character_repository_test.dart` (routage par nom de table, session
/// factice sans réseau), avec en plus le journal [recorded] de chaque
/// requête. Une requête `maybeSingle()` reçoit le premier élément de
/// [tableRows] sous forme d'objet (en-tête `Accept` PostgREST dédié).
Future<SupabaseClient> _buildSignedInFakeSupabaseClient({
  required String ownerId,
  required List<_Recorded> recorded,
  Map<String, List<Map<String, dynamic>>> tableRows = const {},
  bool Function(String method, String table)? failOn,
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
    if (failOn != null && failOn(request.method, table)) {
      return http.Response(
        jsonEncode({'message': 'erreur simulée', 'code': 'XX000'}),
        500,
        request: request,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    final rows = tableRows[table] ?? const <Map<String, dynamic>>[];
    return http.Response(
      jsonEncode(request.method == 'GET' ? rows : const <Object>[]),
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
