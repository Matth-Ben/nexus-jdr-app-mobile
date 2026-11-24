// Tests de widget de l'écran dédié "Paramètres du groupe" (route
// `/groups/:id/settings`) — recettage direction-artistique du 13/09/2026,
// voir la doc de classe de `GroupSettingsScreen`. Remplace
// `showGroupManagementSheet`/`group_rename_sheet.dart` (sheets retirées par
// cette tâche).
//
// Étape 3b (migration DeepCore `20261119090000`) : section « Devenir MJ »
// (visibilité, confirmation, bouton bloqué pendant l'appel, rafraîchissement,
// refus serveur, hors ligne), feuille de dissolution (texte complet D228,
// garde cliente et refus serveur `combat_active` D224).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/alert_banner.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/combat/presentation/providers/character_combat_provider.dart';
import 'package:personnages/features/combat/presentation/providers/combat_providers.dart';
import 'package:personnages/features/combat/presentation/providers/grimoire_combat_providers.dart';
import 'package:personnages/features/groups/data/group_error_mapper.dart';
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
import 'package:personnages/features/groups/presentation/group_settings_screen.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/combat_fixtures.dart';
import '../../../support/fake_combat_repository.dart';
import '../../../support/fake_connectivity_checker.dart';
import '../../../support/fake_current_user.dart';
import '../../../support/fake_grimoire_combat_gateway.dart';

class _FakeGroupRepository implements GroupRepository {
  /// Réponses successives de `fetchGroupIdsForCharacter` (la dernière se
  /// répète) ; vide : aucun groupe.
  List<List<String>> groupIdsResponses = const [];
  int groupIdsCalls = 0;

  @override
  Future<List<String>> fetchGroupIdsForCharacter(String characterId) async {
    final index = groupIdsCalls++;
    if (groupIdsResponses.isEmpty) return const [];
    return groupIdsResponses[index < groupIdsResponses.length
        ? index
        : groupIdsResponses.length - 1];
  }

  int myGroupsCalls = 0;

  GroupDetail? detailToReturn;
  Object? detailErrorToThrow;
  Completer<GroupDetail>? detailCompleter;
  int detailFetchCount = 0;

  String? lastRenamedName;
  Object? renameError;

  String regeneratedCode = 'NEWCODE1';
  Object? regenerateError;

  bool leaveGroupCalled = false;
  Object? leaveGroupError;

  bool dissolveCalled = false;
  Object? dissolveError;

  /// Appels de la RPC `become_group_game_master`.
  int becomeGameMasterCalls = 0;
  Object? becomeGameMasterError;

  /// Si posé, l'appel reste en vol jusqu'à sa complétion.
  Completer<void>? becomeGameMasterGate;

  /// Détail renvoyé par les lectures suivantes après un passage en MJ réussi.
  GroupDetail? detailAfterBecomeGameMaster;

  @override
  Future<GroupDetail> fetchGroupDetail(String groupId) async {
    detailFetchCount++;
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
  Future<void> dissolveGroup(String groupId) async {
    dissolveCalled = true;
    if (dissolveError != null) throw dissolveError!;
  }

  @override
  Future<void> becomeGroupGameMaster(String groupId) async {
    becomeGameMasterCalls++;
    final gate = becomeGameMasterGate;
    if (gate != null) await gate.future;
    final error = becomeGameMasterError;
    if (error != null) throw error;
    final after = detailAfterBecomeGameMaster;
    if (after != null) detailToReturn = after;
  }

  @override
  Future<List<GroupSummary>> fetchMyGroups() async {
    myGroupsCalls++;
    return const [];
  }

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

  @override
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) => throw UnimplementedError();

  @override
  Future<void> setGroupCharacter({
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
    required String groupId,
    required List<String> characterIds,
    required bool Function(String membershipId) isKnownMembershipId,
    required void Function() onChanged,
  }) => throw UnimplementedError();

  @override
  Future<List<GroupNoteEntry>> fetchGroupNoteEntries(String groupId) =>
      throw UnimplementedError();

