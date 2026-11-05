// Tests de widget de `showGroupConfirmationDialog` — dialogue de
// confirmation léger factorisé pour les 3 usages du chantier "Système de
// groupe", voir sa doc de classe. Le titre/message/libellé de confirmation
// sont fournis par l'appelant (hors périmètre de ce lot) : seuls le bouton
// "Annuler" et le choix `DestructiveButton`/`PrimaryButton` sont couverts
// ici — ainsi que la traduction du bouton "Annuler" (chantier "traduction de
// l'app" Phase B, lot "Groups — rejoindre/créer").

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/destructive_button.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/groups/presentation/widgets/group_confirmation_dialog.dart';
import 'package:personnages/l10n/app_localizations.dart';

/// Un simple bouton "Ouvrir" qui déclenche `showGroupConfirmationDialog` —
/// la fonction n'est jamais appelée directement par un écran de test, elle
/// l'est toujours depuis un gestionnaire de tap d'un écran réel
/// (`group_screen.dart`/`group_settings_screen.dart`/
/// `group_character_reassignment_screen.dart`), reproduit ici à l'identique.
Widget _buildWidget({
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
  ValueChanged<bool?>? onResult,
  Locale locale = const Locale('fr'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            final result = await showGroupConfirmationDialog(
              context,
              title: title,
              message: message,
              confirmLabel: confirmLabel,
              destructive: destructive,
            );
            onResult?.call(result);
          },
          child: const Text('Ouvrir'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('destructif (par défaut) : bouton "Annuler" + DestructiveButton, '
      'renvoie false au toucher d\'"Annuler"', (tester) async {
    bool? result;

    await tester.pumpWidget(
      _buildWidget(
        title: 'Quitter « Les Lames » ?',
        message: 'Tu ne pourras plus suivre ce groupe.',
        confirmLabel: 'Quitter',
        onResult: (value) => result = value,
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Quitter « Les Lames » ?'), findsOneWidget);
    expect(find.text('Tu ne pourras plus suivre ce groupe.'), findsOneWidget);
    expect(find.text('ANNULER'), findsOneWidget);
    expect(find.byType(DestructiveButton), findsOneWidget);
    expect(find.byType(PrimaryButton), findsNothing);

    await tester.tap(find.text('ANNULER'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('non destructif : PrimaryButton plutôt que DestructiveButton', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildWidget(
        title: "Régénérer le code d'invitation ?",
        message: "L'ancien code ne fonctionnera plus.",
        confirmLabel: 'Régénérer',
        destructive: false,
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.byType(PrimaryButton), findsOneWidget);
    expect(find.byType(DestructiveButton), findsNothing);
  });

  group('traduction anglaise', () {
    testWidgets('bouton "Annuler" traduit en "Cancel"', (tester) async {
      await tester.pumpWidget(
        _buildWidget(
          title: 'Leave "The Blades"?',
          message: "You won't be able to follow this group anymore.",
          confirmLabel: 'Leave',
          locale: const Locale('en'),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('CANCEL'), findsOneWidget);
    });
  });
}
