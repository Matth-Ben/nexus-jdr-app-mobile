// Préchargement des fiches pour le hors-ligne (V5-5) : ordre, concurrence,
// filtre « en jeu », fraîcheur, hors ligne, erreurs, annulation/changement de
// compte, écritures en attente. Base drift en mémoire, aucun réseau.

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/features/characters/data/character_detail_cache.dart';
import 'package:personnages/features/characters/data/character_detail_prefetcher.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';

const _owner = 'owner-1';

CharacterSummary _summary(
  String id, {
  bool isDead = false,
  bool isArchived = false,
}) => CharacterSummary(
  id: id,
  name: 'Perso $id',
  raceName: 'Humain',
  className: 'Guerrier',
  level: 1,
  xp: 0,
  isDead: isDead,
  isArchived: isArchived,
);

class _FakeConnectivity implements ConnectivityChecker {
  bool connected = true;

  /// Appelé à chaque `hasConnection` (permet de changer d'état pendant les
  /// lectures asynchrones du préchargeur).
  void Function()? onCheck;

  @override
  Future<bool> hasConnection() async {
    onCheck?.call();
    return connected;
  }

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

void main() {
  late AppDatabase db;
  late ReferenceDataCache cache;
  late PendingCharacterWriteQueue pending;
  late _FakeConnectivity connectivity;
  late String? owner;
  late List<String> fetched;
  late int inFlight;
  late int maxInFlight;
  late Future<void> Function(String id) onFetch;
  late DateTime clock;
  var cancelled = false;

  CharacterDetailPrefetcher build({int concurrency = 2}) =>
      CharacterDetailPrefetcher(
        cache: cache,
        pendingWrites: pending,
        connectivity: connectivity,
        currentOwnerId: () => owner,
        concurrency: concurrency,
        now: () => clock,
        fetchDetail: (id) async {
          fetched.add(id);
          inFlight++;
          if (inFlight > maxInFlight) maxInFlight = inFlight;
          try {
            await onFetch(id);
          } finally {
            inFlight--;
          }
        },
      );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cache = ReferenceDataCache(db);
    pending = PendingCharacterWriteQueue(db);
    connectivity = _FakeConnectivity();
    owner = _owner;
    fetched = [];
    inFlight = 0;
    maxInFlight = 0;
    cancelled = false;
    clock = DateTime.now();
    onFetch = (_) => Future<void>.delayed(const Duration(milliseconds: 5));
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> run(
    CharacterDetailPrefetcher p,
    List<CharacterSummary> list, {
    Map<String, int> lastOpened = const {},
  }) => p.prefetch(list, isCancelled: () => cancelled, lastOpened: lastOpened);

  test('précharge uniquement les personnages en jeu, dans l\'ordre', () async {
    await run(build(concurrency: 1), [
      _summary('a'),
      _summary('b', isDead: true),
      _summary('c', isArchived: true),
      _summary('d'),
    ]);

    expect(fetched, ['a', 'd']);
  });

  test(
    'la concurrence ne dépasse jamais 2 et toutes les fiches passent',
    () async {
      await run(build(), [for (var i = 0; i < 7; i++) _summary('c$i')]);

      expect(fetched.toSet(), {for (var i = 0; i < 7; i++) 'c$i'});
      expect(fetched.length, 7);
      expect(maxInFlight, 2);
    },
  );

  test('une fiche en cache fraîche n\'est pas retéléchargée', () async {
    await cache.put(
      CharacterDetailCache.keyFor(ownerId: _owner, characterId: 'a'),
      {'row': <String, dynamic>{}},
    );

    await run(build(), [_summary('a'), _summary('b')]);

    expect(fetched, ['b']);
  });

  test('une fiche en cache périmée est retéléchargée', () async {
    await cache.put(
      CharacterDetailCache.keyFor(ownerId: _owner, characterId: 'a'),
      {'row': <String, dynamic>{}},
    );
    clock = clock.add(const Duration(minutes: 16));

    await run(build(), [_summary('a')]);

    expect(fetched, ['a']);
  });

  test('la fraîcheur est propre au compte : la fiche d\'un autre compte '
      'ne compte pas', () async {
    await cache.put(
      CharacterDetailCache.keyFor(ownerId: 'autre', characterId: 'a'),
      {'row': <String, dynamic>{}},
    );

    await run(build(), [_summary('a')]);

    expect(fetched, ['a']);
  });

  test('hors ligne : rien n\'est lancé', () async {
    connectivity.connected = false;

    await run(build(), [_summary('a'), _summary('b')]);

    expect(fetched, isEmpty);
  });

  test('perte du réseau en cours de route : les fiches restantes ne sont '
      'pas demandées', () async {
    onFetch = (id) async {
      connectivity.connected = false;
    };

    await run(build(concurrency: 1), [
      _summary('a'),
      _summary('b'),
      _summary('c'),
    ]);

    expect(fetched, ['a']);
  });

  test('une erreur sur une fiche ne bloque pas les suivantes et ne remonte '
      'jamais', () async {
    onFetch = (id) async {
      if (id == 'b') throw StateError('boom');
    };

    await run(build(concurrency: 1), [
      _summary('a'),
      _summary('b'),
      _summary('c'),
    ]);

    expect(fetched, ['a', 'b', 'c']);
  });

  test('annulé avant le début : aucune fiche demandée', () async {
    cancelled = true;

    await run(build(), [_summary('a')]);

    expect(fetched, isEmpty);
  });

  test('annulé en cours de route : plus aucune fiche demandée', () async {
    onFetch = (id) async {
      cancelled = true;
    };

    await run(build(concurrency: 1), [_summary('a'), _summary('b')]);

    expect(fetched, ['a']);
  });

  test('déconnexion en cours de route : plus aucune fiche demandée', () async {
    onFetch = (id) async {
      owner = null;
    };

    await run(build(concurrency: 1), [_summary('a'), _summary('b')]);

    expect(fetched, ['a']);
  });

  test('changement de compte en cours de route : aucune fiche demandée pour '
      'le nouveau compte', () async {
    final fetchedForOwner = <String, String?>{};
    final prefetcher = CharacterDetailPrefetcher(
      cache: cache,
      pendingWrites: pending,
      connectivity: connectivity,
      currentOwnerId: () => owner,
      concurrency: 1,
      fetchDetail: (id) async {
        // Le dépôt réel écrit le cache sous le compte courant à cet instant.
        fetchedForOwner[id] = owner;
        owner = 'owner-2';
      },
    );

    await run(prefetcher, [_summary('a'), _summary('b'), _summary('c')]);

    expect(fetchedForOwner, {'a': _owner});
  });

  test('aucun compte connecté : rien n\'est lancé', () async {
    owner = null;

    await run(build(), [_summary('a')]);

    expect(fetched, isEmpty);
  });

  test('un personnage avec des écritures en attente est ignoré (le cache, '
      'base de la détection de conflit, n\'est pas rafraîchi)', () async {
    await pending.enqueue(
      characterId: 'a',
      ownerId: _owner,
      kind: PendingCharacterWriteKind.hp,
      targetId: '',
      payload: {'currentHp': 3, 'temporaryHp': 0},
    );

    await run(build(), [_summary('a'), _summary('b')]);

    expect(fetched, ['b']);
  });

  test('une écriture en attente d\'un autre compte ne bloque pas', () async {
    await pending.enqueue(
      characterId: 'a',
      ownerId: 'autre',
      kind: PendingCharacterWriteKind.hp,
      targetId: '',
      payload: {'currentHp': 3, 'temporaryHp': 0},
    );

    await run(build(), [_summary('a')]);

    expect(fetched, ['a']);
  });

  test('plafond de 10 fiches par passage', () async {
    await run(build(), [for (var i = 0; i < 14; i++) _summary('c$i')]);

    expect(fetched.length, 10);
    expect(fetched.toSet(), {for (var i = 0; i < 10; i++) 'c$i'});
  });

  test('priorité du plafond : les plus récemment ouvertes d\'abord, puis '
      'l\'ordre de la liste', () async {
    await run(
      build(concurrency: 1),
      [for (var i = 0; i < 14; i++) _summary('c$i')],
      lastOpened: {'c13': 300, 'c12': 200, 'c11': 100},
    );

    expect(fetched.take(3), ['c13', 'c12', 'c11']);
    expect(fetched.length, 10);
    expect(fetched.skip(3), [for (var i = 0; i < 7; i++) 'c$i']);
    expect(fetched, isNot(contains('c10')));
  });

  test('une fiche déjà en vol (préchargement annulé puis relancé) n\'est '
      'pas demandée une seconde fois', () async {
    final gate = Completer<void>();
    onFetch = (_) => gate.future;
    final prefetcher = build(concurrency: 1);

    final first = run(prefetcher, [_summary('a')]);
    await pumpEventQueue();
    expect(fetched, ['a']);

    // Relance (autre instance de liste) pendant que la première fiche vole.
    await run(prefetcher, [_summary('a')]);
    expect(fetched, ['a']);

    gate.complete();
    await first;

    // Une fois terminée, la fiche peut de nouveau être demandée.
    await run(prefetcher, [_summary('a')]);
    expect(fetched, ['a', 'a']);
  });

  test('changement de compte pendant les lectures locales qui précèdent le '
      'départ : la fiche n\'est pas demandée', () async {
    // Le compte change juste après la vérification d'ouverture, avant la
    // seconde vérification (celle qui précède `fetchDetail`).
    connectivity.onCheck = () => owner = 'owner-2';

    await run(build(), [_summary('a')]);

    expect(fetched, isEmpty);
  });

  test('liste vide : rien à faire', () async {
    await run(build(), const []);

    expect(fetched, isEmpty);
  });
}
