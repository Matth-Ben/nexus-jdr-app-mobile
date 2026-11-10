// Zone d'état et pastilles de conditions (P6) : règles T1, T2, T8, T9 et T11
// de la spec de la direction artistique.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/pixel_icon.dart';
import 'package:personnages/features/characters/domain/condition_type.dart';
import 'package:personnages/features/characters/presentation/widgets/condition_chips.dart';
import 'package:personnages/features/characters/presentation/widgets/condition_texts.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:personnages/l10n/app_localizations_en.dart';
import 'package:personnages/l10n/app_localizations_fr.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double scale = 1,
  Locale locale = const Locale('fr'),
  Size surface = const Size(360, 800),
}) async {
  tester.view.physicalSize = surface;
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
        body: Padding(
          // Largeur utile d'une carte de la fiche à 360 dp : 360 - 2 x 22
          // (marge de page) - 2 x 16 (padding de carte).
          padding: const EdgeInsets.all(38),
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    ),
  );
}

const _five = [
  ConditionType.blinded,
  ConditionType.poisoned,
  ConditionType.prone,
  ConditionType.stunned,
  ConditionType.unconscious,
];

void main() {
  group('T1 : aucune condition', () {
    testWidgets('aucune pastille, un seul bouton discret >= 44, sans titre', (
      tester,
    ) async {
      await _pump(tester, ConditionsZone(conditions: const [], onEdit: () {}));
      expect(find.byType(ConditionChip), findsNothing);
      expect(find.byType(PixelIcon), findsNothing);
      expect(find.text('État'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byType(TextButton), findsOneWidget);
      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(44),
      );
      expect(find.textContaining('ÉTAT'), findsNothing);
    });

    testWidgets('tap sur le bouton appelle onEdit', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        ConditionsZone(conditions: const [], onEdit: () => taps++),
      );
      await tester.tap(find.text('État'));
      expect(taps, 1);
    });

    testWidgets('lecture seule : rien du tout (hauteur nulle)', (tester) async {
      await _pump(tester, const ConditionsZone(conditions: []));
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(ConditionChip), findsNothing);
      expect(tester.getSize(find.byType(ConditionsZone)), Size.zero);
    });
  });

  group('T2 : pastilles et plafond « +N »', () {
    for (final count in [1, 2, 3]) {
      testWidgets('$count condition(s) : $count pastille(s), pas de « +N »', (
        tester,
      ) async {
        await _pump(
          tester,
          ConditionsZone(
            conditions: _five.take(count).toList(),
            onEdit: () {},
            maxFullChips: 3,
          ),
        );
        expect(find.byType(ConditionChip), findsNWidgets(count));
        expect(find.textContaining('+'), findsNothing);
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      });
    }

    testWidgets('5 conditions à 360 dp : 3 pastilles + « +2 »', (tester) async {
      await _pump(
        tester,
        ConditionsZone(conditions: _five, onEdit: () {}, maxFullChips: 3),
      );
      expect(find.byType(ConditionChip), findsNWidgets(3));
      expect(find.text('+2'), findsOneWidget);
      // Ordre alphabétique FR : les trois premières restent visibles, les
      // deux dernières (Étourdi, Inconscient) sont masquées par « +2 ».
      expect(find.text('À terre'), findsOneWidget);
      expect(find.text('Aveuglé'), findsOneWidget);
      expect(find.text('Empoisonné'), findsOneWidget);
      expect(find.text('Étourdi'), findsNothing);
      expect(find.text('Inconscient'), findsNothing);
    });

    testWidgets('carte membre MJ (max 2) : 2 pastilles + « +N »', (
      tester,
    ) async {
      await _pump(
        tester,
        const ConditionsZone(conditions: _five, maxFullChips: 2, compact: true),
      );
      expect(find.byType(ConditionChip), findsNWidgets(2));
      expect(find.text('+3'), findsOneWidget);
    });

    testWidgets('grande police : pas de plafond, tout passe à la ligne', (
      tester,
    ) async {
      await _pump(
        tester,
        ConditionsZone(conditions: _five, onEdit: () {}, maxFullChips: 3),
        scale: 2,
      );
      expect(find.byType(ConditionChip), findsNWidgets(5));
      expect(find.textContaining('+'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap sur une pastille, sur « +N » ou sur le bouton ouvre le '
        'sélecteur (onEdit)', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        ConditionsZone(
          conditions: _five,
          onEdit: () => taps++,
          maxFullChips: 3,
        ),
      );
      await tester.tap(find.text('Aveuglé'));
      await tester.tap(find.text('+2'));
      await tester.tap(find.byIcon(Icons.edit_outlined));
      expect(taps, 3);
    });

    testWidgets('pastille éditable : zone de tap >= 44, hauteur visuelle 28', (
      tester,
    ) async {
      await _pump(
        tester,
        ConditionsZone(
          conditions: const [ConditionType.blinded],
          onEdit: () {},
        ),
      );
      expect(
        tester.getSize(find.byType(InkWell).first).height,
        greaterThanOrEqualTo(44),
      );
      final visual = find.descendant(
        of: find.byType(InkWell).first,
        matching: find.byType(Container),
      );
      expect(tester.getSize(visual.first).height, 28);
      expect(tester.getSize(find.byType(IconButton)), const Size(44, 44));
    });

    testWidgets('lecture seule : aucune zone de tap, hauteur compacte 24', (
      tester,
    ) async {
      await _pump(
        tester,
        const ConditionsZone(
          conditions: [ConditionType.blinded],
          compact: true,
        ),
      );
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      final visual = find.descendant(
        of: find.byType(ConditionChip),
        matching: find.byType(Container),
      );
      expect(tester.getSize(visual.first).height, 24);
    });
  });

  group('T8 : police x2,0 sur 360 dp', () {
    testWidgets('les 14 pastilles ne débordent pas, aucun texte sous 11 px', (
      tester,
    ) async {
      await _pump(
        tester,
        ConditionsZone(
          conditions: ConditionType.values,
          onEdit: () {},
          maxFullChips: 3,
        ),
        scale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(ConditionChip), findsNWidgets(14));
      final paragraphs = tester.renderObjectList<RenderParagraph>(
        find.descendant(
          of: find.byType(ConditionsZone),
          matching: find.byType(RichText),
        ),
      );
      for (final paragraph in paragraphs) {
        final size = paragraph.text.style?.fontSize ?? 14;
        expect(paragraph.textScaler.scale(size), greaterThanOrEqualTo(11));
      }
    });

    testWidgets('mode « + État » à x2,0 : aucun débordement', (tester) async {
      await _pump(
        tester,
        ConditionsZone(conditions: const [], onEdit: () {}),
        scale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('T9 : textes FR/EN, tokens', () {
    const frLabels = {
      ConditionType.blinded: 'Aveuglé',
      ConditionType.charmed: 'Charmé',
      ConditionType.deafened: 'Assourdi',
      ConditionType.frightened: 'Effrayé',
      ConditionType.grappled: 'Agrippé',
      ConditionType.incapacitated: 'Neutralisé',
      ConditionType.invisible: 'Invisible',
      ConditionType.paralyzed: 'Paralysé',
      ConditionType.petrified: 'Pétrifié',
      ConditionType.poisoned: 'Empoisonné',
      ConditionType.prone: 'À terre',
      ConditionType.restrained: 'Entravé',
      ConditionType.stunned: 'Étourdi',
      ConditionType.unconscious: 'Inconscient',
    };
    const enLabels = {
      ConditionType.blinded: 'Blinded',
      ConditionType.charmed: 'Charmed',
      ConditionType.deafened: 'Deafened',
      ConditionType.frightened: 'Frightened',
      ConditionType.grappled: 'Grappled',
      ConditionType.incapacitated: 'Incapacitated',
      ConditionType.invisible: 'Invisible',
      ConditionType.paralyzed: 'Paralyzed',
      ConditionType.petrified: 'Petrified',
      ConditionType.poisoned: 'Poisoned',
      ConditionType.prone: 'Prone',
      ConditionType.restrained: 'Restrained',
      ConditionType.stunned: 'Stunned',
      ConditionType.unconscious: 'Unconscious',
    };

    test(
      'libellés FR et EN attendus, règles non vides, FR <= 90 caractères',
      () {
        final fr = AppLocalizationsFr();
        final en = AppLocalizationsEn();
        for (final type in ConditionType.values) {
          expect(type.label(fr), frLabels[type], reason: type.name);
          expect(type.label(en), enLabels[type], reason: type.name);
          expect(type.rule(fr).trim(), isNotEmpty, reason: type.name);
          expect(type.rule(en).trim(), isNotEmpty, reason: type.name);
          expect(
            type.rule(fr).length,
            lessThanOrEqualTo(90),
            reason: type.name,
          );
          expect(type.rule(fr), isNot(type.rule(en)), reason: type.name);
        }
      },
    );

    test(
      'ordre alphabétique FR (accents et casse ignorés), pas sur la clé',
      () {
        final sorted = sortConditionsForDisplay(
          ConditionType.values,
          AppLocalizationsFr(),
        ).map((c) => c.label(AppLocalizationsFr())).toList();
        expect(sorted, [
          'À terre',
          'Agrippé',
          'Assourdi',
          'Aveuglé',
          'Charmé',
          'Effrayé',
          'Empoisonné',
          'Entravé',
          'Étourdi',
          'Inconscient',
          'Invisible',
          'Neutralisé',
          'Paralysé',
          'Pétrifié',
        ]);
      },
    );

    test('ordre alphabétique EN', () {
      final en = AppLocalizationsEn();
      final sorted = sortConditionsForDisplay(
        ConditionType.values,
        en,
      ).map((c) => c.label(en)).toList();
      expect(sorted, [
        'Blinded',
        'Charmed',
        'Deafened',
        'Frightened',
        'Grappled',
        'Incapacitated',
        'Invisible',
        'Paralyzed',
        'Petrified',
        'Poisoned',
        'Prone',
        'Restrained',
        'Stunned',
        'Unconscious',
      ]);
    });

    testWidgets('pastille en anglais : libellé EN', (tester) async {
      await _pump(
        tester,
        const ConditionChip(condition: ConditionType.prone),
        locale: const Locale('en'),
      );
      expect(find.text('Prone'), findsOneWidget);
    });

    testWidgets('couleurs de la pastille : uniquement des tokens', (
      tester,
    ) async {
      await _pump(
        tester,
        const ConditionChip(condition: ConditionType.charmed),
      );
      final decoration =
          tester
                  .widget<Container>(
                    find
                        .descendant(
                          of: find.byType(ConditionChip),
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(decoration.color, AppColors.parchmentCardAlt);
      expect((decoration.border! as Border).top.color, AppColors.accentBrick);
      expect((decoration.border! as Border).top.width, 1);
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(PixelIcon),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as PixelIconPainter;
      expect(painter.color, AppColors.accentBrick);
      final text = tester.widget<Text>(find.text('Charmé'));
      expect(text.style!.color, AppColors.textPrimary);
    });

    test('contraste accent.brick sur parchment.card-alt >= 3:1', () {
      double lum(Color c) => c.computeLuminance();
      final a = lum(AppColors.parchmentCardAlt);
      final b = lum(AppColors.accentBrick);
      expect((a + 0.05) / (b + 0.05), greaterThanOrEqualTo(3));
    });
  });

  group('T11 : Semantics', () {
    testWidgets('zone, pastille (bouton), « +N » et boutons', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        ConditionsZone(conditions: _five, onEdit: () {}, maxFullChips: 3),
      );

      // Zone : liste de tous les noms, ordre alphabétique.
      expect(
        find.bySemanticsLabel(
          'États actifs : À terre, Aveuglé, Empoisonné, Étourdi, Inconscient',
        ),
        findsOneWidget,
      );
      // Pastille : « Libellé : règle », bouton.
      final chip = tester.getSemantics(
        find.bySemanticsLabel(
          'Aveuglé : Ne voit pas ; ses attaques ont le désavantage, celles '
          "contre lui l'avantage.",
        ),
      );
      expect(chip.flagsCollection.isButton, isTrue);
      // « +N » : liste les noms masqués.
      expect(
        find.bySemanticsLabel('2 autres états : Étourdi, Inconscient'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Modifier les états'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('bouton « Ajouter un état » quand aucune condition', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, ConditionsZone(conditions: const [], onEdit: () {}));
      final node = tester.getSemantics(
        find.bySemanticsLabel('Ajouter un état'),
      );
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('lecture seule : pastille sans rôle de bouton', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const ConditionsZone(conditions: [ConditionType.blinded]),
      );
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Aveuglé :')),
      );
      expect(node.flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('PixelIcon exclu de l arbre sémantique', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const ConditionChip(condition: ConditionType.blinded),
      );
      expect(
        find.descendant(
          of: find.byType(PixelIcon),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
