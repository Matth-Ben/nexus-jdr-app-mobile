import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/alert_banner.dart';

void main() {
  testWidgets('affiche le message fourni et l\'icône d\'avertissement, non '
      'interactif (pas d\'InkWell)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AlertBanner(message: 'Une erreur est survenue.')),
      ),
    );

    expect(find.text('Une erreur est survenue.'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(
      find.byType(InkWell),
      findsNothing,
      reason: 'ce bandeau est non interactif, jamais de zone de tap',
    );
  });
}
