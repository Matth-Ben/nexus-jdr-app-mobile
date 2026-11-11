import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/offline_journal_writes.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 10, 12);

  group('parseJournalPayload', () {
    test('ajout, modification, tombstone valides (aller-retour)', () {
      final add = parseJournalPayload(
        JournalWrite.add(body: 'Note', createdAt: createdAt).toPayload(),
      )!;
      expect(add.op, JournalWriteOp.add);
      expect(add.body, 'Note');
      expect(add.createdAt, createdAt);

      final update = parseJournalPayload(
        const JournalWrite.update(body: 'Autre').toPayload(),
      )!;
      expect(update.op, JournalWriteOp.update);
      expect(update.body, 'Autre');

      expect(
        parseJournalPayload(const JournalWrite.delete().toPayload())!.op,
        JournalWriteOp.delete,
      );
    });

    test('clés inconnues ignorées', () {
      expect(parseJournalPayload({'body': 'x', 'futur': 1}), isNotNull);
      expect(parseJournalPayload({'deleted': true, 'futur': 1}), isNotNull);
    });

    for (final bad in <Object?>[
      null,
      'texte',
      <Object?>[],
      <String, dynamic>{},
      {'body': ''},
      {'body': '  \n'},
      {'body': 1},
      {'body': null},
      {'deleted': false},
      {'deleted': 1},
      {'body': 'x', 'createdAt': 'nope'},
      {'body': 'x', 'createdAt': 5},
      {'body': 'x', 'createdAt': null},
    ]) {
      test('invalide : $bad', () => expect(parseJournalPayload(bad), isNull));
    }
  });

  group('planJournalWrite', () {
    final pendingAdd = JournalWrite.add(
      body: 'Brouillon',
      createdAt: createdAt,
    );
    const pendingUpdate = JournalWrite.update(body: 'Modifiée');
    const pendingDelete = JournalWrite.delete();

    test('modifier un ajout en attente : reste un ajout, date conservée', () {
      final plan = planJournalWrite(
        pending: pendingAdd,
        requested: const JournalWrite.update(body: 'Final'),
      );
      expect(plan.write!.op, JournalWriteOp.add);
      expect(plan.write!.body, 'Final');
      expect(plan.write!.createdAt, createdAt);
      expect(plan.cancelsPendingAdd, isFalse);
    });

    test('modifier sans ligne ou après une modification : modification', () {
      for (final pending in <JournalWrite?>[null, pendingUpdate]) {
        final plan = planJournalWrite(
          pending: pending,
          requested: const JournalWrite.update(body: 'N'),
        );
        expect(plan.write!.op, JournalWriteOp.update);
        expect(plan.write!.body, 'N');
      }
    });

    test('modifier une entrée déjà supprimée : refusé', () {
      expect(
        planJournalWrite(
          pending: pendingDelete,
          requested: const JournalWrite.update(body: 'N'),
        ).isRejected,
        isTrue,
      );
    });

    test('supprimer un ajout en attente : annule la ligne', () {
      final plan = planJournalWrite(
        pending: pendingAdd,
        requested: const JournalWrite.delete(),
      );
      expect(plan.cancelsPendingAdd, isTrue);
    });

    test('supprimer sinon : tombstone', () {
      for (final pending in <JournalWrite?>[
        null,
        pendingUpdate,
        pendingDelete,
      ]) {
        final plan = planJournalWrite(
          pending: pending,
          requested: const JournalWrite.delete(),
        );
        expect(plan.write!.op, JournalWriteOp.delete);
        expect(plan.cancelsPendingAdd, isFalse);
      }
    });

    test('ajout : tel quel', () {
      final plan = planJournalWrite(pending: null, requested: pendingAdd);
      expect(plan.write, same(pendingAdd));
    });
  });

  test('isValidJournalTargetId : UUID seulement', () {
    expect(
      isValidJournalTargetId('11111111-1111-4111-8111-111111111111'),
      isTrue,
    );
    expect(isValidJournalTargetId(''), isFalse);
    expect(isValidJournalTargetId('abc'), isFalse);
    expect(
      isValidJournalTargetId('11111111-1111-4111-8111-11111111111'),
      isFalse,
    );
  });
}
