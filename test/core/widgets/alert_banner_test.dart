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

  testWidgets('avec onTap : bandeau entier tappable (>= 44 dp), ligne '
      'd\'action soulignée et chevron ; sans ✕', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlertBanner(
            message: '2 alertes de synchronisation',
            actionLabel: 'Voir les alertes',
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(find.text('Voir les alertes'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Voir les alertes')).style?.decoration,
      TextDecoration.underline,
    );
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(
      tester.getSize(find.byType(InkWell)).height,
      greaterThanOrEqualTo(44),
    );

    await tester.tap(find.text('2 alertes de synchronisation'));
    expect(taps, 1);
    await tester.tap(find.text('Voir les alertes'));
    expect(taps, 2);
  });

  testWidgets('rétrocompatible : sans onTap ni actionLabel, ni chevron ni '
      'ligne d\'action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AlertBanner(message: 'Erreur.')),
      ),
    );
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });
}
