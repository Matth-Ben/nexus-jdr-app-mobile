// Déclenchement du préchargement des fiches (V5-5) par `charactersProvider` :
// après la liste, en arrière-plan, sans jamais changer l'état de la liste.

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/features/characters/data/character_detail_prefetcher.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';

class _FakeRepository extends Fake implements CharacterRepository {
  _FakeRepository(this.list);

  final List<CharacterSummary> list;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => list;
}

class _Connectivity implements ConnectivityChecker {
  @override
  Future<bool> hasConnection() async => true;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

CharacterSummary _summary(String id, {bool isArchived = false}) =>
    CharacterSummary(id: id, name: id, level: 1, xp: 0, isArchived: isArchived);

void main() {
  late AppDatabase db;
  late List<String> fetched;
  late Completer<void> gate;
  late Future<void> Function(String id) onFetch;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fetched = [];
    gate = Completer<void>();
    onFetch = (_) async {};
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer container(List<CharacterSummary> list) {
    final c = ProviderContainer(
      overrides: [
        characterRepositoryProvider.overrideWithValue(_FakeRepository(list)),
        characterDetailPrefetcherProvider.overrideWithValue(
          CharacterDetailPrefetcher(
            cache: ReferenceDataCache(db),
            pendingWrites: PendingCharacterWriteQueue(db),
            connectivity: _Connectivity(),
            currentOwnerId: () => 'owner-1',
            concurrency: 1,
            fetchDetail: (id) async {
              fetched.add(id);
              await onFetch(id);
            },
          ),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  test('la liste est servie, puis les fiches en jeu sont préchargées en '
      'arrière-plan', () async {
    final c = container([_summary('a'), _summary('b', isArchived: true)]);
    final sub = c.listen(charactersProvider, (_, _) {});

    final list = await c.read(charactersProvider.future);
    expect(list.map((s) => s.id), ['a', 'b']);
    expect(c.read(charactersProvider).hasError, isFalse);

    await settle();
    expect(fetched, ['a']);
    sub.close();
  });

  test(
    'une erreur de préchargement ne change jamais l\'état de la liste',
    () async {
      onFetch = (_) async => throw const CharacterFailure('boom');
      final c = container([_summary('a')]);
      final sub = c.listen(charactersProvider, (_, _) {});

      await c.read(charactersProvider.future);
      await settle();

      expect(fetched, ['a']);
      expect(c.read(charactersProvider).hasError, isFalse);
      expect(c.read(charactersProvider).hasValue, isTrue);
      sub.close();
    },
  );

  test('liste fermée (écran démonté) pendant le préchargement : les fiches '
      'suivantes ne sont plus demandées', () async {
    onFetch = (_) => gate.future;
    final c = container([_summary('a'), _summary('b'), _summary('c')]);
    final sub = c.listen(charactersProvider, (_, _) {});

    await c.read(charactersProvider.future);
    await settle();
    expect(fetched, ['a']);

    sub.close();
    await settle(); // autoDispose : la liste n'est plus écoutée.
    gate.complete();
    await settle();

    expect(fetched, ['a']);
  });
}