  @override
  Future<void> addGroupNoteEntry({
    required String groupId,
    String? title,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<void> updateGroupNoteEntry({
    required String entryId,
    String? title,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteGroupNoteEntry(String entryId) =>
      throw UnimplementedError();
}

const String _groupName = "Les Lames de l'Aube";

/// Le propriétaire (`user-1`) joue Sylvi (`char-1`) : « Devenir MJ » proposé.
GroupDetail _ownerDetail({String name = _groupName}) => GroupDetail(
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
      isGameMaster: false,
      level: 3,
      currentHp: 10,
      maxHp: 10,
      temporaryHp: 0,
      isDead: false,
    ),
  ],
);

/// Le propriétaire est MJ sans personnage (état après « Devenir MJ »).
GroupDetail _ownerGameMasterDetail() => GroupDetail(
  id: 'group-1',
  name: _groupName,
  ownerId: 'user-1',
  inviteCode: 'AB3F7K2M',
  currentUserId: 'user-1',
  members: const [
    GroupMember(
      userId: 'user-1',
      role: GroupRole.owner,
      name: 'Matthias',
      isGameMaster: true,
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

Widget _buildTestWidget(
  _FakeGroupRepository repository, {
  FakeCombatRepository? combatRepository,
  FakeConnectivityChecker? connectivity,
  double scale = 1,
}) {
  return ProviderScope(
    overrides: [
      groupRepositoryProvider.overrideWithValue(repository),
      // Garde « combat actif » de la dissolution et refus `combat_active` :
      // relecture du combat du groupe (aucun combat par défaut).
      combatRepositoryProvider.overrideWithValue(
        combatRepository ?? FakeCombatRepository(),
      ),
      grimoireCombatGatewayProvider.overrideWithValue(
        FakeGrimoireCombatGateway(),
      ),
      connectivityCheckerProvider.overrideWithValue(
        connectivity ?? FakeConnectivityChecker(),
      ),
      currentUserFromTestOverride,
    ],
    child: MaterialApp.router(
      routerConfig: _buildTestRouter(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
    ),
  );
}

/// Surface de test en pixels logiques (ratio 1, voir D191).
void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

SecondaryButton _becomeGameMasterWidget(WidgetTester tester) =>
    tester.widget<SecondaryButton>(_becomeGameMasterButton);

const String _offlineHint =
    'Indisponible hors ligne : cette action a besoin du serveur.';

final Finder _becomeGameMasterButton = find.byKey(
  const Key('becomeGameMasterButton'),
);

final Finder _gameMasterSection = find.byKey(
  const Key('groupSettingsGameMasterSection'),
);

final Finder _confirmGameMasterButton = find.byWidgetPredicate(
  (widget) => widget is PrimaryButton && widget.label == 'Devenir MJ',
);

GroupFailure _serverError(String message, String code) =>
    mapGroupError(PostgrestException(message: message, code: code));

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

    // La section « Devenir MJ » (propriétaire qui joue) repousse la zone
    // dangereuse sous le pli de la surface de test.
    await tester.ensureVisible(find.text('Dissoudre le groupe'));
    await tester.tap(find.text('Dissoudre le groupe'));
    await tester.pumpAndSettle();

    expect(find.text('DISSOUDRE LE GROUPE'), findsOneWidget);
  });

  group('« Devenir MJ » : visibilité', () {
    testWidgets('propriétaire qui joue un personnage : section et bouton', (
      tester,
    ) async {
      fakeRepository.detailToReturn = _ownerDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(_gameMasterSection, findsOneWidget);
      expect(find.text('MAÎTRE DU JEU'), findsOneWidget);
      expect(
        find.text(
          "Pour lancer les combats dans l'app, deviens-en le MJ : Sylvi "
          'quittera le groupe mais restera dans ta liste de personnages.',
        ),
        findsOneWidget,
      );
      // Bouton secondaire parchemin pleine largeur, libellé court (revue
      // direction-artistique de la PR #303).
      final button = _becomeGameMasterWidget(tester);
      expect(button.label, 'Devenir MJ');
      expect(button.surface, SecondaryButtonSurface.parchment);
      expect(button.icon, Icons.admin_panel_settings_outlined);
      expect(button.onPressed, isNotNull);
      expect(find.text('DEVENIR MJ'), findsOneWidget);
      expect(
        tester.getSize(_becomeGameMasterButton).width,
        tester.getSize(_gameMasterSection).width,
      );
    });

    testWidgets('propriétaire déjà MJ sans personnage : rien', (tester) async {
      fakeRepository.detailToReturn = _ownerGameMasterDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(_gameMasterSection, findsNothing);
      expect(_becomeGameMasterButton, findsNothing);
    });

    testWidgets('propriétaire orphelin (personnage supprimé) : rien', (
      tester,
    ) async {
      fakeRepository.detailToReturn = GroupDetail(
        id: 'group-1',
        name: _groupName,
        ownerId: 'user-1',
        inviteCode: 'AB3F7K2M',
        currentUserId: 'user-1',
        members: const [
          GroupMember(
            userId: 'user-1',
            role: GroupRole.owner,
            name: 'Matthias',
            isGameMaster: false,
          ),
        ],
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(_gameMasterSection, findsNothing);
    });

    testWidgets('membre qui joue mais n\'est pas propriétaire : rien', (
      tester,
    ) async {
      fakeRepository.detailToReturn = _ownerDetail().copyWith(
        currentUserId: 'user-2',
        members: [
          ..._ownerDetail().members,
          const GroupMember(
            characterId: 'char-2',
            userId: 'user-2',
            role: GroupRole.membre,
            name: 'Aria',
            isGameMaster: false,
          ),
        ],
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(_gameMasterSection, findsNothing);
    });
  });

  testWidgets('« Devenir MJ » à ×3,0 sur 320 dp : section et confirmation '
      'sans débordement', (tester) async {
    _setSurface(tester, const Size(320, 640));
    fakeRepository.detailToReturn = _ownerDetail();
    await tester.pumpWidget(_buildTestWidget(fakeRepository, scale: 3));
    await tester.pumpAndSettle();

    await tester.ensureVisible(_becomeGameMasterButton);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('DEVENIR MJ'), findsOneWidget);

    await tester.tap(_becomeGameMasterButton);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.text("Devenir MJ de « Les Lames de l'Aube » ?"),
      findsOneWidget,
    );

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is SecondaryButton && widget.label == 'Annuler',
      ),
    );
    await tester.pumpAndSettle();
    expect(fakeRepository.becomeGameMasterCalls, 0);
  });

  group('« Devenir MJ » : confirmation et appel', () {
    testWidgets('la confirmation explique les conséquences ; Annuler '
        "n'appelle pas le serveur", (tester) async {
      fakeRepository.detailToReturn = _ownerDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      await tester.tap(_becomeGameMasterButton);
      await tester.pumpAndSettle();

      expect(
        find.text("Devenir MJ de « Les Lames de l'Aube » ?"),
        findsOneWidget,
      );
      expect(
        find.text(
          'Sylvi quittera ce groupe mais restera dans ta liste de '
          'personnages, avec toutes ses données. Tu deviendras MJ sans '
          'personnage et tu pourras lancer les combats. Impossible de '
          "revenir en arrière pour l'instant.",
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is SecondaryButton && widget.label == 'Annuler',
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeRepository.becomeGameMasterCalls, 0);
      expect(_gameMasterSection, findsOneWidget);
    });

    testWidgets('bouton bloqué pendant l\'appel, puis rafraîchissement du '
        'groupe et du rôle', (tester) async {
      fakeRepository
        ..detailToReturn = _ownerDetail()
        ..detailAfterBecomeGameMaster = _ownerGameMasterDetail()
        ..becomeGameMasterGate = Completer<void>();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      expect(fakeRepository.detailFetchCount, 1);

      await tester.tap(_becomeGameMasterButton);
      await tester.pumpAndSettle();
      await tester.tap(_confirmGameMasterButton);
      await tester.pumpAndSettle();

      // Appel en vol : libellé « en cours », bouton désactivé.
      expect(fakeRepository.becomeGameMasterCalls, 1);
      expect(_becomeGameMasterWidget(tester).label, 'Passage en MJ…');
      expect(_becomeGameMasterWidget(tester).onPressed, isNull);
      await tester.tap(_becomeGameMasterButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(
        find.text("Devenir MJ de « Les Lames de l'Aube » ?"),
        findsNothing,
      );
      expect(fakeRepository.becomeGameMasterCalls, 1);

      fakeRepository.becomeGameMasterGate!.complete();
      await tester.pumpAndSettle();

      // Groupe relu : le propriétaire est MJ, la section disparaît.
      expect(fakeRepository.detailFetchCount, 2);
      expect(_gameMasterSection, findsNothing);
      expect(
        find.text(
          'Tu es maintenant MJ de ce groupe. Ton personnage reste dans ta '
          'liste.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('le cache des groupes du personnage est relu : son bandeau '
        'de combat ne pointe plus vers ce groupe', (tester) async {
      fakeRepository
        ..detailToReturn = _ownerDetail()
        ..detailAfterBecomeGameMaster = _ownerGameMasterDetail()
        ..groupIdsResponses = const [
          ['group-1'],
          <String>[],
        ];

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      container.listen(characterGroupIdsProvider('char-1'), (_, _) {});
      await tester.pumpAndSettle();
      expect(container.read(characterGroupIdsProvider('char-1')), ['group-1']);

      await tester.tap(_becomeGameMasterButton);
      await tester.pumpAndSettle();
      await tester.tap(_confirmGameMasterButton);
      await tester.pumpAndSettle();

      expect(container.read(characterGroupIdsProvider('char-1')), isEmpty);
      expect(fakeRepository.groupIdsCalls, 2);
    });

    testWidgets('la liste des groupes (badges) est relue', (tester) async {
      fakeRepository
        ..detailToReturn = _ownerDetail()
        ..detailAfterBecomeGameMaster = _ownerGameMasterDetail();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
      container.listen(myGroupsProvider, (_, _) {});
      await tester.pumpAndSettle();
      expect(fakeRepository.myGroupsCalls, 1);

      await tester.tap(_becomeGameMasterButton);
      await tester.pumpAndSettle();
      await tester.tap(_confirmGameMasterButton);
      await tester.pumpAndSettle();

      expect(fakeRepository.myGroupsCalls, 2);
    });

    testWidgets('refus combat_active : message clair, combat relu, bouton '
        'de nouveau actif', (tester) async {
      final combatRepository = FakeCombatRepository();
      fakeRepository
        ..detailToReturn = _ownerDetail()
        ..becomeGameMasterError = _serverError('combat_active', 'P0001');

      await tester.pumpWidget(
        _buildTestWidget(fakeRepository, combatRepository: combatRepository),
      );
      await tester.pumpAndSettle();
      final fetchesBefore = combatRepository.fetchCount;

      await tester.tap(_becomeGameMasterButton);
      await tester.pumpAndSettle();
      await tester.tap(_confirmGameMasterButton);
      await tester.pumpAndSettle();

      expect(fakeRepository.becomeGameMasterCalls, 1);
      expect(
        find.text(
          'Impossible de devenir MJ pendant un combat en cours. Termine '
          "d'abord le combat.",
        ),
        findsOneWidget,
      );
      expect(combatRepository.fetchCount, greaterThan(fetchesBefore));
      expect(_gameMasterSection, findsOneWidget);
      expect(_becomeGameMasterWidget(tester).onPressed, isNotNull);
    });

    testWidgets('refus mj_already_assigned : message, personne n\'est '
        'rétrogradé, groupe relu', (tester) async {
      fakeRepository
        ..detailToReturn = _ownerDetail()
        ..becomeGameMasterError = _serverError('mj_already_assigned', 'P0001');

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      await tester.tap(_becomeGameMasterButton);
      await tester.pumpAndSettle();
      await tester.tap(_confirmGameMasterButton);
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Un autre membre est déjà MJ de ce groupe. Rien n'a changé : il "
          "doit d'abord quitter le groupe, ou tu peux l'exclure depuis "
          "l'onglet Membres.",
        ),
        findsOneWidget,
      );
      expect(fakeRepository.detailFetchCount, 2);
      expect(_gameMasterSection, findsOneWidget);
    });

    // Un message propre par erreur du contrat (lu dans `message` avant le
    // statut HTTP, voir `mapGroupError`).
    const cases = <(String, String, String)>[
      (
        'not_group_owner',
        '42501',
        'Seul le créateur du groupe peut faire cela.',
      ),
      ('not_member', '500', 'Tu ne fais plus partie de ce groupe.'),
      ('group_not_found', 'P0002', 'Groupe introuvable.'),
      (
        'not_authenticated',
        '28000',
        'Session expirée. Reconnectez-vous pour continuer.',
      ),
      (
        'deadlock detected',
        '40P01',
        "Le serveur était occupé : rien n'a été modifié. Réessaie.",
      ),
      (
        'could not serialize access due to concurrent update',
        '40001',
        "Le serveur était occupé : rien n'a été modifié. Réessaie.",
      ),
      (
        'Could not find the function '
            'public.become_group_game_master(p_group_id) in the schema cache',
        'PGRST202',
        "Cette action n'est pas encore disponible sur le serveur. Réessaie "
            'plus tard.',
      ),
      (
        'erreur interne inattendue',
        'XX000',
        'Impossible de devenir MJ. '
            'Réessaie.',
      ),
    ];
    for (final (serverMessage, code, expected) in cases) {
      testWidgets('refus « $serverMessage » ($code) : « $expected »', (
        tester,
      ) async {
        fakeRepository
          ..detailToReturn = _ownerDetail()
          ..becomeGameMasterError = _serverError(serverMessage, code);

        await tester.pumpWidget(_buildTestWidget(fakeRepository));
        await tester.pumpAndSettle();

        await tester.tap(_becomeGameMasterButton);
        await tester.pumpAndSettle();
        await tester.tap(_confirmGameMasterButton);
        await tester.pumpAndSettle();

        expect(find.text(expected), findsOneWidget);
        expect(find.text(serverMessage), findsNothing);
      });
    }

    testWidgets('échec réseau : message réseau', (tester) async {
      fakeRepository
        ..detailToReturn = _ownerDetail()
        ..becomeGameMasterError = mapUnknownGroupError();

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      await tester.tap(_becomeGameMasterButton);
      await tester.pumpAndSettle();
      await tester.tap(_confirmGameMasterButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('connexion'), findsOneWidget);
    });
  });

  group('« Devenir MJ » hors ligne', () {
    testWidgets('bouton désactivé avec une explication, aucun dialogue', (
      tester,
    ) async {
      fakeRepository.detailToReturn = _ownerDetail();

      await tester.pumpWidget(
        _buildTestWidget(
          fakeRepository,
          connectivity: FakeConnectivityChecker(connected: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(_becomeGameMasterWidget(tester).onPressed, isNull);
      expect(find.text(_offlineHint), findsOneWidget);

      await tester.tap(_becomeGameMasterButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(
        find.text("Devenir MJ de « Les Lames de l'Aube » ?"),
        findsNothing,
      );
      expect(fakeRepository.becomeGameMasterCalls, 0);
    });

    testWidgets('réseau perdu pendant la confirmation : aucun appel, jamais '
        'de file d\'attente ; message passager, rien ne reste après la '
        'reconnexion', (tester) async {
      final connectivity = FakeConnectivityChecker();
      fakeRepository.detailToReturn = _ownerDetail();

      await tester.pumpWidget(
        _buildTestWidget(fakeRepository, connectivity: connectivity),
      );
      await tester.pumpAndSettle();

      await tester.tap(_becomeGameMasterButton);
      await tester.pumpAndSettle();
      connectivity.goOffline();
      await tester.pump();
      await tester.tap(_confirmGameMasterButton);
      await tester.pumpAndSettle();

      expect(fakeRepository.becomeGameMasterCalls, 0);
      // Une seule fois dans la section (indice sous le bouton), plus le
      // SnackBar ; jamais de bandeau d'erreur dans la section.
      expect(
        find.descendant(
          of: _gameMasterSection,
          matching: find.text(_offlineHint),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(_offlineHint),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _gameMasterSection,
          matching: find.byType(AlertBanner),
        ),
        findsNothing,
      );

      connectivity.goOnline();
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text(_offlineHint), findsNothing);
      expect(_becomeGameMasterWidget(tester).onPressed, isNotNull);
    });
  });

  group('dissolution (D224, D228)', () {
    const intro =
        'Cette action est irréversible. Elle supprimera définitivement, pour '
        'tous les membres :';
    const items = [
      "le groupe et l'accès de tous ses membres ;",
      'le butin commun ;',
      'les carnets de notes des joueurs pour ce groupe (onglet Notes, '
          'toutes les entrées du journal comprises) ;',
      "l'historique des combats du groupe.",
    ];
    const charactersKept =
        'Les personnages des joueurs restent intacts : ils gardent toutes '
        'leurs données.';
    const blocked =
        'Tu ne peux pas dissoudre le groupe pendant un combat en cours. '
        "Termine d'abord le combat.";

    Future<void> openSheet(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Dissoudre le groupe'));
      await tester.tap(find.text('Dissoudre le groupe'));
      await tester.pumpAndSettle();
    }

    Future<void> confirmDissolution(WidgetTester tester) async {
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, _groupName);
      await tester.pump();
      await tester.tap(find.text('Dissoudre définitivement'));
      await tester.pumpAndSettle();
    }

    testWidgets('légende de l\'écran complète', (tester) async {
      fakeRepository.detailToReturn = _ownerDetail();
      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Réservé au créateur du groupe. Retire tous les membres et '
          'supprime le butin commun, les carnets de notes des joueurs et '
          "l'historique des combats ; les personnages et leurs données "
          'restent intacts.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('avertissement complet : toutes les suppressions en cascade '
        'et personnages intacts', (tester) async {
      fakeRepository.detailToReturn = _ownerDetail();
      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      await openSheet(tester);

      // Seule l'introduction est dans le bandeau d'alerte.
      expect(
        find.descendant(
          of: find.byType(AlertBanner),
          matching: find.text(intro),
        ),
        findsOneWidget,
      );
      // Un texte par élément, hors du bandeau, à droite de sa puce.
      for (final item in items) {
        expect(find.text(item), findsOneWidget, reason: item);
        expect(
          find.descendant(
            of: find.byType(AlertBanner),
            matching: find.text(item),
          ),
          findsNothing,
          reason: item,
        );
        final row = find
            .ancestor(of: find.text(item), matching: find.byType(Row))
            .first;
        final bullet = find.descendant(of: row, matching: find.text('•'));
        expect(bullet, findsOneWidget, reason: item);
        expect(
          tester.getTopLeft(find.text(item)).dx,
          greaterThan(tester.getTopRight(bullet).dx),
          reason: item,
        );
      }
      expect(find.text(charactersKept), findsOneWidget);
      expect(find.textContaining('ne peut pas être annulée'), findsNothing);
    });

    testWidgets("lecteur d'écran : chaque élément lu seul, jamais la puce", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      fakeRepository.detailToReturn = _ownerDetail();
      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      await openSheet(tester);

      expect(find.bySemanticsLabel(RegExp('•')), findsNothing);
      for (final item in items) {
        expect(find.bySemanticsLabel(item), findsOneWidget, reason: item);
      }
      expect(find.bySemanticsLabel(charactersKept), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('avertissement à ×3,0 sur 320 dp : aucun débordement', (
      tester,
    ) async {
      _setSurface(tester, const Size(320, 640));
      fakeRepository.detailToReturn = _ownerDetail();
      await tester.pumpWidget(_buildTestWidget(fakeRepository, scale: 3));
      await tester.pumpAndSettle();

      await openSheet(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(items.first), findsOneWidget);
    });

    testWidgets('garde cliente : combat actif, la feuille ne s\'ouvre pas', (
      tester,
    ) async {
      final combatRepository = FakeCombatRepository()
        ..snapshot = fakeSnapshot();
      fakeRepository.detailToReturn = _ownerDetail();
      await tester.pumpWidget(
        _buildTestWidget(fakeRepository, combatRepository: combatRepository),
      );
      await tester.pumpAndSettle();

      await openSheet(tester);

      expect(find.text(blocked), findsOneWidget);
      expect(find.text('DISSOUDRE LE GROUPE'), findsNothing);
      expect(fakeRepository.dissolveCalled, isFalse);
    });

    testWidgets('garde cliente : le combat est relu avant de décider', (
      tester,
    ) async {
      final combatRepository = FakeCombatRepository();
      fakeRepository.detailToReturn = _ownerDetail();
      await tester.pumpWidget(
        _buildTestWidget(fakeRepository, combatRepository: combatRepository),
      );
      await tester.pumpAndSettle();

      // Aucun combat jusqu'ici ; il démarre juste avant l'appui.
      await openSheet(tester);
      expect(find.text('DISSOUDRE LE GROUPE'), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is SecondaryButton && widget.label == 'Annuler',
        ),
      );
      await tester.pumpAndSettle();

      combatRepository.snapshot = fakeSnapshot();
      await openSheet(tester);

      expect(find.text(blocked), findsOneWidget);
      expect(find.text('DISSOUDRE LE GROUPE'), findsNothing);
    });

    testWidgets('refus serveur combat_active (état local périmé) : message '
        'clair dans la feuille, combat relu, pas de navigation', (
      tester,
    ) async {
      final combatRepository = FakeCombatRepository();
      fakeRepository
        ..detailToReturn = _ownerDetail()
        ..dissolveError = _serverError('combat_active', 'P0001');
      await tester.pumpWidget(
        _buildTestWidget(fakeRepository, combatRepository: combatRepository),
      );
      await tester.pumpAndSettle();

      await openSheet(tester);
      final fetchesBefore = combatRepository.fetchCount;
      await confirmDissolution(tester);

      expect(fakeRepository.dissolveCalled, isTrue);
      expect(find.text(blocked), findsOneWidget);
      expect(find.text('DISSOUDRE LE GROUPE'), findsOneWidget);
      expect(find.text('Liste des personnages'), findsNothing);
      expect(combatRepository.fetchCount, greaterThan(fetchesBefore));
    });

    testWidgets('conflit transitoire (40P01) : « Réessaie »', (tester) async {
      fakeRepository
        ..detailToReturn = _ownerDetail()
        ..dissolveError = _serverError('deadlock detected', '40P01');
      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      await openSheet(tester);
      await confirmDissolution(tester);

      expect(
        find.text("Le serveur était occupé : rien n'a été modifié. Réessaie."),
        findsOneWidget,
      );
    });

    testWidgets('échec non reconnu : message générique, jamais le texte brut '
        'du serveur', (tester) async {
      fakeRepository
        ..detailToReturn = _ownerDetail()
        ..dissolveError = _serverError('erreur interne', 'XX000');
      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      await openSheet(tester);
      await confirmDissolution(tester);

      expect(
        find.text('Impossible de dissoudre le groupe. Réessaie.'),
        findsOneWidget,
      );
      expect(find.text('erreur interne'), findsNothing);
    });

    testWidgets('sans combat : dissolution puis retour à l\'accueil', (
      tester,
    ) async {
      fakeRepository.detailToReturn = _ownerDetail();
      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      await openSheet(tester);
      await confirmDissolution(tester);

      expect(fakeRepository.dissolveCalled, isTrue);
      expect(find.text('Liste des personnages'), findsOneWidget);
      expect(find.text('Groupe dissous.'), findsOneWidget);
    });
  });
}
