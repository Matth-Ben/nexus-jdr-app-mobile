// Tests de widget de l'écran "Groupe" (route /groups/:id) — voir
// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2.

import 'dart:async';

import 'package:personnages/features/combat/presentation/providers/character_combat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/theme/app_spacing.dart';
import 'package:personnages/core/widgets/destructive_button.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/wood_back_header.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/groups/data/group_treasure_inventory_adapter.dart';
import 'package:personnages/features/combat/presentation/providers/combat_providers.dart';
import 'package:personnages/features/combat/presentation/providers/grimoire_combat_providers.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/created_group.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_note_entry.dart';
import 'package:personnages/features/groups/domain/group_preview.dart';
import 'package:personnages/features/groups/domain/group_role.dart';
import 'package:personnages/features/groups/domain/group_summary.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/domain/joined_group.dart';
import 'package:personnages/features/groups/presentation/group_screen.dart';
import 'package:personnages/features/groups/presentation/group_settings_screen.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';
import 'package:personnages/features/groups/presentation/widgets/group_campaign_card.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../../support/fake_combat_repository.dart';
import '../../../support/fake_connectivity_checker.dart';
import '../../../support/fake_current_user.dart';
import '../../../support/fake_grimoire_combat_gateway.dart';

class _NoopSubscription implements GroupRealtimeSubscription {
  @override
  Future<void> cancel() async {}
}

class _FakeGroupRepository implements GroupRepository {
  int idsCalls = 0;

  @override
  Future<List<String>> fetchGroupIdsForCharacter(String characterId) async {
    idsCalls++;
    return const [];
  }

  GroupDetail? detailToReturn;
  Object? detailErrorToThrow;
  Completer<GroupDetail>? detailCompleter;
  int detailFetchCount = 0;

  GroupTreasure? treasureToReturn;
  Object? treasureErrorToThrow;

  Object? removeMemberError;
  String? lastRemovedUserId;

  /// Exclusion en attente (D232) : `removeMember` ne se termine qu'à sa
  /// complétion.
  Completer<void>? removeMemberCompleter;

  /// Exclusions en attente par membre (deux exclusions simultanées).
  final Map<String, Completer<void>> removeMemberCompleters = {};

  /// Tous les appels à `removeMember`, dans l'ordre.
  final List<String> removedUserIds = [];

  bool leaveGroupCalled = false;
  Object? leaveGroupError;

  String? lastRenamedName;
  Object? renameError;

  String regeneratedCode = 'NEWCODE1';
  Object? regenerateError;

  bool dissolveCalled = false;
  Object? dissolveError;

  bool claimCurrencyResult = true;
  Set<CurrencyKind> failingCurrencies = {};
  final Map<CurrencyKind, int> lastClaimedAmounts = {};
  int claimCurrencyCallCount = 0;
  int treasureFetchCount = 0;

  Object? claimItemError;
  int? lastClaimedQuantity;

  Map<CurrencyKind, int>? lastAddedTotals;
  Map<CurrencyKind, int>? lastCurrencyExpected;
  List<GroupTreasureItem>? lastAddedItems;
  GroupTreasureItem? lastUpdatedExpected;
  GroupTreasureItem? lastUpdatedItem;
  GroupTreasureItem? lastRemovedItem;
  GroupTreasureItem? lastClaimedItem;

  /// Erreur levée par toutes les écritures du butin (hors monnaie RPC).
  Object? treasureWriteError;

  int detailsFetchCount = 0;
  CharacterInventoryItem? detailsToReturn;
  Object? detailsError;
  Completer<CharacterInventoryItem>? detailsCompleter;

  List<GroupNoteEntry>? entriesToReturn;
  Object? entriesErrorToThrow;
  int entriesFetchCount = 0;

  String? lastAddedNoteTitle;
  String? lastAddedNoteBody;
  Object? addNoteError;
  int addNoteCallCount = 0;

  String? lastUpdatedNoteEntryId;
  String? lastUpdatedNoteTitle;
  String? lastUpdatedNoteBody;
  Object? updateNoteError;
  int updateNoteCallCount = 0;

  String? lastDeletedNoteEntryId;
  Object? deleteNoteError;
  int deleteNoteCallCount = 0;

  @override
  Future<GroupDetail> fetchGroupDetail(String groupId) async {
    detailFetchCount++;
    if (detailCompleter != null) return detailCompleter!.future;
    if (detailErrorToThrow != null) throw detailErrorToThrow!;
    return detailToReturn!;
  }

  @override
  Future<GroupTreasure> fetchGroupTreasure(String groupId) async {
    treasureFetchCount++;
    if (treasureErrorToThrow != null) throw treasureErrorToThrow!;
    return treasureToReturn ?? GroupTreasure(groupId: groupId);
  }

  @override
  GroupRealtimeSubscription subscribeToMemberUpdates({
    required String groupId,
    required List<String> characterIds,
    required bool Function(String membershipId) isKnownMembershipId,
    required void Function() onChanged,
  }) => _NoopSubscription();

  @override
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    lastRemovedUserId = userId;
    removedUserIds.add(userId);
    final pending = removeMemberCompleters[userId];
    if (pending != null) await pending.future;
    if (removeMemberCompleter != null) await removeMemberCompleter!.future;
    if (removeMemberError != null) throw removeMemberError!;
  }

  @override
  Future<void> setGroupCharacter({
    required String groupId,
    required String characterId,
  }) => throw UnimplementedError();

  @override
  Future<void> leaveGroup(String groupId) async {
    leaveGroupCalled = true;
    if (leaveGroupError != null) throw leaveGroupError!;
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
  Future<void> dissolveGroup(String groupId) async {
    dissolveCalled = true;
    if (dissolveError != null) throw dissolveError!;
  }

  int becomeGameMasterCalls = 0;

  /// Détail renvoyé par les lectures suivantes après « Devenir MJ ».
  GroupDetail? detailAfterBecomeGameMaster;

  @override
  Future<void> becomeGroupGameMaster(String groupId) async {
    becomeGameMasterCalls++;
    final after = detailAfterBecomeGameMaster;
    if (after != null) detailToReturn = after;
  }

  @override
  Future<bool> claimTreasureCurrency({
    required String groupId,
    required String characterId,
    required CurrencyKind currency,
    required int amount,
  }) async {
    claimCurrencyCallCount++;
    lastClaimedAmounts[currency] = amount;
    if (failingCurrencies.contains(currency)) return false;
    return claimCurrencyResult;
  }

  @override
  Future<void> claimTreasureItem({
    required String groupId,
    required String characterId,
    required GroupTreasureItem item,
    required int quantity,
  }) async {
    lastClaimedQuantity = quantity;
    lastClaimedItem = item;
    if (claimItemError != null) throw claimItemError!;
  }

  @override
  Future<void> addTreasureItems({
    required String groupId,
    required List<GroupTreasureItem> items,
  }) async {
    lastAddedItems = items;
    if (treasureWriteError != null) throw treasureWriteError!;
  }

  @override
  Future<void> updateTreasureItem({
    required String groupId,
    required GroupTreasureItem expected,
    required GroupTreasureItem updated,
  }) async {
    lastUpdatedExpected = expected;
    lastUpdatedItem = updated;
    if (treasureWriteError != null) throw treasureWriteError!;
  }

  @override
  Future<void> removeTreasureItem({
    required String groupId,
    required GroupTreasureItem expected,
  }) async {
    lastRemovedItem = expected;
    if (treasureWriteError != null) throw treasureWriteError!;
  }

  @override
  Future<void> setTreasureCurrency({
    required String groupId,
    required Map<CurrencyKind, int> expected,
    required Map<CurrencyKind, int> newTotals,
  }) async {
    lastCurrencyExpected = expected;
    lastAddedTotals = newTotals;
    if (treasureWriteError != null) throw treasureWriteError!;
  }

  @override
  Future<CharacterInventoryItem> fetchTreasureItemDetails(
    GroupTreasureItem item,
  ) async {
    detailsFetchCount++;
    if (detailsCompleter != null) return detailsCompleter!.future;
    if (detailsError != null) throw detailsError!;
    return detailsToReturn ??
        GroupTreasureInventoryAdapter.toInventoryItem(item);
  }

  @override
  Future<List<GroupNoteEntry>> fetchGroupNoteEntries(String groupId) async {
    entriesFetchCount++;
    if (entriesErrorToThrow != null) throw entriesErrorToThrow!;
    return entriesToReturn ?? const [];
  }

  @override
  Future<void> addGroupNoteEntry({
    required String groupId,
    String? title,
    required String body,
  }) async {
    addNoteCallCount++;
    lastAddedNoteTitle = title;
    lastAddedNoteBody = body;
    if (addNoteError != null) throw addNoteError!;
  }

  @override
  Future<void> updateGroupNoteEntry({
    required String entryId,
    String? title,
    required String body,
  }) async {
    updateNoteCallCount++;
    lastUpdatedNoteEntryId = entryId;
    lastUpdatedNoteTitle = title;
    lastUpdatedNoteBody = body;
    if (updateNoteError != null) throw updateNoteError!;
  }

  @override
  Future<void> deleteGroupNoteEntry(String entryId) async {
    deleteNoteCallCount++;
    lastDeletedNoteEntryId = entryId;
    if (deleteNoteError != null) throw deleteNoteError!;
  }

  @override
  Future<List<GroupSummary>> fetchMyGroups() => throw UnimplementedError();

  @override
  Future<CreatedGroup> createGroup({
    required String name,
    String? characterId,
  }) => throw UnimplementedError();

  @override
  Future<GroupPreview> previewGroupInvite(String code) =>
      throw UnimplementedError();

  @override
  Future<JoinedGroup> joinGroup({required String code, String? characterId}) =>
      throw UnimplementedError();
}

