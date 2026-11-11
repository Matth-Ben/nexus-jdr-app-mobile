// Tests de widget du dé 3D animé de la feuille de dés (P2b, prototype d20) :
// animation, saut au tap, animations coupées, sémantique, repli, skins,
// avantage/désavantage, grande police.

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
import 'package:personnages/features/characters/presentation/widgets/dice/dice_board.dart';
import 'package:personnages/features/characters/presentation/widgets/dice/die_painter.dart';
import 'package:personnages/features/characters/presentation/widgets/dice/die_plate.dart';
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

Future<void> _open(
  WidgetTester tester, {
  required Random random,
  int modifier = 3,
  bool disableAnimations = false,
  bool settle = true,
  Locale locale = const Locale('fr'),
  List<String>? announcements,
  DieSkin skin = DieSkin.defaultSkin,
  DieShaderCache? shaderCache,
  VoidCallback? paintProbe,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
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
    // Construit la feuille et fait avancer l'animation de ~100 ms.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }
}

List<DiePlate> _plates(WidgetTester tester) =>
    tester.widgetList<DiePlate>(find.byType(DiePlate)).toList();

DieSurfacePainter _painter(WidgetTester tester, {int index = 0}) {
  final paints = tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(const ValueKey('die-surface')),
          matching: find.byType(CustomPaint),
        ),
      )
      .toList();
  return paints[index].painter! as DieSurfacePainter;
}

SecondaryButton _reroll(WidgetTester tester) =>
    tester.widget<SecondaryButton>(find.byType(SecondaryButton));

