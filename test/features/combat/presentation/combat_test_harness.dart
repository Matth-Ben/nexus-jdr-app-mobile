// Harnais commun des tests de widgets du combat : vraies polices, taille de
// vue, échelle de texte, faux dépôt/connectivité/utilisateur.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/features/combat/domain/combat_enums.dart';
import 'package:personnages/features/combat/domain/combat_participant.dart';
import 'package:personnages/features/combat/presentation/combat_screen.dart';
import 'package:personnages/features/combat/presentation/providers/combat_providers.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_role.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../../support/combat_fixtures.dart';
import '../../../support/fake_combat_repository.dart';
import '../../../support/fake_connectivity_checker.dart';
import '../../../support/fake_current_user.dart';

const groupId = 'group-1';
const ownerId = 'owner-1';
const playerId = 'player-1';

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

/// Polices réelles (la police de test rendrait chaque glyphe large d'un em).
Future<void> loadCombatFonts() async {
  await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
  await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
}

GroupMember fakeMember({
  required String userId,
  String? characterId,
  bool isGameMaster = false,
  String name = 'Membre',
  GroupRole role = GroupRole.membre,
}) => GroupMember(
  userId: userId,
  characterId: characterId,
  role: role,
  name: name,
  isGameMaster: isGameMaster,
);

/// MJ = propriétaire avec une ligne `is_game_master` ; [asPlayer] : l'utilisateur
/// courant est un joueur ; [ownerPlaysCharacter] : propriétaire sans rôle MJ ;
/// [masterAbsent] : le propriétaire n'a plus de ligne MJ.
GroupDetail fakeGroupDetail({
  bool asPlayer = false,
  bool ownerPlaysCharacter = false,
  bool masterAbsent = false,
}) {
  return GroupDetail(
    id: groupId,
    name: 'Les Braves',
    ownerId: ownerId,
    inviteCode: 'ABC123',
    currentUserId: asPlayer ? playerId : ownerId,
    members: [
      if (!masterAbsent)
        fakeMember(
          userId: ownerId,
          characterId: ownerPlaysCharacter ? 'c-owner' : null,
          isGameMaster: !ownerPlaysCharacter,
          name: 'MJ',
          role: GroupRole.owner,
        ),
      fakeMember(userId: playerId, characterId: 'c-player', name: 'Aria'),
    ],
  );
}

class CombatHarness {
  CombatHarness({
    GroupDetail? detail,
    FakeCombatRepository? repo,
    FakeConnectivityChecker? connectivity,
  }) : detail = detail ?? fakeGroupDetail(),
       repo = repo ?? FakeCombatRepository(),
       connectivity = connectivity ?? FakeConnectivityChecker();

  final GroupDetail detail;
  final FakeCombatRepository repo;
  final FakeConnectivityChecker connectivity;

  late ProviderContainer container;

  List<String> announcements = [];
  Locale locale = const Locale('fr');
  double scale = 1;
  String? lastLocation;

  Widget build({Widget? home}) {
    container = ProviderContainer(
      overrides: [
        currentUserFromTestOverride,
        combatRepositoryProvider.overrideWithValue(repo),
        connectivityCheckerProvider.overrideWithValue(connectivity),
        combatRefetchDebounceProvider.overrideWithValue(
          const Duration(milliseconds: 10),
        ),
        groupDetailProvider(groupId).overrideWith((ref) async => detail),
      ],
    );
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push('/groups/$groupId/combat'),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/groups/:id/combat',
          builder: (context, state) => CombatScreen(
            groupId: state.pathParameters['id']!,
            announcer: (context, text) => announcements.add(text),
          ),
        ),
        GoRoute(
          path: '/groups/:id',
          builder: (context, state) => const Scaffold(body: Text('GROUPE')),
        ),
      ],
    );
    addTearDown(container.dispose);
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    );
  }

  /// Ouvre l'écran Combat (poussé comme dans l'app) et laisse se résoudre le
  /// premier chargement.
  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(320, 700),
    bool settle = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    await tester.tap(find.text('ouvrir'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // Un indicateur de chargement anime en continu : pas de pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  /// Simule un évènement Realtime : le dépôt change puis le canal notifie.
  Future<void> emitChange(WidgetTester tester) async {
    repo.lastChannel.emitChange();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }
}

/// Distribution type : Aria (joueuse, 18), deux gobelins à égalité (12), Brun
/// sans initiative.
List<CombatParticipant> combatRoster() => [
  fakeParticipant(
    'aria',
    name: 'Aria',
    initiative: 18,
    sortOrder: 1,
    characterId: 'c-player',
  ).copyWith(userId: playerId),
  fakeParticipant(
    'gob1',
    name: 'Gobelin 1',
    initiative: 12,
    sortOrder: 2,
    kind: ParticipantKind.npc,
  ),
  fakeParticipant(
    'gob2',
    name: 'Gobelin 2',
    initiative: 12,
    sortOrder: 3,
    kind: ParticipantKind.npc,
  ),
  fakeParticipant('brun', name: 'Brun', sortOrder: 4, characterId: 'c-brun'),
];