GroupMember _member({
  required String characterId,
  required String userId,
  required GroupRole role,
  required String name,
  int currentHp = 10,
  int maxHp = 10,
  int temporaryHp = 0,
  bool isDead = false,
}) {
  return GroupMember(
    characterId: characterId,
    userId: userId,
    role: role,
    name: name,
    isGameMaster: false,
    level: 3,
    currentHp: currentHp,
    maxHp: maxHp,
    temporaryHp: temporaryHp,
    isDead: isDead,
    raceName: 'Elfe',
    className: 'Rôdeur',
  );
}

GoRouter _buildTestRouter({bool realSettings = false}) {
  return GoRouter(
    initialLocation: '/groups/group-1',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Liste des personnages'))),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (context, state) =>
            GroupScreen(groupId: state.pathParameters['id']!),
      ),
      // Stub de `GroupSettingsScreen` (route `/groups/:id/settings`,
      // recettage direction-artistique du 13/09/2026) — seul le fait que
      // l'icône réglages y navigue est du ressort de ce fichier, le contenu
      // de l'écran lui-même est testé dans
      // `group_settings_screen_test.dart`.
      GoRoute(
        path: '/groups/:id/settings',
        builder: (context, state) => realSettings
            ? GroupSettingsScreen(groupId: state.pathParameters['id']!)
            : Scaffold(
                body: Center(
                  child: Text(
                    'Paramètres du groupe ${state.pathParameters['id']}',
                  ),
                ),
              ),
      ),
    ],
  );
}

Widget _buildTestWidget(
  _FakeGroupRepository repository, {
  bool realSettings = false,
  Locale locale = const Locale('fr'),
  FakeConnectivityChecker? connectivity,
  List<InventoryCatalogItem> catalog = const [],
}) {
  return ProviderScope(
    overrides: [
      groupRepositoryProvider.overrideWithValue(repository),
      // Combat du groupe (bandeau, « Lancer un combat ») : aucun combat actif.
      combatRepositoryProvider.overrideWithValue(FakeCombatRepository()),
      grimoireCombatGatewayProvider.overrideWithValue(
        FakeGrimoireCombatGateway(),
      ),
      connectivityCheckerProvider.overrideWithValue(
        connectivity ?? FakeConnectivityChecker(),
      ),
      // Catalogue de l'ajout d'objets au butin (parcours de l'inventaire).
      inventoryCatalogProvider.overrideWith((ref) async => catalog),
      currentUserFromTestOverride,
    ],
    child: MaterialApp.router(
      routerConfig: _buildTestRouter(realSettings: realSettings),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
    ),
  );
}

