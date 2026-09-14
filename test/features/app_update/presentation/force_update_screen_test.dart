// Tests de widget de `ForceUpdateScreen` (écran bloquant "Erreur — Mise à
// jour obligatoire").
//
// Le bouton "METTRE À JOUR" n'est volontairement jamais tapé ici : il
// déclenche `canLaunchUrl`/`launchUrl` (`url_launcher`), dépendant d'un canal
// de plateforme natif non mocké sous `flutter test` — même convention que
// `test/features/profile/presentation/profile_help_screen_test.dart`
// (`_contactSupport`). `AppStoreUrls` est testée séparément, de façon pure,
// dans `test/features/app_update/domain/app_store_urls_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/app_update/presentation/force_update_screen.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ForceUpdateScreen(
          installedVersion: '0.1.0',
          minimumVersion: '0.3.0',
        ),
      ),
    );
  }

  testWidgets('affiche le titre deux lignes "MISE À JOUR"/"REQUISE"', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('MISE À JOUR'), findsOneWidget);
    expect(find.text('REQUISE'), findsOneWidget);
  });

  testWidgets('affiche le texte explicatif', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining("n'est plus prise en charge"), findsOneWidget);
  });

  testWidgets('affiche le bouton primaire pleine largeur "↓ METTRE À JOUR"', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('↓ METTRE À JOUR'), findsOneWidget);
  });

  testWidgets(
    'affiche "Version installée : X · minimum requis : Y" avec les valeurs '
    'reçues',
    (tester) async {
      await pumpScreen(tester);

      expect(
        find.text('Version installée : 0.1.0 · minimum requis : 0.3.0'),
        findsOneWidget,
      );
    },
  );

  testWidgets('écran bloquant : aucune flèche retour, aucune AppBar', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byType(AppBar), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
  });

  testWidgets('affiche le badge doré avec l\'icône de téléchargement', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
  });
}
