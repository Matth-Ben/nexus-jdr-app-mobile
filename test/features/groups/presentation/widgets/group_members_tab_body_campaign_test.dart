// Carte « Campagne » de l'onglet « Membres » (étape 4 de Grimoire,
// spécification direction-artistique du 19/11/2026, décision n° 36) : titre
// de la campagne associée au groupe, résumé public replié.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_role.dart';
import 'package:personnages/features/groups/presentation/widgets/group_campaign_card.dart';
import 'package:personnages/features/groups/presentation/widgets/group_members_tab_body.dart';
import 'package:personnages/l10n/app_localizations.dart';

const _groupName = 'Les Lames de l’Aube';
const _title = 'La Mine perdue de Phandelver';
const _summary = 'Phandaline est menacée.\nLes héros enquêtent.';
const _prefix = 'Campagne\u00a0: ';

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

GroupDetail _detail({
  String? storyTitle,
  String? storySummaryPublic,
  List<GroupMember> members = const [_me, _friend],
}) => GroupDetail(
  id: 'group-1',
  name: _groupName,
  ownerId: 'user-me',
  inviteCode: 'ABC123',
  currentUserId: 'user-me',
  members: members,
  storyTitle: storyTitle,
  storySummaryPublic: storySummaryPublic,
);

Future<void> _pump(
  WidgetTester tester,
  GroupDetail detail, {
  double scale = 1,
  Size surface = const Size(360, 1400),
  Locale locale = const Locale('fr'),
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
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

Finder _titleLine() => find.textContaining(_title, findRichText: true);

Finder _summaryToggle() => find.byKey(const ValueKey('groupCampaignSummary'));

Future<void> _expandSummary(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Résumé de la campagne'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Résumé de la campagne'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('avec une campagne : carte en tête de liste, avant « Mis à jour '
      'en direct », titre précédé de « Campagne : »', (tester) async {
    await _pump(
      tester,
      _detail(storyTitle: _title, storySummaryPublic: _summary),
    );

    expect(find.byType(GroupCampaignCard), findsOneWidget);
    expect(find.text('$_prefix$_title', findRichText: true), findsOneWidget);
    expect(find.byIcon(Icons.auto_stories), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(GroupCampaignCard)).dy,
      lessThan(tester.getTopLeft(find.text('Mis à jour en direct')).dy),
    );
    // Écart `md` entre la carte et l'indicateur.
    expect(
      tester.getTopLeft(find.text('Mis à jour en direct')).dy -
          tester.getBottomLeft(find.byType(GroupCampaignCard)).dy,
      greaterThanOrEqualTo(16),
    );
    // Titre sans limite de lignes.
    final paragraph = tester.renderObject<RenderParagraph>(_titleLine());
    expect(paragraph.maxLines, isNull);
  });

  testWidgets('en anglais : préfixe « Campaign: », titre non traduit', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(storyTitle: _title, storySummaryPublic: _summary),
      locale: const Locale('en'),
    );

    expect(find.text('Campaign: $_title', findRichText: true), findsOneWidget);
    expect(find.text('Campaign summary'), findsOneWidget);
  });

  testWidgets('sans campagne : ni carte ni espace, « Mis à jour en direct » '
      'reste en tête', (tester) async {
    await _pump(tester, _detail());
    final withoutCampaignTop = tester
        .getTopLeft(find.text('Mis à jour en direct'))
        .dy;

    expect(find.byType(GroupCampaignCard), findsNothing);
    expect(find.textContaining('Campagne', findRichText: true), findsNothing);

    await _pump(tester, _detail(storySummaryPublic: _summary));
    expect(
      find.byType(GroupCampaignCard),
      findsNothing,
      reason: 'un résumé sans titre ne s\'affiche pas',
    );
    expect(
      tester.getTopLeft(find.text('Mis à jour en direct')).dy,
      withoutCampaignTop,
    );
  });

  testWidgets('titre identique au nom du groupe avec un résumé : pas de '
      'ligne « Campagne : », le résumé reste', (tester) async {
    await _pump(
      tester,
      _detail(
        storyTitle: '  les lames de l’AUBE ',
        storySummaryPublic: _summary,
      ),
    );

    expect(find.byType(GroupCampaignCard), findsOneWidget);
    expect(find.textContaining('Campagne', findRichText: true), findsNothing);
    expect(find.byIcon(Icons.auto_stories), findsNothing);
    expect(_summaryToggle(), findsOneWidget);
  });

  testWidgets('titre identique au nom du groupe sans résumé : pas de carte', (
    tester,
  ) async {
    await _pump(tester, _detail(storyTitle: _groupName));

    expect(find.byType(GroupCampaignCard), findsNothing);
  });

  testWidgets('sans résumé : titre seul, aucune section repliable', (
    tester,
  ) async {
    await _pump(tester, _detail(storyTitle: _title));

    expect(_titleLine(), findsOneWidget);
    expect(_summaryToggle(), findsNothing);
    expect(find.text('Résumé de la campagne'), findsNothing);
  });

  testWidgets('résumé replié par défaut, déplié au toucher, retours à la '
      'ligne gardés', (tester) async {
    await _pump(
      tester,
      _detail(storyTitle: _title, storySummaryPublic: '  $_summary\n'),
    );

    expect(_summaryToggle(), findsOneWidget);
    expect(find.text(_summary), findsNothing);

    await _expandSummary(tester);
    expect(find.text(_summary), findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(find.text(_summary));
    expect(paragraph.maxLines, isNull);

    await tester.tap(find.text('Résumé de la campagne'));
    await tester.pumpAndSettle();
    expect(find.text(_summary), findsNothing);
  });

  testWidgets('titre de 200 caractères et résumé de 500 avec retours à la '
      'ligne, à ×3,0 sur 320 dp : aucun débordement', (tester) async {
    // Plafonds de DeepCore (`char_length`), sans blanc à rogner aux bords.
    final longTitle =
        '${List.filled(20, 'Chroniques ').join().substring(0, 199)}Z';
    final summaryLines = List.generate(
      10,
      (i) => 'Ligne $i : la compagnie traverse les Montagnes de l’Épée.',
    ).join('\n');
    final longSummary = '${summaryLines.substring(0, 499)}.';
    expect(longTitle.runes.length, 200);
    expect(longSummary.runes.length, 500);
    expect('\n'.allMatches(longSummary).length, greaterThanOrEqualTo(8));

    // Le joueur seul dans son groupe : la carte d'un coéquipier que le
    // propriétaire peut exclure déborde déjà à ×3,0 sur 320 dp, sans
    // campagne (ligne PV à côté du bouton « Exclure », hors périmètre).
    await _pump(
      tester,
      _detail(
        storyTitle: longTitle,
        storySummaryPublic: longSummary,
        members: const [_me],
      ),
      scale: 3,
      surface: const Size(320, 640),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('$_prefix$longTitle', findRichText: true), findsOneWidget);

    await _expandSummary(tester);
    expect(tester.takeException(), isNull);
    expect(find.text(longSummary), findsOneWidget);
    // La carte tient dans la largeur de l'écran (marges de la liste comprises).
    expect(tester.getSize(find.byType(GroupCampaignCard)).width, lessThan(320));
  });

  testWidgets('ordre sémantique : en-tête « Campagne », résumé, puis « Mis à '
      'jour en direct » et les membres ; icône exclue', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      _detail(storyTitle: _title, storySummaryPublic: _summary),
    );

    expect(
      tester.getSemantics(_titleLine()),
      isSemantics(label: '$_prefix$_title', isHeader: true),
    );

    final labels = [
      for (final node in tester.semantics.simulatedAccessibilityTraversal())
        node.label,
    ];
    int indexOf(String text) =>
        labels.indexWhere((label) => label.contains(text));

    final header = indexOf(_title);
    final toggle = indexOf('Résumé de la campagne');
    final live = indexOf('Mis à jour en direct');
    final member = indexOf('Brunhilde');
    expect(header, isNonNegative, reason: '$labels');
    expect(toggle, greaterThan(header), reason: '$labels');
    expect(live, greaterThan(toggle), reason: '$labels');
    expect(member, greaterThan(live), reason: '$labels');
    handle.dispose();
  });
}
