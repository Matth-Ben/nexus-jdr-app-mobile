// Tests de widget de l'onglet « Membres » d'un groupe
// (`presentation/widgets/group_members_tab_body.dart`) : code d'invitation
// copiable, ouverture de la fiche d'un membre au toucher (demandes
// utilisateur du 2026-09-27), tri MJ-en-premier et carte "en attente d'un
// personnage" (membre orphelin, voir `GroupMember.isAwaitingCharacter`).

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
  isGameMaster: false,
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
  isGameMaster: false,
  level: 3,
  currentHp: 15,
  maxHp: 18,
  temporaryHp: 0,
  isDead: false,
);

GroupDetail _detail(
  List<GroupMember> members, {
  String currentUserId = 'user-me',
}) => GroupDetail(
  id: 'group-1',
  name: 'Les Lames de l’Aube',
  ownerId: 'user-me',
  inviteCode: 'ABC123',
  currentUserId: currentUserId,
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
      GoRoute(
        path: '/groups/:id/reassign-character',
        builder: (context, state) =>
            Text('Choisir un nouveau personnage ${state.pathParameters['id']}'),
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

  group('MJ volontaire', () {
    // Nom volontairement distinct de `_me`/`_friend` (jamais un sous-chaîne
    // de "Brunhilde"/"Eldrin") : `find.textContaining` ci-dessous ne doit
    // jamais ambiguïser la carte MJ avec une autre carte de ce fichier.
    const gameMaster = GroupMember(
      userId: 'user-mj',
      role: GroupRole.membre,
      name: 'Oswald',
      isGameMaster: true,
    );

    testWidgets('libellé "MJ - {nom}", texte PV neutre, jamais le fond '
        '"MORT"', (tester) async {
      await _pump(tester, _detail(const [_me, gameMaster]));

      expect(
        find.textContaining('MJ - Oswald', findRichText: true),
        findsOneWidget,
      );
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

    testWidgets('jamais le badge "MJ" en pilule (retiré au profit du '
        'libellé "MJ - {nom}")', (tester) async {
      await _pump(tester, _detail(const [_me, gameMaster]));

      // Seul "MJ - Oswald" doit matérialiser le préfixe "MJ" — jamais un
      // texte "MJ" isolé (ancien badge pilule, retiré).
      expect(find.text('MJ'), findsNothing);
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

    testWidgets('toujours affiché en premier, sans réordonner les autres '
        'membres entre eux', (tester) async {
      // `_friend` et `_me` apparaissent dans cet ordre AVANT le MJ dans la
      // liste source — le tri ne doit déplacer que le MJ, jamais permuter
      // `_friend`/`_me` entre eux.
      await _pump(tester, _detail(const [_friend, _me, gameMaster]));

      final cardOrder = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((richText) => richText.text.toPlainText())
          .where(
            (text) =>
                text.contains('Oswald') ||
                text.contains('Eldrin') ||
                text.contains('Brunhilde'),
          )
          .toList();

      expect(cardOrder.first, contains('Oswald'));
      final eldrinIndex = cardOrder.indexWhere((t) => t.contains('Eldrin'));
      final brunhildeIndex = cardOrder.indexWhere(
        (t) => t.contains('Brunhilde'),
      );
      expect(eldrinIndex, lessThan(brunhildeIndex));
    });
  });

  group('Membre orphelin (GroupMember.isAwaitingCharacter)', () {
    const orphan = GroupMember(
      userId: 'user-orphan',
      role: GroupRole.membre,
      name: "En attente d'un personnage",
      isGameMaster: false,
    );

    testWidgets('rendu : icône sablier, nom, texte d\'état, jamais le fond '
        '"MORT"', (tester) async {
      await _pump(tester, _detail(const [_me, orphan]));

      expect(
        find.textContaining("En attente d'un personnage", findRichText: true),
        findsWidgets,
      );
      expect(find.byIcon(Icons.hourglass_empty_rounded), findsWidgets);

      final cardFinder = find.ancestor(
        of: find
            .textContaining("En attente d'un personnage", findRichText: true)
            .first,
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

    testWidgets('pas trié en première position (reste à sa position '
        'naturelle)', (tester) async {
      await _pump(tester, _detail(const [orphan, _me]));

      final cardOrder = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((richText) => richText.text.toPlainText())
          .where(
            (text) =>
                text.contains("En attente d'un personnage") ||
                text.contains('Brunhilde'),
          )
          .toList();

      expect(cardOrder.first, contains("En attente d'un personnage"));
    });

    testWidgets('ligne orpheline d\'un AUTRE membre : aucune zone de tap', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail(const [_me, orphan], currentUserId: 'user-me'),
      );

      final orphanInkWell = find.ancestor(
        of: find
            .textContaining("En attente d'un personnage", findRichText: true)
            .first,
        matching: find.byType(InkWell),
      );
      expect(orphanInkWell, findsNothing);
    });

    testWidgets('sa PROPRE ligne orpheline rouvre l\'écran de choix de '
        'personnage', (tester) async {
      await _pump(
        tester,
        _detail(const [orphan, _friend], currentUserId: 'user-orphan'),
      );

      await tester.tap(
        find
            .textContaining("En attente d'un personnage", findRichText: true)
            .first,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Choisir un nouveau personnage group-1'),
        findsOneWidget,
      );
    });

    testWidgets('suffixe " (toi)" sur sa propre ligne orpheline', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail(const [orphan, _friend], currentUserId: 'user-orphan'),
      );

      expect(find.textContaining('(toi)', findRichText: true), findsOneWidget);
    });
  });

  group('Ligne 3 : Classe d\'Armure (GroupMember.armorClass)', () {
    const gameMaster = GroupMember(
      userId: 'user-mj',
      role: GroupRole.membre,
      name: 'Oswald',
      isGameMaster: true,
    );
    const orphan = GroupMember(
      userId: 'user-orphan',
      role: GroupRole.membre,
      name: "En attente d'un personnage",
      isGameMaster: false,
    );

    testWidgets('armorClassBonus nul -> "CA {valeur}" seul, sans suffixe', (
      tester,
    ) async {
      final member = _me.copyWith(armorClass: 16, armorClassBonus: 0);
      await _pump(tester, _detail([member]));

      expect(find.text('CA 16'), findsOneWidget);
    });

    testWidgets(
      'armorClassBonus positif -> suffixe signé "+N" après la valeur',
      (tester) async {
        final member = _me.copyWith(armorClass: 18, armorClassBonus: 2);
        await _pump(tester, _detail([member]));

        expect(find.text('CA 16'), findsNothing);
        expect(
          find.textContaining('CA 18 +2', findRichText: true),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'armorClassBonus négatif -> suffixe signé avec le vrai signe moins '
      'Unicode',
      (tester) async {
        final member = _me.copyWith(armorClass: 13, armorClassBonus: -1);
        await _pump(tester, _detail([member]));

        expect(
          find.textContaining('CA 13 −1', findRichText: true),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'armorClass null (ex. membre pas encore enrichi) -> aucune ligne CA',
      (tester) async {
        // `_friend` n'a pas `armorClass` renseigné (null par défaut).
        await _pump(tester, _detail([_friend]));

        expect(find.textContaining('CA '), findsNothing);
      },
    );

    testWidgets('jamais affichée sur la carte MJ volontaire', (tester) async {
      await _pump(tester, _detail([_me, gameMaster]));

      expect(find.textContaining('CA '), findsNothing);
    });

    testWidgets('jamais affichée sur la carte orpheline', (tester) async {
      await _pump(tester, _detail([_me, orphan]));

      expect(find.textContaining('CA '), findsNothing);
    });
  });
}
