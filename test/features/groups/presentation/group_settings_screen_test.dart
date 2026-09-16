// Tests de widget de l'écran dédié "Paramètres du groupe" (route
// `/groups/:id/settings`) — recettage direction-artistique du 13/09/2026,
// voir la doc de classe de `GroupSettingsScreen`. Remplace
// `showGroupManagementSheet`/`group_rename_sheet.dart` (sheets retirées par
// cette tâche) ; `group_dissolve_sheet.dart` reste testé ailleurs (son propre
// flux de confirmation n'est pas réécrit par cette tâche).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/created_group.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_note.dart';
import 'package:personnages/features/groups/domain/group_preview.dart';
import 'package:personnages/features/groups/domain/group_role.dart';
import 'package:personnages/features/groups/domain/group_summary.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/domain/joined_group.dart';
import 'package:personnages/features/groups/presentation/group_settings_screen.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';

class _FakeGroupRepository implements GroupRepository {
  GroupDetail? detailToReturn;
  Object? detailErrorToThrow;
  Completer<GroupDetail>? detailCompleter;

  String? lastRenamedName;
  Object? renameError;

  String regeneratedCode = 'NEWCODE1';
  Object? regenerateError;

  bool leaveGroupCalled = false;
  Object? leaveGroupError;

  @override
  Future<GroupDetail> fetchGroupDetail(String groupId) async {
    if (detailCompleter != null) return detailCompleter!.future;
    if (detailErrorToThrow != null) throw detailErrorToThrow!;
    return detailToReturn!;
  }

  @override
  Future<void> renameGroup({
    required String groupId,
    required String name,
  }) async {
    lastRenamedName = name;
    if (renameError != null) throw renameError!;
  }

  @override
  Future<String> regenerateInviteCode(String groupId) async {
    if (regenerateError != null) throw regenerateError!;
    return regeneratedCode;
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    leaveGroupCalled = true;
    if (leaveGroupError != null) throw leaveGroupError!;
  }

  @override
  Future<List<GroupSummary>> fetchMyGroups() => throw UnimplementedError();

  @override
  Future<CreatedGroup> createGroup({
    required String name,
    required String characterId,
  }) => throw UnimplementedError();

  @override
  Future<GroupPreview> previewGroupInvite(String code) =>
      throw UnimplementedError();

  @override
  Future<JoinedGroup> joinGroup({
    required String code,
    required String characterId,
  }) => throw UnimplementedError();

  @override
  Future<void> dissolveGroup(String groupId) => throw UnimplementedError();

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

  @override
  Future<GroupNote> fetchGroupNote({
    required String groupId,
    required String characterId,
  }) => throw UnimplementedError();

  @override
  Future<void> saveGroupNote({
    required String groupId,
    required String characterId,
    required String body,
  }) => throw UnimplementedError();
}

GroupDetail _ownerDetail({String name = "Les Lames de l'Aube"}) => GroupDetail(
  id: 'group-1',
  name: name,
  ownerId: 'user-1',
  inviteCode: 'AB3F7K2M',
  currentUserId: 'user-1',
  members: [
    GroupMember(
      characterId: 'char-1',
      userId: 'user-1',
      role: GroupRole.owner,
      name: 'Sylvi',
      level: 3,
      currentHp: 10,
      maxHp: 10,
      temporaryHp: 0,
      isDead: false,
    ),
  ],
);

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/groups/group-1/settings',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Liste des personnages'))),
      ),
      GoRoute(
        path: '/groups/:id/settings',
        builder: (context, state) =>
            GroupSettingsScreen(groupId: state.pathParameters['id']!),
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
    fakeRepository.detailCompleter = Completer<GroupDetail>();
    await tester.pumpWidget(_buildTestWidget(fakeRepository));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('PARAMÈTRES DU GROUPE'), findsOneWidget);
  });

  testWidgets(
    'état d\'erreur : message + "Réessayer" relance fetchGroupDetail',
    (tester) async {
      fakeRepository.detailErrorToThrow = const GroupFailure(
        'Groupe introuvable.',
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(find.text('Groupe introuvable.'), findsOneWidget);
    },
  );

  testWidgets(
    'affiche le nom pré-rempli, le code d\'invitation et les légendes',
    (tester) async {
      fakeRepository.detailToReturn = _ownerDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(find.text("Les Lames de l'Aube"), findsOneWidget);
      expect(find.text('AB3F7K2M'), findsOneWidget);
      expect(
        find.textContaining("Régénérer invalide l'ancien code"),
        findsOneWidget,
      );
      expect(find.text('ZONE DANGEREUSE'), findsOneWidget);
      expect(find.text('Dissoudre le groupe'), findsOneWidget);
      expect(
        find.textContaining('Réservé au créateur du groupe'),
        findsOneWidget,
      );
      // Pas de "Quitter le groupe" ici : cet écran n'est accessible qu'au
      // fondateur, qui dissout plutôt qu'il ne quitte (décision chef de
      // projet, voir la doc de classe de GroupSettingsScreen).
      expect(find.text('Quitter le groupe'), findsNothing);
    },
  );

  testWidgets(
    '"Enregistrer" désactivé tant que le nom n\'a pas changé, actif après '
    'modification',
    (tester) async {
      fakeRepository.detailToReturn = _ownerDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(PrimaryButton, 'ENREGISTRER');
      expect(tester.widget<PrimaryButton>(saveButton).onPressed, isNull);

      await tester.enterText(find.byType(TextFormField), 'Les Épées de Minuit');
      await tester.pump();

      expect(tester.widget<PrimaryButton>(saveButton).onPressed, isNotNull);
    },
  );

  testWidgets('"Enregistrer" renomme le groupe et affiche un SnackBar', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _ownerDetail();

    await tester.pumpWidget(_buildTestWidget(fakeRepository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Les Épées de Minuit');
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
    await tester.pumpAndSettle();

    expect(fakeRepository.lastRenamedName, 'Les Épées de Minuit');
    expect(find.text('Groupe renommé.'), findsOneWidget);
    // Redésactivé jusqu'à la prochaine modification.
    expect(
      tester
          .widget<PrimaryButton>(
            find.widgetWithText(PrimaryButton, 'ENREGISTRER'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('"Régénérer" : confirmation puis rafraîchissement', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _ownerDetail();
    fakeRepository.regeneratedCode = 'ZZZZ9999';

    await tester.pumpWidget(_buildTestWidget(fakeRepository));
    await tester.pumpAndSettle();

    // Désambiguïsation par type de bouton plutôt que par texte affiché : la
    // `SecondaryButton` "Régénérer" de l'écran et le `PrimaryButton`
    // "Régénérer" du dialogue de confirmation (`confirmLabel: 'Régénérer'`)
    // s'affichent tous les deux "RÉGÉNÉRER" (majuscules), et coexistent à
    // l'écran une fois le dialogue ouvert.
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is SecondaryButton && widget.label == 'Régénérer',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Régénérer le code d'invitation ?"), findsOneWidget);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is PrimaryButton && widget.label == 'Régénérer',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Code régénéré.'), findsOneWidget);
  });

  testWidgets('"Dissoudre le groupe" ouvre le flux de confirmation existant', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _ownerDetail();

    await tester.pumpWidget(_buildTestWidget(fakeRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dissoudre le groupe'));
    await tester.pumpAndSettle();

    expect(find.text('DISSOUDRE LE GROUPE'), findsOneWidget);
  });
}
