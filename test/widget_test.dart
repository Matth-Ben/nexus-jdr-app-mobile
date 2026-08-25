// Test de fumée pour le point d'entrée de l'app.
//
// Note : on pompe directement `NexusJdrApp` (pas `main()`), pour ne pas
// dépendre de `Supabase.initialize` (accès réseau/plugins natifs) dans un
// test de widget.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personnages/main.dart';

void main() {
  testWidgets('affiche l\'écran placeholder au démarrage', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: NexusJdrApp()),
    );

    expect(find.text('Nexus JDR — Personnages'), findsWidgets);
  });
}
