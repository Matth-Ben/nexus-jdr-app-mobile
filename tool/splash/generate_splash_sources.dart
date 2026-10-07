// Générateur des PNG sources du splash natif (`assets/splash/*.png`), lus
// ensuite par `flutter_native_splash` (voir la section du même nom dans
// `pubspec.yaml`).
//
// Ne pas lancer ce fichier directement : passer par
// `tool/generate_splash_assets.sh`, qui récupère les polices, lance ce
// générateur puis `dart run flutter_native_splash:create`.
//
// Pourquoi un fichier lancé par `flutter test` : un splash natif s'affiche
// avant le démarrage du moteur Flutter, il ne peut donc contenir que des
// images. Pour qu'elles soient identiques au pixel près à ce que dessine
// ensuite `SplashScreen`, on rend ici les vrais widgets de l'app
// (`AppBrandBadge`, les deux `Text` de `SplashScreen`,
// `AppColors.sceneBackground`) dans le harnais de test, seul moyen de
// rasteriser un widget sans appareil. Ce fichier vit dans `tool/` et non
// dans `test/` : il écrit dans `assets/` et ne doit pas tourner avec la
// suite de tests.
//
// Aucune taille, couleur ni police n'est recopiée ici : les widgets et
// leurs positions sont relevés sur le vrai `SplashScreen`. Si celui-ci
// change, relancer le script suffit à réaligner le splash natif.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/theme/app_theme.dart';
import 'package:personnages/core/widgets/app_brand_badge.dart';
import 'package:personnages/features/splash/presentation/splash_screen.dart';

/// Dossier contenant `PressStart2P-Regular.ttf` et `WorkSans-Regular.ttf`,
/// fourni par `tool/generate_splash_assets.sh`.
const _fontDir = String.fromEnvironment('SPLASH_FONT_DIR');

const _outputDir = 'assets/splash';

/// `flutter_native_splash` traite ses images sources comme du xxxhdpi (4x)
/// et en dérive les autres densités : 1 dp = 4 px dans les sources.
const double _sourcePixelRatio = 4;

/// Largeur de la toile du logo, en dp. Assez étroite pour ne jamais être
/// rognée sur un écran de 320 dp, assez large pour "NEXUS JDR".
const double _logoCanvasWidth = 160;

/// Toile de l'icône Android 12 et plus, en dp : icône sans fond, 288 × 288 dp,
/// contenu visible dans un cercle de 192 dp de diamètre (documentation
/// Android "Splash screens", section "Splash screen dimensions").
const double _android12CanvasSize = 288;
const double _android12SafeDiameter = 192;

/// Fond : le dégradé étant strictement vertical, une bande étroite étirée
/// par `gravity="fill"` suffit.
const Size _backgroundSize = Size(16, 512);

