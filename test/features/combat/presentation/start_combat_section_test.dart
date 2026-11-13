// Entrée « Lancer un combat » de l'onglet Membres : visible seulement pour le
// MJ (`canStartCombat`), états, conflit, propriétaire sans rôle MJ.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/info_banner.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/combat/domain/combat_failure.dart';
import 'package:personnages/features/combat/presentation/providers/combat_providers.dart';
import 'package:personnages/features/combat/presentation/widgets/start_combat_section.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../../support/combat_fixtures.dart';
import '../../../support/fake_combat_repository.dart';
import '../../../support/fake_connectivity_checker.dart';
import '../../../support/fake_current_user.dart';
import 'combat_test_harness.dart';

class _Env {
  _Env({required this.detail});

  final GroupDetail detail;
  final repo = FakeCombatRepository();
  final connectivity = FakeConnectivityChecker();
  int opened = 0;
  int settings = 0;
}

Future<void> _pump(WidgetTester tester, _Env env) async {
  tester.view.physicalSize = const Size(360, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserFromTestOverride,
        combatRepositoryProvider.overrideWithValue(env.repo),
        connectivityCheckerProvider.overrideWithValue(env.connectivity),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              // Le fournisseur du combat est observé par l'écran Groupe.
              ref.watch(combatProvider(groupId));
              return StartCombatSection(
                detail: env.detail,
                onOpenCombat: () => env.opened++,
                onOpenSettings: () => env.settings++,
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadCombatFonts);

  testWidgets('MJ : bouton « Lancer un combat » pleine largeur', (
    tester,
  ) async {
    final env = _Env(detail: fakeGroupDetail());
    await _pump(tester, env);
    expect(find.text('LANCER UN COMBAT'), findsOneWidget);
    expect(find.byType(InfoBanner), findsNothing);
  });

  testWidgets('joueur : rien, aucun bouton grisé', (tester) async {
    final env = _Env(detail: fakeGroupDetail(asPlayer: true));
    await _pump(tester, env);
    expect(find.byType(PrimaryButton), findsNothing);
    expect(find.byType(InfoBanner), findsNothing);
    expect(find.textContaining('combat'), findsNothing);
  });

  testWidgets('membre MJ non propriétaire : rien', (tester) async {
    // Un membre porteur de `is_game_master` qui n'est pas le propriétaire ne
    // pilote pas (`canStartCombat`).
    final detail = fakeGroupDetail(asPlayer: true).copyWith(
      members: [
        fakeMember(userId: ownerId, isGameMaster: true, name: 'MJ'),
        fakeMember(userId: playerId, isGameMaster: true, name: 'Aria'),
      ],
    );
    final env = _Env(detail: detail);
    await _pump(tester, env);
    expect(find.byType(PrimaryButton), findsNothing);
    expect(find.byType(InfoBanner), findsNothing);
  });

  testWidgets('propriétaire sans rôle MJ : bandeau explicatif et lien', (
    tester,
  ) async {
    final env = _Env(detail: fakeGroupDetail(ownerPlaysCharacter: true));
    await _pump(tester, env);
    expect(find.byType(PrimaryButton), findsNothing);
    expect(find.text('Pas de combat sans MJ dans l\'app.'), findsOneWidget);
    await tester.tap(find.text('Paramètres du groupe'));
    expect(env.settings, 1);
  });

  testWidgets('combat déjà actif : le bouton disparaît (le bandeau prend le '
      'relais)', (tester) async {
    final env = _Env(detail: fakeGroupDetail());
    env.repo.snapshot = fakeSnapshot();
    await _pump(tester, env);
    expect(find.byType(PrimaryButton), findsNothing);
  });

  testWidgets('succès : appel, puis ouverture de l\'écran Combat', (
    tester,
  ) async {
    final env = _Env(detail: fakeGroupDetail());
    await _pump(tester, env);
    await tester.tap(find.text('LANCER UN COMBAT'));
    await tester.pumpAndSettle();
    expect(env.repo.calls, ['start:group-1']);
    expect(env.opened, 1);
  });

  testWidgets('chargement : spinner dans le bouton, pas de double appel', (
    tester,
  ) async {
    final env = _Env(detail: fakeGroupDetail());
    env.repo.writeGate = Completer<void>();
    await _pump(tester, env);
    await tester.tap(find.text('LANCER UN COMBAT'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).isLoading,
      isTrue,
    );
    await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
    await tester.pump();
    expect(env.repo.calls, ['start:group-1']);
    env.repo.writeGate!.complete();
    await tester.pumpAndSettle();
    expect(env.opened, 1);
  });

  testWidgets('hors ligne : désactivé avec « Indisponible hors ligne »', (
    tester,
  ) async {
    final env = _Env(detail: fakeGroupDetail());
    await _pump(tester, env);
    env.connectivity.goOffline();
    await tester.pumpAndSettle();
    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNull,
    );
    expect(find.text('Indisponible hors ligne'), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
    await tester.pump();
    expect(env.repo.calls, isEmpty);
  });

  testWidgets('conflit combat_already_active : refetch + snackbar', (
    tester,
  ) async {
    final env = _Env(detail: fakeGroupDetail());
    await _pump(tester, env);
    final before = env.repo.fetchCount;
    env.repo.writeFailure = const CombatFailure(
      CombatFailureKind.combatAlreadyActive,
    );
    await tester.tap(find.text('LANCER UN COMBAT'));
    await tester.pumpAndSettle();
    expect(find.text('Un combat est déjà en cours.'), findsOneWidget);
    expect(env.repo.fetchCount, greaterThan(before));
    expect(env.opened, 0);
  });

  testWidgets('no_game_master : erreur expliquée', (tester) async {
    final env = _Env(detail: fakeGroupDetail());
    await _pump(tester, env);
    env.repo.writeFailure = const CombatFailure(CombatFailureKind.noGameMaster);
    await tester.tap(find.text('LANCER UN COMBAT'));
    await tester.pumpAndSettle();
    expect(find.text('Pas de combat sans MJ dans l\'app.'), findsOneWidget);
  });
}
