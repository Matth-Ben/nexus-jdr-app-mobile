import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/l10n/app_localizations.dart';

/// Monte [child] dans une appli dont la taille de police système vaut
/// [scale] (comme le réglage d'accessibilité de l'OS).
Future<void> pumpScaled(
  WidgetTester tester,
  Widget child, {
  required double scale,
  Size surface = const Size(400, 800),
}) async {
  // `tester.view` (et non `binding.setSurfaceSize`, qui n'est pas pris en compte
  // par le premier `MediaQuery`) : la taille est appliquée avant le montage.
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );
}

/// Taille de police effective (en px logiques) du texte [text] pour une taille
/// déclarée de [fontSize] : ce que le moteur de rendu applique réellement.
double effectiveFontSize(WidgetTester tester, String text, double fontSize) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );
  return paragraph.textScaler.scale(fontSize);
}

/// Familles de polices pixel (`AppTypography.display`).
const _displayFamily = 'PressStart2P';

/// Tous les paragraphes rendus en police pixel (`AppTypography.display`).
List<RenderParagraph> displayParagraphs(WidgetTester tester) {
  final result = <RenderParagraph>[];
  for (final element in find.byType(RichText).evaluate()) {
    final render = element.renderObject;
    if (render is RenderParagraph &&
        render.text.style?.fontFamily == _displayFamily) {
      result.add(render);
    }
  }
  return result;
}

/// Vérifie, pour chaque texte en police pixel affiché :
/// - aucune exception de rendu (débordement) levée jusque-là ;
/// - taille effective >= [minSize] (jamais de display sous 11 px) ;
/// - agrandissement effectif <= [maxFactor] (x1,5 = plafond du palier le plus
///   haut : un `Text` brut à x2,0 ou x3,0 échoue ici) ;
/// - aucun mot coupé en plein mot : le mot le plus long tient sur une ligne.
///
/// Retourne le nombre de textes display inspectés (l'appelant s'assure qu'il
/// n'est pas nul, sinon le test ne prouverait rien).
int expectDisplayTextSane(
  WidgetTester tester, {
  double minSize = 11,
  double maxFactor = 1.5,
}) {
  final exception = tester.takeException();
  expect(
    exception,
    isNull,
    reason: exception is FlutterError ? exception.toStringDeep() : null,
  );
  final paragraphs = displayParagraphs(tester);
  for (final paragraph in paragraphs) {
    final span = paragraph.text;
    final base = span.style!.fontSize!;
    final effective = paragraph.textScaler.scale(base);
    final text = span.toPlainText();
    expect(
      effective,
      greaterThanOrEqualTo(minSize),
      reason: '« $text » : $effective px < $minSize px',
    );
    expect(
      effective / base,
      lessThanOrEqualTo(maxFactor + 0.001),
      reason: '« $text » : agrandissement x${effective / base} non plafonné',
    );
    // Une ellipse explicite (`maxLines` + `overflow`) n'est pas une coupure en
    // plein mot subie : le code l'a demandée.
    if (paragraph.didExceedMaxLines) continue;
    final words = text.split(RegExp(r'\s+'))..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) continue;
    final longest = words.reduce((a, b) => a.length >= b.length ? a : b);
    final painter = TextPainter(
      text: TextSpan(text: longest, style: span.style),
      textDirection: TextDirection.ltr,
      textScaler: paragraph.textScaler,
    )..layout();
    final wordWidth = painter.width;
    painter.dispose();
    expect(
      paragraph.size.width,
      greaterThanOrEqualTo(wordWidth - 0.5),
      reason:
          '« $text » : mot « $longest » coupé en plein mot '
          '(${paragraph.size.width} < $wordWidth)',
    );
  }
  return paragraphs.length;
}

/// Largeurs (dp) et échelles de police testées par [displayScaleMatrix].
const displayScaleWidths = [320.0, 360.0];
const displayScaleFactors = [2.0, 3.0];

/// Enregistre un test par couple (échelle, largeur) : monte [build] dans une
/// appli localisée en français (avec `ProviderScope`), à x2,0 et x3,0 sur 320
/// et 360 dp, puis applique [expectDisplayTextSane]. [scroll] : place le
/// widget dans une zone défilante (cartes), sinon il occupe l'écran (écrans).
/// [minDisplayTexts] : nombre minimal de textes display attendus.
/// Charge les vraies polices de l'app (Press Start 2P et Work Sans) : la police
/// de test (Ahem) est plus large que Work Sans et fausserait les débordements.
/// À appeler dans un `setUpAll`.
bool _fontsLoaded = false;

Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  _fontsLoaded = true;
  for (final (family, file) in [
    ('PressStart2P', 'PressStart2P-Regular.ttf'),
    ('WorkSans', 'WorkSans-VariableFont_wght.ttf'),
  ]) {
    final loader = FontLoader(family)
      ..addFont(
        Future.value(
          ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync()),
        ),
      );
    await loader.load();
  }
}

void displayScaleMatrix(
  String description,
  Widget Function() build, {
  bool scroll = true,
  int minDisplayTexts = 1,
  List<double> widths = displayScaleWidths,
  List<Override> overrides = const [],
  Future<void> Function(WidgetTester tester)? afterPump,
}) {
  setUpAll(loadAppFonts);
  for (final scale in displayScaleFactors) {
    for (final width in widths) {
      testWidgets('$description — x$scale sur ${width.toInt()} dp', (
        tester,
      ) async {
        // `tester.view` (pas `setSurfaceSize`, voir D191).
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        // Détail des erreurs de rendu (le widget fautif), que `takeException`
        // ne conserve pas.
        final captured = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          captured.add(details);
          previous?.call(details);
        };
        addTearDown(() => FlutterError.onError = previous);
        final body = build();
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('fr'),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: scroll ? SingleChildScrollView(child: body) : body,
              ),
            ),
          ),
        );
        await tester.pump();
        if (afterPump != null) await afterPump(tester);
        if (captured.isNotEmpty) {
          debugPrint(captured.first.toString());
        }
        final count = expectDisplayTextSane(tester);
        expect(count, greaterThanOrEqualTo(minDisplayTexts));
      });
    }
  }
}

/// Applique, comme le ferait l'OS, une taille de police système [scale] et une
/// largeur d'écran [width] (dp, ratio 1) à un test dont le harnais monte déjà
/// sa propre appli : à appeler AVANT le montage. Charge les vraies polices.
Future<void> useScaledView(
  WidgetTester tester, {
  required double scale,
  required double width,
  double height = 800,
}) async {
  await loadAppFonts();
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  // Détail des erreurs de rendu (widget fautif), que `takeException` perd.
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    debugPrint(details.toString());
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}