void main() {
  testWidgets('génère les PNG sources du splash natif', (tester) async {
    expect(
      _fontDir,
      isNotEmpty,
      reason: 'Lancer tool/generate_splash_assets.sh plutôt que ce fichier.',
    );
    await tester.runAsync(_loadFonts);

    // 1. Relevé sur le vrai écran de lancement, hébergé comme dans
    // `AppBootstrap._splashApp` (`lib/main.dart`) : le thème compte, il fixe
    // la hauteur de ligne des textes, donc leur position.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
    final title = find.text('NEXUS JDR');
    final subtitle = find.text('PERSONNAGES');
    final badge = find.byType(AppBrandBadge);
    final column = tester.getRect(
      find.ancestor(of: title, matching: find.byType(Column)).first,
    );
    final placed = [
      for (final finder in [badge, title, subtitle])
        _Placed(
          widget: tester.widget(finder),
          // Position relative au bord haut et à l'axe vertical de la colonne.
          rect: tester.getRect(finder).shift(-column.topCenter),
        ),
    ];
    final badgeWidget = tester.widget<AppBrandBadge>(badge);
    // Contexte dont héritent les textes dans `SplashScreen`, à reproduire
    // autour des captures pour obtenir le même rendu.
    final inherited = DefaultTextStyle.of(tester.element(title));
    Widget inSplashContext(Widget child) {
      return Theme(
        data: AppTheme.light,
        child: DefaultTextStyle(
          style: inherited.style,
          textAlign: inherited.textAlign,
          softWrap: inherited.softWrap,
          overflow: inherited.overflow,
          maxLines: inherited.maxLines,
          textWidthBasis: inherited.textWidthBasis,
          textHeightBehavior: inherited.textHeightBehavior,
          child: child,
        ),
      );
    }

    final logoCanvas = Size(_logoCanvasWidth, column.height.ceilToDouble());
    for (final item in placed) {
      expect(
        item.rect.left >= -_logoCanvasWidth / 2 &&
            item.rect.right <= _logoCanvasWidth / 2,
        isTrue,
        reason: 'Un élément du logo dépasse la toile de $_logoCanvasWidth dp.',
      );
      expect(
        item.rect.top >= 0 && item.rect.bottom <= logoCanvas.height,
        isTrue,
        reason:
            'Un élément du logo sort de la colonne de SplashScreen : '
            'sa structure a changé, adapter le générateur.',
      );
    }
    expect(badgeWidget.size, lessThanOrEqualTo(_android12SafeDiameter));

    // 2. Logo (avant Android 12, et iOS) : même hauteur que la colonne
    // complète de `SplashScreen`, contenu en haut, bas transparent — centrée
    // par `gravity="center"`, la toile place donc l'emblème et les textes
    // exactement là où Flutter les dessine, sans le loader ni le texte de
    // chargement (qui n'ont pas de sens figés dans une image).
    await _capture(
      tester,
      file: 'splash_logo.png',
      size: logoCanvas,
      pixelRatio: _sourcePixelRatio,
      child: inSplashContext(
        Stack(
          children: [
            for (final item in placed)
              Positioned(
                left: _logoCanvasWidth / 2 + item.rect.left,
                top: item.rect.top,
                width: item.rect.width,
                height: item.rect.height,
                child: item.widget,
              ),
          ],
        ),
      ),
    );

    // 3. Icône Android 12 et plus : l'emblème seul, centré.
    await _capture(
      tester,
      file: 'splash_icon_android12.png',
      size: const Size.square(_android12CanvasSize),
      pixelRatio: _sourcePixelRatio,
      child: inSplashContext(Center(child: badgeWidget)),
    );

    // 4. Fond : le dégradé de `SceneScaffold`.
    await _capture(
      tester,
      file: 'splash_background.png',
      size: _backgroundSize,
      pixelRatio: 1,
      child: const DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.sceneBackground),
      ),
    );

    // Trace des mesures, reprise dans le commentaire de `pubspec.yaml`.
    // ignore: avoid_print
    print(
      'Colonne SplashScreen : ${column.width} x ${column.height} dp ; '
      'toile logo : ${logoCanvas.width} x ${logoCanvas.height} dp ; '
      '${placed.map((item) => '${item.widget.runtimeType} ${item.rect}').join(' ; ')}',
    );
  });
}

class _Placed {
  const _Placed({required this.widget, required this.rect});

  final Widget widget;
  final Rect rect;
}

/// Charge les vraies polices : le harnais de test n'en charge aucune (tout
/// texte y est rendu en pavés, et les icônes Material n'y sont pas
/// rasterisées).
Future<void> _loadFonts() async {
  // Pas de téléchargement par `google_fonts` : les fichiers sont fournis.
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<ByteData> fromFile(String name) async {
    final bytes = await File('$_fontDir/$name').readAsBytes();
    return ByteData.sublistView(bytes);
  }

  // `google_fonts` nomme chaque police `<Famille>_<variante>` et se replie
  // sur `<Famille>` : on enregistre les deux noms.
  const families = {
    'PressStart2P': 'PressStart2P-Regular.ttf',
    // Work Sans n'apparaît dans aucune image : elle sert au relevé, pour que
    // "Préparation de la taverne…" (dernière ligne de la colonne, donc de la
    // hauteur de la toile) soit mise en page avec sa vraie police.
    'WorkSans': 'WorkSans-Regular.ttf',
  };
  for (final MapEntry(key: family, value: file) in families.entries) {
    for (final name in [family, '${family}_regular']) {
      await (FontLoader(name)..addFont(fromFile(file))).load();
    }
  }
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}

/// Rend [child] sur une toile transparente de [size] dp et l'écrit en PNG
/// dans [_outputDir], à [pixelRatio] px par dp.
Future<void> _capture(
  WidgetTester tester, {
  required String file,
  required Size size,
  required double pixelRatio,
  required Widget child,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: key,
          child: SizedBox.fromSize(size: size, child: child),
        ),
      ),
    ),
  );
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$_outputDir/$file')
        .writeAsBytes(data!.buffer.asUint8List(), flush: true);
    image.dispose();
  });
}
