// Tests de widget de l'étape 2/3 "Confirmation" du flux "Rejoindre un
// groupe" — voir `docs/cahier-des-charges/12-partage-et-groupes.md` section
// 2. Le dépôt de test (`_FakeGroupRepository`) est injecté via
// `overrideWithValue` sur `groupRepositoryProvider`, même principe que
// `join_confirmation_step_screen_test.dart`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/created_group.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_invite_failure.dart';
import 'package:personnages/features/groups/domain/group_preview.dart';
import 'package:personnages/features/groups/domain/group_summary.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/domain/joined_group.dart';
import 'package:personnages/features/groups/presentation/group_join_confirmation_step_screen.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';

class _FakeGroupRepository implements GroupRepository {
  GroupPreview? previewToReturn;
  Object? previewErrorToThrow;
  Completer<GroupPreview>? previewCompleter;
  int previewCallCount = 0;

  @override
  Future<GroupPreview> previewGroupInvite(String code) async {
    previewCallCount++;
    if (previewCompleter != null) return previewCompleter!.future;
    if (previewErrorToThrow != null) throw previewErrorToThrow!;
    return previewToReturn ??
        const GroupPreview(name: 'Groupe test', memberCount: 1);
  }

  @override
  Future<List<GroupSummary>> fetchMyGroups() => throw UnimplementedError();

  @override
  Future<CreatedGroup> createGroup({
    required String name,
    required String characterId,
  }) => throw UnimplementedError();

  @override
  Future<JoinedGroup> joinGroup({
    required String code,
    required String characterId,
  }) => throw UnimplementedError();

  @override
  Future<GroupDetail> fetchGroupDetail(String groupId) =>
      throw UnimplementedError();

  @override
  Future<void> renameGroup({required String groupId, required String name}) =>
      throw UnimplementedError();

  @override
  Future<String> regenerateInviteCode(String groupId) =>
      throw UnimplementedError();

  @override
  Future<void> dissolveGroup(String groupId) => throw UnimplementedError();

  @override
  Future<void> leaveGroup(String groupId) => throw UnimplementedError();

  @override
  Future<void> removeMember({
    required String groupId,
    required String characterId,
  }) => throw UnimplementedError();

  @override
  Future<GroupTreasure> fetchGroupTreasure(String groupId) =>
      throw UnimplementedError();

  @override
  Future<void> addToTreasure({
    required String groupId,
    required Map<CurrencyKind, int> newCurrencyTotals,
    required List<GroupTreasureItem> newItems,
  }) => throw UnimplementedError();

  @override
  Future<bool> claimTreasureCurrency({
    required String groupId,
    required String characterId,
    required CurrencyKind currency,
    required int amount,
  }) => throw UnimplementedError();

  @override
  Future<void> claimTreasureItem({
    required String groupId,
    required String characterId,
    required GroupTreasureItem item,
    required int quantity,
  }) => throw UnimplementedError();

  @override
  GroupRealtimeSubscription subscribeToMemberUpdates({
    required List<String> characterIds,
    required void Function() onChanged,
  }) => throw UnimplementedError();
}

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/groups/join/step-2?code=AB3F7K2M',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Liste des personnages'))),
      ),
      GoRoute(
        path: '/groups/join',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Étape 1 code=${state.uri.queryParameters['code']}'),
          ),
        ),
      ),
      GoRoute(
        path: '/groups/join/step-2',
        builder: (context, state) => GroupJoinConfirmationStepScreen(
          code: state.uri.queryParameters['code']!,
        ),
      ),
      GoRoute(
        path: '/groups/join/step-3',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Étape 3 code=${state.uri.queryParameters['code']}'),
          ),
        ),
      ),
    ],
  );
}

Widget _buildTestWidget(_FakeGroupRepository repository) {
  return ProviderScope(
    overrides: [groupRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(routerConfig: _buildTestRouter()),
  );
}

void main() {
  late _FakeGroupRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeGroupRepository();
  });

  testWidgets('affiche un indicateur de chargement pendant la résolution', (
    tester,
  ) async {
    fakeRepository.previewCompleter = Completer<GroupPreview>();

    await tester.pumpWidget(_buildTestWidget(fakeRepository));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'affiche le nom et "{n} membres" une fois résolu, puis "Rejoindre" '
    'pousse l\'étape 3/3 avec le code',
    (tester) async {
      fakeRepository.previewToReturn = const GroupPreview(
        name: 'Les Lames de l\'Aube',
        memberCount: 4,
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(find.text('Les Lames de l\'Aube'), findsOneWidget);
      expect(find.text('4 membres'), findsOneWidget);
      expect(find.byIcon(Icons.groups), findsOneWidget);

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('Étape 3 code=AB3F7K2M'), findsOneWidget);
    },
  );

  testWidgets(
    'code invalide : affiche le message dédié, "Modifier le code" repousse '
    'l\'étape 1/3 avec le code pré-rempli',
    (tester) async {
      fakeRepository.previewErrorToThrow = const GroupInviteFailure(
        GroupInviteFailureKind.invalidCode,
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(
        find.text("Ce code d'invitation n'est pas valide."),
        findsOneWidget,
      );

      await tester.tap(find.text('MODIFIER LE CODE'));
      await tester.pumpAndSettle();

      expect(find.text('Étape 1 code=AB3F7K2M'), findsOneWidget);
    },
  );

  testWidgets(
    'erreur générique/réseau : affiche le message générique, "Réessayer" '
    'relance la requête',
    (tester) async {
      fakeRepository.previewErrorToThrow = const GroupInviteFailure(
        GroupInviteFailureKind.generic,
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Impossible de contacter le serveur. Vérifiez votre connexion '
          'internet et réessayez.',
        ),
        findsOneWidget,
      );
      expect(fakeRepository.previewCallCount, 1);

      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(fakeRepository.previewCallCount, 2);
    },
  );

  testWidgets(
    'une exception qui n\'est pas une GroupInviteFailure est traitée comme '
    'générique',
    (tester) async {
      fakeRepository.previewErrorToThrow = StateError('boom');

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Impossible de contacter le serveur. Vérifiez votre connexion '
          'internet et réessayez.',
        ),
        findsOneWidget,
      );
    },
  );
}
