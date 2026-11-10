// Tests de la machine à états du bandeau de synchro (T2 du chantier
// hors-ligne) : précédence, temporisations (1 s / 800 ms / 2 s / 3 s / 2 s) et
// règles de la spec DA. `testWidgets` + `tester.pump(Duration)` : le temps est
// celui du `FakeAsync` du banc de test, jamais une vraie attente.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/core/sync/sync_banner_engine.dart';

SyncAlert _alert(int id) => SyncAlert(
  id: id,
  ownerId: 'owner-1',
  kind: SyncAlertKind.abandon,
  characterId: 'c1',
  characterName: 'Aria',
  dataKind: 'hp',
  serverValue: const {'currentHp': 7, 'maxHp': 12},
  createdAt: DateTime.utc(2026, 11, 10),
);

const _ms = Duration(milliseconds: 1);

final _engines = <SyncBannerEngine>[];

/// `testWidgets` qui libère les moteurs créés AVANT la vérification des
/// timers en attente du banc de test.
void engineTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    _engines.clear();
    await body(tester);
    for (final e in _engines) {
      e.dispose();
    }
  });
}

SyncBannerKind _kind(SyncBannerEngine e) => e.state.kind;

void main() {
  late SyncBannerEngine engine;

  SyncBannerEngine build({bool showOfflineWhenEmpty = true}) {
    engine = SyncBannerEngine(showOfflineWhenEmpty: showOfflineWhenEmpty);
    _engines.add(engine);
    return engine;
  }

  engineTest('règle 1 : en ligne, rien en attente, aucune alerte -> rien '
      '(même après un long moment, jamais « Synchronisé »)', (tester) async {
    build();
    await tester.pump(const Duration(seconds: 30));
    expect(_kind(engine), SyncBannerKind.none);
  });

  engineTest('règle 4 : « en cours » pas avant 1 s continue, puis reste '
      '>= 800 ms', (tester) async {
    build();
    engine.setSyncing(true);
    await tester.pump(const Duration(milliseconds: 999));
    expect(_kind(engine), SyncBannerKind.none);

    // Une synchro de 999 ms ne clignote jamais.
    engine.setSyncing(false);
    await tester.pump(const Duration(seconds: 2));
    expect(_kind(engine), SyncBannerKind.none);

    engine.setSyncing(true);
    await tester.pump(const Duration(seconds: 1));
    expect(_kind(engine), SyncBannerKind.syncing);

    // Fin de synchro tout de suite après l'apparition : maintenu 800 ms.
    engine.setSyncing(false);
    await tester.pump(const Duration(milliseconds: 799));
    expect(_kind(engine), SyncBannerKind.syncing);
    await tester.pump(_ms);
    expect(_kind(engine), SyncBannerKind.none);
  });

  engineTest('« en cours » plus long que 1 s + 800 ms : suit la synchro', (
    tester,
  ) async {
    build();
    engine.setSyncing(true);
    await tester.pump(const Duration(seconds: 3));
    expect(_kind(engine), SyncBannerKind.syncing);
    engine.setSyncing(false);
    await tester.pump(_ms);
    expect(_kind(engine), SyncBannerKind.none);
  });

  engineTest('règle 5 : hors-ligne pas avant 2 s ; une coupure de 1 s ne '
      'clignote pas ; disparaît dès le retour du réseau', (tester) async {
    build();
    engine.setOnline(false);
    await tester.pump(const Duration(seconds: 1));
    engine.setOnline(true);
    await tester.pump(const Duration(seconds: 5));
    expect(_kind(engine), SyncBannerKind.none, reason: 'coupure de 1 s');

    engine.setOnline(false);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(_kind(engine), SyncBannerKind.none);
    await tester.pump(_ms);
    expect(engine.state.kind, SyncBannerKind.offline);
    expect(engine.state.pendingCount, 0);

    engine.setOnline(true);
    expect(
      _kind(engine),
      isNot(SyncBannerKind.offline),
      reason: 'immédiat au retour du réseau',
    );
  });

  engineTest('hors-ligne : N en direct', (tester) async {
    build();
    engine.setOnline(false);
    await tester.pump(const Duration(seconds: 2));
    engine.setPendingCount(2);
    expect(engine.state.pendingCount, 2);
    engine.setPendingCount(3);
    expect(engine.state.pendingCount, 3);
    expect(_kind(engine), SyncBannerKind.offline);
  });

  engineTest('décision (a) : liste (showOfflineWhenEmpty = false), hors-ligne '
      'avec N = 0 -> rien ; N > 0 -> bandeau', (tester) async {
    build(showOfflineWhenEmpty: false);
    engine.setOnline(false);
    await tester.pump(const Duration(seconds: 10));
    expect(_kind(engine), SyncBannerKind.none);

    engine.setPendingCount(1);
    expect(_kind(engine), SyncBannerKind.offline);
    expect(engine.state.pendingCount, 1);
  });

  engineTest('en attente en ligne : seulement si N > 0 depuis plus de 3 s', (
    tester,
  ) async {
    build();
    engine.setPendingCount(2);
    await tester.pump(const Duration(milliseconds: 2999));
    expect(_kind(engine), SyncBannerKind.none);
    await tester.pump(_ms);
    expect(_kind(engine), SyncBannerKind.pending);
    expect(engine.state.pendingCount, 2);

    // N revient à 0 avant 3 s : jamais affiché.
    final other = SyncBannerEngine(showOfflineWhenEmpty: true);
    _engines.add(other);
    other.setPendingCount(1);
    await tester.pump(const Duration(seconds: 2));
    other.setPendingCount(0);
    await tester.pump(const Duration(seconds: 5));
    expect(other.state.kind, SyncBannerKind.none);
  });

  engineTest('règle 6 : « Synchronisé » seulement après un état '
      'hors-ligne/attente, pendant 2 s puis rien', (tester) async {
    build();
    engine.setPendingCount(1);
    await tester.pump(const Duration(seconds: 3));
    expect(_kind(engine), SyncBannerKind.pending);

    engine.setPendingCount(0);
    expect(_kind(engine), SyncBannerKind.synced);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(_kind(engine), SyncBannerKind.synced);
    await tester.pump(_ms);
    expect(_kind(engine), SyncBannerKind.none);
  });

  engineTest('« Synchronisé » après un hors-ligne N = 0 de la fiche', (
    tester,
  ) async {
    build();
    engine.setOnline(false);
    await tester.pump(const Duration(seconds: 2));
    engine.setOnline(true);
    expect(_kind(engine), SyncBannerKind.synced);
  });

  engineTest('règle 3 : précédence alerte > en cours > hors-ligne > en '
      'attente > synchronisé > rien', (tester) async {
    build();
    engine.setOnline(false);
    engine.setPendingCount(1);
    await tester.pump(const Duration(seconds: 3));
    expect(_kind(engine), SyncBannerKind.offline);

    engine.setSyncing(true);
    await tester.pump(const Duration(seconds: 1));
    expect(
      _kind(engine),
      SyncBannerKind.syncing,
      reason: 'en cours > hors-ligne',
    );

    engine.setAlerts([_alert(1)]);
    expect(_kind(engine), SyncBannerKind.alert, reason: 'alerte > en cours');

    engine.setAlerts(const []);
    expect(_kind(engine), SyncBannerKind.syncing);
    engine.setSyncing(false);
    await tester.pump(const Duration(seconds: 1));
    expect(_kind(engine), SyncBannerKind.offline);

    // En ligne, N > 0 : « en attente » (3 s), puis « Synchronisé ».
    engine.setOnline(true);
    await tester.pump(const Duration(seconds: 3));
    expect(_kind(engine), SyncBannerKind.pending);
    engine.setPendingCount(0);
    expect(_kind(engine), SyncBannerKind.synced);
  });

  engineTest('règle 2 : une alerte à la fois (la plus ancienne), fermer '
      'affiche la suivante, compteur « +N »', (tester) async {
    build();
    engine.setAlerts([_alert(1), _alert(2), _alert(3)]);
    expect(engine.state.alert!.id, 1);
    expect(engine.state.moreAlerts, 2);

    engine.setAlerts([_alert(2), _alert(3)]);
    expect(engine.state.alert!.id, 2);
    expect(engine.state.moreAlerts, 1);

    engine.setAlerts([_alert(3)]);
    expect(engine.state.alert!.id, 3);
    expect(engine.state.moreAlerts, 0);

    engine.setAlerts(const []);
    expect(_kind(engine), SyncBannerKind.none);
  });

  engineTest('une alerte ne déclenche pas de « Synchronisé » parasite '
      'quand elle est fermée plus tard', (tester) async {
    build();
    engine.setPendingCount(1);
    await tester.pump(const Duration(seconds: 3));
    engine.setAlerts([_alert(1)]);
    engine.setPendingCount(0);
    await tester.pump(const Duration(seconds: 10));
    engine.setAlerts(const []);
    expect(_kind(engine), SyncBannerKind.none);
  });

  engineTest('B3 : retour du réseau avec N > 0 (hors-ligne, N = 2) -> pas de '
      '« Synchronisé », seul « en attente » viendra', (tester) async {
    build();
    engine.setPendingCount(2);
    engine.setOnline(false);
    await tester.pump(const Duration(seconds: 2));
    expect(_kind(engine), SyncBannerKind.offline);

    engine.setOnline(true);
    expect(_kind(engine), isNot(SyncBannerKind.synced));
    await tester.pump(const Duration(seconds: 2));
    expect(_kind(engine), isNot(SyncBannerKind.synced));
    await tester.pump(const Duration(seconds: 1));
    expect(_kind(engine), SyncBannerKind.pending);
  });

  engineTest('B3 : synchro en échec (N reste à 2) -> jamais « Synchronisé »', (
    tester,
  ) async {
    build();
    engine.setPendingCount(2);
    await tester.pump(const Duration(seconds: 3));
    expect(_kind(engine), SyncBannerKind.pending);

    engine.setSyncing(true);
    await tester.pump(const Duration(seconds: 1));
    expect(_kind(engine), SyncBannerKind.syncing);
    engine.setSyncing(false); // échec : N inchangé
    await tester.pump(const Duration(seconds: 1));
    expect(_kind(engine), SyncBannerKind.pending);
    await tester.pump(const Duration(seconds: 10));
    expect(_kind(engine), SyncBannerKind.pending);
  });

  engineTest('B3 : N tombe à 0 alors qu\'on est hors-ligne (liste) -> pas de '
      '« Synchronisé » tant que le réseau n\'est pas revenu', (tester) async {
    build(showOfflineWhenEmpty: false);
    engine.setPendingCount(1);
    engine.setOnline(false);
    await tester.pump(const Duration(seconds: 2));
    expect(_kind(engine), SyncBannerKind.offline);

    engine.setPendingCount(0);
    expect(_kind(engine), SyncBannerKind.none);
    await tester.pump(const Duration(seconds: 5));
    expect(_kind(engine), SyncBannerKind.none);
  });

  engineTest('B3 : une alerte annule « Synchronisé » ; la fermer avant '
      'l\'échéance ne le fait pas réapparaître', (tester) async {
    build();
    engine.setPendingCount(1);
    await tester.pump(const Duration(seconds: 3));
    engine.setPendingCount(0);
    expect(_kind(engine), SyncBannerKind.synced);

    engine.setAlerts([_alert(1)]);
    expect(_kind(engine), SyncBannerKind.alert);
    await tester.pump(const Duration(milliseconds: 500));
    engine.setAlerts(const []);
    expect(_kind(engine), SyncBannerKind.none);
    await tester.pump(const Duration(seconds: 5));
    expect(_kind(engine), SyncBannerKind.none);
  });
}
