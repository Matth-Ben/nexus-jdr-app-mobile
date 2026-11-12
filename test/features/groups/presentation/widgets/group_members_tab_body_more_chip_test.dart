// V3-5 : la pastille « +N » d'une carte membre (vue MJ) ouvre une feuille en
// lecture seule listant TOUS les états du membre ; le reste de la carte ouvre
// toujours la fiche.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/characters/domain/condition_type.dart';
import 'package:personnages/features/characters/presentation/widgets/condition_chips.dart';
import 'package:personnages/features/characters/presentation/widgets/condition_texts.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_role.dart';
import 'package:personnages/features/groups/presentation/widgets/group_members_tab_body.dart';
import 'package:personnages/features/groups/presentation/widgets/member_conditions_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:personnages/l10n/app_localizations_en.dart';
import 'package:personnages/l10n/app_localizations_fr.dart';

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

const _five = [
  ConditionType.blinded,
  ConditionType.poisoned,
  ConditionType.prone,
  ConditionType.stunned,
  ConditionType.unconscious,
];

GroupMember _friend({
  List<ConditionType> conditions = _five,
  String name = 'Eldrin',
}) => GroupMember(
  characterId: 'char-friend',
  userId: 'user-friend',
  role: GroupRole.membre,
  name: name,
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
  Locale locale = const Locale('fr'),
  Size surface = const Size(360, 1400),
}) async {
  tester.view.physicalSize = surface;
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

Finder get _sheet => find.byType(MemberConditionsSheet);

Finder _inSheet(String text) =>
    find.descendant(of: _sheet, matching: find.text(text));

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

void main() {
  // Polices réelles : la police de test fausserait les largeurs de texte.
  setUpAll(() async {
    await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  group('ouverture de la feuille', () {
    testWidgets('FR : tap sur « +3 » ouvre la feuille avec les 5 états', (
      tester,
    ) async {
      await _pump(tester, _friend());
      final l10n = AppLocalizationsFr();
      expect(find.byType(ConditionChip), findsNWidgets(2));

      await tester.tap(find.text('+3'));
      await tester.pumpAndSettle();

      expect(_sheet, findsOneWidget);
      expect(find.text('Fiche membre char-friend'), findsNothing);
      // Titre + TOUS les états, pas seulement les masqués, chacun avec sa
      // règle courte.
      expect(
        find.text(l10n.memberConditionsSheetTitle('Eldrin')),
        findsOneWidget,
      );
      for (final c in _five) {
        expect(_inSheet(c.label(l10n)), findsOneWidget, reason: c.name);
        expect(_inSheet(c.rule(l10n)), findsOneWidget, reason: c.name);
      }
      // Ordre alphabétique (sortConditionsForDisplay).
      final sorted = sortConditionsForDisplay(_five, l10n);
      final tops = [
        for (final c in sorted) tester.getTopLeft(_inSheet(c.label(l10n))).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      // Lecture seule : ni case, ni pied, ni bouton de validation.
      expect(
        find.descendant(of: _sheet, matching: find.byType(Checkbox)),
        findsNothing,
      );
      expect(
        find.descendant(of: _sheet, matching: find.byType(ElevatedButton)),
        findsNothing,
      );
    });

    testWidgets('EN : titre « Eldrin\'s conditions » et 5 états', (
      tester,
    ) async {
      await _pump(tester, _friend(), locale: const Locale('en'));
      final l10n = AppLocalizationsEn();
      await tester.tap(find.text('+3'));
      await tester.pumpAndSettle();

      expect(_sheet, findsOneWidget);
      expect(find.text("Eldrin's conditions"), findsOneWidget);
      for (final c in _five) {
        expect(_inSheet(c.label(l10n)), findsOneWidget, reason: c.name);
        expect(_inSheet(c.rule(l10n)), findsOneWidget, reason: c.name);
      }
    });

    testWidgets('la feuille se ferme par la croix, sans ouvrir la fiche', (
      tester,
    ) async {
      await _pump(tester, _friend());
      await tester.tap(find.text('+3'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(_sheet, findsNothing);
      expect(find.text('Fiche membre char-friend'), findsNothing);
    });

    testWidgets('hauteur de la feuille plafonnée à 0,6 de l\'écran', (
      tester,
    ) async {
      await _pump(
        tester,
        _friend(conditions: ConditionType.values),
        surface: const Size(360, 640),
      );
      await tester.tap(find.text('+12'));
      await tester.pumpAndSettle();
      expect(_sheet, findsOneWidget);
      expect(
        tester.getSize(find.byType(MemberConditionsSheet)).height,
        lessThanOrEqualTo(640 * kMemberConditionsSheetMaxHeightFactor + 0.01),
      );
    });
  });

  group('arène de gestes', () {
    testWidgets('tap sur « +N » n\'ouvre PAS la fiche ; tap ailleurs oui', (
      tester,
    ) async {
      await _pump(tester, _friend());
      await tester.tap(find.text('+3'));
      await tester.pumpAndSettle();
      expect(find.text('Fiche membre char-friend'), findsNothing);
      expect(_sheet, findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eldrin'));
      await tester.pumpAndSettle();
      expect(find.text('Fiche membre char-friend'), findsOneWidget);
      expect(_sheet, findsNothing);
    });

    testWidgets('une pastille individuelle n\'ouvre pas la feuille', (
      tester,
    ) async {
      await _pump(tester, _friend());
      await tester.tap(find.text('Aveuglé'));
      await tester.pumpAndSettle();
      expect(_sheet, findsNothing);
      expect(find.text('Fiche membre char-friend'), findsOneWidget);
    });
  });

  group('pastille « +N »', () {
    testWidgets('cible de tap >= 44 x 44', (tester) async {
      await _pump(tester, _friend());
      final target = find
          .ancestor(of: find.text('+3'), matching: find.byType(InkWell))
          .first;
      expect(target, findsOneWidget);
      final size = tester.getSize(target);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('sémantique : bouton, libellé inchangé, hint', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _friend());
      final node = tester.getSemantics(
        find.bySemanticsLabel(
          '3 autres états : Empoisonné, Étourdi, Inconscient',
        ),
      );
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.hint, 'Ouvre la liste des états');
      handle.dispose();
    });

    testWidgets('sémantique EN : hint traduit', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _friend(), locale: const Locale('en'));
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'^3 more conditions: ')),
      );
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.hint, 'Opens the list of conditions');
      handle.dispose();
    });

    testWidgets('2 conditions ou moins : pas de « +N », donc pas de feuille', (
      tester,
    ) async {
      await _pump(
        tester,
        _friend(conditions: const [ConditionType.blinded, ConditionType.prone]),
      );
      expect(find.textContaining('+'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(ConditionsZone),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });

    testWidgets('x2,0 sur 320 dp : pas de « +N », tous les noms visibles', (
      tester,
    ) async {
      await _pump(tester, _friend(), scale: 2, surface: const Size(320, 1800));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('+'), findsNothing);
      final l10n = AppLocalizationsFr();
      for (final c in _five) {
        expect(find.text(c.label(l10n)), findsOneWidget, reason: c.name);
      }
    });

    testWidgets('x1,4 (> 1,3) : pas de « +N », tous les noms visibles', (
      tester,
    ) async {
      await _pump(tester, _friend(), scale: 1.4);
      expect(find.textContaining('+'), findsNothing);
      expect(find.byType(ConditionChip), findsNWidgets(5));
    });
  });

  group('feuille seule', () {
    Future<void> pumpSheet(
      WidgetTester tester, {
      required String name,
      required List<ConditionType> conditions,
      double scale = 2,
      Locale locale = const Locale('fr'),
    }) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          builder: (context, c) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: c!,
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MemberConditionsSheet(
                memberName: name,
                conditions: conditions,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final locale in const [Locale('fr'), Locale('en')]) {
      testWidgets('x2,0 sur 320 dp (${locale.languageCode}) : 14 états, '
          'aucune exception, corps défilant', (tester) async {
        await pumpSheet(
          tester,
          name: 'Eldrin',
          conditions: ConditionType.values,
          locale: locale,
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(MemberConditionsSheet)).height,
          lessThanOrEqualTo(640 * kMemberConditionsSheetMaxHeightFactor + 0.01),
        );
        // Le corps défile : on atteint la dernière ligne.
        final l10n = locale.languageCode == 'fr'
            ? AppLocalizationsFr() as AppLocalizations
            : AppLocalizationsEn();
        final last = sortConditionsForDisplay(
          ConditionType.values,
          l10n,
        ).last.label(l10n);
        await tester.scrollUntilVisible(
          find.text(last),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(last), findsOneWidget);
        // Jamais d'ellipse sur libellé ni règle.
        for (final t in tester.widgetList<Text>(
          find.descendant(
            of: find.byType(MemberConditionsSheet),
            matching: find.byType(Text),
          ),
        )) {
          if (t.maxLines == null) {
            expect(t.overflow, isNot(TextOverflow.ellipsis));
          }
        }
      });
    }

    testWidgets('nom de membre très long : pas d\'exception', (tester) async {
      await pumpSheet(
        tester,
        name:
            'Alexandrina-Wilhelmina von Hohenzollern-Sigmaringen-Montmorency '
            'de la Haute-Vallée des Quatre Vents',
        conditions: const [ConditionType.blinded],
      );
      expect(tester.takeException(), isNull);
      expect(_inSheet('Aveuglé'), findsOneWidget);
    });

    testWidgets('liste vide : « Aucun état actif. »', (tester) async {
      await pumpSheet(tester, name: 'Eldrin', conditions: const [], scale: 1);
      expect(find.text('Aucun état actif.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('liste vide EN', (tester) async {
      await pumpSheet(
        tester,
        name: 'Eldrin',
        conditions: const [],
        scale: 1,
        locale: const Locale('en'),
      );
      expect(find.text('No active condition.'), findsOneWidget);
    });
  });
}
