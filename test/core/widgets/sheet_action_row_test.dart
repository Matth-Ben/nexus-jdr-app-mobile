// Tests de widget de la ligne d'action de bottom sheet
// (`core/widgets/sheet_action_row.dart`) : rendu de base, désactivation
// (`enabled: false`), et non-régression D24 (`docs/dette-technique.md`) —
// un `trailingText` long, combiné à un `label` long et un texte agrandi
// (réglage d'accessibilité), ne doit plus faire déborder la `Row`
// horizontalement : [SheetActionRow.trailingText] est maintenant protégé par
// un `Flexible` + ellipse, comme [SheetActionRow.label] l'est déjà par son
// `Expanded`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/sheet_action_row.dart';

/// Même largeur que les sheets réelles qui utilisent ce composant
/// (`weapon_slot_picker_sheet.dart` sur un écran de 320 dp).
Future<void> _pumpRow(
  WidgetTester tester, {
  required String label,
  String? trailingText,
  bool enabled = true,
  VoidCallback? onTap,
  double width = 320,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: SheetActionRow(
            icon: Icons.looks_one_outlined,
            label: label,
            trailingText: trailingText,
            enabled: enabled,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('affiche l\'icône, le libellé et le texte de fin', (
    tester,
  ) async {
    await _pumpRow(tester, label: 'Set principal', trailingText: 'Vide');

    expect(find.byIcon(Icons.looks_one_outlined), findsOneWidget);
    expect(find.text('Set principal'), findsOneWidget);
    expect(find.text('Vide'), findsOneWidget);
  });

  testWidgets('sans trailingText : rien n\'est affiché à droite du libellé', (
    tester,
  ) async {
    await _pumpRow(tester, label: 'Set principal');

    expect(find.text('Set principal'), findsOneWidget);
  });

  testWidgets('un tap appelle onTap', (tester) async {
    var tapped = false;
    await _pumpRow(tester, label: 'Set principal', onTap: () => tapped = true);

    await tester.tap(find.byType(SheetActionRow));
    expect(tapped, isTrue);
  });

  testWidgets('enabled: false : tap ignoré, ligne atténuée', (tester) async {
    var tapped = false;
    await _pumpRow(
      tester,
      label: 'Set principal',
      enabled: false,
      onTap: () => tapped = true,
    );

    await tester.tap(find.byType(SheetActionRow));
    expect(tapped, isFalse);
    expect(find.byType(Opacity), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.45);
  });

  group('D24 : libellé et texte de fin longs, texte agrandi (320 dp)', () {
    const longLabel = 'Épée longue +1 de la lignée des rois oubliés';
    const longTrailing = 'Épée courte, dague empoisonnée, arc composite';

    testWidgets('échelle 1 : aucun débordement', (tester) async {
      await _pumpRow(
        tester,
        label: longLabel,
        trailingText: longTrailing,
        textScale: 1,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('échelle 3 : aucun débordement, le texte de fin est tronqué '
        'par une ellipse plutôt que de déborder', (tester) async {
      await _pumpRow(
        tester,
        label: longLabel,
        trailingText: longTrailing,
        textScale: 3,
      );

      expect(tester.takeException(), isNull);
      final trailing = tester.widget<Text>(find.text(longTrailing));
      expect(trailing.overflow, TextOverflow.ellipsis);
      // Vraiment rendu dans une largeur bornée (sinon l'ellipse ne ferait
      // rien) : strictement plus étroit que la largeur totale de la ligne.
      expect(tester.getRect(find.text(longTrailing)).width, lessThan(320));
    });
  });
}
