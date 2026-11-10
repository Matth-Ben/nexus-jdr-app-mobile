import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart'
    hide PendingCharacterWrite;
import 'package:personnages/core/cache/pending_character_write_queue.dart';

/// Chantier hors-ligne T1 : ordre de lecture déterministe (constat b de la
/// relecture de la PR #248), kinds inconnus tolérés, abandons consommés avec
/// leur personnage (D186).
void main() {
  late AppDatabase db;
  late PendingCharacterWriteQueue queue;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = PendingCharacterWriteQueue(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertRaw({
    required String characterId,
    required DateTime queuedAt,
    String kind = 'hp',
    String targetId = '',
    String ownerId = 'owner-1',
    bool abandoned = false,
    String payload = '{"currentHp":1,"temporaryHp":0}',
    String? message,
  }) => db
      .into(db.pendingCharacterWrites)
      .insert(
        PendingCharacterWritesCompanion.insert(
          characterId: characterId,
          ownerId: ownerId,
          kind: kind,
          targetId: Value(targetId),
          payload: payload,
          queuedAt: queuedAt,
          abandoned: Value(abandoned),
          lastFailureMessage: Value(message),
        ),
      );

  test('allForOwner : trié par queuedAt, jamais par ordre physique ni par '
      'clé primaire', () async {
    // Ordre d'insertion (rowid) et ordre de clé primaire : a, b, c.
    // Ordre de mise en file : c, a, b.
    await insertRaw(
      characterId: 'a',
      queuedAt: DateTime.utc(2026, 11, 10, 12, 2),
    );
    await insertRaw(
      characterId: 'b',
      queuedAt: DateTime.utc(2026, 11, 10, 12, 3),
    );
    await insertRaw(
      characterId: 'c',
      queuedAt: DateTime.utc(2026, 11, 10, 12, 1),
    );

    final ids = (await queue.allForOwner('owner-1')).map((w) => w.characterId);

    expect(ids, ['c', 'a', 'b']);
  });

  test('allForOwner : à horodatage égal, ordre stable par personnage, kind '
      'puis cible', () async {
    final t = DateTime.utc(2026, 11, 10, 12);
    await insertRaw(characterId: 'b', queuedAt: t);
    await insertRaw(characterId: 'a', queuedAt: t, kind: 'xp');
    await insertRaw(
      characterId: 'a',
      queuedAt: t,
      kind: 'spell_slot',
      targetId: 'std_2',
    );
    await insertRaw(
      characterId: 'a',
      queuedAt: t,
      kind: 'spell_slot',
      targetId: 'std_1',
    );

    final keys = (await queue.allForOwner('owner-1'))
        .map((w) => '${w.characterId}|${w.kind.storageKey}|${w.targetId}');

    expect(keys, [
      'a|spell_slot|std_1',
      'a|spell_slot|std_2',
      'a|xp|',
      'b|hp|',
    ]);
  });

  test('forCharacter suit le même ordre', () async {
    await insertRaw(
      characterId: 'a',
      kind: 'xp',
      queuedAt: DateTime.utc(2026, 11, 10, 12, 2),
      payload: '{"newXp":5}',
    );
    await insertRaw(
      characterId: 'a',
      queuedAt: DateTime.utc(2026, 11, 10, 12, 1),
    );

    final kinds = (await queue.forCharacter(
      ownerId: 'owner-1',
      characterId: 'a',
    )).map((w) => w.kind);

    expect(kinds, [PendingCharacterWriteKind.hp, PendingCharacterWriteKind.xp]);
  });

  test('fromStorageKey : clé inconnue -> null, jamais d\'exception', () {
    expect(
      PendingCharacterWriteKind.fromStorageKey('hp'),
      PendingCharacterWriteKind.hp,
    );
    expect(PendingCharacterWriteKind.fromStorageKey('inventory'), isNull);
    expect(
      PendingCharacterWriteKind.fromStorageKey('currency'),
      PendingCharacterWriteKind.currency,
    );
    expect(PendingCharacterWriteKind.fromStorageKey(''), isNull);
  });

  test('allForOwner ignore une ligne de kind inconnu ou de payload illisible '
      'sans lever, et rend les autres', () async {
    final t = DateTime.utc(2026, 11, 10, 12);
    await insertRaw(characterId: 'a', queuedAt: t, kind: 'currency_v9');
    await insertRaw(characterId: 'b', queuedAt: t, payload: 'pas du json');
    await insertRaw(characterId: 'c', queuedAt: t);

    final pending = await queue.allForOwner('owner-1');

    expect(pending.map((w) => w.characterId), ['c']);
  });

  test('consumeAbandoned renvoie le personnage et le message de chaque '
      'entrée abandonnée, puis les supprime', () async {
    final t = DateTime.utc(2026, 11, 10, 12);
    await insertRaw(
      characterId: 'char-9',
      queuedAt: t,
      abandoned: true,
      message: 'refusé',
    );
    await insertRaw(characterId: 'char-actif', queuedAt: t);
    await insertRaw(
      characterId: 'char-autre-compte',
      queuedAt: t,
      ownerId: 'owner-2',
      abandoned: true,
      message: 'pas pour owner-1',
    );

    final abandoned = await queue.consumeAbandoned(ownerId: 'owner-1');

    expect(abandoned.map((a) => (a.characterId, a.message)), [
      ('char-9', 'refusé'),
    ]);
    expect(await queue.consumeAbandoned(ownerId: 'owner-1'), isEmpty);
    expect(await queue.allForOwner('owner-1'), hasLength(1));
    expect(await queue.consumeAbandonedMessages(ownerId: 'owner-2'), [
      'pas pour owner-1',
    ]);
  });

  test('abandonAfterConsecutiveFailures vaut 5 (littéral : changer ce seuil '
      'est une décision produit, pas un détail)', () {
    expect(PendingCharacterWriteQueue.abandonAfterConsecutiveFailures, 5);
  });
}
