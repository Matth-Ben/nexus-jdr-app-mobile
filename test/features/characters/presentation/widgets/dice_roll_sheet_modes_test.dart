// Tests de widget de l'avantage/désavantage de la feuille de dés et des
// sauvegardes touchables (P2 étape 1, 11/11/2026).

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/pixel_icon.dart';
import 'package:personnages/core/widgets/segmented_toggle.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';
import 'package:personnages/core/widgets/sheet_header_bar.dart';
import 'package:personnages/features/characters/domain/dice_roller.dart';
import 'package:personnages/features/characters/domain/saving_throw_calculator.dart';
import 'package:personnages/features/characters/presentation/widgets/character_saving_throws_card.dart';
import 'package:personnages/features/characters/presentation/widgets/dice_roll_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

/// Random figé : `nextInt(20)` renvoie `valeur - 1`, donc chaque tirage vaut la
/// valeur donnée. Lève une `RangeError` si un tirage de trop est effectué
/// (ce qui détecte un relancement non voulu).
class _Seq implements Random {
  _Seq(this._values);

  final List<int> _values;
  int drawn = 0;

  @override
  int nextInt(int max) => _values[drawn++] - 1;

  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0;
}

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

Widget _app({required Widget home, Locale locale = const Locale('fr')}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(body: home),
  );
}

