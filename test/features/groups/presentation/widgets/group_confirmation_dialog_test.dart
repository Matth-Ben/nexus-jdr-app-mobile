// `showGroupConfirmationDialog` en grande police (§7 de
// `10-design-system.md`, revue direction-artistique de la PR #303) : titre et
// message défilent (à ×3,0 sur 320 dp, le titre seul dépasse l'écran), les
// boutons restent visibles et utilisables ; un contenu court garde exactement
// sa hauteur (usages existants inchangés).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/groups/presentation/widgets/group_confirmation_dialog.dart';

const String _longTitle = "Devenir MJ de « Les Lames de l'Aube » ?";
const String _longMessage =
    'Sylvi quittera ce groupe mais restera dans ta liste de personnages, avec '
    'toutes ses données. Tu deviendras MJ sans personnage et tu pourras '
    "lancer les combats. Impossible de revenir en arrière pour l'instant.";
const String _shortMessage =
    "L'ancien code cessera de fonctionner immédiatement. Les membres déjà "
    'présents ne sont pas affectés.';

Future<List<bool?>> _openDialog(
  WidgetTester tester, {
  required double scale,
  required String title,
  required String message,
  Size size = const Size(320, 640),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final results = <bool?>[];
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async => results.add(
                await showGroupConfirmationDialog(
                  context,
                  title: title,
                  message: message,
                  confirmLabel: 'Devenir MJ',
                  destructive: false,
                  focusCancelInitially: true,
                ),
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  return results;
}

ScrollableState _messageScrollable(WidgetTester tester) => tester.state(
  find.ancestor(of: find.text(_longMessage), matching: find.byType(Scrollable)),
);

void main() {
  for (final scale in [2.0, 3.0]) {
    testWidgets('×$scale sur 320 dp : aucun débordement, le contenu défile, '
        'boutons visibles et utilisables', (tester) async {
      final results = await _openDialog(
        tester,
        scale: scale,
        title: _longTitle,
        message: _longMessage,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_longTitle), findsOneWidget);
      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.byType(SecondaryButton), findsOneWidget);
      if (scale == 3.0) {
        // Le contenu ne tient pas : il défile au lieu de déborder.
        expect(
          _messageScrollable(tester).position.maxScrollExtent,
          greaterThan(0),
        );
      }
      // Boutons entièrement dans l'écran.
      final screen = tester.view.physicalSize.height;
      for (final button in [
        find.byType(PrimaryButton),
        find.byType(SecondaryButton),
      ]) {
        expect(tester.getRect(button).bottom, lessThanOrEqualTo(screen));
      }

      // Les boutons restent à l'écran et répondent.
      await tester.tap(find.byType(SecondaryButton));
      await tester.pumpAndSettle();
      expect(results, [false]);
    });
  }

  testWidgets('×1,0 : un contenu court ne défile pas et garde sa hauteur', (
    tester,
  ) async {
    await _openDialog(
      tester,
      scale: 1,
      title: "Régénérer le code d'invitation ?",
      message: _shortMessage,
      size: const Size(360, 800),
    );

    expect(tester.takeException(), isNull);
    final scrollable = tester.state<ScrollableState>(
      find.ancestor(
        of: find.text(_shortMessage),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, 0);
    final content = find
        .descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Column),
        )
        .first;
    expect(
      tester.getSize(find.byType(SingleChildScrollView)).height,
      tester.getSize(content).height,
    );
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
  });
}
