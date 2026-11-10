import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart'
    hide PendingCharacterWrite;
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/features/characters/data/character_detail_cache.dart';
import 'package:personnages/features/characters/data/sync_alert_recorder.dart';

class _FailingAlertStore extends SyncAlertStore {
  _FailingAlertStore(super.db);

  @override
  Future<void> add({
    required String ownerId,
    required SyncAlertKind kind,
    required String characterId,
    required String characterName,
    required String dataKind,
    Map<String, dynamic>? serverValue,
  }) async => throw StateError('échec simulé de l\'insertion');
}

void main() {
  late AppDatabase db;
  late PendingCharacterWriteQueue queue;
  late ReferenceDataCache cache;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    queue = PendingCharacterWriteQueue(db);
    cache = ReferenceDataCache(db);
    await db
        .into(db.pendingCharacterWrites)
        .insert(
          PendingCharacterWritesCompanion.insert(
            characterId: 'c1',
            ownerId: 'owner-1',
            kind: 'hp',
            payload: '{"currentHp":1,"temporaryHp":0}',
            queuedAt: DateTime.utc(2026, 11, 10),
            failureCount: const Value(5),
            abandoned: const Value(true),
            lastFailureMessage: const Value('abandonnée'),
          ),
        );
  });

  tearDown(() => db.close());

  test('abandon : la ligne est consommée et l\'alerte insérée (nom et valeur '
      'du cache)', () async {
    await cache.put(
      CharacterDetailCache.keyFor(ownerId: 'owner-1', characterId: 'c1'),
      {
        CharacterDetailCache.rowKey: {
          'name': 'Aria',
          'current_hp': 7,
          'max_hp': 12,
        },
      },
    );
    final recorder = SyncAlertRecorder(
      db,
      queue,
      SyncAlertStore(db),
      CharacterDetailCache(cache),
    );

    final consumed = await recorder.recordAbandoned('owner-1');

    expect(consumed, hasLength(1));
    expect(await db.select(db.pendingCharacterWrites).get(), isEmpty);
    final alert = (await SyncAlertStore(db).allForOwner('owner-1')).single;
    expect(alert.characterName, 'Aria');
    expect(alert.serverValue, {'currentHp': 7, 'maxHp': 12});
  });

  test('atomicité : un échec à l\'insertion de l\'alerte ne perd PAS la ligne '
      'abandonnée (consommation annulée)', () async {
    final recorder = SyncAlertRecorder(
      db,
      queue,
      _FailingAlertStore(db),
      CharacterDetailCache(cache),
    );

    await expectLater(recorder.recordAbandoned('owner-1'), throwsStateError);

    final rows = await db.select(db.pendingCharacterWrites).get();
    expect(rows, hasLength(1));
    expect(rows.single.abandoned, isTrue);
    expect(await db.select(db.syncAlerts).get(), isEmpty);
  });
}
