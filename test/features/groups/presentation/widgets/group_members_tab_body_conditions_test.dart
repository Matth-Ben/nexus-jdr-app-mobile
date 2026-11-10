// Pastilles de conditions (P6) sur la carte membre de l'onglet « Membres »
// (vue du MJ) : lecture seule, compactes, carte toujours tappable (T7).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/characters/domain/condition_type.dart';
import 'package:personnages/features/characters/presentation/widgets/condition_chips.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_role.dart';
import 'package:personnages/features/groups/presentation/widgets/group_members_tab_body.dart';
import 'package:personnages/l10n/app_localizations.dart';

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

GroupMember _friend({List<ConditionType> conditions = const []}) => GroupMember(
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
  conditions: conditions,
);

Future<void> _pump(
  WidgetTester tester,
  GroupMember friend, {
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(360, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final detail = GroupDetail(
    id: 'group-1',
    name: 'Les Lames de l’Aube',
    ownerId: 'user-me',
    inviteCode: 'ABC123',
    currentUserId: 'user-me',
    members: [_me, friend],
  );
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
        path: '/groups/:id/members/:characterId',
        builder: (context, state) =>
            Text('Fiche membre ${state.pathParameters['characterId']}'),
      ),
      GoRoute(
        path: '/characters/:id',
        builder: (context, state) => const Text('Ma fiche'),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
}

/// Hauteur de la carte d'Eldrin (le plus petit `Container` décoré qui
/// contient son nom).
double _friendCardHeight(WidgetTester tester) {
  final card = find
      .ancestor(
        of: find.textContaining('Eldrin'),
        matching: find.byType(InkWell),
      )
      .first;
  return tester.getSize(card).height;
}

void main() {
  testWidgets('sans condition : aucune zone, aucune hauteur ajoutée', (
    tester,
  ) async {
    await _pump(tester, _friend());
    final withoutConditions = _friendCardHeight(tester);
    expect(find.byType(ConditionsZone), findsNothing);
    expect(find.byType(ConditionChip), findsNothing);

    await _pump(tester, _friend(conditions: const [ConditionType.blinded]));
    // La zone ne peut ajouter que sa propre hauteur (24 compact + 4 de marge) ;
    // une carte sans condition garde exactement sa hauteur d'origine.
    final withOne = _friendCardHeight(tester);
    expect(withOne, greaterThanOrEqualTo(withoutConditions));
    expect(withOne, lessThanOrEqualTo(withoutConditions + 24 + 4));
    await _pump(tester, _friend());
    expect(_friendCardHeight(tester), withoutConditions);
  });

  testWidgets('5 conditions à 360 dp : 2 pastilles compactes + « +3 »', (
    tester,
  ) async {
    await _pump(
      tester,
      _friend(
        conditions: const [
          ConditionType.blinded,
          ConditionType.poisoned,
          ConditionType.prone,
          ConditionType.stunned,
          ConditionType.unconscious,
        ],
      ),
    );
    expect(find.byType(ConditionChip), findsNWidgets(2));
    expect(find.text('+3'), findsOneWidget);
    // Lecture seule : aucune zone de tap propre ni bouton d'édition.
    expect(
      find.descendant(
        of: find.byType(ConditionsZone),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(ConditionsZone),
        matching: find.byType(IconButton),
      ),
      findsNothing,
    );
    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: find.byType(ConditionChip).first,
                  matching: find.byType(Container),
                )
                .first,
          )
          .height,
      24,
    );
  });

  testWidgets('la carte reste tappable : un tap sur une pastille ouvre la '
      'fiche du membre', (tester) async {
    await _pump(tester, _friend(conditions: const [ConditionType.blinded]));
    await tester.tap(find.text('Aveuglé'));
    await tester.pumpAndSettle();
    expect(find.text('Fiche membre char-friend'), findsOneWidget);
  });

  testWidgets('police x2,0 : la zone ne déborde pas (toutes les pastilles '
      'passent à la ligne)', (tester) async {
    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previous);

    await _pump(
      tester,
      _friend(conditions: ConditionType.values.take(5).toList()),
      scale: 2,
    );

    expect(find.byType(ConditionChip), findsNWidgets(5));
    expect(
      reported.where((d) => d.toString().contains('overflowed')),
      isEmpty,
      reason: 'aucun débordement de mise en page',
    );
  });
}