Future<void> _openSheet(
  WidgetTester tester, {
  required Random random,
  int modifier = 3,
  Locale locale = const Locale('fr'),
  List<String>? announcements,
}) async {
  await tester.pumpWidget(
    _app(
      locale: locale,
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDiceRollSheet(
            context,
            label: 'Force',
            modifier: modifier,
            random: random,
            announcer: (_, text) => announcements?.add(text),
          ),
          child: const Text('Ouvrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

/// Plain text de tous les `Text` affichés (y compris `Text.rich`).
List<String> _texts(WidgetTester tester) => [
  for (final t in tester.widgetList<Text>(find.byType(Text)))
    t.data ?? t.textSpan?.toPlainText() ?? '',
];

final _savingResults = SavingThrowCalculator.computeAll(
  abilityScores: const {
    'str': 16,
    'dex': 14,
    'con': 10,
    'int': 8,
    'wis': 12,
    'cha': 10,
  },
  proficientAbilities: const {'str'},
  proficiencyBonus: 2,
);

void main() {
  setUpAll(() async {
    await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  group('sélecteur de mode', () {
    testWidgets('3 états, Normal par défaut, ouverture en Normal', (
      tester,
    ) async {
      final random = _Seq([7]);
      await _openSheet(tester, random: random);

      expect(find.text('NORMAL'), findsOneWidget);
      expect(find.text('AVANTAGE'), findsOneWidget);
      expect(find.text('DÉSAVANTAGE'), findsOneWidget);
      expect(random.drawn, 1, reason: 'un seul d20 tiré à l\'ouverture');
      expect(find.text('d20 (7) +3 = 10'), findsOneWidget);
      expect(find.text('Jet en mode Normal'), findsOneWidget);
      expect(_texts(tester).any((t) => t.contains('écarté')), isFalse);
    });

    testWidgets('segments de 44 dp minimum de haut', (tester) async {
      await _openSheet(tester, random: _Seq([7]));
      for (final label in ['NORMAL', 'AVANTAGE', 'DÉSAVANTAGE']) {
        final inkWell = find.ancestor(
          of: find.text(label),
          matching: find.byType(InkWell),
        );
        expect(tester.getSize(inkWell.first).height, greaterThanOrEqualTo(44));
      }
    });

    testWidgets('changer de mode ne relance pas', (tester) async {
      final random = _Seq([7]);
      await _openSheet(tester, random: random);

      await tester.tap(find.text('AVANTAGE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('DÉSAVANTAGE'));
      await tester.pumpAndSettle();

      expect(random.drawn, 1);
      expect(find.text('d20 (7) +3 = 10'), findsOneWidget);
      // Le résultat affiché garde son mode (Normal) tant qu'on ne relance pas.
      expect(find.text('Jet en mode Normal'), findsOneWidget);
    });

    testWidgets('"Relancer" utilise le mode choisi (avantage)', (tester) async {
      final random = _Seq([5, 4, 17]);
      await _openSheet(tester, random: random);

      await tester.tap(find.text('AVANTAGE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RELANCER'));
      await tester.pumpAndSettle();

      expect(random.drawn, 3);
      expect(
        find.text('Avantage : 4 (écarté) et 17 → 17 + 3 = 20'),
        findsOneWidget,
      );
      expect(find.text('Jet en mode Avantage'), findsOneWidget);
      expect(find.text('20 NATUREL'), findsNothing);
    });

    testWidgets('"Relancer" utilise le mode choisi (désavantage)', (
      tester,
    ) async {
      final random = _Seq([5, 17, 4]);
      await _openSheet(tester, random: random);

      await tester.tap(find.text('DÉSAVANTAGE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RELANCER'));
      await tester.pumpAndSettle();

      expect(
        find.text('Désavantage : 17 (écarté) et 4 → 4 + 3 = 7'),
        findsOneWidget,
      );
    });

    testWidgets('pas de mémoire d\'un jet à l\'autre : réouverture en Normal', (
      tester,
    ) async {
      final random = _Seq([5, 4, 17, 9]);
      await _openSheet(tester, random: random);
      await tester.tap(find.text('AVANTAGE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RELANCER'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('d20 (9) +3 = 12'), findsOneWidget);
      expect(find.text('Jet en mode Normal'), findsOneWidget);
    });
  });

  group('détail avec dé écarté', () {
    testWidgets('dé écarté barré ET accompagné du mot "écarté"', (
      tester,
    ) async {
      await _openSheet(tester, random: _Seq([5, 4, 17]));
      await tester.tap(find.text('AVANTAGE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RELANCER'));
      await tester.pumpAndSettle();

      final detail = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere((t) => (t.textSpan?.toPlainText() ?? '').contains('→'));
      final spans = <TextSpan>[];
      detail.textSpan!.visitChildren((span) {
        if (span is TextSpan) spans.add(span);
        return true;
      });
      final struck = spans.where(
        (s) => s.style?.decoration == TextDecoration.lineThrough,
      );
      expect(struck.map((s) => s.text), ['4']);
      expect(detail.textSpan!.toPlainText(), contains('4 (écarté)'));
      // Le dé gardé n'est pas barré.
      expect(spans.where((s) => s.text == '17').single.style, isNull);
    });

    testWidgets('anglais : "Advantage: 17 and 4 (discarded) → 17 + 3 = 20"', (
      tester,
    ) async {
      await _openSheet(
        tester,
        random: _Seq([5, 17, 4]),
        locale: const Locale('en'),
      );
      await tester.tap(find.text('ADVANTAGE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('REROLL'));
      await tester.pumpAndSettle();

      expect(
        find.text('Advantage: 17 and 4 (discarded) → 17 + 3 = 20'),
        findsOneWidget,
      );
      expect(find.text('Roll mode: Advantage'), findsOneWidget);
    });

    testWidgets('modificateur négatif : "− 2" espacé dans le détail', (
      tester,
    ) async {
      await _openSheet(tester, random: _Seq([5, 17, 4]), modifier: -2);
      await tester.tap(find.text('AVANTAGE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RELANCER'));
      await tester.pumpAndSettle();

      expect(
        find.text('Avantage : 17 et 4 (écarté) → 17 − 2 = 15'),
        findsOneWidget,
      );
    });
  });

  group('vocabulaire et sémantique', () {
    testWidgets('20 naturel : aucun mot "critique", icône + texte', (
      tester,
    ) async {
      await _openSheet(tester, random: _Seq([20]));

      expect(find.text('20 NATUREL'), findsOneWidget);
      // P2b : l'icône Material est remplacée par l'icône pixel provisoire
      // (étoile) prévue par la spec ; la mention texte reste obligatoire.
      expect(find.byKey(const ValueKey('natural-icon-star')), findsOneWidget);
      expect(find.byType(PixelIcon), findsOneWidget);
      expect(
        _texts(tester).any((t) => t.toLowerCase().contains('critique')),
        isFalse,
      );
    });

    testWidgets('1 naturel : aucun mot "critique", icône + texte', (
      tester,
    ) async {
      await _openSheet(tester, random: _Seq([1]));

      expect(find.text('1 NATUREL'), findsOneWidget);
      // P2b : icône pixel provisoire (crâne) à la place de la croix Material.
      expect(find.byKey(const ValueKey('natural-icon-skull')), findsOneWidget);
      expect(find.byType(PixelIcon), findsOneWidget);
      expect(
        _texts(tester).any((t) => t.toLowerCase().contains('critique')),
        isFalse,
      );
    });

    testWidgets('anglais : "NATURAL 20" sans "critical"', (tester) async {
      await _openSheet(tester, random: _Seq([20]), locale: const Locale('en'));
      expect(find.text('NATURAL 20'), findsOneWidget);
      expect(
        _texts(tester).any((t) => t.toLowerCase().contains('critical')),
        isFalse,
      );
    });

    testWidgets('résultat en région live avec libellé complet + annonce', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final announcements = <String>[];
      await _openSheet(
        tester,
        random: _Seq([20, 3]),
        announcements: announcements,
      );

      const label = 'Résultat : d20 20, plus 3, total 23, 20 naturel';
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(node.flagsCollection.isLiveRegion, isTrue);
      expect(announcements, [label]);

      await tester.tap(find.text('RELANCER'));
      await tester.pumpAndSettle();
      expect(announcements.length, 2, reason: 'une annonce par tirage');
      handle.dispose();
    });

    testWidgets('libellé accessible avec avantage et modificateur négatif', (
      tester,
    ) async {
      final announcements = <String>[];
      await _openSheet(
        tester,
        random: _Seq([5, 17, 4]),
        modifier: -2,
        announcements: announcements,
      );
      await tester.tap(find.text('AVANTAGE'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RELANCER'));
      await tester.pumpAndSettle();

      expect(
        announcements.last,
        'Résultat : d20 17, moins 2, total 15, '
        'Avantage, dés 17 et 4, 4 écarté',
      );
    });
  });

  group('grande police', () {
    Future<void> setLarge(WidgetTester tester, double scale) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    testWidgets('x2,0 sur 360 dp : dé à deux chiffres et détail avec avantage '
        'sans overflow, sélecteur en colonne', (tester) async {
      await setLarge(tester, 2);
      await _openSheet(tester, random: _Seq([5, 12, 18]), modifier: -12);
      await tester.tap(find.text('Avantage'));
      await tester.pumpAndSettle();
      // P2b : la boîte du dé (192 dp de haut, spec) pousse « Relancer » sous
      // le pli à x2,0 sur 640 dp ; la feuille est défilable par conception.
      await tester.ensureVisible(find.text('RELANCER'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('RELANCER'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SegmentedToggle<RollMode>), findsNothing);
      expect(find.byType(SelectableOptionTile), findsNWidgets(3));
      for (final tile in tester.widgetList(find.byType(SelectableOptionTile))) {
        final size = tester.getSize(find.byWidget(tile));
        expect(size.height, greaterThanOrEqualTo(44));
      }
      expect(find.text('18'), findsOneWidget);
      final die = tester.getSize(
        find
            .ancestor(of: find.text('18'), matching: find.byType(Container))
            .first,
      );
      expect(die.width, greaterThanOrEqualTo(88));
      expect(die.height, greaterThanOrEqualTo(88));
    });

    testWidgets(
      'x2,0 : après défilement, "Relancer" relance vraiment et l\'en-tête '
      'reste visible',
      (tester) async {
        await setLarge(tester, 2);
        final random = _Seq([20, 3]);
        await _openSheet(tester, random: random);
        expect(find.text('20 NATUREL'), findsOneWidget);

        await tester.ensureVisible(find.text('RELANCER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('RELANCER'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(random.drawn, 2);
        expect(find.text('d20 (3) +3 = 6'), findsOneWidget);
        expect(find.text('20 NATUREL'), findsNothing);
        final header = tester.getRect(find.byType(SheetHeaderBar));
        expect(header.top, greaterThanOrEqualTo(0));
        expect(header.height, greaterThan(0));
        expect(find.text('FORCE'), findsOneWidget);
      },
    );

    testWidgets(
      'x2,0 sur 320 dp : sélecteur lisible (3 tuiles complètes) et carte des '
      'sauvegardes avec ses bonus',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await _openSheet(tester, random: _Seq([14]));
        expect(tester.takeException(), isNull);
        for (final title in ['Normal', 'Avantage', 'Désavantage']) {
          expect(find.text(title), findsOneWidget);
          final rect = tester.getRect(find.text(title));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
        }
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          _app(
            home: SingleChildScrollView(
              child: CharacterSavingThrowsCard(results: _savingResults),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final text in ['For', 'Dex', 'Con', 'Int', 'Sag', 'Cha']) {
          final rect = tester.getRect(find.text(text));
          expect(rect.left, greaterThanOrEqualTo(0), reason: text);
          expect(rect.right, lessThanOrEqualTo(320), reason: text);
        }
        expect(find.text('+5'), findsOneWidget);
        expect(find.text('+2'), findsOneWidget);
        expect(find.text('−1'), findsOneWidget);
      },
    );

    testWidgets('x1,0 sur 360 dp : bascule segmentée, aucune exception', (
      tester,
    ) async {
      await setLarge(tester, 1);
      await _openSheet(tester, random: _Seq([14]));

      expect(tester.takeException(), isNull);
      expect(find.byType(SegmentedToggle<RollMode>), findsOneWidget);
    });
  });

  group('sauvegardes touchables', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      Locale locale = const Locale('fr'),
    }) async {
      await tester.pumpWidget(
        _app(
          locale: locale,
          home: SingleChildScrollView(
            child: CharacterSavingThrowsCard(results: _savingResults),
          ),
        ),
      );
    }

    testWidgets('avec maîtrise : tap ouvre la feuille avec +5', (tester) async {
      await pumpCard(tester);
      await tester.tap(find.bySemanticsLabel('Sauvegarde de Force'));
      await tester.pumpAndSettle();

      expect(find.text('SAUVEGARDE DE FORCE'), findsOneWidget);
      expect(
        _texts(tester)
            .any((t) => RegExp(r'^d20 \(\d+\) \+5 = \d+$').hasMatch(t)),
        isTrue,
      );
    });

    testWidgets('sans maîtrise : tap ouvre la feuille avec +2', (tester) async {
      await pumpCard(tester);
      await tester.tap(find.bySemanticsLabel('Sauvegarde de Dextérité'));
      await tester.pumpAndSettle();

      expect(find.text('SAUVEGARDE DE DEXTÉRITÉ'), findsOneWidget);
      expect(
        _texts(tester)
            .any((t) => RegExp(r'^d20 \(\d+\) \+2 = \d+$').hasMatch(t)),
        isTrue,
      );
    });

    testWidgets('bonus négatif (Int 8, sans maîtrise) : −1', (tester) async {
      await pumpCard(tester);
      await tester.tap(find.bySemanticsLabel("Sauvegarde d'Intelligence"));
      await tester.pumpAndSettle();

      expect(
        _texts(tester)
            .any((t) => RegExp(r'^d20 \(\d+\) −1 = -?\d+$').hasMatch(t)),
        isTrue,
      );
    });

    testWidgets('nœud sémantique : nom, bonus signé et maîtrise', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      SemanticsNode node(String label) =>
          tester.getSemantics(find.bySemanticsLabel(label));
      expect(node('Sauvegarde de Force').value, 'plus 5, maîtrisé');
      expect(node('Sauvegarde de Dextérité').value, 'plus 2, non maîtrisé');
      expect(node("Sauvegarde d'Intelligence").value, 'moins 1, non maîtrisé');
      handle.dispose();
    });

    testWidgets('nœud sémantique en anglais', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester, locale: const Locale('en'));

      SemanticsNode node(String label) =>
          tester.getSemantics(find.bySemanticsLabel(label));
      expect(node('Strength saving throw').value, 'plus 5, proficient');
      expect(node('Dexterity saving throw').value, 'plus 2, not proficient');
      handle.dispose();
    });

    testWidgets('anglais : libellé "Strength saving throw"', (tester) async {
      await pumpCard(tester, locale: const Locale('en'));
      expect(find.bySemanticsLabel('Strength saving throw'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Wisdom saving throw'));
      await tester.pumpAndSettle();
      expect(find.text('WISDOM SAVING THROW'), findsOneWidget);
    });

    testWidgets('chaque ligne fait au moins 44 dp de haut et de large', (
      tester,
    ) async {
      await pumpCard(tester);
      for (final label in [
        'Sauvegarde de Force',
        'Sauvegarde de Dextérité',
        'Sauvegarde de Constitution',
        "Sauvegarde d'Intelligence",
        'Sauvegarde de Sagesse',
        'Sauvegarde de Charisme',
      ]) {
        final size = tester.getSize(find.bySemanticsLabel(label));
        expect(size.height, greaterThanOrEqualTo(44), reason: label);
        expect(size.width, greaterThanOrEqualTo(44), reason: label);
      }
    });

    testWidgets('x2,0 sur 360 dp : aucune exception', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpCard(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