void main() {
  late _FakeGroupRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeGroupRepository();
    // Court-circuite `Clipboard.setData` (pas de presse-papier réel en
    // test) — même principe que `device_permissions_sheet_test.dart`/
    // `export_data_sheet_test.dart` pour un autre canal natif.
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') return null;
          return null;
        });
  });

  final owner = _member(
    characterId: 'char-1',
    userId: 'user-1',
    role: GroupRole.owner,
    name: 'Sylvi',
  );
  final unconsciousMember = _member(
    characterId: 'char-2',
    userId: 'user-2',
    role: GroupRole.membre,
    name: 'Borgan',
    currentHp: 0,
    maxHp: 15,
  );
  final deadMember = _member(
    characterId: 'char-3',
    userId: 'user-3',
    role: GroupRole.membre,
    name: 'Ithil',
    currentHp: 12,
    maxHp: 12,
    isDead: true,
  );

  GroupDetail ownerViewDetail() => GroupDetail(
    id: 'group-1',
    name: 'Les Lames de l\'Aube',
    ownerId: 'user-1',
    inviteCode: 'AB3F7K2M',
    currentUserId: 'user-1',
    members: [owner, unconsciousMember, deadMember],
  );

  GroupDetail memberViewDetail() =>
      ownerViewDetail().copyWith(currentUserId: 'user-2');

  testWidgets('affiche un indicateur de chargement pendant la résolution', (
    tester,
  ) async {
    fakeRepository.detailCompleter = Completer<GroupDetail>();
    await tester.pumpWidget(_buildTestWidget(fakeRepository));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('GROUPE'), findsOneWidget);
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
      expect(fakeRepository.detailFetchCount, 1);

      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(fakeRepository.detailFetchCount, 2);
    },
  );

  group('en-tête', () {
    testWidgets('affiche le nom du groupe en majuscules une fois chargé', (
      tester,
    ) async {
      fakeRepository.detailToReturn = ownerViewDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(find.text('LES LAMES DE L\'AUBE'), findsOneWidget);
    });

    testWidgets('owner : icône réglages dans le header, jamais déconnexion', (
      tester,
    ) async {
      fakeRepository.detailToReturn = ownerViewDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      final header = find.byType(WoodBackHeader);
      expect(
        find.descendant(
          of: header,
          matching: find.byIcon(Icons.settings_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.byIcon(Icons.logout)),
        findsNothing,
      );
    });

    testWidgets(
      'membre : icône déconnexion (quitter) dans le header, jamais réglages',
      (tester) async {
        fakeRepository.detailToReturn = memberViewDetail();

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();

        final header = find.byType(WoodBackHeader);
        expect(
          find.descendant(of: header, matching: find.byIcon(Icons.logout)),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: header,
            matching: find.byIcon(Icons.settings_outlined),
          ),
          findsNothing,
        );
      },
    );
  });

  group('onglet Membres', () {
    testWidgets('indicateur "Mis à jour en direct" en tête de liste', (
      tester,
    ) async {
      fakeRepository.detailToReturn = ownerViewDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(find.text('Mis à jour en direct'), findsOneWidget);
    });

    testWidgets('texte explicatif de confidentialité en pied de liste', (
      tester,
    ) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      // Écran haut : le bandeau « Pas de combat sans MJ » du propriétaire
      // sans rôle MJ pousse le pied de liste hors de la fenêtre construite.
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('voir sa fiche complète, en lecture seule'),
        findsOneWidget,
      );
    });

    testWidgets('carte "MORT" : bordure accent.brick 3px, fond dédié '
        '(distincte de la carte par défaut)', (tester) async {
      fakeRepository.detailToReturn = ownerViewDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      final deadNameFinder = find.text('Ithil');
      final deadCardFinder = find.ancestor(
        of: deadNameFinder,
        matching: find.byType(Container),
      );
      final decorations = tester
          .widgetList<Container>(deadCardFinder)
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .where(
            (decoration) => decoration.color == AppColors.deadCardBackground,
          )
          .toList();

      expect(decorations, isNotEmpty);
      expect(decorations.first.border, isA<Border>());
      final border = decorations.first.border! as Border;
      expect(border.top.color, AppColors.accentBrick);
      expect(border.top.width, AppBorders.cardEmphasis);
    });

    testWidgets('affiche tous les membres, "(toi)" sur sa propre ligne', (
      tester,
    ) async {
      fakeRepository.detailToReturn = ownerViewDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sylvi'), findsOneWidget);
      expect(find.textContaining('(toi)'), findsOneWidget);
      expect(find.textContaining('Borgan'), findsOneWidget);
      expect(find.textContaining('Ithil'), findsOneWidget);
    });

    testWidgets('badge INCONSCIENT sur le membre à 0 PV non marqué mort', (
      tester,
    ) async {
      fakeRepository.detailToReturn = ownerViewDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(find.text('INCONSCIENT'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('badge MORT sur le membre marqué is_dead, sans icône', (
      tester,
    ) async {
      fakeRepository.detailToReturn = ownerViewDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(find.text('MORT'), findsOneWidget);
    });

    testWidgets(
      'owner : bouton exclure présent sur les autres lignes, absent sur la '
      'sienne',
      (tester) async {
        fakeRepository.detailToReturn = ownerViewDetail();

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.person_remove_outlined), findsNWidgets(2));
      },
    );

    testWidgets('membre (non owner) : jamais de bouton exclure', (
      tester,
    ) async {
      fakeRepository.detailToReturn = memberViewDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_remove_outlined), findsNothing);
    });

    testWidgets(
      'exclure un membre : confirmation puis removeMember + rafraîchissement',
      (tester) async {
        fakeRepository.detailToReturn = ownerViewDetail();

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.person_remove_outlined).first);
        await tester.pumpAndSettle();

        expect(find.text('Exclure Borgan du groupe ?'), findsOneWidget);

        // `DestructiveButton` n'uppercase jamais son libellé (contrairement à
        // `PrimaryButton`/`SecondaryButton`) — le bouton affiche "Exclure"
        // tel quel, jamais "EXCLURE".
        await tester.tap(find.text('Exclure'));
        await tester.pumpAndSettle();

        expect(fakeRepository.lastRemovedUserId, 'user-2');
        expect(find.textContaining('exclu du groupe'), findsOneWidget);
      },
    );

    // D232 : aucun retour visuel pendant l'exclusion jusqu'ici.
    for (final fails in [false, true]) {
      testWidgets(
        'exclusion en cours : « Exclure » désactivé avec indicateur '
        'et libellé dédié, rétabli à la fin (${fails ? 'échec' : 'succès'})',
        (tester) async {
          final handle = tester.ensureSemantics();
          fakeRepository
            ..detailToReturn = ownerViewDetail()
            ..removeMemberCompleter = Completer<void>()
            ..removeMemberError = fails ? Exception('réseau') : null;

          await tester.pumpWidget(_buildTestWidget(fakeRepository));
          await tester.pumpAndSettle();

          final borgan = find.byKey(const ValueKey('removeMember-user-2'));
          final ithil = find.byKey(const ValueKey('removeMember-user-3'));
          await tester.tap(borgan);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Exclure'));
          await tester.pump();
          await tester.pump();

          expect(
            find.descendant(
              of: borgan,
              matching: find.byType(CircularProgressIndicator),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: borgan,
              matching: find.byIcon(Icons.person_remove_outlined),
            ),
            findsNothing,
          );
          expect(
            tester.getSemantics(borgan),
            isSemantics(
              label: 'Borgan : exclusion en cours',
              isButton: true,
              hasEnabledState: true,
              isEnabled: false,
            ),
          );
          // L'autre membre reste excluable.
          expect(
            tester.getSemantics(ithil),
            isSemantics(
              label: 'Exclure Ithil',
              isButton: true,
              hasEnabledState: true,
              isEnabled: true,
              hasTapAction: true,
            ),
          );

          fakeRepository.removeMemberCompleter!.complete();
          await tester.pumpAndSettle();

          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(
            tester.getSemantics(borgan),
            isSemantics(
              label: 'Exclure Borgan',
              isButton: true,
              hasEnabledState: true,
              isEnabled: true,
              hasTapAction: true,
            ),
          );
          handle.dispose();
        },
      );
    }

    // Relecture QA de la PR #306 : avec un seul membre « en cours », exclure
    // Ithil pendant l'exclusion de Borgan réactivait le bouton de Borgan, et
    // un second toucher renvoyait `removeMember(user-2)`.
    testWidgets('deux exclusions simultanées : aucun appel en double, chaque '
        'bouton reste désactivé jusqu\'à la fin de sa propre exclusion', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      fakeRepository
        ..detailToReturn = ownerViewDetail()
        ..removeMemberCompleters['user-2'] = Completer<void>()
        ..removeMemberCompleters['user-3'] = Completer<void>();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      final borgan = find.byKey(const ValueKey('removeMember-user-2'));
      final ithil = find.byKey(const ValueKey('removeMember-user-3'));

      /// Laisse passer l'animation de la boîte sans attendre l'indicateur,
      /// qui tourne sans fin.
      Future<void> settleDialog() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      /// Touche [button], puis confirme si la boîte s'ouvre.
      Future<void> removeVia(Finder button) async {
        await tester.tap(button);
        await settleDialog();
        final confirm = find.text('Exclure');
        if (confirm.evaluate().isNotEmpty) {
          await tester.tap(confirm.last);
          await settleDialog();
        }
      }

      Matcher disabled(String name) => isSemantics(
        label: '$name : exclusion en cours',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      );
      Matcher enabled(String name) => isSemantics(
        label: 'Exclure $name',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      );

      await removeVia(borgan);
      await removeVia(ithil);
      // Nouveau toucher sur Borgan, toujours en cours : rien ne se passe.
      await removeVia(borgan);

      expect(fakeRepository.removedUserIds, ['user-2', 'user-3']);
      expect(tester.getSemantics(borgan), disabled('Borgan'));
      expect(tester.getSemantics(ithil), disabled('Ithil'));

      fakeRepository.removeMemberCompleters['user-3']!.complete();
      await settleDialog();
      expect(tester.getSemantics(borgan), disabled('Borgan'));
      expect(tester.getSemantics(ithil), enabled('Ithil'));

      fakeRepository.removeMemberCompleters['user-2']!.complete();
      await tester.pumpAndSettle();
      expect(tester.getSemantics(borgan), enabled('Borgan'));
      expect(tester.getSemantics(ithil), enabled('Ithil'));
      expect(fakeRepository.removedUserIds, ['user-2', 'user-3']);
      handle.dispose();
    });

    // Relecture de code de la PR #306 : `GroupRepository.removeMember` lève
    // toujours une `GroupFailure` (réseau compris), et l'écran peut avoir été
    // quitté entre-temps.
    group('exclusion en échec ou suivie d\'un rechargement', () {
      const networkFailure = GroupFailure(
        'Erreur réseau.',
        code: GroupErrorCode.network,
      );
      final borgan = find.byKey(const ValueKey('removeMember-user-2'));

      /// Exclut Borgan (toucher + confirmation), sans attendre la fin de
      /// l'indicateur, qui tourne sans fin.
      Future<void> removeBorgan(WidgetTester tester) async {
        await tester.tap(borgan);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Exclure'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      for (final locale in const [Locale('fr'), Locale('en')]) {
        testWidgets('[${locale.languageCode}] échec réseau (GroupFailure) : '
            'message de la clé characterNetworkErrorMessage', (tester) async {
          fakeRepository
            ..detailToReturn = ownerViewDetail()
            ..removeMemberError = networkFailure;
          await tester.pumpWidget(
            _buildTestWidget(fakeRepository, locale: locale),
          );
          await tester.pumpAndSettle();

          await tester.tap(borgan);
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(
              lookupAppLocalizations(locale).groupMemberRemoveConfirmAction,
            ),
          );
          await tester.pumpAndSettle();

          // Clé partagée, encore au vouvoiement en français (D136, D237).
          expect(
            find.text(
              lookupAppLocalizations(locale).characterNetworkErrorMessage,
            ),
            findsOneWidget,
          );
          expect(fakeRepository.removedUserIds, ['user-2']);
        });
      }

      testWidgets('quitter l\'écran pendant une exclusion qui échoue : '
          'aucune erreur', (tester) async {
        fakeRepository
          ..detailToReturn = ownerViewDetail()
          ..removeMemberCompleters['user-2'] = Completer<void>()
          ..removeMemberError = networkFailure;
        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();
        await removeBorgan(tester);

        GoRouter.of(tester.element(find.byType(GroupScreen))).go('/');
        await tester.pumpAndSettle();
        expect(find.byType(GroupScreen), findsNothing);

        fakeRepository.removeMemberCompleters['user-2']!.complete();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(fakeRepository.removedUserIds, ['user-2']);
      });

      testWidgets('succès : « Exclure » reste désactivé jusqu\'à la fin du '
          'rechargement du groupe', (tester) async {
        final handle = tester.ensureSemantics();
        fakeRepository
          ..detailToReturn = ownerViewDetail()
          ..removeMemberCompleters['user-2'] = Completer<void>();
        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();
        await removeBorgan(tester);

        final reload = Completer<GroupDetail>();
        fakeRepository.detailCompleter = reload;
        fakeRepository.removeMemberCompleters['user-2']!.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Ancien détail toujours affiché, Borgan encore « en cours ».
        expect(find.text('Borgan a été exclu du groupe.'), findsOneWidget);
        expect(
          tester.getSemantics(borgan),
          isSemantics(
            label: 'Borgan : exclusion en cours',
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
          ),
        );

        reload.complete(
          ownerViewDetail().copyWith(members: [owner, deadMember]),
        );
        await tester.pumpAndSettle();
        expect(borgan, findsNothing);
        expect(tester.takeException(), isNull);
        handle.dispose();
      });

      testWidgets('succès puis rechargement en échec : Borgan n\'est plus '
          '« en cours » une fois le groupe relu', (tester) async {
        final handle = tester.ensureSemantics();
        fakeRepository
          ..detailToReturn = ownerViewDetail()
          ..removeMemberCompleters['user-2'] = Completer<void>();
        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();
        await removeBorgan(tester);

        final reload = Completer<GroupDetail>();
        fakeRepository.detailCompleter = reload;
        fakeRepository.removeMemberCompleters['user-2']!.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        reload.completeError(networkFailure);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Relecture réussie (Borgan encore membre côté serveur) : son
        // « Exclure » est de nouveau actif.
        fakeRepository.detailCompleter = null;
        if (find.text('RÉESSAYER').evaluate().isNotEmpty) {
          await tester.tap(find.text('RÉESSAYER'));
          await tester.pumpAndSettle();
        }
        expect(
          tester.getSemantics(borgan),
          isSemantics(
            label: 'Exclure Borgan',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasTapAction: true,
          ),
        );
        handle.dispose();
      });
    });

    // Messages de fin d'exclusion localisés, au tutoiement (D232).
    test('messages d\'exclusion au tutoiement en français', () {
      final fr = lookupAppLocalizations(const Locale('fr'));
      expect(
        fr.groupMemberRemovedSuccess('Borgan'),
        'Borgan a été exclu du groupe.',
      );
      expect(
        fr.groupMemberRemoveGenericError,
        "Impossible d'exclure ce membre. Réessaie.",
      );
      expect(
        fr.groupMemberRemoveConfirmTitle('Borgan'),
        'Exclure Borgan du groupe ?',
      );
      expect(fr.groupMemberRemoveConfirmAction, 'Exclure');
      for (final text in [
        fr.groupMemberRemovedSuccess('Borgan'),
        fr.groupMemberRemoveGenericError,
        fr.groupMemberRemoveConfirmTitle('Borgan'),
        fr.groupMemberRemoveConfirmBodyCharacter,
        fr.groupMemberRemoveConfirmBodyGameMaster,
        fr.groupMemberRemoveConfirmBodyAwaitingCharacter,
      ]) {
        expect(text, isNot(matches(RegExp(r'\b(Réessayez|vous|votre|vos)\b'))));
      }
    });

    // Textes de la boîte selon la nature du membre, en anglais (le français
    // est couvert par le groupe « message de confirmation distinct… »).
    for (final (member, body) in [
      (
        const GroupMember(
          userId: 'user-mj',
          role: GroupRole.membre,
          name: 'Brunhilde',
          isGameMaster: true,
        ),
        'They leave the group immediately.',
      ),
      (
        const GroupMember(
          userId: 'user-orphan',
          role: GroupRole.membre,
          name: 'Eldrin',
          isGameMaster: false,
        ),
        'Their character was already deleted; they leave the group '
            'immediately.',
      ),
    ]) {
      testWidgets('[en] boîte d\'exclusion de ${member.name} : « $body »', (
        tester,
      ) async {
        fakeRepository.detailToReturn = ownerViewDetail().copyWith(
          members: [owner, member],
        );
        await tester.pumpWidget(
          _buildTestWidget(fakeRepository, locale: const Locale('en')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(ValueKey('removeMember-${member.userId}')));
        await tester.pumpAndSettle();

        expect(
          find.text('Remove ${member.name} from the group?'),
          findsOneWidget,
        );
        expect(find.text(body), findsOneWidget);
        await tester.tap(find.text('CANCEL'));
        await tester.pumpAndSettle();
        expect(fakeRepository.removedUserIds, isEmpty);
      });
    }

    for (final locale in const [Locale('fr'), Locale('en')]) {
      final l10n = lookupAppLocalizations(locale);
      for (final fails in [false, true]) {
        testWidgets('[${locale.languageCode}] fin d\'exclusion '
            '(${fails ? 'échec' : 'succès'}) : message de sa clé', (
          tester,
        ) async {
          fakeRepository
            ..detailToReturn = ownerViewDetail()
            ..removeMemberError = fails ? Exception('réseau') : null;

          await tester.pumpWidget(
            _buildTestWidget(fakeRepository, locale: locale),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const ValueKey('removeMember-user-2')));
          await tester.pumpAndSettle();
          // Boîte de confirmation : textes de leurs clés.
          expect(
            find.text(l10n.groupMemberRemoveConfirmTitle('Borgan')),
            findsOneWidget,
          );
          expect(
            find.text(l10n.groupMemberRemoveConfirmBodyCharacter),
            findsOneWidget,
          );
          expect(
            find.text(l10n.groupMemberRemoveCancel.toUpperCase()),
            findsOneWidget,
          );
          await tester.tap(find.text(l10n.groupMemberRemoveConfirmAction));
          await tester.pumpAndSettle();

          expect(
            find.text(
              fails
                  ? l10n.groupMemberRemoveGenericError
                  : l10n.groupMemberRemovedSuccess('Borgan'),
            ),
            findsOneWidget,
          );
        });
      }
    }
  });

  group('Exclure un membre : message de confirmation distinct selon la nature '
      'du membre (régression — characterId == null ne doit JAMAIS confondre '
      'MJ volontaire et orphelin)', () {
    const gameMasterMember = GroupMember(
      userId: 'user-mj',
      role: GroupRole.membre,
      name: 'Brunhilde',
      isGameMaster: true,
    );
    const orphanMember = GroupMember(
      userId: 'user-orphan',
      role: GroupRole.membre,
      name: 'Eldrin',
      isGameMaster: false,
    );

    testWidgets('personnage normal : message "garde toutes ses données"', (
      tester,
    ) async {
      fakeRepository.detailToReturn = ownerViewDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_remove_outlined).first);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Son personnage garde toutes ses données, mais quitte '
          'immédiatement le groupe.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('MJ volontaire : message neutre, jamais le texte orphelin', (
      tester,
    ) async {
      fakeRepository.detailToReturn = GroupDetail(
        id: 'group-1',
        name: 'Les Lames de l\'Aube',
        ownerId: 'user-1',
        inviteCode: 'AB3F7K2M',
        currentUserId: 'user-1',
        members: [owner, gameMasterMember],
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_remove_outlined).first);
      await tester.pumpAndSettle();

      expect(
        find.text('Il/elle quitte immédiatement le groupe.'),
        findsOneWidget,
      );
      expect(find.textContaining('a déjà été supprimé'), findsNothing);
      expect(find.textContaining('garde toutes ses données'), findsNothing);
    });

    testWidgets(
      'membre orphelin : message dédié ("a déjà été supprimé"), jamais '
      'le texte MJ ni celui du personnage normal',
      (tester) async {
        fakeRepository.detailToReturn = GroupDetail(
          id: 'group-1',
          name: 'Les Lames de l\'Aube',
          ownerId: 'user-1',
          inviteCode: 'AB3F7K2M',
          currentUserId: 'user-1',
          members: [owner, orphanMember],
        );

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.person_remove_outlined).first);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Son personnage a déjà été supprimé ; il/elle quitte '
            'immédiatement le groupe.',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Il/elle quitte immédiatement le groupe.'),
          findsNothing,
        );
        expect(find.textContaining('garde toutes ses données'), findsNothing);
      },
    );
  });

  // Parcours complet avec le vrai écran Paramètres : après « Devenir MJ »,
  // l'onglet Membres propose « Lancer un combat » au lieu du bandeau.
  testWidgets('après « Devenir MJ », l\'onglet Membres affiche « Lancer un '
      'combat » au lieu de « Pas de combat sans MJ dans l\'app »', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    fakeRepository
      ..detailToReturn = ownerViewDetail()
      ..detailAfterBecomeGameMaster = ownerViewDetail().copyWith(
        members: [
          const GroupMember(
            userId: 'user-1',
            role: GroupRole.owner,
            name: 'Matthias',
            isGameMaster: true,
          ),
          unconsciousMember,
          deadMember,
        ],
      );

    await tester.pumpWidget(
      _buildTestWidget(fakeRepository, realSettings: true),
    );
    await tester.pumpAndSettle();
    expect(find.text("Pas de combat sans MJ dans l'app."), findsOneWidget);
    expect(find.text('LANCER UN COMBAT'), findsNothing);

    // Lien du bandeau vers les paramètres.
    await tester.tap(find.text('Paramètres du groupe'));
    await tester.pumpAndSettle();
    final becomeButton = find.byKey(const Key('becomeGameMasterButton'));
    await tester.ensureVisible(becomeButton);
    await tester.tap(becomeButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is PrimaryButton && widget.label == 'Devenir MJ',
      ),
    );
    await tester.pumpAndSettle();
    expect(fakeRepository.becomeGameMasterCalls, 1);

    // Retour à l'écran Groupe.
    GoRouter.of(tester.element(find.byType(GroupSettingsScreen))).pop();
    await tester.pumpAndSettle();

    expect(find.byType(GroupScreen), findsOneWidget);
    expect(find.text("Pas de combat sans MJ dans l'app."), findsNothing);
    expect(find.text('LANCER UN COMBAT'), findsOneWidget);
  });

  group('quitter le groupe (membre, icône du header)', () {
    testWidgets(
      'confirmation puis leaveGroup, navigation vers / avec SnackBar',
      (tester) async {
        fakeRepository.detailToReturn = memberViewDetail();

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();

        await tester.tap(
          find.descendant(
            of: find.byType(WoodBackHeader),
            matching: find.byIcon(Icons.logout),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Quitter'), findsWidgets);

        // Même remarque que pour "Exclure" : `DestructiveButton` garde la
        // casse du libellé fourni.
        await tester.tap(find.text('Quitter'));
        await tester.pumpAndSettle();

        expect(fakeRepository.leaveGroupCalled, isTrue);
        expect(find.text('Liste des personnages'), findsOneWidget);
        expect(find.text('Tu as quitté le groupe.'), findsOneWidget);
      },
    );
    testWidgets('quitter invalide le cache des groupes d\'un personnage (le '
        'bandeau de combat disparaît sans attendre)', (tester) async {
      fakeRepository.detailToReturn = memberViewDetail();
      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      container.listen(characterGroupIdsProvider('c-1'), (_, _) {});
      await tester.pumpAndSettle();
      expect(fakeRepository.idsCalls, 1);

      await tester.tap(
        find.descendant(
          of: find.byType(WoodBackHeader),
          matching: find.byIcon(Icons.logout),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitter'));
      await tester.pumpAndSettle();

      expect(fakeRepository.leaveGroupCalled, isTrue);
      expect(fakeRepository.idsCalls, 2);
    });
  });

  group('quitter le groupe (lien en pied de l\'onglet Membres)', () {
    testWidgets(
      'membre : le lien "Quitter le groupe" est présent et fonctionne',
      (tester) async {
        fakeRepository.detailToReturn = memberViewDetail();

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();

        // Le lien est en pied de liste : il faut défiler jusqu'à lui (le badge
        // de statut sur sa propre ligne allonge la carte d'un membre).
        await tester.scrollUntilVisible(
          find.text('Quitter le groupe'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text('Quitter le groupe'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Quitter'));
        await tester.pumpAndSettle();

        expect(fakeRepository.leaveGroupCalled, isTrue);
        expect(find.text('Tu as quitté le groupe.'), findsOneWidget);
      },
    );

    testWidgets('owner (fondateur) : le lien "Quitter le groupe" est absent — '
        'décision du chef de projet, un fondateur dissout son groupe plutôt '
        'que de le quitter (voir GroupMembersTabBody.onLeaveGroup)', (
      tester,
    ) async {
      fakeRepository.detailToReturn = ownerViewDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(find.text('Quitter le groupe'), findsNothing);
    });
  });

  group('onglet Butin', () {
    // Objet personnalisé (description portée par l'entrée) et objet du
    // catalogue (description relue par `item_id` à l'ouverture de la fiche).
    final moonVial = GroupTreasureItem.custom(
      entryId: 'entry-vial',
      name: 'Fiole de lune',
      quantity: 2,
      description: 'Brille faiblement la nuit.',
    );
    const potion = GroupTreasureItem(
      entryId: 'entry-potion',
      itemId: 7,
      displayName: 'Potion',
      quantity: 3,
      category: 'equipement_general',
    );

    Future<void> openTreasureTab(WidgetTester tester) async {
      await tester.tap(find.text('BUTIN'));
      await tester.pumpAndSettle();
    }

    testWidgets('affiche les tuiles de monnaie, l\'état vide des objets et la '
        'tuile « Objet » de l\'inventaire', (tester) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = const GroupTreasure(
        groupId: 'group-1',
        currencyGp: 12,
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await openTreasureTab(tester);

      expect(find.text('12'), findsOneWidget);
      expect(find.text('Aucun objet en attente.'), findsOneWidget);
      expect(find.text('Objet'), findsOneWidget);
      // L'ancien bouton unique « Ajouter au butin du groupe » a disparu.
      expect(find.text('AJOUTER AU BUTIN DU GROUPE'), findsNothing);
    });

    testWidgets(
      '"Répartir vers mon inventaire" désactivé quand le butin est vide',
      (tester) async {
        fakeRepository.detailToReturn = ownerViewDetail();
        fakeRepository.treasureToReturn = const GroupTreasure(
          groupId: 'group-1',
        );

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();
        await openTreasureTab(tester);

        await tester.tap(find.text('Répartir vers mon inventaire'));
        await tester.pumpAndSettle();

        expect(find.text("S'ATTRIBUER DE LA MONNAIE"), findsNothing);
      },
    );

    testWidgets('la ligne n\'a plus de raccourci « S\'attribuer » : toucher la '
        'carte ouvre la fiche de l\'objet', (tester) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = GroupTreasure(
        groupId: 'group-1',
        items: [moonVial],
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await openTreasureTab(tester);

      expect(find.text('Fiole de lune'), findsOneWidget);
      expect(find.text("S'attribuer"), findsNothing);

      await tester.tap(find.text('Fiole de lune'));
      await tester.pumpAndSettle();

      expect(find.text('FIOLE DE LUNE'), findsOneWidget);
      expect(find.text('Provenance'), findsOneWidget);
      expect(find.text('Objet personnalisé'), findsWidgets);
      expect(find.text('×2'), findsOneWidget);
      expect(find.text('Brille faiblement la nuit.'), findsOneWidget);
      expect(find.text("S'ATTRIBUER"), findsOneWidget);
      expect(find.text('MODIFIER'), findsOneWidget);
      expect(find.text('Retirer du butin'), findsOneWidget);
      // Objet personnalisé : aucune relecture réseau.
      expect(fakeRepository.detailsFetchCount, 0);
    });

    testWidgets(
      'objet du catalogue : description relue par item_id (indicateur '
      'pendant le chargement, actions actives)',
      (tester) async {
        fakeRepository.detailToReturn = ownerViewDetail();
        fakeRepository.treasureToReturn = const GroupTreasure(
          groupId: 'group-1',
          items: [potion],
        );
        final completer = Completer<CharacterInventoryItem>();
        fakeRepository.detailsCompleter = completer;

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();
        await openTreasureTab(tester);

        await tester.tap(find.text('Potion'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(fakeRepository.detailsFetchCount, 1);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Catalogue'), findsOneWidget);
        final claim = tester.widget<PrimaryButton>(
          find.byKey(const Key('groupTreasureItemClaimButton')),
        );
        expect(claim.onPressed, isNotNull);

        completer.complete(
          GroupTreasureInventoryAdapter.toInventoryItem(
            potion,
            itemRow: const {'category': 'equipement_general', 'weight': 0.5},
            description: 'Rend 2d4+2 points de vie.',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Rend 2d4+2 points de vie.'), findsOneWidget);
      },
    );

    testWidgets('objet du catalogue : erreur de lecture -> message et '
        '« Réessayer » relance la lecture', (tester) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = const GroupTreasure(
        groupId: 'group-1',
        items: [potion],
      );
      fakeRepository.detailsError = const GroupFailure(
        'réseau',
        code: GroupErrorCode.network,
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await openTreasureTab(tester);
      await tester.tap(find.text('Potion'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de charger la description.'),
        findsOneWidget,
      );

      fakeRepository.detailsError = null;
      fakeRepository.detailsToReturn =
          GroupTreasureInventoryAdapter.toInventoryItem(
            potion,
            description: 'Rend 2d4+2 points de vie.',
          );
      await tester.tap(find.byKey(const Key('groupTreasureItemDetailsRetry')));
      await tester.pumpAndSettle();

      expect(fakeRepository.detailsFetchCount, 2);
      expect(find.text('Rend 2d4+2 points de vie.'), findsOneWidget);
    });

    testWidgets("S'attribuer : fiche -> sheet de quantité plafonnée -> "
        'claimTreasureItem avec l\'entrée vue, puis rechargement', (
      tester,
    ) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = const GroupTreasure(
        groupId: 'group-1',
        items: [potion],
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await openTreasureTab(tester);
      await tester.tap(find.text('Potion'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('groupTreasureItemClaimButton')));
      await tester.pumpAndSettle();

      expect(find.text("S'attribuer Potion"), findsOneWidget);
      // Plafond : la quantité disponible (3).
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text("S'ATTRIBUER"));
      await tester.pumpAndSettle();

      expect(fakeRepository.lastClaimedQuantity, 3);
      expect(fakeRepository.lastClaimedItem, potion);
      expect(find.text('Objet ajouté à ton inventaire.'), findsOneWidget);
      expect(fakeRepository.treasureFetchCount, greaterThanOrEqualTo(2));
    });

    testWidgets('Retirer du butin : confirmation (titre et texte du butin), '
        'puis removeTreasureItem et message', (tester) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = GroupTreasure(
        groupId: 'group-1',
        items: [moonVial],
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await openTreasureTab(tester);
      await tester.tap(find.text('Fiole de lune'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('groupTreasureItemRemoveButton')));
      await tester.pumpAndSettle();

      expect(find.text('Retirer Fiole de lune du butin ?'), findsOneWidget);
      expect(
        find.text(
          'Les 2 exemplaires disparaissent du butin pour tout le groupe. '
          'Cette action est définitive.',
        ),
        findsOneWidget,
      );

      // Annuler : rien n'est retiré.
      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();
      expect(fakeRepository.lastRemovedItem, isNull);

      await tester.tap(find.text('Fiole de lune'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('groupTreasureItemRemoveButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirer'));
      await tester.pumpAndSettle();

      expect(fakeRepository.lastRemovedItem, moonVial);
      expect(find.text('Fiole de lune retiré du butin.'), findsOneWidget);
    });

    testWidgets('Modifier un objet du catalogue : seulement sa quantité '
        '(min 1, bouton Enregistrer)', (tester) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = const GroupTreasure(
        groupId: 'group-1',
        items: [potion],
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await openTreasureTab(tester);
      await tester.tap(find.text('Potion'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('groupTreasureItemEditButton')));
      await tester.pumpAndSettle();

      expect(find.text('Quantité de Potion'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(fakeRepository.lastUpdatedExpected, potion);
      expect(fakeRepository.lastUpdatedItem?.quantity, 4);
      expect(fakeRepository.lastUpdatedItem?.entryId, 'entry-potion');
      expect(find.text('Objet modifié.'), findsOneWidget);
    });

    testWidgets('Modifier un objet personnalisé sans type : formulaire en deux '
        'temps (mode « Enrichir »), quantité modifiable', (tester) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = GroupTreasure(
        groupId: 'group-1',
        items: [moonVial],
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await openTreasureTab(tester);
      await tester.tap(find.text('Fiole de lune'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('groupTreasureItemEditButton')));
      await tester.pumpAndSettle();

      expect(find.text("ENRICHIR L'OBJET"), findsOneWidget);
      await tester.tap(find.byKey(const Key('customItemKindOther')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('customItemNameField')),
        'Fiole de lune pleine',
      );
      await tester.pumpAndSettle();
      expect(find.text('QUANTITÉ'), findsOneWidget);
      await tester.ensureVisible(find.byIcon(Icons.add).last);
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();

      final updated = fakeRepository.lastUpdatedItem!;
      expect(fakeRepository.lastUpdatedExpected, moonVial);
      expect(updated.customName, 'Fiole de lune pleine');
      expect(updated.quantity, 3);
      expect(updated.customDescription, 'Brille faiblement la nuit.');
      expect(updated.enrichment?.kind, 'autre');
    });

    testWidgets('objet modifié entre-temps par un autre membre : message '
        'dédié et butin rechargé', (tester) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = const GroupTreasure(
        groupId: 'group-1',
        items: [potion],
      );
      fakeRepository.treasureWriteError = const GroupFailure(
        'périmé',
        code: GroupErrorCode.treasureStale,
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await openTreasureTab(tester);
      final fetchesBefore = fakeRepository.treasureFetchCount;
      await tester.tap(find.text('Potion'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('groupTreasureItemRemoveButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirer'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Un autre membre vient de modifier ou d'attribuer cet objet. "
          'Vérifie et recommence.',
        ),
        findsOneWidget,
      );
      expect(fakeRepository.treasureFetchCount, greaterThan(fetchesBefore));
    });

    testWidgets('ajout par le parcours de l\'inventaire : « Objet » -> '
        'catalogue en sélection multiple -> addTreasureItems', (tester) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = const GroupTreasure(groupId: 'group-1');

      await tester.pumpWidget(
        _buildTestWidget(
          fakeRepository,
          catalog: const [
            InventoryCatalogItem(
              id: 3,
              name: 'Corde',
              category: 'equipement_general',
              costAmount: 1,
              weight: 5,
            ),
            InventoryCatalogItem(
              id: 9,
              name: 'Dague',
              category: 'arme',
              costAmount: 2,
              weight: 0.5,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await openTreasureTab(tester);

      await tester.tap(find.text('Objet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Depuis le catalogue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Corde'));
      await tester.tap(find.text('Dague'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AJOUTER (2)'));
      await tester.pumpAndSettle();

      final added = fakeRepository.lastAddedItems!;
      expect(added, hasLength(2));
      expect(added.map((item) => item.itemId), [3, 9]);
      expect(added.last.category, 'arme');
      expect(added.last.weight, 0.5);
      expect(find.text('Butin mis à jour.'), findsOneWidget);
    });

    testWidgets('monnaie modifiable comme dans l\'inventaire : toucher la '
        'tuile PO, ajouter 5 -> setTreasureCurrency conditionnel', (
      tester,
    ) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = const GroupTreasure(
        groupId: 'group-1',
        currencyGp: 12,
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await openTreasureTab(tester);

      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '5');
      await tester.pumpAndSettle();
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(fakeRepository.lastCurrencyExpected, {CurrencyKind.gold: 12});
      expect(fakeRepository.lastAddedTotals, {CurrencyKind.gold: 17});
      expect(find.text('Butin mis à jour.'), findsOneWidget);
    });

    testWidgets('hors connexion : bandeau, tuiles de monnaie et « Objet » '
        'désactivés, fiche en lecture (trois actions désactivées)', (
      tester,
    ) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = GroupTreasure(
        groupId: 'group-1',
        currencyGp: 12,
        items: [moonVial],
      );
      final connectivity = FakeConnectivityChecker(connected: false);

      await tester.pumpWidget(
        _buildTestWidget(fakeRepository, connectivity: connectivity),
      );
      await tester.pumpAndSettle();
      await openTreasureTab(tester);

      const banner =
          "Pas de connexion : le butin est en lecture seule jusqu'au retour "
          'du réseau.';
      expect(find.text(banner), findsOneWidget);

      // Tuile de monnaie : aucune sheet d'ajustement.
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      expect(find.text('APPLIQUER'), findsNothing);
      // Tuile « Objet » : aucune sheet d'entrée.
      await tester.tap(find.text('Objet'));
      await tester.pumpAndSettle();
      expect(find.text('Depuis le catalogue'), findsNothing);

      await tester.tap(find.text('Fiole de lune'));
      await tester.pumpAndSettle();
      for (final key in const [
        'groupTreasureItemClaimButton',
        'groupTreasureItemEditButton',
        'groupTreasureItemRemoveButton',
      ]) {
        final finder = find.byKey(Key(key));
        final widget = tester.widget(finder);
        final onPressed = switch (widget) {
          PrimaryButton(:final onPressed) => onPressed,
          SecondaryButton(:final onPressed) => onPressed,
          DestructiveButton(:final onPressed) => onPressed,
          _ => throw StateError('bouton inattendu'),
        };
        expect(onPressed, isNull, reason: key);
      }
      expect(find.text(banner), findsNWidgets(2));
    });

    testWidgets('fiche : la connexion est surveillée en direct, les actions '
        'se réactivent au retour du réseau sans rouvrir la fiche', (
      tester,
    ) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = GroupTreasure(
        groupId: 'group-1',
        items: [moonVial],
      );
      final connectivity = FakeConnectivityChecker(connected: false);

      await tester.pumpWidget(
        _buildTestWidget(fakeRepository, connectivity: connectivity),
      );
      await tester.pumpAndSettle();
      await openTreasureTab(tester);
      await tester.tap(find.text('Fiole de lune'));
      await tester.pumpAndSettle();

      VoidCallback? claimAction() => tester
          .widget<PrimaryButton>(
            find.byKey(const Key('groupTreasureItemClaimButton')),
          )
          .onPressed;
      VoidCallback? removeAction() => tester
          .widget<DestructiveButton>(
            find.byKey(const Key('groupTreasureItemRemoveButton')),
          )
          .onPressed;
      expect(claimAction(), isNull);
      expect(removeAction(), isNull);

      connectivity.goOnline();
      await tester.pumpAndSettle();

      expect(claimAction(), isNotNull);
      expect(removeAction(), isNotNull);
      expect(
        find.text(
          "Pas de connexion : le butin est en lecture seule jusqu'au retour "
          'du réseau.',
        ),
        findsNothing,
      );
    });

    group('bandeau « en ligne » mais vérification « hors connexion » juste '
        'avant l\'écriture : aucune écriture ne part', () {
      const offlineError =
          "Pas de connexion : le butin n'a pas été modifié. Réessaie une fois "
          'connecté.';

      /// Ouvre l'onglet en ligne puis coupe le réseau **sans** prévenir le
      /// flux de connectivité : le bandeau reste « en ligne », seule la
      /// vérification faite au moment d'écrire voit la coupure.
      Future<FakeConnectivityChecker> openOnlineThenCut(
        WidgetTester tester,
        GroupTreasure treasure,
      ) async {
        fakeRepository.detailToReturn = ownerViewDetail();
        fakeRepository.treasureToReturn = treasure;
        final connectivity = FakeConnectivityChecker();
        await tester.pumpWidget(
          _buildTestWidget(fakeRepository, connectivity: connectivity),
        );
        await tester.pumpAndSettle();
        await openTreasureTab(tester);
        connectivity.connected = false;
        return connectivity;
      }

      testWidgets('attribution d\'un objet', (tester) async {
        await openOnlineThenCut(
          tester,
          const GroupTreasure(groupId: 'group-1', items: [potion]),
        );
        await tester.tap(find.text('Potion'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('groupTreasureItemClaimButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.text("S'ATTRIBUER"));
        await tester.pumpAndSettle();

        expect(fakeRepository.lastClaimedQuantity, isNull);
        expect(find.text(offlineError), findsOneWidget);
      });

      testWidgets('modification', (tester) async {
        await openOnlineThenCut(
          tester,
          const GroupTreasure(groupId: 'group-1', items: [potion]),
        );
        await tester.tap(find.text('Potion'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('groupTreasureItemEditButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('ENREGISTRER'));
        await tester.pumpAndSettle();

        expect(fakeRepository.lastUpdatedItem, isNull);
        expect(find.text(offlineError), findsOneWidget);
      });

      testWidgets('retrait', (tester) async {
        await openOnlineThenCut(
          tester,
          GroupTreasure(groupId: 'group-1', items: [moonVial]),
        );
        await tester.tap(find.text('Fiole de lune'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('groupTreasureItemRemoveButton')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Retirer'));
        await tester.pumpAndSettle();

        expect(fakeRepository.lastRemovedItem, isNull);
        expect(find.text(offlineError), findsOneWidget);
      });

      testWidgets('ajustement de la monnaie', (tester) async {
        await openOnlineThenCut(
          tester,
          const GroupTreasure(groupId: 'group-1', currencyGp: 12),
        );
        await tester.tap(find.text('12'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, '5');
        await tester.pumpAndSettle();
        await tester.tap(find.text('APPLIQUER'));
        await tester.pumpAndSettle();

        expect(fakeRepository.lastAddedTotals, isNull);
        expect(find.text(offlineError), findsOneWidget);
      });

      testWidgets('répartition de la monnaie (« Répartir vers mon '
          'inventaire »)', (tester) async {
        await openOnlineThenCut(
          tester,
          const GroupTreasure(groupId: 'group-1', currencyGp: 20),
        );
        await tester.tap(find.text('Répartir vers mon inventaire'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), '5');
        await tester.pumpAndSettle();
        await tester.tap(find.text("S'ATTRIBUER"));
        await tester.pumpAndSettle();

        expect(fakeRepository.claimCurrencyCallCount, 0);
        expect(find.text(offlineError), findsOneWidget);
      });
    });

    testWidgets('platine à 0 : sa tuile reste affichée et permet d\'en '
        'ajouter (décision 92)', (tester) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = const GroupTreasure(
        groupId: 'group-1',
        currencyGp: 12,
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await openTreasureTab(tester);

      expect(find.text('PP'), findsOneWidget);
      expect(find.text('PE'), findsOneWidget);
      await tester.tap(find.text('PP'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '2');
      await tester.pumpAndSettle();
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(fakeRepository.lastCurrencyExpected, {CurrencyKind.platinum: 0});
      expect(fakeRepository.lastAddedTotals, {CurrencyKind.platinum: 2});
    });

    testWidgets(
      "réclamer de la monnaie : succès total appelle claimTreasureCurrency "
      "pour chaque dénomination saisie et affiche 'Monnaie récupérée.'",
      (tester) async {
        fakeRepository.detailToReturn = ownerViewDetail();
        fakeRepository.treasureToReturn = const GroupTreasure(
          groupId: 'group-1',
          currencyGp: 20,
          currencySp: 10,
        );
        fakeRepository.claimCurrencyResult = true;

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();
        await openTreasureTab(tester);

        await tester.tap(find.text('Répartir vers mon inventaire'));
        await tester.pumpAndSettle();

        // Ordre des champs de `claim_group_treasure_currency_sheet.dart` :
        // PO, PA, PC, PP, PE.
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), '5'); // PO
        await tester.enterText(fields.at(1), '3'); // PA
        await tester.pumpAndSettle();

        await tester.tap(find.text("S'ATTRIBUER"));
        await tester.pumpAndSettle();

        expect(fakeRepository.claimCurrencyCallCount, 2);
        expect(fakeRepository.lastClaimedAmounts[CurrencyKind.gold], 5);
        expect(fakeRepository.lastClaimedAmounts[CurrencyKind.silver], 3);
        expect(find.text('Monnaie récupérée.'), findsOneWidget);
        // Le butin est rafraîchi après la réclamation (nouveau solde côté
        // serveur), pas seulement mis à jour de façon optimiste.
        expect(fakeRepository.treasureFetchCount, greaterThanOrEqualTo(2));
      },
    );

    testWidgets(
      "réclamer de la monnaie : échec total (un autre membre a modifié le "
      "butin entretemps) affiche le message dédié, jamais 'Monnaie "
      "récupérée.'",
      (tester) async {
        fakeRepository.detailToReturn = ownerViewDetail();
        fakeRepository.treasureToReturn = const GroupTreasure(
          groupId: 'group-1',
          currencyGp: 20,
        );
        fakeRepository.claimCurrencyResult = false;

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();
        await openTreasureTab(tester);

        await tester.tap(find.text('Répartir vers mon inventaire'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField).at(0), '5');
        await tester.pumpAndSettle();
        await tester.tap(find.text("S'ATTRIBUER"));
        await tester.pumpAndSettle();

        expect(
          find.text('Un autre membre vient de modifier le butin. Réessaie.'),
          findsOneWidget,
        );
        expect(find.text('Monnaie récupérée.'), findsNothing);
      },
    );

    testWidgets(
      'réclamer de la monnaie : échec PARTIEL (une dénomination refusée par '
      "la décrémentation atomique, l'autre acceptée) — message récapitulatif "
      'honnête plutôt que succès/échec binaire, voir '
      '_GroupScreenState._claimCurrency',
      (tester) async {
        fakeRepository.detailToReturn = ownerViewDetail();
        fakeRepository.treasureToReturn = const GroupTreasure(
          groupId: 'group-1',
          currencyGp: 20,
          currencySp: 10,
        );
        // PA refusée (un autre membre l'a réclamée entretemps), PO acceptée.
        fakeRepository.failingCurrencies = {CurrencyKind.silver};

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();
        await openTreasureTab(tester);

        await tester.tap(find.text('Répartir vers mon inventaire'));
        await tester.pumpAndSettle();

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), '5'); // PO — acceptée
        await tester.enterText(fields.at(1), '3'); // PA — refusée
        await tester.pumpAndSettle();
        await tester.tap(find.text("S'ATTRIBUER"));
        await tester.pumpAndSettle();

        expect(fakeRepository.claimCurrencyCallCount, 2);
        expect(
          find.textContaining('PA non récupérées'),
          findsOneWidget,
          reason:
              'les deux dénominations sont réclamées séquentiellement '
              '(jamais un lire-puis-écrire manuel groupé) : un cas partiel '
              'doit informer honnêtement des dénominations perdues',
        );
        expect(find.text('Monnaie récupérée.'), findsNothing);
        expect(
          find.text('Un autre membre vient de modifier le butin. Réessaie.'),
          findsNothing,
        );
      },
    );
  });

  group('onglet Notes (fractionné en entrées multiples le 07/11/2026, voir '
      'group_notes_tab_body_test.dart pour le détail ligne/sheet)', () {
    testWidgets('affiche les entrées déjà enregistrées (plus récent -> plus '
        'ancien)', (tester) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.entriesToReturn = [
        GroupNoteEntry(
          id: 'entry-2',
          title: 'Chapitre 2',
          body: 'Combat contre les gobelins.',
          createdAt: DateTime(2026, 9, 8, 20, 30),
        ),
        GroupNoteEntry(
          id: 'entry-1',
          body: 'Le MJ a mentionné une amulette bleue.',
          createdAt: DateTime(2026, 9, 1, 20, 0),
        ),
      ];

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NOTES'));
      await tester.pumpAndSettle();

      expect(find.text('Chapitre 2'), findsOneWidget);
      expect(find.text('Combat contre les gobelins.'), findsOneWidget);
      expect(
        find.text('Le MJ a mentionné une amulette bleue.'),
        findsOneWidget,
      );
    });

    testWidgets('aucune entrée : état vide, tuile "Ajouter une note" '
        'toujours visible', (tester) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.entriesToReturn = const [];

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NOTES'));
      await tester.pumpAndSettle();

      expect(find.text('Aucune note pour l\'instant.'), findsOneWidget);
      expect(find.text('Ajouter une note'), findsOneWidget);
    });

    testWidgets(
      '"Ajouter une note" ouvre la sheet ; saisie + Enregistrer appelle '
      'addGroupNoteEntry et affiche la confirmation',
      (tester) async {
        fakeRepository.detailToReturn = ownerViewDetail();
        fakeRepository.entriesToReturn = const [];

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();
        await tester.tap(find.text('NOTES'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ajouter une note'));
        await tester.pumpAndSettle();

        expect(find.text('AJOUTER UNE NOTE'), findsOneWidget);

        await tester.enterText(
          find.byType(TextFormField).last,
          'Piège découvert dans la crypte.',
        );
        await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
        await tester.pumpAndSettle();

        expect(fakeRepository.addNoteCallCount, 1);
        expect(
          fakeRepository.lastAddedNoteBody,
          'Piège découvert dans la crypte.',
        );
        expect(find.text('Note ajoutée.'), findsOneWidget);
      },
    );

    testWidgets('échec de l\'enregistrement (GroupFailure) : bandeau d\'erreur '
        'inline, sheet reste ouverte, jamais "Note ajoutée."', (tester) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.entriesToReturn = const [];
      fakeRepository.addNoteError = const GroupFailure(
        'Impossible d\'enregistrer : session expirée.',
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NOTES'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajouter une note'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).last, 'Un indice.');
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible d\'enregistrer : session expirée.'),
        findsOneWidget,
      );
      expect(find.text('Note ajoutée.'), findsNothing);
    });

    testWidgets('tap sur une ligne -> "Supprimer" + confirmer appelle '
        'deleteGroupNoteEntry et affiche la confirmation', (tester) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.entriesToReturn = [
        GroupNoteEntry(
          id: 'entry-1',
          body: 'Le MJ a mentionné une amulette bleue.',
          createdAt: DateTime(2026, 9, 1, 20, 0),
        ),
      ];

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await tester.tap(find.text('NOTES'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Le MJ a mentionné une amulette bleue.'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer').last);
      await tester.pumpAndSettle();

      expect(fakeRepository.deleteNoteCallCount, 1);
      expect(fakeRepository.lastDeletedNoteEntryId, 'entry-1');
      expect(find.text('Note supprimée.'), findsOneWidget);
    });
  });

  group('MJ sans personnage (décision du 12-13/10/2026)', () {
    final gameMaster = const GroupMember(
      userId: 'user-mj',
      role: GroupRole.membre,
      name: 'Brunhilde',
      isGameMaster: true,
    );

    GroupDetail gameMasterViewDetail() => GroupDetail(
      id: 'group-1',
      name: 'Les Lames de l\'Aube',
      ownerId: 'user-1',
      inviteCode: 'AB3F7K2M',
      currentUserId: 'user-mj',
      members: [owner, gameMaster],
    );

    testWidgets(
      'onglet Membres : libellé "MJ - {nom}", texte PV neutre, pas de zone '
      'de tap',
      (tester) async {
        fakeRepository.detailToReturn = gameMasterViewDetail();

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('MJ - Brunhilde', findRichText: true),
          findsOneWidget,
        );
        expect(find.text('Ne suit pas ses PV ici.'), findsOneWidget);

        // Aucun `InkWell` enveloppant la carte "Brunhilde" (rien à ouvrir).
        final gmCardText = find.textContaining('Brunhilde', findRichText: true);
        final gmInkWell = find.ancestor(
          of: gmCardText,
          matching: find.byType(InkWell),
        );
        expect(gmInkWell, findsNothing);
      },
    );

    testWidgets(
      'owner : exclure le MJ sans personnage appelle removeMember avec son '
      'userId (characterId est null, inutilisable comme clé)',
      (tester) async {
        fakeRepository.detailToReturn = GroupDetail(
          id: 'group-1',
          name: 'Les Lames de l\'Aube',
          ownerId: 'user-1',
          inviteCode: 'AB3F7K2M',
          currentUserId: 'user-1',
          members: [owner, gameMaster],
        );

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.person_remove_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Exclure'));
        await tester.pumpAndSettle();

        expect(fakeRepository.lastRemovedUserId, 'user-mj');
        expect(find.textContaining('a été exclu du groupe'), findsOneWidget);
      },
    );

    testWidgets(
      'onglet Butin : bandeau dédié, "Répartir vers mon inventaire" assourdi ; '
      'la fiche refuse "S\'attribuer" (légende) mais permet Modifier et '
      'Retirer (décision 91 : tout membre)',
      (tester) async {
        fakeRepository.detailToReturn = gameMasterViewDetail();
        fakeRepository.treasureToReturn = const GroupTreasure(
          groupId: 'group-1',
          currencyGp: 12,
          items: [
            GroupTreasureItem(itemId: 7, displayName: 'Potion', quantity: 1),
          ],
        );

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();
        await tester.tap(find.text('BUTIN'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining("tu peux gérer le butin commun mais pas"),
          findsOneWidget,
        );

        await tester.tap(find.text('Répartir vers mon inventaire'));
        await tester.pumpAndSettle();
        expect(fakeRepository.claimCurrencyCallCount, 0);
        expect(find.text("S'ATTRIBUER DE LA MONNAIE"), findsNothing);

        // Entrée ancienne (sans entry_id ni catégorie) : la carte s'affiche
        // et ouvre la fiche.
        await tester.tap(find.text('Potion'));
        await tester.pumpAndSettle();

        final claim = tester.widget<PrimaryButton>(
          find.byKey(const Key('groupTreasureItemClaimButton')),
        );
        expect(claim.onPressed, isNull);
        expect(
          find.text(
            "Il te faut un personnage dans ce groupe pour t'attribuer un "
            'objet.',
          ),
          findsOneWidget,
        );
        final edit = tester.widget<SecondaryButton>(
          find.byKey(const Key('groupTreasureItemEditButton')),
        );
        expect(edit.onPressed, isNotNull);
        final remove = tester.widget<DestructiveButton>(
          find.byKey(const Key('groupTreasureItemRemoveButton')),
        );
        expect(remove.onPressed, isNotNull);

        // Le MJ sans personnage retire l'objet du butin.
        await tester.tap(
          find.byKey(const Key('groupTreasureItemRemoveButton')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Retirer'));
        await tester.pumpAndSettle();
        expect(fakeRepository.lastRemovedItem?.itemId, 7);
        expect(fakeRepository.lastClaimedQuantity, isNull);
      },
    );

    testWidgets(
      'onglet Notes (F02a, comité de revue du 06/11/2026 ; inchangé par le '
      'fractionnement du 07/11/2026) : accessible comme n\'importe quel '
      'membre — affiche ses entrées, jamais l\'ancien état bloquant',
      (tester) async {
        fakeRepository.detailToReturn = gameMasterViewDetail();
        fakeRepository.entriesToReturn = [
          GroupNoteEntry(
            id: 'entry-1',
            body: 'Le groupe attaque le donjon ce soir.',
            createdAt: DateTime(2026, 9, 1),
          ),
        ];

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();
        await tester.tap(find.text('NOTES'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Le carnet de notes est propre à un personnage'),
          findsNothing,
        );
        expect(
          find.text('Le groupe attaque le donjon ce soir.'),
          findsOneWidget,
        );
        expect(fakeRepository.entriesFetchCount, 1);
      },
    );

    testWidgets(
      'onglet Notes : "Ajouter une note" appelle addGroupNoteEntry sans '
      'dépendre d\'un personnage (RLS filtre déjà sur user_id)',
      (tester) async {
        fakeRepository.detailToReturn = gameMasterViewDetail();
        fakeRepository.entriesToReturn = const [];

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();
        await tester.tap(find.text('NOTES'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ajouter une note'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).last,
          'Le MJ note une embuscade au pont.',
        );
        await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
        await tester.pumpAndSettle();

        expect(fakeRepository.addNoteCallCount, 1);
        expect(
          fakeRepository.lastAddedNoteBody,
          'Le MJ note une embuscade au pont.',
        );
        expect(find.text('Note ajoutée.'), findsOneWidget);
      },
    );
  });

  group('gestion du groupe (owner)', () {
    testWidgets(
      "l'icône réglages navigue vers l'écran dédié /groups/:id/settings "
      '(recettage direction-artistique du 13/09/2026 : remplace la sheet '
      '"GESTION DU GROUPE", voir group_settings_screen_test.dart pour le '
      'contenu de cet écran)',
      (tester) async {
        fakeRepository.detailToReturn = ownerViewDetail();

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Paramètres du groupe group-1'), findsOneWidget);
      },
    );
  });

  // Étape 4 : `groups` n'est pas diffusée en temps réel, la campagne est
  // relue à chaque lecture du détail (ouverture, rafraîchissement).
  testWidgets('campagne : carte dans l\'onglet Membres, titre changé dans '
      'Grimoire visible à la relecture, retirée quand elle est dissociée', (
    tester,
  ) async {
    fakeRepository.detailToReturn = ownerViewDetail().copyWith(
      storyTitle: 'La Mine perdue',
      storySummaryPublic: 'Phandaline est menacée.',
    );
    await tester.pumpWidget(_buildTestWidget(fakeRepository));
    await tester.pumpAndSettle();

    expect(find.byType(GroupCampaignCard), findsOneWidget);
    expect(
      find.text('Campagne\u00a0: La Mine perdue', findRichText: true),
      findsOneWidget,
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(GroupScreen)),
    );
    fakeRepository.detailToReturn = ownerViewDetail().copyWith(
      storyTitle: 'Le Dragon de Glace',
    );
    container.invalidate(groupDetailProvider('group-1'));
    await tester.pumpAndSettle();

    expect(
      find.text('Campagne\u00a0: Le Dragon de Glace', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('La Mine perdue', findRichText: true),
      findsNothing,
    );

    fakeRepository.detailToReturn = ownerViewDetail();
    container.invalidate(groupDetailProvider('group-1'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupCampaignCard), findsNothing);
  });
}
