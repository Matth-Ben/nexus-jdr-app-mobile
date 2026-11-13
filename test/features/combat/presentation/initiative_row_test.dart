// `InitiativeRow` : états, badges, modes normal/empilé, sémantique et
// recettage mesurable (`docs/combat-groupe-ui.md` §6) à 320 dp.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/compact_action_button.dart';
import 'package:personnages/core/widgets/dashed_border_painter.dart';
import 'package:personnages/features/combat/domain/combat_enums.dart';
import 'package:personnages/features/combat/domain/combat_participant.dart';
import 'package:personnages/features/combat/presentation/widgets/initiative_row.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../../support/combat_fixtures.dart';
import 'combat_test_harness.dart';

const _longName = 'Capitaine Gobelin des Montagnes Brumeuses';

Future<void> _pumpRow(
  WidgetTester tester,
  CombatParticipant participant, {
  double scale = 1,
  int? rank = 1,
  bool isCurrent = false,
  bool isYou = false,
  bool manage = false,
  bool actionsEnabled = true,
  bool reorderMode = false,
  Locale locale = const Locale('fr'),
}) async {
  tester.view.physicalSize = const Size(320, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Align(
            alignment: Alignment.topCenter,
            child: InitiativeRow(
              participant: participant,
              rank: rank,
              isCurrent: isCurrent,
              isYou: isYou,
              actionsEnabled: actionsEnabled,
              reorderMode: reorderMode,
              onEditInitiative: manage ? () {} : null,
              onRemove: manage ? () {} : null,
              onFill: manage ? () {} : null,
              onMoveUp: reorderMode ? () {} : null,
              onMoveDown: reorderMode ? () {} : null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color _fillOf(WidgetTester tester) {
  final box = tester
      .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
      .first;
  return (box.decoration! as BoxDecoration).color!;
}

void main() {
  setUpAll(loadCombatFonts);

  final pc = fakeParticipant(
    'aria',
    name: 'Aria',
    initiative: 18,
    characterId: 'c',
  );
  final npc = fakeParticipant(
    'gob',
    name: 'Gobelin 1',
    initiative: 12,
    kind: ParticipantKind.npc,
  );

  group('états', () {
    testWidgets('normal : rang, initiative, badge PJ', (tester) async {
      await _pumpRow(tester, pc);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('Init.'), findsOneWidget);
      expect(find.text('PJ'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.text('Tour en cours'), findsNothing);
      expect(_fillOf(tester), AppColors.parchmentCard);
    });

    testWidgets('badge PNJ : libellé + icône, jamais la couleur seule', (
      tester,
    ) async {
      await _pumpRow(tester, npc);
      expect(find.text('PNJ'), findsOneWidget);
      expect(find.byIcon(Icons.dangerous_outlined), findsOneWidget);
    });

    testWidgets('pastille « Toi » sur la ligne du joueur', (tester) async {
      await _pumpRow(tester, pc, isYou: true);
      expect(find.text('Toi'), findsOneWidget);
    });

    testWidgets('tour en cours : libellé, chevron, fond « turn-fill »', (
      tester,
    ) async {
      await _pumpRow(tester, pc, isCurrent: true);
      expect(find.text('Tour en cours'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      final fill = _fillOf(tester);
      expect(fill, kCombatTurnFill);
      // ≈ #F6E4B6 (goldStart à 25 % sur parchment.card), pas un nouvel hex.
      expect((fill.r * 255).round(), closeTo(0xF6, 1));
      expect((fill.g * 255).round(), closeTo(0xE4, 1));
      expect((fill.b * 255).round(), closeTo(0xB6, 1));
      final decoration =
          tester
                  .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
                  .first
                  .decoration!
              as BoxDecoration;
      expect((decoration.border! as Border).top.width, 3);
      expect(decoration.boxShadow!.single.spreadRadius, 1);
    });

    testWidgets('en attente : libellé, icône pause, bordure pointillée', (
      tester,
    ) async {
      await _pumpRow(
        tester,
        npc.copyWith(status: ParticipantStatus.waiting),
        manage: true,
      );
      expect(find.text('En attente'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.foregroundPainter is DashedBorderPainter,
        ),
        findsOneWidget,
      );
      expect(_fillOf(tester), AppColors.parchmentCardAlt);
    });

    testWidgets('retiré : nom barré, libellé, aucun menu', (tester) async {
      await _pumpRow(
        tester,
        npc.copyWith(status: ParticipantStatus.removed),
        manage: true,
      );
      expect(find.text('Retiré'), findsOneWidget);
      final name = tester.widget<Text>(find.text('Gobelin 1'));
      expect(name.style!.decoration, TextDecoration.lineThrough);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(_fillOf(tester), AppColors.parchmentCardAlt);
    });

    testWidgets('sans initiative : « – », libellé et « Renseigner »', (
      tester,
    ) async {
      await _pumpRow(
        tester,
        fakeParticipant('brun', name: 'Brun'),
        rank: null,
        manage: true,
      );
      expect(find.text('–'), findsNWidgets(2));
      expect(find.text('Initiative à saisir'), findsOneWidget);
      expect(find.text('Renseigner'), findsOneWidget);
    });

    testWidgets('hors ligne : menu et « Renseigner » désactivés', (
      tester,
    ) async {
      await _pumpRow(
        tester,
        fakeParticipant('brun', name: 'Brun'),
        rank: null,
        manage: true,
        actionsEnabled: false,
      );
      final menu = tester.widget<IconButton>(
        find.byKey(const Key('combatRowMenu-brun')),
      );
      expect(menu.onPressed, isNull);
      final fill = tester.widget<CompactActionButton>(
        find.byType(CompactActionButton),
      );
      expect(fill.onTap, isNull);
      expect(find.byTooltip('Indisponible hors ligne'), findsNWidgets(2));
    });

    testWidgets('anglais : libellés traduits', (tester) async {
      await _pumpRow(
        tester,
        npc.copyWith(status: ParticipantStatus.waiting),
        locale: const Locale('en'),
      );
      expect(find.text('NPC'), findsOneWidget);
      expect(find.text('On hold'), findsOneWidget);
    });
  });

  group('sémantique', () {
    testWidgets('ligne fusionnée : rang, nom, type, initiative, tour', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpRow(tester, pc, isCurrent: true, isYou: true, manage: true);
      expect(
        find.bySemanticsLabel('1. Aria, PJ, initiative 18, Toi, tour en cours'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('actions sémantiques : Éditer, Retirer, Monter, Descendre', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpRow(tester, npc, manage: true, reorderMode: true);
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^1. Gobelin 1')),
      );
      final labels = node
          .getSemanticsData()
          .customSemanticsActionIds!
          .map((id) => CustomSemanticsAction.getAction(id)!.label)
          .toSet();
      expect(labels, {
        'Éditer l\'initiative',
        'Retirer du combat',
        'Monter Gobelin 1',
        'Descendre Gobelin 1',
      });
      handle.dispose();
    });

    testWidgets('ligne sans initiative : libellé dédié', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpRow(tester, fakeParticipant('brun', name: 'Brun'), rank: null);
      expect(
        find.bySemanticsLabel('Brun, PJ, initiative à saisir'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('recettage à 320 dp', () {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('×$scale : hauteur, cibles, aucun débordement ni ellipse', (
        tester,
      ) async {
        final long = fakeParticipant(
          'cap',
          name: _longName,
          initiative: 12,
          kind: ParticipantKind.npc,
        );
        await _pumpRow(
          tester,
          long,
          scale: scale,
          isCurrent: true,
          isYou: true,
          manage: true,
          reorderMode: true,
        );
        // Aucun RenderFlex overflow (une erreur de rendu ferait échouer).
        expect(tester.takeException(), isNull);

        expect(tester.getSize(find.byType(InitiativeRow)).width, 320 - 44);

        // Nom entier, jamais d'ellipse ni de coupure.
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(_longName),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(tester.widget<Text>(find.text(_longName)).overflow, isNull);
        expect(tester.widget<Text>(find.text(_longName)).maxLines, isNull);

        // Cibles interactives >= 44x44.
        for (final button in tester.widgetList<IconButton>(
          find.byType(IconButton),
        )) {
          final size = tester.getSize(find.byWidget(button));
          expect(size.width, greaterThanOrEqualTo(44));
          expect(size.height, greaterThanOrEqualTo(44));
        }
      });

      testWidgets('×$scale : hauteur d\'une ligne simple dans la spec', (
        tester,
      ) async {
        await _pumpRow(
          tester,
          fakeParticipant(
            'cap',
            name: 'Gobelin 1',
            initiative: 12,
            kind: ParticipantKind.npc,
          ),
          scale: scale,
          isYou: true,
          manage: true,
        );
        expect(tester.takeException(), isNull);
        final height = tester.getSize(find.byType(InitiativeRow)).height;
        if (scale == 1.0) {
          expect(height, inInclusiveRange(64, 84));
        } else if (scale == 2.0) {
          expect(height, inInclusiveRange(100, 150));
        } else {
          expect(height, lessThanOrEqualTo(280));
        }
      });
    }

    testWidgets('mode empilé à partir de ×1,6 : initiative sous le nom', (
      tester,
    ) async {
      await _pumpRow(tester, pc, scale: 1.0);
      final normalInit = tester.getTopLeft(find.text('18'));
      final normalName = tester.getTopLeft(find.text('Aria'));
      expect(normalInit.dx, greaterThan(normalName.dx));
      expect(normalInit.dy, lessThan(normalName.dy + 40));

      await _pumpRow(tester, pc, scale: 1.6);
      final stackedInit = tester.getTopLeft(find.text('18'));
      final stackedName = tester.getTopLeft(find.text('Aria'));
      expect(stackedInit.dy, greaterThan(stackedName.dy + 10));
    });

    testWidgets('nom très long sur 3 lignes à ×3,0 sans ellipse', (
      tester,
    ) async {
      await _pumpRow(
        tester,
        fakeParticipant('cap', name: _longName, initiative: 12),
        scale: 3,
      );
      final lines = tester
          .renderObject<RenderParagraph>(find.text(_longName))
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: _longName.length),
          )
          .map((box) => box.top.round())
          .toSet();
      expect(lines.length, greaterThan(1));
    });
  });
}
