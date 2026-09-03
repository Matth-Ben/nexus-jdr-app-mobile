import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/info_banner.dart';

void main() {
  testWidgets('affiche le message et l\'icône fournis, non interactif '
      '(pas d\'InkWell)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InfoBanner(
            icon: Icons.smartphone_outlined,
            message: "Compte lié à l'app Histoires",
          ),
        ),
      ),
    );

    expect(find.text("Compte lié à l'app Histoires"), findsOneWidget);
    expect(find.byIcon(Icons.smartphone_outlined), findsOneWidget);
    expect(
      find.byType(InkWell),
      findsNothing,
      reason: 'ce bandeau est non interactif, jamais de zone de tap',
    );
  });
}
