// Tests de widget de l'écran "Groupes" (route /groups) — voir
// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2. Point
// d'entrée UNIQUE du bouton "groupes" de `character_list_screen.dart`
// (voir `test/features/characters/presentation/character_list_screen_test.dart`
// pour la navigation déclenchée par ce bouton, non retestée ici).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/dashed_border_painter.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/created_group.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:personnages/features/groups/domain/group_note.dart';
import 'package:personnages/features/groups/domain/group_preview.dart';
import 'package:personnages/features/groups/domain/group_summary.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/domain/joined_group.dart';
import 'package:personnages/features/groups/presentation/group_list_screen.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeGroupRepository implements GroupRepository {
  List<GroupSummary>? groupsToReturn;
  Object? errorToThrow;
  int fetchCallCount = 0;

  @override
  Future<List<GroupSummary>> fetchMyGroups() async {
    fetchCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
    return groupsToReturn ?? const [];
  }

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

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/groups',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Liste des personnages'))),
      ),
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupListScreen(),
      ),
      GoRoute(
        path: '/groups/new',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Créer un groupe'))),
      ),
      GoRoute(
        path: '/groups/join',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Rejoindre un groupe'))),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Écran Groupe ${state.pathParameters['id']}'),
          ),
        ),
      ),
    ],
  );
}

User _fakeUser() {
  return User(
    id: 'current-user-id',
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    email: 'joueur@exemple.com',
    createdAt: '2026-01-01T00:00:00Z',
  );
}

Widget _buildTestWidget(_FakeGroupRepository groupRepository) {
  return ProviderScope(
    overrides: [
      groupRepositoryProvider.overrideWithValue(groupRepository),
      currentUserProvider.overrideWithValue(_fakeUser()),
    ],
    child: MaterialApp.router(routerConfig: _buildTestRouter()),
  );
}

