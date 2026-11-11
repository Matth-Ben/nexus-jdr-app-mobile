// Tests de widget du dé lancé sur la page entière (P2b, addendum du
// 11/11/2026) : couche plein écran, vol, saut au tap, pose immédiate,
// sémantique, repli, skins, avantage/désavantage, grande police.

import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/pixel_icon.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/characters/presentation/widgets/dice/die_flight_layer.dart';
import 'package:personnages/features/characters/presentation/widgets/dice/die_motion.dart';
import 'package:personnages/features/characters/presentation/widgets/dice/die_number_badge.dart';
import 'package:personnages/features/characters/presentation/widgets/dice/die_painter.dart';
import 'package:personnages/features/characters/presentation/widgets/dice/die_shader_cache.dart';
import 'package:personnages/features/characters/presentation/widgets/dice/die_skin.dart';
import 'package:personnages/features/characters/presentation/widgets/dice_roll_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

/// Random figé : `nextInt(20)` renvoie `valeur - 1`. Lève une `RangeError` si
/// un tirage de trop est effectué.
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

/// Shader indisponible : force le rendu de niveau 1.
DieShaderCache _brokenShaders() =>
    DieShaderCache(loader: (_) async => throw StateError('shader absent'));

const _die = ValueKey('die-surface');

Future<void> _open(
  WidgetTester tester, {
  required Random random,
  int modifier = 3,
  bool disableAnimations = false,
  bool accessibleNavigation = false,
  bool settle = true,
  Locale locale = const Locale('fr'),
  List<String>? announcements,
  DieSkin skin = DieSkin.defaultSkin,
  DieShaderCache? shaderCache,
  VoidCallback? paintProbe,
  Random? flightRandom,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (textScale != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          accessibleNavigation: accessibleNavigation,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDiceRollSheet(
              context,
              label: 'Force',
              modifier: modifier,
              random: random,
              announcer: (_, text) => announcements?.add(text),
              skin: skin,
              shaderCache: shaderCache ?? _brokenShaders(),
              paintProbe: paintProbe,
              flightRandom: flightRandom ?? Random(7),
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Construit la feuille, insère la couche et avance le vol de ~100 ms.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

int _diceCount(WidgetTester tester) => find.byKey(_die).evaluate().length;

DieSurfacePainter _painter(WidgetTester tester, {int index = 0}) {
  final paints = tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(_die),
          matching: find.byType(CustomPaint),
        ),
      )
      .toList();
  return paints[index].painter! as DieSurfacePainter;
}

SecondaryButton _reroll(WidgetTester tester) =>
    tester.widget<SecondaryButton>(find.byType(SecondaryButton));

Future<void> _tapReroll(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(SecondaryButton));
  await tester.tap(find.byType(SecondaryButton));
}

int _liveRegions(WidgetTester tester) {
  var count = 0;
  void visit(SemanticsNode node) {
    if (node.flagsCollection.isLiveRegion) count++;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  final owner = tester.renderObject(find.byType(Scaffold).first).owner!;
  visit(owner.semanticsOwner!.rootSemanticsNode!);
  return count;
}

List<String> _texts(WidgetTester tester) => [
  for (final t in tester.widgetList<Text>(find.byType(Text)))
    t.data ?? t.textSpan?.toPlainText() ?? '',
];

FadeTransition _formulaFade(WidgetTester tester, String formula) =>
    tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text(formula),
            matching: find.byType(FadeTransition),
          )
          .first,
    );

void _closeSheet(WidgetTester tester) {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
}

