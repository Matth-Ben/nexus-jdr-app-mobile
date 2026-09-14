// Tests de widget de l'écran "Groupe" (route /groups/:id) — voir
// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/theme/app_spacing.dart';
import 'package:personnages/core/widgets/wood_back_header.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/created_group.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_preview.dart';
import 'package:personnages/features/groups/domain/group_role.dart';
import 'package:personnages/features/groups/domain/group_summary.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/domain/joined_group.dart';
import 'package:personnages/features/groups/presentation/group_screen.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';

class _NoopSubscription implements GroupRealtimeSubscription {
  @override
  Future<void> cancel() async {}
}

class _FakeGroupRepository implements GroupRepository {
  GroupDetail? detailToReturn;
  Object? detailErrorToThrow;
  Completer<GroupDetail>? detailCompleter;
  int detailFetchCount = 0;

  GroupTreasure? treasureToReturn;
  Object? treasureErrorToThrow;

  Object? removeMemberError;
  String? lastRemovedCharacterId;

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
  List<GroupTreasureItem>? lastAddedItems;

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
    required List<String> characterIds,
    required void Function() onChanged,
  }) => _NoopSubscription();

  @override
  Future<void> removeMember({
    required String groupId,
    required String characterId,
  }) async {
    lastRemovedCharacterId = characterId;
    if (removeMemberError != null) throw removeMemberError!;
  }

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
    if (claimItemError != null) throw claimItemError!;
  }

  @override
  Future<void> addToTreasure({
    required String groupId,
    required Map<CurrencyKind, int> newCurrencyTotals,
    required List<GroupTreasureItem> newItems,
  }) async {
    lastAddedTotals = newCurrencyTotals;
    lastAddedItems = newItems;
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
    level: 3,
    currentHp: currentHp,
    maxHp: maxHp,
    temporaryHp: temporaryHp,
    isDead: isDead,
    raceName: 'Elfe',
    className: 'Rôdeur',
  );
}

GoRouter _buildTestRouter() {
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
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Paramètres du groupe ${state.pathParameters['id']}'),
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

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Seuls les PV et le statut sont visibles ici'),
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

        expect(fakeRepository.lastRemovedCharacterId, 'char-2');
        expect(find.textContaining('exclu du groupe'), findsOneWidget);
      },
    );
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
  });

  group('quitter le groupe (lien en pied de l\'onglet Membres)', () {
    testWidgets(
      'membre : le lien "Quitter le groupe" est présent et fonctionne',
      (tester) async {
        fakeRepository.detailToReturn = memberViewDetail();

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();

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
    testWidgets('affiche les stat boxes et l\'état vide des objets', (
      tester,
    ) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = const GroupTreasure(
        groupId: 'group-1',
        currencyGp: 12,
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('BUTIN'));
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
      expect(find.text('Aucun objet en attente.'), findsOneWidget);
      expect(find.text('AJOUTER AU BUTIN DU GROUPE'), findsOneWidget);
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
        await tester.tap(find.text('BUTIN'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Répartir vers mon inventaire'));
        await tester.pumpAndSettle();

        // Aucune sheet ne s'ouvre : le titre de la sheet de réclamation
        // n'apparaît jamais.
        expect(find.text("S'ATTRIBUER DE LA MONNAIE"), findsNothing);
      },
    );

    testWidgets('affiche un objet en attente avec un lien de réclamation', (
      tester,
    ) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = const GroupTreasure(
        groupId: 'group-1',
        items: [
          GroupTreasureItem(itemId: 7, displayName: 'Potion', quantity: 3),
        ],
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BUTIN'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Potion'), findsOneWidget);
      expect(find.text("S'attribuer"), findsOneWidget);
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
        await tester.tap(find.text('BUTIN'));
        await tester.pumpAndSettle();

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
        await tester.tap(find.text('BUTIN'));
        await tester.pumpAndSettle();

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
        await tester.tap(find.text('BUTIN'));
        await tester.pumpAndSettle();

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

    testWidgets("réclamer un objet : ouvre la sheet de quantité, appelle "
        "claimTreasureItem puis rafraîchit le butin", (tester) async {
      fakeRepository.detailToReturn = ownerViewDetail();
      fakeRepository.treasureToReturn = const GroupTreasure(
        groupId: 'group-1',
        items: [
          GroupTreasureItem(itemId: 7, displayName: 'Potion', quantity: 3),
        ],
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BUTIN'));
      await tester.pumpAndSettle();

      await tester.tap(find.text("S'attribuer"));
      await tester.pumpAndSettle();

      expect(find.text('Réclamer Potion'), findsOneWidget);

      await tester.tap(find.text('RÉCLAMER'));
      await tester.pumpAndSettle();

      expect(fakeRepository.lastClaimedQuantity, 1);
      expect(find.text('Objet ajouté à ton inventaire.'), findsOneWidget);
      expect(fakeRepository.treasureFetchCount, greaterThanOrEqualTo(2));
    });
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
}
