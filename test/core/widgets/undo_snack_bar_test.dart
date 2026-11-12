// `showUndoSnackBar` (P18, patron P9 extrait) : un seul SnackBar à la fois,
// durées 6 s / 10 s (navigation accessible), garde anti-double appui,
// annonce liveRegion, cible >= 44.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/undo_snack_bar.dart';

Future<void> _pump(
  WidgetTester tester, {
  required void Function(BuildContext) onShow,
  bool accessible = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(accessibleNavigation: accessible),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => onShow(context),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('affiche message, lignes supplémentaires et bouton >= 44', (
    tester,
  ) async {
    await _pump(
      tester,
      onShow: (context) => showUndoSnackBar(
        context,
        message: 'Fait',
        undoLabel: 'Annuler',
        announcement: 'Fait. Bouton Annuler.',
        extraMessages: const ['Ligne 2'],
        onUndo: () {},
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Fait'), findsOneWidget);
    expect(find.text('Ligne 2'), findsOneWidget);
    final size = tester.getSize(
      find
          .ancestor(
            of: find.text('ANNULER'),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    expect(size.height, greaterThanOrEqualTo(44));
    expect(size.width, greaterThanOrEqualTo(44));
  });

  testWidgets('garde anti-double appui : onUndo appelé une seule fois', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      onShow: (context) => showUndoSnackBar(
        context,
        message: 'Fait',
        undoLabel: 'Annuler',
        announcement: 'Fait.',
        onUndo: () => calls++,
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('ANNULER'));
    await tester.tap(find.text('ANNULER'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(calls, 1);
  });

  testWidgets('durée 6 s, 10 s en navigation accessible', (tester) async {
    for (final accessible in [false, true]) {
      await _pump(
        tester,
        accessible: accessible,
        onShow: (context) => showUndoSnackBar(
          context,
          message: 'Fait',
          undoLabel: 'Annuler',
          announcement: 'Fait.',
          onUndo: () {},
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(
        snackBar.duration,
        accessible ? const Duration(seconds: 10) : const Duration(seconds: 6),
      );
      ScaffoldMessenger.of(tester.element(find.text('go')))
          .removeCurrentSnackBar();
      await tester.pump();
    }
  });

  testWidgets('un nouveau SnackBar remplace le précédent', (tester) async {
    var n = 0;
    await _pump(
      tester,
      onShow: (context) => showUndoSnackBar(
        context,
        message: 'Message ${++n}',
        undoLabel: 'Annuler',
        announcement: 'x',
        onUndo: () {},
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Message 1'), findsNothing);
    expect(find.text('Message 2'), findsOneWidget);
  });

  testWidgets('annonce liveRegion portée par le message', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      onShow: (context) => showUndoSnackBar(
        context,
        message: 'Fait',
        undoLabel: 'Annuler',
        announcement: 'Fait. Bouton Annuler disponible.',
        onUndo: () {},
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.bySemanticsLabel(RegExp('Fait. Bouton Annuler disponible.')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