void main() {
  setUpAll(() async {
    await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  group('valeur affichée = résultat tiré', () {
    for (var value = 1; value <= 20; value++) {
      testWidgets('d20 = $value : pastille, formule et dé de la couche', (
        tester,
      ) async {
        await _open(tester, random: _Seq([value]));

        expect(find.text('$value'), findsOneWidget);
        expect(find.text('d20 ($value) +3 = ${value + 3}'), findsOneWidget);
        expect(_diceCount(tester), 1);
        expect(_painter(tester).value, value);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('idem avec les animations coupées', (tester) async {
      for (final value in [1, 6, 9, 13, 20]) {
        await _open(tester, random: _Seq([value]), disableAnimations: true);
        expect(find.text('$value'), findsOneWidget, reason: '$value');
        expect(_painter(tester).value, value);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('la trajectoire (Random distinct) ne change jamais le '
        'résultat', (tester) async {
      for (final seed in [1, 2, 3]) {
        await _open(tester, random: _Seq([14]), flightRandom: Random(seed));
        expect(_painter(tester).value, 14);
        expect(find.text('d20 (14) +3 = 17'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });

  group('couche plein écran et vol', () {
    testWidgets('le dé vit dans l\'Overlay racine, hors de la feuille, sur '
        'toute la page', (tester) async {
      await _open(tester, random: _Seq([9]), settle: false);
      expect(find.byType(DiceFlightLayer), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(DiceFlightLayer),
        ),
        findsNothing,
      );
      expect(
        tester.getSize(find.byType(DiceFlightLayer)),
        const Size(390, 844),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('en vol : pas d\'annonce, pas de sémantique de résultat, '
        'formule invisible, "Relancer" inactif', (tester) async {
      final handle = tester.ensureSemantics();
      final announcements = <String>[];
      await _open(
        tester,
        random: _Seq([17]),
        settle: false,
        announcements: announcements,
      );

      expect(_painter(tester).progress.value, inExclusiveRange(0, 1));
      expect(_reroll(tester).onPressed, isNull);
      expect(announcements, isEmpty);
      expect(find.bySemanticsLabel(RegExp('Résultat')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('17')), findsNothing);
      expect(_formulaFade(tester, 'd20 (17) +3 = 20').opacity.value, 0);
      // La couche entière est décorative.
      expect(
        find.descendant(
          of: find.byType(DiceFlightLayer),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );

      await tester.pump(const Duration(milliseconds: 1500));
      handle.dispose();
    });

    testWidgets('posé : une seule annonce, un seul nœud liveRegion, '
        '"Relancer" actif', (tester) async {
      final handle = tester.ensureSemantics();
      final announcements = <String>[];
      await _open(
        tester,
        random: _Seq([17]),
        settle: false,
        announcements: announcements,
      );
      await tester.pumpAndSettle();

      const label = 'Résultat : d20 17, plus 3, total 20';
      expect(announcements, [label]);
      expect(find.bySemanticsLabel(label), findsOneWidget);
      expect(_liveRegions(tester), 1);
      expect(_reroll(tester).onPressed, isNotNull);
      expect(_painter(tester).progress.value, 1);

      await tester.pump(const Duration(seconds: 2));
      expect(announcements, [label]);
      handle.dispose();
    });

    testWidgets('un tap pendant le vol : état posé, feuille toujours '
        'ouverte', (tester) async {
      final announcements = <String>[];
      await _open(
        tester,
        random: _Seq([8]),
        settle: false,
        announcements: announcements,
      );
      expect(_painter(tester).progress.value, lessThan(1));

      // Tout l'écran saute, y compris hors de la feuille (barrière).
      await tester.tapAt(const Offset(195, 40));
      await tester.pump();

      expect(_painter(tester).progress.value, 1);
      expect(find.text('FORCE'), findsOneWidget, reason: 'feuille ouverte');
      expect(find.byType(DiceFlightLayer), findsOneWidget);
      expect(_reroll(tester).onPressed, isNotNull);
      expect(announcements, hasLength(1));
      expect(_formulaFade(tester, 'd20 (8) +3 = 11').opacity.value, 1);
    });

    testWidgets('un tap sur la feuille pendant le vol est absorbé (saut, pas '
        'de changement de mode)', (tester) async {
      await _open(tester, random: _Seq([8]), settle: false);
      await tester.tap(find.text('AVANTAGE'), warnIfMissed: false);
      await tester.pump();
      expect(find.text('FORCE'), findsOneWidget);
      expect(_painter(tester).progress.value, 1);
      expect(find.text('Jet en mode Normal'), findsOneWidget);
    });

    testWidgets('après la pose, la couche ne bloque plus rien (IgnorePointer, '
        'la croix de la feuille ferme)', (tester) async {
      await _open(tester, random: _Seq([8]));
      final ignore = tester.widget<IgnorePointer>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('dice-flight-tap')),
              matching: find.byType(IgnorePointer),
            )
            .first,
      );
      expect(ignore.ignoring, isTrue);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('FORCE'), findsNothing);
    });

    testWidgets('le dé reste visible jusqu\'à la fermeture de la feuille', (
      tester,
    ) async {
      await _open(tester, random: _Seq([8]));
      expect(_diceCount(tester), 1);
      await tester.pump(const Duration(seconds: 3));
      expect(_diceCount(tester), 1);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(_diceCount(tester), 0);
      expect(find.byType(DiceFlightLayer), findsNothing);
    });

    testWidgets('fermeture pendant le vol : entrée retirée, controller '
        'disposé, aucune exception', (tester) async {
      await _open(tester, random: _Seq([8]), settle: false);
      final progress = _painter(tester).progress;
      expect(find.byType(DiceFlightLayer), findsOneWidget);

      _closeSheet(tester);
      await tester.pumpAndSettle();

      expect(find.byType(DiceFlightLayer), findsNothing);
      expect(_diceCount(tester), 0);
      expect(tester.takeException(), isNull);
      // Le contrôleur est disposé : le relancer lève en debug.
      final controller =
          (progress as PlateProgress).parent as AnimationController;
      expect(controller.forward, throwsAssertionError);
    });

    testWidgets('"Relancer" pendant le vol ne tire rien', (tester) async {
      final random = _Seq([5, 9]);
      await _open(tester, random: random, settle: false);
      expect(random.drawn, 1);
      await tester.tap(find.byType(SecondaryButton), warnIfMissed: false);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(random.drawn, 1);
    });

    testWidgets('"Relancer" relance en plein écran : nouveau vol, nouvelle '
        'annonce unique à la pose', (tester) async {
      final announcements = <String>[];
      await _open(tester, random: _Seq([5, 9]), announcements: announcements);
      expect(announcements, hasLength(1));

      await _tapReroll(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_diceCount(tester), 1);
      expect(_painter(tester).value, 9);
      expect(_painter(tester).progress.value, inExclusiveRange(0, 1));
      expect(announcements, hasLength(1), reason: 'pas avant la pose');

      await tester.pumpAndSettle();
      expect(announcements, hasLength(2));
      expect(announcements.last, 'Résultat : d20 9, plus 3, total 12');
      expect(find.text('FORCE'), findsOneWidget);
    });
  });

  group('animations coupées ou navigation accessible', () {
    for (final accessible in [false, true]) {
      final name = accessible ? 'accessibleNavigation' : 'disableAnimations';
      testWidgets('$name : pose immédiate, texte et annonce tout de suite', (
        tester,
      ) async {
        final announcements = <String>[];
        await _open(
          tester,
          random: _Seq([14]),
          settle: false,
          disableAnimations: !accessible,
          accessibleNavigation: accessible,
          announcements: announcements,
        );

        expect(_painter(tester).progress.value, 1);
        expect(find.text('d20 (14) +3 = 17'), findsOneWidget);
        expect(_reroll(tester).onPressed, isNotNull);
        expect(announcements, ['Résultat : d20 14, plus 3, total 17']);
        expect(_formulaFade(tester, 'd20 (14) +3 = 17').opacity.value, 1);
      });

      testWidgets('$name : relancer reste instantané', (tester) async {
        final announcements = <String>[];
        await _open(
          tester,
          random: _Seq([3, 11]),
          disableAnimations: !accessible,
          accessibleNavigation: accessible,
          announcements: announcements,
        );
        await _tapReroll(tester);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.text('d20 (11) +3 = 14'), findsOneWidget);
        expect(_painter(tester).progress.value, 1);
        expect(announcements, hasLength(2));
      });
    }

    testWidgets('1 naturel : aucun tressautement (progression finale)', (
      tester,
    ) async {
      await _open(
        tester,
        random: _Seq([1]),
        settle: false,
        disableAnimations: true,
      );
      expect(_painter(tester).natural, DieNatural.one);
      await tester.pump(const Duration(milliseconds: 80));
      expect(_painter(tester).progress.value, 1);
    });
  });

  group('sémantique', () {
    testWidgets('le dé est décoratif : aucun nœud pour le chiffre', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _open(tester, random: _Seq([12]));
      expect(find.bySemanticsLabel('12'), findsNothing);
      expect(_liveRegions(tester), 1);
      handle.dispose();
    });
  });

  group('niveaux de rendu et repli', () {
    testWidgets('niveau 1 : shader indisponible -> couleurs de sommets, '
        'aucune exception, valeur et texte intacts', (tester) async {
      await _open(tester, random: _Seq([19]));
      expect(_painter(tester).level, DieRenderLevel.vertexColors);
      expect(_painter(tester).shader, isNull);
      expect(_painter(tester).failed, isFalse);
      expect(tester.takeException(), isNull);
      expect(find.text('d20 (19) +3 = 22'), findsOneWidget);
      expect(find.text('19'), findsOneWidget);
    });

    testWidgets('skin sans texture : niveau 1', (tester) async {
      await _open(
        tester,
        random: _Seq([4]),
        skin: DieSkin.tavernOak.copyWith(textureId: DieTextureId.none),
      );
      expect(_painter(tester).level, DieRenderLevel.vertexColors);
    });

    testWidgets('repli statique : le painter lève -> couche retirée, ancien '
        'dé dans la feuille, rien d\'erreur affiché, tirage et texte '
        'intacts', (tester) async {
      await _open(
        tester,
        random: _Seq([16]),
        paintProbe: () => throw StateError('painter en panne'),
      );

      expect(find.byType(DiceFlightLayer), findsNothing);
      expect(_diceCount(tester), 0);
      expect(find.text('16'), findsOneWidget, reason: 'ancien _DieFace');
      expect(find.text('d20 (16) +3 = 19'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(_reroll(tester).onPressed, isNotNull);
    });

    testWidgets('repli statique : les jets suivants restent possibles', (
      tester,
    ) async {
      final announcements = <String>[];
      await _open(
        tester,
        random: _Seq([16, 2]),
        paintProbe: () => throw StateError('painter en panne'),
        announcements: announcements,
      );
      await _tapReroll(tester);
      await tester.pumpAndSettle();
      expect(find.text('d20 (2) +3 = 5'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(announcements, hasLength(2));
    });

    testWidgets('chargement réel du shader : niveau « shader », aucune '
        'exception au dessin', (tester) async {
      final cache = DieShaderCache();
      await tester.runAsync(() => cache.preload(DieShaderId.texture));
      expect(cache.programFor(DieShaderId.texture), isNotNull);
      await _open(tester, random: _Seq([7]), shaderCache: cache);
      expect(_painter(tester).level, DieRenderLevel.shader);
      expect(_painter(tester).failed, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('le cache ne recharge jamais un shader en échec', (
      tester,
    ) async {
      var calls = 0;
      final cache = DieShaderCache(
        loader: (_) async {
          calls++;
          throw StateError('KO');
        },
      );
      await cache.preload(DieShaderId.texture);
      await cache.preload(DieShaderId.texture);
      expect(calls, 1);
      expect(cache.hasFailed(DieShaderId.texture), isTrue);
    });

    test('dessin direct (mode couche) à toutes les phases, deux skins, sans '
        'exception', () {
      for (final skin in [DieSkin.tavernOak, DieSkin.brassSeal]) {
        for (final natural in DieNatural.values) {
          for (final t in [0.0, 0.05, 0.15, 0.3, 0.5, 0.7, 0.85, 0.95, 1.0]) {
            final p = DieSurfacePainter(
              progress: AlwaysStoppedAnimation(t),
              value: 1 + (t * 19).round(),
              skin: skin,
              natural: natural,
              struck: natural == DieNatural.none,
              opacity: natural == DieNatural.none ? 0.55 : 1,
              free: true,
            );
            final recorder = ui.PictureRecorder();
            p.paint(Canvas(recorder), const Size(220, 220));
            recorder.endRecording().dispose();
            expect(p.failed, isFalse, reason: '$skin $natural $t');
            p.dispose();
          }
        }
      }
    });

    test('shouldRepaint : valeur, skin, opacité, mode', () {
      DieSurfacePainter make({
        int value = 5,
        DieSkin skin = DieSkin.tavernOak,
        double opacity = 1,
        bool free = true,
      }) => DieSurfacePainter(
        progress: const AlwaysStoppedAnimation(1),
        value: value,
        skin: skin,
        opacity: opacity,
        free: free,
      );
      final base = make();
      expect(base.shouldRepaint(make()), isFalse);
      expect(base.shouldRepaint(make(value: 6)), isTrue);
      expect(base.shouldRepaint(make(skin: DieSkin.brassSeal)), isTrue);
      expect(base.shouldRepaint(make(opacity: 0.55)), isTrue);
      expect(base.shouldRepaint(make(free: false)), isTrue);
    });
  });

  group('skins', () {
    testWidgets('skin injecté : appliqué sans autre changement de code', (
      tester,
    ) async {
      await _open(tester, random: _Seq([10]), skin: DieSkin.brassSeal);
      expect(_painter(tester).skin, DieSkin.brassSeal);
    });

    testWidgets('skin par défaut : Chêne de taverne', (tester) async {
      await _open(tester, random: _Seq([10]));
      expect(_painter(tester).skin, DieSkin.tavernOak);
    });

    testWidgets('skin illisible : repli automatique chiffre/pastille', (
      tester,
    ) async {
      final bad = DieSkin.tavernOak.copyWith(
        numberColor: AppColors.woodMedium,
        numberBackdropColor: AppColors.woodDark,
      );
      await _open(tester, random: _Seq([10]), skin: bad);
      expect(_painter(tester).skin.isReadable, isTrue);
      final text = tester.widget<Text>(find.text('10'));
      expect(text.style!.color, AppColors.textPrimary);
    });
  });

  group('pastille du chiffre et dé posé', () {
    testWidgets('font.body 800, 28 dp (1 chiffre) / 24 dp (2 chiffres), fond '
        '>= 70 %', (tester) async {
      await _open(tester, random: _Seq([7]));
      var text = tester.widget<Text>(find.text('7'));
      expect(text.style!.fontFamily, 'WorkSans');
      expect(text.style!.fontWeight, FontWeight.w800);
      expect(text.style!.fontSize, 28);

      await tester.pumpWidget(const SizedBox.shrink());
      await _open(tester, random: _Seq([13]));
      text = tester.widget<Text>(find.text('13'));
      expect(text.style!.fontSize, 24);
      final deco =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.text('13'),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(deco.color!.a, greaterThanOrEqualTo(0.7));
    });

    testWidgets('6, 9, 16 et 19 soulignés (2 dp), les autres non', (
      tester,
    ) async {
      for (final value in [6, 9, 16, 19, 8, 20]) {
        await _open(tester, random: _Seq([value]), disableAnimations: true);
        final style = tester.widget<Text>(find.text('$value')).style!;
        final expected = {6, 9, 16, 19}.contains(value);
        expect(
          style.decoration == TextDecoration.underline,
          expected,
          reason: '$value',
        );
        if (expected) expect(style.decorationThickness, 2);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('dé seul : boîte de dessin 220 dp (176 × 1,25), posé au-dessus '
        'de la feuille, centré', (tester) async {
      await _open(tester, random: _Seq([7]));
      final rect = tester.getRect(find.byKey(_die));
      expect(rect.size, const Size(220, 220));
      expect(rect.center.dx, closeTo(195, 1));
      final sheetTop = tester.getTopLeft(find.byType(BottomSheet)).dy;
      expect(rect.center.dy, lessThan(sheetTop));
      expect(rect.top, greaterThanOrEqualTo(0));
    });

    testWidgets('tablette (>= 600 dp) : dé de 220 dp nominaux', (tester) async {
      await _open(tester, random: _Seq([7]), size: const Size(800, 1000));
      expect(tester.getSize(find.byKey(_die)), const Size(275, 275));
    });

    testWidgets('formule en font.body 20 sp w800', (tester) async {
      await _open(tester, random: _Seq([20]));
      final style = tester.widget<Text>(find.text('d20 (20) +3 = 23')).style!;
      expect(style.fontSize, 20);
      expect(style.fontWeight, FontWeight.w800);
      expect(style.fontFamily, 'WorkSans');
    });

    testWidgets('feuille plafonnée à 62 % de la hauteur', (tester) async {
      await _open(tester, random: _Seq([5, 4, 17]));
      await tester.tap(find.text('AVANTAGE'));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(BottomSheet)).height,
        lessThanOrEqualTo(844 * 0.62 + 0.5),
      );
    });

    testWidgets('le slot de 192 dp n\'existe plus dans la feuille', (
      tester,
    ) async {
      await _open(tester, random: _Seq([7]));
      expect(tester.getSize(find.byType(BottomSheet)).height, lessThan(480));
    });

    testWidgets('20 naturel : halo or, icône pixel étoile, mention texte', (
      tester,
    ) async {
      await _open(tester, random: _Seq([20]));
      expect(_painter(tester).natural, DieNatural.twenty);
      expect(find.byKey(const ValueKey('natural-icon-star')), findsOneWidget);
      expect(find.text('20 NATUREL'), findsOneWidget);
      expect(tester.widget<PixelIcon>(find.byType(PixelIcon)).size, 16);
    });

    testWidgets('1 naturel : halo brique, icône pixel crâne, mention texte', (
      tester,
    ) async {
      await _open(tester, random: _Seq([1]));
      expect(_painter(tester).natural, DieNatural.one);
      expect(find.byKey(const ValueKey('natural-icon-skull')), findsOneWidget);
      expect(find.text('1 NATUREL'), findsOneWidget);
    });
  });

  group('avantage / désavantage', () {
    Future<void> roll(
      WidgetTester tester,
      List<int> draws, {
      String mode = 'AVANTAGE',
      int modifier = 3,
      Locale locale = const Locale('fr'),
      List<String>? announcements,
    }) async {
      await _open(
        tester,
        random: _Seq([5, ...draws]),
        modifier: modifier,
        locale: locale,
        announcements: announcements,
      );
      await tester.tap(find.text(mode));
      await tester.pumpAndSettle();
      await _tapReroll(tester);
      await tester.pumpAndSettle();
    }

    testWidgets('deux dés de 136 dp côte à côte (écart 16), étiquettes '
        '« Retenu » et « Écarté »', (tester) async {
      await roll(tester, [4, 17]);

      expect(_diceCount(tester), 2);
      final a = tester.getRect(find.byKey(_die).at(0));
      final b = tester.getRect(find.byKey(_die).at(1));
      expect(a.size, const Size(170, 170));
      expect(b.size, const Size(170, 170));
      expect(b.center.dx - a.center.dx, closeTo(136 + 16, 1));
      expect(a.center.dy, closeTo(b.center.dy, 1));
      expect(find.text('Retenu'), findsOneWidget);
      expect(find.text('Écarté'), findsOneWidget);
      expect(
        tester.getCenter(find.text('Écarté')).dx,
        lessThan(tester.getCenter(find.text('Retenu')).dx),
      );
      expect(
        find.text('Avantage : 4 (écarté) et 17 → 17 + 3 = 20'),
        findsOneWidget,
      );
    });

    testWidgets('le dé écarté est à 55 % et barré, pas le retenu', (
      tester,
    ) async {
      await roll(tester, [4, 17]);
      expect(_painter(tester, index: 0).opacity, 0.55);
      expect(_painter(tester, index: 0).struck, isTrue);
      expect(_painter(tester, index: 1).opacity, 1);
      expect(_painter(tester, index: 1).struck, isFalse);
    });

    testWidgets('le second dé démarre 120 ms après le premier', (tester) async {
      await _open(tester, random: _Seq([5, 4, 17]));
      await tester.tap(find.text('AVANTAGE'));
      await tester.pumpAndSettle();
      await _tapReroll(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(_painter(tester, index: 0).progress.value, greaterThan(0));
      expect(_painter(tester, index: 1).progress.value, 0);
      await tester.pump(const Duration(milliseconds: 120));
      expect(_painter(tester, index: 1).progress.value, greaterThan(0));
      await tester.pumpAndSettle();
    });

    testWidgets('désavantage : le plus bas est retenu', (tester) async {
      await roll(tester, [17, 4], mode: 'DÉSAVANTAGE');
      expect(_painter(tester, index: 0).struck, isTrue);
      expect(_painter(tester, index: 1).struck, isFalse);
      expect(_painter(tester, index: 1).value, 4);
    });

    testWidgets('20 naturel jugé sur le dé retenu seulement (20 écarté : pas '
        'de 20 naturel)', (tester) async {
      await roll(tester, [20, 3], mode: 'DÉSAVANTAGE');
      expect(find.text('20 NATUREL'), findsNothing);
      expect(find.byKey(const ValueKey('natural-icon-star')), findsNothing);
      expect(_painter(tester, index: 0).natural, DieNatural.none);
      expect(_painter(tester, index: 1).natural, DieNatural.none);
    });

    testWidgets('1 naturel jugé sur le dé retenu seulement (1 écarté : pas '
        'de 1 naturel)', (tester) async {
      await roll(tester, [1, 14]);
      expect(find.text('1 NATUREL'), findsNothing);
      expect(find.byKey(const ValueKey('natural-icon-skull')), findsNothing);
      expect(_painter(tester, index: 0).natural, DieNatural.none);
      expect(_painter(tester, index: 1).natural, DieNatural.none);
    });

    testWidgets('20 naturel sur le dé retenu : halo sur ce dé seul', (
      tester,
    ) async {
      await roll(tester, [20, 9]);
      expect(find.text('20 NATUREL'), findsOneWidget);
      expect(_painter(tester, index: 0).natural, DieNatural.twenty);
      expect(_painter(tester, index: 0).struck, isFalse);
      expect(_painter(tester, index: 1).natural, DieNatural.none);
    });

    testWidgets('égalité : le second dé est l\'écarté', (tester) async {
      await roll(tester, [11, 11]);
      expect(_painter(tester, index: 0).struck, isFalse);
      expect(_painter(tester, index: 1).struck, isTrue);
    });

    testWidgets('relancer fait varier le nombre de dés : 1 -> 2 -> 1', (
      tester,
    ) async {
      await _open(tester, random: _Seq([5, 4, 17, 9]));
      expect(_diceCount(tester), 1);
      await tester.tap(find.text('AVANTAGE'));
      await tester.pumpAndSettle();
      await _tapReroll(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(_diceCount(tester), 2);
      await tester.pumpAndSettle();
      await tester.tap(find.text('NORMAL'));
      await tester.pumpAndSettle();
      await _tapReroll(tester);
      await tester.pumpAndSettle();
      expect(_diceCount(tester), 1);
      expect(find.text('Retenu'), findsNothing);
    });

    testWidgets('anglais : Kept / Discarded', (tester) async {
      await roll(
        tester,
        [4, 17],
        mode: 'ADVANTAGE',
        locale: const Locale('en'),
      );
      expect(find.text('Kept'), findsOneWidget);
      expect(find.text('Discarded'), findsOneWidget);
    });

    testWidgets('annonce unique, à la pose, avec le dé écarté', (tester) async {
      final announcements = <String>[];
      await _open(
        tester,
        random: _Seq([5, 4, 17]),
        announcements: announcements,
      );
      await tester.tap(find.text('AVANTAGE'));
      await tester.pumpAndSettle();
      await _tapReroll(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(announcements, hasLength(1));
      await tester.pumpAndSettle();
      expect(announcements, hasLength(2));
      expect(
        announcements.last,
        'Résultat : d20 17, plus 3, total 20, '
        'Avantage, dés 4 et 17, 4 écarté',
      );
    });
  });

  group('grande police', () {
    testWidgets('x2,0 sur 320 dp, vraies polices : feuille défilable, contenu '
        'complet, aucune exception', (tester) async {
      await _open(
        tester,
        random: _Seq([5, 12, 18]),
        modifier: -12,
        size: const Size(320, 640),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Avantage'));
      await tester.pumpAndSettle();
      await _tapReroll(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(find.text('Retenu'), findsOneWidget);
      expect(find.text('Écarté'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(
        _texts(tester).any((t) => t.contains('12') && t.contains('écarté')),
        isTrue,
      );
      // Les deux dés tiennent dans la largeur de 320 dp.
      final left = tester.getRect(find.byKey(_die).at(0));
      final right = tester.getRect(find.byKey(_die).at(1));
      expect(left.center.dx, greaterThan(0));
      expect(right.center.dx, lessThan(320));
      // Feuille <= 62 % de 640 et « Relancer » atteignable.
      expect(
        tester.getSize(find.byType(BottomSheet)).height,
        lessThanOrEqualTo(640 * 0.62 + 0.5),
      );
      await tester.ensureVisible(find.byType(SecondaryButton));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(SecondaryButton)).bottom,
        lessThanOrEqualTo(640),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('x2,0 sur 320 dp, jet normal : formule non plafonnée, '
        'pastille plafonnée à x1,3', (tester) async {
      await _open(
        tester,
        random: _Seq([20]),
        size: const Size(320, 640),
        textScale: 2,
      );
      final formula = tester.getSize(find.text('d20 (20) +3 = 23'));
      expect(formula.height, greaterThan(40));
      final digit = tester.widget<Text>(find.text('20'));
      expect(digit.textScaler, isNot(TextScaler.noScaling));
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(BottomSheet)).height,
        lessThanOrEqualTo(640 * 0.62 + 0.5),
      );
    });
  });

  test('DieNumberBadge : 6/9/16/19 soulignés', () {
    expect(DieNumberBadge.underlined, {6, 9, 16, 19});
  });
}
