import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/cache_providers.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/core/sync/relative_sync_time.dart';
import 'package:personnages/core/sync/sync_alerts_panel_providers.dart';
import 'package:personnages/core/sync/sync_status_providers.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/l10n/app_localizations_en.dart';
import 'package:personnages/l10n/app_localizations_fr.dart';

SyncAlert _alert(int id, DateTime createdAt) => SyncAlert(
  id: id,
  ownerId: 'owner-1',
  kind: SyncAlertKind.abandon,
  characterId: 'c$id',
  characterName: 'N$id',
  dataKind: 'hp',
  serverValue: null,
  createdAt: createdAt,
);

CharacterSummary _character(String id) => CharacterSummary(
  id: id,
  name: id,
  raceName: 'Elfe',
  className: 'Magicienne',
  level: 1,
  xp: 0,
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr');
    await initializeDateFormatting('en');
  });

  group('sortSyncAlertsNewestFirst', () {
    test('createdAt décroissant, puis id décroissant à date égale', () {
      final t = DateTime.utc(2026, 11, 12, 10);
      final input = [
        _alert(1, t),
        _alert(2, t.add(const Duration(hours: 1))),
        _alert(3, t),
        _alert(4, t.subtract(const Duration(hours: 1))),
      ];
      expect(sortSyncAlertsNewestFirst(input).map((a) => a.id), [2, 3, 1, 4]);
    });

    test('ne modifie pas la liste reçue et gère le vide', () {
      final t = DateTime.utc(2026, 11, 12);
      final input = [_alert(1, t), _alert(2, t)];
      sortSyncAlertsNewestFirst(input);
      expect(input.map((a) => a.id), [1, 2]);
      expect(sortSyncAlertsNewestFirst(const []), isEmpty);
    });
  });

  group('sortedSyncAlertsProvider', () {
    test('flux du compte connecté, trié ; vide sans compte', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      var clock = DateTime.utc(2026, 11, 12, 9);
      final store = SyncAlertStore(db, now: () => clock);
      Future<void> add(String name) => store.add(
        ownerId: 'owner-1',
        kind: SyncAlertKind.abandon,
        characterId: 'c-$name',
        characterName: name,
        dataKind: 'hp',
      );
      await add('Ancienne');
      clock = DateTime.utc(2026, 11, 12, 11);
      await add('Récente');

      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncOwnerIdProvider.overrideWithValue('owner-1'),
        ],
      );
      addTearDown(container.dispose);
      final keep = container.listen(sortedSyncAlertsProvider, (_, _) {});
      addTearDown(keep.close);
      final sorted = await container.read(sortedSyncAlertsProvider.future);
      expect(sorted.map((a) => a.characterName), ['Récente', 'Ancienne']);
      // Le flux du moteur (ordre d'insertion) n'est pas affecté.
      final keepRaw = container.listen(syncAlertsProvider, (_, _) {});
      addTearDown(keepRaw.close);
      final raw = await container.read(syncAlertsProvider.future);
      expect(raw.map((a) => a.characterName), ['Ancienne', 'Récente']);

      final anonymous = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncOwnerIdProvider.overrideWithValue(null),
        ],
      );
      addTearDown(anonymous.dispose);
      final keepAnon = anonymous.listen(sortedSyncAlertsProvider, (_, _) {});
      addTearDown(keepAnon.close);
      expect(await anonymous.read(sortedSyncAlertsProvider.future), isEmpty);
    });
  });

  group('knownCharacterIdsProvider (orphelines)', () {
    test('liste non vivante : inconnu, et le panneau ne déclenche pas son '
        'chargement (aucun appel réseau)', () {
      var loads = 0;
      final container = ProviderContainer(
        overrides: [
          charactersProvider.overrideWith((ref) async {
            loads++;
            return const <CharacterSummary>[];
          }),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(knownCharacterIdsProvider), isNull);
      expect(container.exists(charactersProvider), isFalse);
      expect(loads, 0);
    });

    test('liste vivante : inconnu pendant le chargement (jamais de faux '
        'positif), puis l\'ensemble des ids', () async {
      final completer = Completer<List<CharacterSummary>>();
      final container = ProviderContainer(
        overrides: [charactersProvider.overrideWith((ref) => completer.future)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(charactersProvider, (_, _) {});
      addTearDown(sub.close);

      expect(container.read(knownCharacterIdsProvider), isNull);

      completer.complete([_character('a'), _character('b')]);
      await container.read(charactersProvider.future);
      expect(container.read(knownCharacterIdsProvider), {'a', 'b'});
    });

    test('liste en erreur : inconnu', () async {
      final container = ProviderContainer(
        overrides: [
          charactersProvider.overrideWith((ref) async => throw StateError('x')),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(charactersProvider, (_, _) {});
      addTearDown(sub.close);
      await expectLater(
        container.read(charactersProvider.future),
        throwsA(anything),
      );
      expect(container.read(knownCharacterIdsProvider), isNull);
    });
  });

  group('relativeSyncWhen (formules partagées avec « Dernière synchro »)', () {
    final fr = AppLocalizationsFr();
    final en = AppLocalizationsEn();
    final now = DateTime(2026, 11, 12, 12);

    String when(Duration ago, {bool english = false}) => relativeSyncWhen(
      english ? en : fr,
      instant: now.subtract(ago),
      now: now,
    );

    test('bornes : instant / minutes / heures / date absolue', () {
      expect(when(const Duration(seconds: 59)), 'à l\'instant');
      expect(when(const Duration(seconds: -30)), 'à l\'instant');
      expect(when(const Duration(minutes: 1)), 'il y a 1 min');
      expect(when(const Duration(minutes: 59)), 'il y a 59 min');
      expect(when(const Duration(hours: 1)), 'il y a 1 h');
      expect(when(const Duration(hours: 23, minutes: 59)), 'il y a 23 h');
      expect(
        relativeSyncWhen(fr, instant: DateTime(2026, 11, 7, 14, 32), now: now),
        '7 nov. 2026 à 14:32',
      );
    });

    test('anglais', () {
      expect(when(const Duration(seconds: 5), english: true), 'just now');
      expect(when(const Duration(minutes: 5), english: true), '5 min ago');
      expect(when(const Duration(hours: 3), english: true), '3 h ago');
    });
  });
}
