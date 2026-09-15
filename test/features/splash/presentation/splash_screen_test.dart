// Tests de widget de l'écran de lancement (`SplashScreen`) — voir
// `docs/cahier-des-charges/09-maquettes-captures.md`, section "Lancement —
// Splash".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/app_brand_badge.dart';
import 'package:personnages/features/splash/presentation/splash_screen.dart';

/// Repère un point de l'indicateur "3 points" : un petit cercle plein
/// `AppColors.goldEnd`, distinct de tout autre `Container` circulaire de
/// l'écran (l'emblème [AppBrandBadge] utilise d'autres couleurs, voir sa doc
/// de classe).
bool _isLoaderDot(Widget widget) {
  if (widget is! Container) return false;
  final decoration = widget.decoration;
  return decoration is BoxDecoration &&
      decoration.shape == BoxShape.circle &&
      decoration.color == AppColors.goldEnd;
}

void main() {
  Widget buildTestWidget() {
    return const MaterialApp(home: SplashScreen());
  }

  testWidgets('affiche l\'emblème de marque', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.byType(AppBrandBadge), findsOneWidget);
  });

  testWidgets('affiche "NEXUS JDR" et "PERSONNAGES"', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.text('NEXUS JDR'), findsOneWidget);
    expect(find.text('PERSONNAGES'), findsOneWidget);
  });

  testWidgets('affiche le texte de chargement "Préparation de la taverne…"', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Préparation de la taverne…'), findsOneWidget);
  });

  testWidgets('affiche un indicateur de chargement à 3 points', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    // Un seul `pump` : laisse l'`AnimationController` démarrer sans
    // atteindre `pumpAndSettle`, qui ne se stabiliserait jamais tant que
    // l'indicateur tourne en boucle (`..repeat()`).
    await tester.pump();

    expect(find.byWidgetPredicate(_isLoaderDot), findsNWidgets(3));
  });

  testWidgets(
    'l\'indicateur de chargement continue d\'animer sans lever d\'erreur '
    'sur plusieurs frames, et se nettoie proprement au démontage',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byWidgetPredicate(_isLoaderDot), findsNWidgets(3));
      expect(tester.takeException(), isNull);

      // Démonte l'écran (remplace tout l'arbre) : `AnimationController
      // .dispose()` doit être appelé sans lever (sinon `tester.takeException`
      // ci-dessous le remonterait).
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}
