// Section repliable « Options avancées » (P7) : repliée par défaut, déplie à la
// demande ou d'emblée, sémantique d'expansion, cible d'au moins 48 dp, contenu
// non monté tant qu'elle est repliée.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/advanced_section.dart';

Widget _app({
  bool initiallyExpanded = false,
  bool forceExpanded = false,
  double scale = 1,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: AdvancedSection(
        title: 'Options avancées',
        initiallyExpanded: initiallyExpanded,
        forceExpanded: forceExpanded,
        child: const Text('contenu'),
      ),
    ),
  ),
);

void main() {
  testWidgets('repliée par défaut : contenu non monté, icône « déplier »', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.text('contenu'), findsNothing);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsNothing);
  });

  testWidgets('un tap sur l\'en-tête déplie puis replie', (tester) async {
    await tester.pumpWidget(_app());

    await tester.tap(find.byKey(const Key('advancedSectionHeader')));
    await tester.pump();
    expect(find.text('contenu'), findsOneWidget);
    expect(find.byIcon(Icons.expand_less), findsOneWidget);

    await tester.tap(find.byKey(const Key('advancedSectionHeader')));
    await tester.pump();
    expect(find.text('contenu'), findsNothing);
  });

  testWidgets('initiallyExpanded : dépliée d\'emblée', (tester) async {
    await tester.pumpWidget(_app(initiallyExpanded: true));

    expect(find.text('contenu'), findsOneWidget);
  });

  testWidgets('forceExpanded (erreur) déplie, et un retour à false ne '
      'replie pas', (tester) async {
    await tester.pumpWidget(_app());
    expect(find.text('contenu'), findsNothing);

    await tester.pumpWidget(_app(forceExpanded: true));
    expect(find.text('contenu'), findsOneWidget);

    await tester.pumpWidget(_app());
    expect(find.text('contenu'), findsOneWidget);
  });

  testWidgets('sémantique : bouton avec état déplié/replié', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app());

    expect(
      tester.getSemantics(find.bySemanticsLabel('Options avancées')),
      matchesSemantics(
        label: 'Options avancées',
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.byKey(const Key('advancedSectionHeader')));
    await tester.pump();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Options avancées')),
      matchesSemantics(
        label: 'Options avancées',
        isButton: true,
        hasExpandedState: true,
        isExpanded: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('en-tête d\'au moins 48 dp, y compris police agrandie', (
    tester,
  ) async {
    for (final scale in [1.0, 3.0]) {
      await tester.pumpWidget(_app(scale: scale));

      expect(
        tester.getSize(find.byKey(const Key('advancedSectionHeader'))).height,
        greaterThanOrEqualTo(48),
        reason: 'x$scale',
      );
    }
  });
}