int _liveRegions(WidgetTester tester) {
  var count = 0;
  void visit(SemanticsNode node) {
    if (node.flagsCollection.isLiveRegion) count++;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  // Propriétaire de la vue (celui qui porte réellement l'arbre sémantique).
  final owner = tester.renderObject(find.byType(Scaffold).first).owner!;
  visit(owner.semanticsOwner!.rootSemanticsNode!);
  return count;
}

List<String> _texts(WidgetTester tester) => [
  for (final t in tester.widgetList<Text>(find.byType(Text)))
    t.data ?? t.textSpan?.toPlainText() ?? '',
];

void main() {
  setUpAll(() async {
    await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  group('valeur affichée = résultat tiré', () {
    for (var value = 1; value <= 20; value++) {
      testWidgets('d20 = $value : pastille, formule et dé du plateau', (
        tester,
      ) async {
        await _open(tester, random: _Seq([value]));

        expect(find.text('$value'), findsOneWidget);
        expect(find.text('d20 ($value) +3 = ${value + 3}'), findsOneWidget);
        expect(_plates(tester).single.value, value);
        expect(_painter(tester).value, value);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('idem avec les animations coupées', (tester) async {
      for (final value in [1, 6, 9, 13, 20]) {
        await _open(tester, random: _Seq([value]), disableAnimations: true);
        expect(find.text('$value'), findsOneWidget, reason: '$value');
        expect(_plates(tester).single.value, value);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });

  group('animation de 1 400 ms', () {
    testWidgets('en vol : ni texte de résultat visible, ni région live, ni '
        'annonce ; "Relancer" inactif', (tester) async {
      final handle = tester.ensureSemantics();
      final announcements = <String>[];
      await _open(
        tester,
        random: _Seq([17]),
        settle: false,
        announcements: announcements,
      );

      final progress = _painter(tester).progress.value;
      expect(progress, inExclusiveRange(0, 1));
      expect(_reroll(tester).onPressed, isNull);
      expect(announcements, isEmpty);
      expect(
        find.bySemanticsLabel(RegExp('Résultat : d20 17')),
        findsNothing,
        reason: 'sémantique annoncée avant la pose',
      );
      // La formule est encore transparente.
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('d20 (17) +3 = 20'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, 0);

      await tester.pump(const Duration(milliseconds: 1500));
      handle.dispose();
    });

    testWidgets('posé : annonce une seule fois, un seul nœud liveRegion, '
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

      // Plus rien ne s'annonce ensuite.
      await tester.pump(const Duration(seconds: 2));
      expect(announcements, [label]);
      handle.dispose();
    });

    testWidgets('un tap sur le plateau pendant le lancer saute à l\'état '
        'posé', (tester) async {
      final announcements = <String>[];
      await _open(
        tester,
        random: _Seq([8]),
        settle: false,
        announcements: announcements,
      );
      expect(_painter(tester).progress.value, lessThan(1));
      expect(_reroll(tester).onPressed, isNull);

      await tester.tap(find.byType(DiePlate));
      await tester.pump();

      expect(_painter(tester).progress.value, 1);
      expect(_reroll(tester).onPressed, isNotNull);
      expect(announcements, hasLength(1));
      // La formule est entièrement visible tout de suite.
      await tester.pump(const Duration(milliseconds: 1));
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('d20 (8) +3 = 11'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, 1);
    });

    testWidgets('"Relancer" pendant le lancer ne tire rien', (tester) async {
      final random = _Seq([5, 9]);
      await _open(tester, random: random, settle: false);
      expect(random.drawn, 1);

      await tester.ensureVisible(find.byType(SecondaryButton));
      await tester.tap(find.byType(SecondaryButton), warnIfMissed: false);
      await tester.pump();
      expect(random.drawn, 1);

      await tester.pumpAndSettle();
      await tester.tap(find.byType(SecondaryButton));
      await tester.pumpAndSettle();
      expect(random.drawn, 2);
      expect(find.text('9'), findsOneWidget);
    });

    testWidgets('relancer relance l\'animation et réannonce une fois à la '
        'pose', (tester) async {
      final announcements = <String>[];
      await _open(tester, random: _Seq([5, 9]), announcements: announcements);
      expect(announcements, hasLength(1));

      await tester.tap(find.byType(SecondaryButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_painter(tester).progress.value, inExclusiveRange(0, 1));
      expect(announcements, hasLength(1), reason: 'pas avant la pose');

      await tester.pumpAndSettle();
      expect(announcements, hasLength(2));
      expect(announcements.last, 'Résultat : d20 9, plus 3, total 12');
    });
  });

  group('animations coupées (disableAnimations)', () {
    testWidgets('pose immédiate, texte et annonce tout de suite, pas '
        'd\'animation en cours', (tester) async {
      final announcements = <String>[];
      await _open(
        tester,
        random: _Seq([14]),
        settle: false,
        disableAnimations: true,
        announcements: announcements,
      );

      // ~100 ms après l'ouverture : déjà posé.
      expect(_painter(tester).progress.value, 1);
      expect(find.text('d20 (14) +3 = 17'), findsOneWidget);
      expect(_reroll(tester).onPressed, isNotNull);
      expect(announcements, ['Résultat : d20 14, plus 3, total 17']);
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.text('d20 (14) +3 = 17'),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, 1);
    });

    testWidgets('1 naturel : aucun tressautement (progression finale, '
        'décalage nul)', (tester) async {
      await _open(
        tester,
        random: _Seq([1]),
        settle: false,
        disableAnimations: true,
      );
      expect(_painter(tester).natural, DieNatural.one);
      expect(_painter(tester).progress.value, 1);
      await tester.pump(const Duration(milliseconds: 80));
      expect(_painter(tester).progress.value, 1);
    });

    testWidgets('relancer reste instantané', (tester) async {
      final announcements = <String>[];
      await _open(
        tester,
        random: _Seq([3, 11]),
        disableAnimations: true,
        announcements: announcements,
      );
      await tester.tap(find.byType(SecondaryButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('d20 (11) +3 = 14'), findsOneWidget);
      expect(_painter(tester).progress.value, 1);
      expect(announcements, hasLength(2));
    });
  });

  group('sémantique', () {
    testWidgets('le dé est décoratif : ExcludeSemantics, aucun nœud pour le '
        'chiffre ni les faces', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester, random: _Seq([12]));

      expect(
        find.descendant(
          of: find.byType(DiePlate),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      expect(
        find.ancestor(
          of: find.byType(DiePlate),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      expect(find.bySemanticsLabel('12'), findsNothing);
      expect(_liveRegions(tester), 1);
      handle.dispose();
    });
  });

  group('niveaux de rendu et repli', () {
    testWidgets('niveau 1 : shader indisponible -> couleurs de sommets, '
        'aucune exception, valeur et texte intacts', (tester) async {
      await _open(tester, random: _Seq([19]), shaderCache: _brokenShaders());
      expect(_painter(tester).level, DieRenderLevel.vertexColors);
      expect(_painter(tester).shader, isNull);
      expect(_painter(tester).failed, isFalse);
      expect(tester.takeException(), isNull);
      expect(find.text('d20 (19) +3 = 22'), findsOneWidget);
      expect(find.text('19'), findsOneWidget);
    });

    testWidgets('skin sans texture : niveau 1 sans chercher de shader', (
      tester,
    ) async {
      await _open(
        tester,
        random: _Seq([4]),
        skin: DieSkin.tavernOak.copyWith(textureId: DieTextureId.none),
      );
      expect(_painter(tester).level, DieRenderLevel.vertexColors);
    });

    testWidgets('niveau 2 : le painter lève -> dé statique, rien d\'affiché '
        'd\'erreur, tirage et texte intacts', (tester) async {
      await _open(
        tester,
        random: _Seq([16]),
        paintProbe: () => throw StateError('painter en panne'),
      );

      expect(find.byKey(const ValueKey('die-surface')), findsNothing);
      expect(find.text('16'), findsOneWidget, reason: 'ancien _DieFace');
      expect(find.text('d20 (16) +3 = 19'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(_reroll(tester).onPressed, isNotNull);
    });

    testWidgets('niveau 2 : le repli ne bloque pas le jet suivant', (
      tester,
    ) async {
      await _open(
        tester,
        random: _Seq([16, 2]),
        paintProbe: () => throw StateError('painter en panne'),
      );
      await tester.tap(find.byType(SecondaryButton));
      await tester.pumpAndSettle();
      expect(find.text('d20 (2) +3 = 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('chargement réel du shader (asset compilé par le build) : '
        'niveau « shader », aucune exception au dessin', (tester) async {
      final cache = DieShaderCache();
      await tester.runAsync(() => cache.preload(DieShaderId.texture));
      expect(cache.programFor(DieShaderId.texture), isNotNull);
      await _open(tester, random: _Seq([7]), shaderCache: cache);
      expect(_painter(tester).level, DieRenderLevel.shader);
      expect(_painter(tester).shader, isNotNull);
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
      expect(cache.programFor(DieShaderId.texture), isNull);
    });

    test('dessin direct à toutes les phases, deux skins, sans exception', () {
      for (final skin in [DieSkin.tavernOak, DieSkin.brassSeal]) {
        for (final natural in DieNatural.values) {
          final painter = DieSurfacePainter(
            progress: const AlwaysStoppedAnimation(0),
            value: 20,
            skin: skin,
            natural: natural,
          );
          for (final t in [0.0, 0.05, 0.15, 0.3, 0.5, 0.7, 0.85, 0.95, 1.0]) {
            final p = DieSurfacePainter(
              progress: AlwaysStoppedAnimation(t),
              value: 1 + (t * 19).round(),
              skin: skin,
              natural: natural,
              struck: natural == DieNatural.none,
              opacity: natural == DieNatural.none ? 0.55 : 1,
            );
            final recorder = ui.PictureRecorder();
            p.paint(Canvas(recorder), const Size(154, 154));
            recorder.endRecording().dispose();
            expect(p.failed, isFalse, reason: '$skin $natural $t');
            p.dispose();
          }
          painter.dispose();
        }
      }
    });

    test('shouldRepaint : changement de valeur, de skin ou d\'opacité', () {
      DieSurfacePainter make({
        int value = 5,
        DieSkin skin = DieSkin.tavernOak,
        double opacity = 1,
      }) => DieSurfacePainter(
        progress: const AlwaysStoppedAnimation(1),
        value: value,
        skin: skin,
        opacity: opacity,
      );
      final base = make();
      expect(base.shouldRepaint(make()), isFalse);
      expect(base.shouldRepaint(make(value: 6)), isTrue);
      expect(base.shouldRepaint(make(skin: DieSkin.brassSeal)), isTrue);
      expect(base.shouldRepaint(make(opacity: 0.55)), isTrue);
    });
  });

  group('skins', () {
    testWidgets('skin injecté : appliqué sans autre changement de code', (
      tester,
    ) async {
      await _open(tester, random: _Seq([10]), skin: DieSkin.brassSeal);
      expect(_painter(tester).skin, DieSkin.brassSeal);
      expect(_plates(tester).single.skin, DieSkin.brassSeal);
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
      final badge = tester.widget<DieNumberBadge>(find.byType(DieNumberBadge));
      expect(badge.skin.ensureReadable().isReadable, isTrue);
      expect(_painter(tester).skin.isReadable, isTrue);
      final text = tester.widget<Text>(find.text('10'));
      expect(text.style!.color, AppColors.textPrimary);
    });
  });

  group('pastille du chiffre et plateau', () {
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

    testWidgets('plateau 160×160 dans une boîte de 192 dp, cible >= 44', (
      tester,
    ) async {
      await _open(tester, random: _Seq([7]));
      expect(tester.getSize(find.byType(DiePlate)), const Size(160, 160));
      expect(
        tester.getSize(find.byType(DiceBoard)).height,
        greaterThanOrEqualTo(kDiceBoardHeight),
      );
      expect(
        tester.getSize(find.byType(DiePlate)).shortestSide,
        greaterThan(44),
      );
    });

    testWidgets('pas de saut de layout entre jet normal et avantage', (
      tester,
    ) async {
      await _open(tester, random: _Seq([7, 3, 15]));
      final normal = tester.getSize(find.byType(DiceBoard)).height;
      await tester.tap(find.text('AVANTAGE'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SecondaryButton));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(DiceBoard)).height, normal);
    });

    testWidgets('bordure : or (20 naturel), brique (1 naturel), bois clair '
        'sinon — après la pose', (tester) async {
      Color border(WidgetTester t) {
        final box =
            t
                    .widget<Container>(
                      find
                          .descendant(
                            of: find.byType(DiePlate),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration!
                as BoxDecoration;
        return (box.border! as Border).top.color;
      }

      await _open(tester, random: _Seq([20]));
      expect(border(tester), AppColors.goldEnd);
      await tester.pumpWidget(const SizedBox.shrink());
      await _open(tester, random: _Seq([1]));
      expect(border(tester), AppColors.accentBrick);
      await tester.pumpWidget(const SizedBox.shrink());
      await _open(tester, random: _Seq([12]));
      expect(border(tester), AppColors.woodLight);
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
      bool disableAnimations = false,
    }) async {
      await _open(
        tester,
        random: _Seq([5, ...draws]),
        modifier: modifier,
        disableAnimations: disableAnimations,
      );
      await tester.tap(find.text(mode));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SecondaryButton));
      await tester.pumpAndSettle();
    }

    testWidgets('deux plateaux 120×120 côte à côte (gap 8), étiquettes '
        '« Retenu » et « Écarté »', (tester) async {
      await roll(tester, [4, 17]);

      final plates = _plates(tester);
      expect(plates, hasLength(2));
      final a = tester.getRect(find.byType(DiePlate).at(0));
      final b = tester.getRect(find.byType(DiePlate).at(1));
      expect(a.size, const Size(120, 120));
      expect(b.size, const Size(120, 120));
      expect(b.left - a.right, 8);
      expect(a.top, b.top);
      expect(find.text('Retenu'), findsOneWidget);
      expect(find.text('Écarté'), findsOneWidget);
      // Étiquette sous le bon dé : 4 écarté (gauche), 17 retenu (droite).
      expect(
        tester.getCenter(find.text('Écarté')).dx,
        lessThan(tester.getCenter(find.text('Retenu')).dx),
      );
      expect(plates[0].dimmed, isTrue);
      expect(plates[1].dimmed, isFalse);
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

    testWidgets('le second plateau démarre 120 ms après le premier', (
      tester,
    ) async {
      await _open(tester, random: _Seq([5, 4, 17]));
      await tester.tap(find.text('AVANTAGE'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SecondaryButton));
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
      final plates = _plates(tester);
      expect(plates[0].dimmed, isTrue);
      expect(plates[1].dimmed, isFalse);
      expect(plates[1].value, 4);
    });

    testWidgets('20 naturel jugé sur le dé retenu seulement (20 écarté : '
        'pas de 20 naturel)', (tester) async {
      // Désavantage : 20 et 3 -> retenu = 3, le 20 est écarté.
      await roll(tester, [20, 3], mode: 'DÉSAVANTAGE');
      expect(find.text('20 NATUREL'), findsNothing);
      expect(find.byKey(const ValueKey('natural-icon-star')), findsNothing);
      for (final plate in _plates(tester)) {
        expect(plate.natural, DieNatural.none);
      }
      expect(_painter(tester, index: 0).natural, DieNatural.none);
    });

    testWidgets('1 naturel jugé sur le dé retenu seulement (1 écarté : pas '
        'de 1 naturel)', (tester) async {
      await roll(tester, [1, 14]);
      expect(find.text('1 NATUREL'), findsNothing);
      expect(find.byKey(const ValueKey('natural-icon-skull')), findsNothing);
      for (final plate in _plates(tester)) {
        expect(plate.natural, DieNatural.none);
      }
    });

    testWidgets('20 naturel sur le dé retenu : halo sur ce plateau seul', (
      tester,
    ) async {
      await roll(tester, [20, 9]);
      expect(find.text('20 NATUREL'), findsOneWidget);
      final plates = _plates(tester);
      expect(plates[0].natural, DieNatural.twenty);
      expect(plates[0].dimmed, isFalse);
      expect(plates[1].natural, DieNatural.none);
    });

    testWidgets('égalité : le second dé est l\'écarté', (tester) async {
      await roll(tester, [11, 11]);
      final plates = _plates(tester);
      expect(plates[0].dimmed, isFalse);
      expect(plates[1].dimmed, isTrue);
    });

    testWidgets('anglais : Kept / Discarded', (tester) async {
      await _open(tester, random: _Seq([5, 4, 17]), locale: const Locale('en'));
      await tester.tap(find.text('ADVANTAGE'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SecondaryButton));
      await tester.pumpAndSettle();
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
      await tester.tap(find.byType(SecondaryButton));
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
    testWidgets('x2,0 sur 320 dp, vraies polices : feuille défilable, '
        'contenu complet, aucune exception', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _open(tester, random: _Seq([5, 12, 18]), modifier: -12);
      expect(tester.takeException(), isNull);

      // Mode avantage, deux chiffres : tout le contenu est atteignable.
      await tester.tap(find.text('Avantage'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(SecondaryButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SecondaryButton));
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
      // Les plateaux restent côte à côte dans la largeur de 320 dp.
      final left = tester.getRect(find.byType(DiePlate).at(0));
      final right = tester.getRect(find.byType(DiePlate).at(1));
      expect(left.left, greaterThanOrEqualTo(0));
      expect(right.right, lessThanOrEqualTo(320));
      // La pastille ne grandit pas au-delà de x1,3 (28 * 1,3 = 36,4 dp).
      final badge = tester.getSize(find.byType(DieNumberBadge).last);
      expect(badge.width, lessThan(120));
      // Et la feuille n'a rien perdu : « Relancer » est atteignable.
      await tester.ensureVisible(find.byType(SecondaryButton));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(SecondaryButton)).bottom,
        lessThanOrEqualTo(640),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('x2,0 sur 320 dp, jet normal : plateau intact (160) et '
        'formule non plafonnée', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _open(tester, random: _Seq([20]));
      expect(tester.getSize(find.byType(DiePlate)), const Size(160, 160));
      // La formule suit la police système (x2,0) : plus haute qu'à x1,0.
      final formula = tester.getSize(find.text('d20 (20) +3 = 23'));
      expect(formula.height, greaterThan(30));
      // La pastille est plafonnée à x1,3 : 28 * 1,3 environ.
      final digit = tester.widget<Text>(find.text('20'));
      expect(digit.textScaler, isNot(TextScaler.noScaling));
      expect(tester.takeException(), isNull);
    });
  });
}
