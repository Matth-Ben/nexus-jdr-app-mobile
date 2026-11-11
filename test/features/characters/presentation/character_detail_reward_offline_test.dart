// Bouton « RÉCOMPENSE » de l'onglet « Sac » hors ligne (constat B de la
// campagne émulateur V4) : le bouton n'a aucune condition de connectivité, il
// n'est grisé que par le verrou `_isWritingInventory` de
// `character_detail_screen.dart`. Ces tests figent : actif hors ligne, feuille
// ouverte, butin mis en file, verrou relâché après `queued` / exception /
// échec métier, second butin possible, désactivé pendant une écriture en cours
// puis réactivé, désactivé en lecture seule (`actionsDisabled`).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_tab_body.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../../support/fake_connectivity_checker.dart';

const _queuedMessage =
    'Hors ligne : sera synchronisé dès que la connexion revient.';

const _detail = CharacterDetail(
  id: '1',
  name: 'Sylas',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      className: 'Guerrier',
      level: 3,
      isPrimary: true,
      savingThrowProficiencies: [],
      hitDie: 10,
    ),
  ],
  xp: 0,
  currentHp: 10,
  maxHp: 10,
  temporaryHp: 0,
  abilityScores: {},
  currencyGp: 10,
);

/// Dépôt minimal : seules les méthodes lues par la fiche + `addReward`.
class _RewardRepository implements CharacterRepository {
  int addRewardCalls = 0;
  Map<CurrencyKind, int>? lastTotals;

  /// Résultat renvoyé par `addReward` (sauf si [failure] est fourni).
  WriteOutcome outcome = WriteOutcome.queued;

  /// Si non nul, `addReward` lève cette erreur (consommée).
  Object? failure;

  /// Si non nul, `addReward` attend ce `Completer` avant de répondre.
  Completer<void>? gate;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async =>
      _detail;

  @override
  Future<List<InventoryCatalogItem>> fetchInventoryCatalog() async => const [];

  @override
  Future<WriteOutcome> addReward({
    required String characterId,
    required Map<CurrencyKind, int> newCurrencyTotals,
    required List<RewardItemDraft> items,
  }) async {
    addRewardCalls++;
    lastTotals = newCurrencyTotals;
    final pending = gate;
    if (pending != null) await pending.future;
    final error = failure;
    if (error != null) {
      failure = null;
      throw error;
    }
    return outcome;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Future<_RewardRepository> _pumpOfflineBag(WidgetTester tester) async {
  final repository = _RewardRepository();
  final connectivity = FakeConnectivityChecker(connected: false);
  addTearDown(connectivity.close);
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(repository),
        connectivityCheckerProvider.overrideWithValue(connectivity),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        routerConfig: GoRouter(
          initialLocation: '/characters/1',
          routes: [
            GoRoute(
              path: '/characters/:id',
              builder: (context, state) => CharacterDetailScreen(
                characterId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('SAC'));
  await tester.pumpAndSettle();
  return repository;
}

bool _rewardEnabled(WidgetTester tester) {
  final inkWell = find
      .ancestor(of: find.text('RÉCOMPENSE'), matching: find.byType(InkWell))
      .first;
  return tester.widget<InkWell>(inkWell).onTap != null;
}

/// Ouvre la feuille, saisit [gold] PO et valide.
Future<void> _submitReward(WidgetTester tester, String gold) async {
  await tester.tap(find.text('RÉCOMPENSE'));
  await tester.pumpAndSettle();
  expect(find.text('AJOUTER UNE RÉCOMPENSE'), findsOneWidget);
  await tester.enterText(find.byType(TextFormField).first, gold);
  await tester.pump();
  await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER LA RÉCOMPENSE'));
}

void main() {
  testWidgets('hors ligne : le bouton est actif, la feuille s\'ouvre avec ses '
      'champs de saisie', (tester) async {
    await _pumpOfflineBag(tester);

    expect(_rewardEnabled(tester), isTrue);
    await tester.tap(find.text('RÉCOMPENSE'));
    await tester.pumpAndSettle();

    expect(find.text('AJOUTER UNE RÉCOMPENSE'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });

  testWidgets('hors ligne : le butin est mis en file (message « sera '
      'synchronisé »), le verrou est relâché et un second butin est '
      'possible', (tester) async {
    final repository = await _pumpOfflineBag(tester);

    await _submitReward(tester, '5');
    await tester.pumpAndSettle();

    expect(repository.addRewardCalls, 1);
    expect(repository.lastTotals, {CurrencyKind.gold: 15});
    expect(find.text(_queuedMessage), findsOneWidget);
    expect(_rewardEnabled(tester), isTrue);

    await _submitReward(tester, '2');
    await tester.pumpAndSettle();

    expect(repository.addRewardCalls, 2);
  });

  testWidgets('exception inattendue : verrou relâché, bouton actif, second '
      'butin possible', (tester) async {
    final repository = await _pumpOfflineBag(tester)
      ..failure = StateError('boom');

    await _submitReward(tester, '5');
    await tester.pumpAndSettle();

    expect(
      find.text("Impossible d'ajouter la récompense. Réessayez."),
      findsOneWidget,
    );
    expect(_rewardEnabled(tester), isTrue);

    await _submitReward(tester, '3');
    await tester.pumpAndSettle();

    expect(repository.addRewardCalls, 2);
  });

  testWidgets('échec métier (CharacterFailure) : verrou relâché', (
    tester,
  ) async {
    final repository = await _pumpOfflineBag(tester)
      ..failure = const CharacterFailure('Refusé.');

    await _submitReward(tester, '5');
    await tester.pumpAndSettle();

    expect(find.text('Refusé.'), findsOneWidget);
    expect(_rewardEnabled(tester), isTrue);
    expect(repository.addRewardCalls, 1);
  });

  testWidgets('écriture en cours : bouton désactivé, puis réactivé à la fin', (
    tester,
  ) async {
    final repository = await _pumpOfflineBag(tester);
    final gate = Completer<void>();
    repository.gate = gate;

    await _submitReward(tester, '5');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.addRewardCalls, 1);
    expect(_rewardEnabled(tester), isFalse);

    gate.complete();
    await tester.pumpAndSettle();

    expect(_rewardEnabled(tester), isTrue);
  });

  testWidgets('lecture seule (actionsDisabled) : bouton désactivé', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: CharacterInventoryTabBody(
            detail: _detail,
            actionsDisabled: true,
            onAddReward: () {},
            onUseItem: (_) {},
            onToggleItemEquipped: (_) {},
            onToggleItemAttuned: (_) {},
            onRemoveItem: (_) {},
            onAdjustCurrency: (_, _) {},
            onAddInventoryItem: (_, _) {},
            onAddCustomInventoryItem: (
              customName,
              quantity, {
              description,
              damageDice,
              damageType,
              properties = const [],
            }) {},
            onEquipWeaponToSlot: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(_rewardEnabled(tester), isFalse);
  });
}