void main() {
  late _FakeGroupRepository fakeGroupRepository;

  setUp(() {
    fakeGroupRepository = _FakeGroupRepository();
  });

  testWidgets(
    'aucun groupe : état vide + les 2 boutons Créer/Rejoindre restent '
    'affichés',
    (tester) async {
      fakeGroupRepository.groupsToReturn = const [];

      await tester.pumpWidget(_buildTestWidget(fakeGroupRepository));
      await tester.pumpAndSettle();

      expect(find.text("AUCUN GROUPE POUR L'INSTANT"), findsOneWidget);
      expect(find.text('CRÉER UN GROUPE'), findsOneWidget);
      expect(find.text('REJOINDRE UN GROUPE'), findsOneWidget);
    },
  );

  testWidgets(
    'état vide : tokens "on-wood" (écran "scène") plutôt que "parchemin" — '
    'médaillon en bordure pointillée circulaire, icône groups_outlined en '
    'goldEnd (recettage direction artistique du 13/09)',
    (tester) async {
      fakeGroupRepository.groupsToReturn = const [];

      await tester.pumpWidget(_buildTestWidget(fakeGroupRepository));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.painter is DashedBorderPainter &&
              (widget.painter! as DashedBorderPainter).shape ==
                  BoxShape.circle &&
              (widget.painter! as DashedBorderPainter).color ==
                  AppColors.textOnWoodMuted,
        ),
        findsOneWidget,
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.groups_outlined));
      expect(icon.color, AppColors.goldEnd);

      final title = tester.widget<Text>(
        find.text("AUCUN GROUPE POUR L'INSTANT"),
      );
      expect(title.style?.color, AppColors.textOnWood);

      final body = tester.widget<Text>(
        find.text(
          "Crée un groupe pour ton équipe, ou rejoins celui de tes "
          "coéquipiers avec un code d'invitation.",
        ),
      );
      expect(body.style?.color, AppColors.textOnWoodMuted);
    },
  );

  testWidgets('liste les groupes du joueur (nom + nombre de membres), boutons '
      'Créer/Rejoindre toujours affichés même avec des groupes existants', (
    tester,
  ) async {
    fakeGroupRepository.groupsToReturn = const [
      GroupSummary(
        id: 'group-1',
        name: 'Les Lames',
        memberCount: 2,
        founderId: 'founder-id',
      ),
      GroupSummary(
        id: 'group-2',
        name: 'Les Ombres',
        memberCount: 4,
        founderId: 'founder-id',
      ),
    ];

    await tester.pumpWidget(_buildTestWidget(fakeGroupRepository));
    await tester.pumpAndSettle();

    expect(find.text('Les Lames'), findsOneWidget);
    expect(find.text('2 membres'), findsOneWidget);
    expect(find.text('Les Ombres'), findsOneWidget);
    expect(find.text('4 membres'), findsOneWidget);
    expect(find.text('CRÉER UN GROUPE'), findsOneWidget);
    expect(find.text('REJOINDRE UN GROUPE'), findsOneWidget);
  });

  testWidgets('taper un groupe de la liste navigue vers /groups/:id', (
    tester,
  ) async {
    fakeGroupRepository.groupsToReturn = const [
      GroupSummary(
        id: 'group-1',
        name: 'Les Lames',
        memberCount: 2,
        founderId: 'founder-id',
      ),
    ];

    await tester.pumpWidget(_buildTestWidget(fakeGroupRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Les Lames'));
    await tester.pumpAndSettle();

    expect(find.text('Écran Groupe group-1'), findsOneWidget);
  });

  testWidgets(
    '"Créer un groupe" navigue vers /groups/new — même avec un groupe '
    'déjà rejoint (permet d\'en créer un second)',
    (tester) async {
      fakeGroupRepository.groupsToReturn = const [
        GroupSummary(
          id: 'group-1',
          name: 'Les Lames',
          memberCount: 2,
          founderId: 'founder-id',
        ),
      ];

      await tester.pumpWidget(_buildTestWidget(fakeGroupRepository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CRÉER UN GROUPE'));
      await tester.pumpAndSettle();

      expect(find.text('Créer un groupe'), findsOneWidget);
    },
  );

  testWidgets('"Rejoindre un groupe" navigue vers /groups/join — même avec un '
      'groupe déjà rejoint (permet d\'en rejoindre un second)', (tester) async {
    fakeGroupRepository.groupsToReturn = const [
      GroupSummary(
        id: 'group-1',
        name: 'Les Lames',
        memberCount: 2,
        founderId: 'founder-id',
      ),
    ];

    await tester.pumpWidget(_buildTestWidget(fakeGroupRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('REJOINDRE UN GROUPE'));
    await tester.pumpAndSettle();

    expect(find.text('Rejoindre un groupe'), findsOneWidget);
  });

  testWidgets(
    'badge "TOI" affiché uniquement sur le groupe fondé par le joueur '
    'connecté',
    (tester) async {
      fakeGroupRepository.groupsToReturn = const [
        GroupSummary(
          id: 'group-1',
          name: 'Les Lames',
          memberCount: 2,
          founderId: 'current-user-id',
        ),
        GroupSummary(
          id: 'group-2',
          name: 'Les Ombres',
          memberCount: 4,
          founderId: 'someone-else-id',
        ),
      ];

      await tester.pumpWidget(_buildTestWidget(fakeGroupRepository));
      await tester.pumpAndSettle();

      expect(find.text('TOI'), findsOneWidget);
    },
  );

  testWidgets(
    'puces de couleur : une par membre (borné à 6), badge pointillé "+N" '
    'au-delà',
    (tester) async {
      fakeGroupRepository.groupsToReturn = const [
        GroupSummary(
          id: 'group-1',
          name: 'Petit groupe',
          memberCount: 3,
          founderId: 'founder-id',
        ),
        GroupSummary(
          id: 'group-2',
          name: 'Grand groupe',
          memberCount: 8,
          founderId: 'founder-id',
        ),
      ];

      await tester.pumpWidget(_buildTestWidget(fakeGroupRepository));
      await tester.pumpAndSettle();

      final squares = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (container) =>
                container.constraints?.maxWidth == 16 &&
                container.constraints?.maxHeight == 16,
          )
          .toList();
      // 3 puces (groupe 1) + 6 puces visibles (groupe 2, borné) = 9.
      expect(squares.length, 9);
      expect(find.text('+2'), findsOneWidget);
    },
  );

  testWidgets('échec réseau : affiche un message d\'erreur avec un bouton '
      '"Réessayer" qui relance fetchMyGroups', (tester) async {
    fakeGroupRepository.errorToThrow = const GroupFailure('Erreur serveur.');

    await tester.pumpWidget(_buildTestWidget(fakeGroupRepository));
    await tester.pumpAndSettle();

    expect(find.text('Erreur serveur.'), findsOneWidget);
    expect(fakeGroupRepository.fetchCallCount, 1);

    fakeGroupRepository.errorToThrow = null;
    fakeGroupRepository.groupsToReturn = const [];
    await tester.tap(find.text('RÉESSAYER'));
    await tester.pumpAndSettle();

    expect(fakeGroupRepository.fetchCallCount, 2);
    expect(find.text("AUCUN GROUPE POUR L'INSTANT"), findsOneWidget);
  });

  testWidgets('état d\'erreur : tokens "on-wood" (écran "scène") plutôt que '
      '"parchemin" — texte en textOnWood, bouton "Réessayer" en surface '
      '"scene" par défaut (recettage direction artistique du 13/09)', (
    tester,
  ) async {
    fakeGroupRepository.errorToThrow = const GroupFailure('Erreur serveur.');

    await tester.pumpWidget(_buildTestWidget(fakeGroupRepository));
    await tester.pumpAndSettle();

    final message = tester.widget<Text>(find.text('Erreur serveur.'));
    expect(message.style?.color, AppColors.textOnWood);

    // `find.byType(SecondaryButton)` seul trouverait aussi "REJOINDRE UN
    // GROUPE" (pied d'écran, toujours affiché même en état d'erreur) : on
    // restreint donc à celui portant le libellé "Réessayer".
    final retryButton = tester.widget<SecondaryButton>(
      find.ancestor(
        of: find.text('RÉESSAYER'),
        matching: find.byType(SecondaryButton),
      ),
    );
    expect(retryButton.surface, SecondaryButtonSurface.scene);

    final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
    expect(icon.color, AppColors.accentBrick);
  });

  testWidgets('le bouton retour navigue vers / (aucune pile à dépiler ici)', (
    tester,
  ) async {
    fakeGroupRepository.groupsToReturn = const [];

    await tester.pumpWidget(_buildTestWidget(fakeGroupRepository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Liste des personnages'), findsOneWidget);
  });
}
