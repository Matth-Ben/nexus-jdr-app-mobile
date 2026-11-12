// Contrôles communs des tests « grande police » des étapes de l'assistant de
// création (D192) : x2,0 et x3,0 sur 320x568 dp, avec les vraies polices.
//
// Chaque fichier de test d'étape garde son propre harnais (dépôt factice,
// brouillon) ; il appelle [useCreationScaledView] avant de monter l'écran puis
// [expectCreationStepFitsScaled] une fois l'écran stabilisé.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';

import '../../../core/widgets/display_scale_helpers.dart';

/// Échelles testées (x2,0 et x3,0 : réglages d'accessibilité extrêmes).
const creationScaleFactors = [2.0, 3.0];

/// Taille d'écran de référence : petit téléphone, portrait.
const creationScaleSurface = Size(320, 568);

/// Applique l'échelle de police et la surface 320x568 AVANT le montage.
Future<void> useCreationScaledView(WidgetTester tester, double scale) =>
    useScaledView(
      tester,
      scale: scale,
      width: creationScaleSurface.width,
      height: creationScaleSurface.height,
    );

/// Vérifie l'écran monté et stabilisé :
/// - aucune exception de rendu (débordement) ;
/// - la police est bien agrandie (garde contre un test qui ne prouverait rien) ;
/// - textes display : taille mini, plafond, aucun mot coupé ;
/// - boutons et tuiles d'option rendus : cible tactile >= 44 dp de haut ;
/// - aucun texte tronqué par une ellipse ;
/// - le bouton de navigation [navLabel] est atteignable (par défilement au
///   besoin) et entièrement dans l'écran.
Future<void> expectCreationStepFitsScaled(
  WidgetTester tester, {
  required double scale,
  String? navLabel = 'SUIVANT',
}) async {
  final exception = tester.takeException();
  expect(
    exception,
    isNull,
    reason: exception is FlutterError ? exception.toStringDeep() : null,
  );
  final paragraphs = find
      .byType(RichText)
      .evaluate()
      .map((e) => e.renderObject)
      .whereType<RenderParagraph>()
      .where((p) => p.text.style?.fontFamily == 'WorkSans')
      .toList();
  expect(paragraphs, isNotEmpty, reason: 'aucun texte WorkSans rendu');
  // La police est effectivement agrandie (au moins un texte >= x scale).
  expect(
    paragraphs.any((p) => p.textScaler.scale(10) >= 10 * scale - 0.01),
    isTrue,
    reason: 'échelle x$scale non appliquée',
  );
  displayParagraphs(tester); // lève tôt si le rendu est cassé
  expectDisplayTextSane(tester);

  for (final type in <Type>[
    PrimaryButton,
    SecondaryButton,
    SelectableOptionTile,
  ]) {
    for (final element in _typeFinder(type).evaluate()) {
      final size = element.size!;
      expect(
        size.height,
        greaterThanOrEqualTo(44),
        reason: '$type : cible ${size.width}x${size.height} < 44 dp',
      );
    }
  }

  final cut = _ellipsized(tester);
  expect(cut, isEmpty, reason: 'texte tronqué par une ellipse : $cut');

  // Parcourt tout le contenu défilant : une liste paresseuse ne construit que
  // ce qui est visible, un débordement plus bas passerait sinon inaperçu.
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isNotEmpty) {
    final scrollable = scrollables.first;
    for (var i = 0; i < 60; i++) {
      final before = tester.state<ScrollableState>(scrollable).position.pixels;
      await tester.drag(scrollable, const Offset(0, -150));
      await tester.pump();
      final scrollException = tester.takeException();
      expect(
        scrollException,
        isNull,
        reason: scrollException is FlutterError
            ? scrollException.toStringDeep()
            : null,
      );
      final ellipsized = _ellipsized(tester);
      expect(
        ellipsized,
        isEmpty,
        reason: 'texte tronqué par une ellipse après défilement : $ellipsized',
      );
      if (tester.state<ScrollableState>(scrollable).position.pixels == before) {
        break;
      }
    }
  }

  if (navLabel != null) {
    final nav = find.text(navLabel);
    if (nav.evaluate().isEmpty || !_isInScreen(tester, nav)) {
      await tester.scrollUntilVisible(
        nav,
        150,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 80,
      );
      await tester.pump();
    }
    expect(nav, findsAtLeastNWidgets(1), reason: '« $navLabel » introuvable');
    expect(
      _isInScreen(tester, nav.first),
      isTrue,
      reason: '« $navLabel » hors écran',
    );
  }
}

bool _isInScreen(WidgetTester tester, Finder finder) {
  if (finder.evaluate().isEmpty) return false;
  final rect = tester.getRect(finder.first);
  final screen = Offset.zero & creationScaleSurface;
  return screen.contains(rect.topLeft) && screen.contains(rect.bottomRight);
}

Finder _typeFinder(Type type) => find.byWidgetPredicate(
  (w) => w.runtimeType == type,
  description: type.toString(),
);

/// Textes tronqués par une ellipse, hors indications (`hint`) des champs de
/// saisie : un exemple de saisie coupé ne retire aucune information.
List<String> _ellipsized(WidgetTester tester) {
  final inFields = {
    for (final e
        in find
            .descendant(
              of: find.byType(TextField),
              matching: find.byType(RichText),
            )
            .evaluate())
      e.renderObject,
  };
  return [
    for (final e in find.byType(RichText).evaluate())
      if (e.renderObject case final RenderParagraph p
          when p.didExceedMaxLines && !inFields.contains(p))
        p.text.toPlainText(),
  ];
}
