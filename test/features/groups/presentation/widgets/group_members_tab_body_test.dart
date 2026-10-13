// Tests de widget de l'onglet « Membres » d'un groupe
// (`presentation/widgets/group_members_tab_body.dart`) : code d'invitation
// copiable et ouverture de la fiche d'un membre au toucher (demandes
// utilisateur du 2026-09-27).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_role.dart';
import 'package:personnages/features/groups/presentation/widgets/group_members_tab_body.dart';

const _me = GroupMember(
  characterId: 'char-me',
  userId: 'user-me',
  role: GroupRole.owner,
  name: 'Brunhilde',
  level: 3,
  currentHp: 20,
  maxHp: 24,
  temporaryHp: 0,
  isDead: false,
);

const _friend = GroupMember(
  characterId: 'char-friend',
  userId: 'user-friend',
  role: GroupRole.membre,
  name: 'Eldrin',
  level: 3,
  currentHp: 15,
  maxHp: 18,
  temporaryHp: 0,
  isDead: false,
);

GroupDetail _detail(List<GroupMember> members) => GroupDetail(
  id: 'group-1',
  name: 'Les Lames de l’Aube',
  ownerId: 'user-me',
  inviteCode: 'ABC123',
  currentUserId: 'user-me',
  members: members,
);

Future<void> _pump(WidgetTester tester, GroupDetail detail) async {
  final router = GoRouter(
    initialLocation: '/group',
    routes: [
      GoRoute(
        path: '/group',
        builder: (context, state) => Scaffold(
          body: GroupMembersTabBody(
            detail: detail,
            onRemoveMember: (_) {},
            onLeaveGroup: () {},
          ),
        ),
      ),
      GoRoute(
        path: '/characters/:id',
        builder: (context, state) =>
            Text('Fiche perso ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/groups/:id/members/:characterId',
        builder: (context, state) => Text(
          'Fiche membre ${state.pathParameters['id']} '
          '${state.pathParameters['characterId']}',
        ),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('seul dans le groupe : le code est affiché et se copie d’un '
      'toucher', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await _pump(tester, _detail(const [_me]));

    expect(find.text('ABC123'), findsOneWidget);
    await tester.tap(find.text('ABC123'));
    await tester.pumpAndSettle();

    expect(copied, 'ABC123');
    expect(find.text('Code ABC123 copié.'), findsOneWidget);
  });

  testWidgets('toucher sa propre carte ouvre sa fiche (modifiable)', (
    tester,
  ) async {
    await _pump(tester, _detail(const [_me, _friend]));

    await tester.tap(find.textContaining('Brunhilde', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.text('Fiche perso char-me'), findsOneWidget);
  });

  testWidgets('toucher la carte d’un autre membre ouvre sa fiche en '
      'lecture seule', (tester) async {
    await _pump(tester, _detail(const [_me, _friend]));

    await tester.tap(find.textContaining('Eldrin', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.text('Fiche membre group-1 char-friend'), findsOneWidget);
  });

  group('MJ sans personnage (décision du 12-13/10/2026)', () {
    // Nom volontairement distinct de `_me`/`_friend` (jamais un sous-chaîne
    // de "Brunhilde"/"Eldrin") : `find.textContaining` ci-dessous ne doit
    // jamais ambiguïser la carte MJ avec une autre carte de ce fichier.
    const gameMaster = GroupMember(
      userId: 'user-mj',
      role: GroupRole.membre,
      name: 'Oswald',
    );

    testWidgets('badge "MJ", texte PV neutre, jamais le fond "MORT"', (
      tester,
    ) async {
      await _pump(tester, _detail(const [_me, gameMaster]));

      expect(find.text('MJ'), findsOneWidget);
      expect(find.text('Ne suit pas ses PV ici.'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      final cardFinder = find.ancestor(
        of: find.textContaining('Oswald', findRichText: true),
        matching: find.byType(Container),
      );
      final decorations = tester
          .widgetList<Container>(cardFinder)
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .toList();
      expect(
        decorations.any(
          (decoration) => decoration.color == AppColors.deadCardBackground,
        ),
        isFalse,
      );
    });

    testWidgets('aucune zone de tap (rien à ouvrir)', (tester) async {
      await _pump(tester, _detail(const [_me, gameMaster]));

      final gmInkWell = find.ancestor(
        of: find.textContaining('Oswald', findRichText: true),
        matching: find.byType(InkWell),
      );
      expect(gmInkWell, findsNothing);
    });

    testWidgets('suffixe " (toi)" quand le MJ est le joueur connecté', (
      tester,
    ) async {
      final detail = GroupDetail(
        id: 'group-1',
        name: 'Les Lames de l’Aube',
        ownerId: 'user-mj',
        inviteCode: 'ABC123',
        currentUserId: 'user-mj',
        members: const [gameMaster, _friend],
      );
      await _pump(tester, detail);

      expect(find.textContaining('(toi)', findRichText: true), findsOneWidget);
    });
  });
}
