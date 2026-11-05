// Tests de widget de `ErrorRetryState` (état d'erreur centré, icône +
// message + bouton "Réessayer", partagé par les feuilles qui chargent une
// liste — extrait de `add_item_flow.dart`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/error_retry_state.dart';
import 'package:personnages/l10n/app_localizations.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('fr')}) {
  // `ErrorRetryState` lit `AppLocalizations.of(context)!` (libellé du bouton
  // "Réessayer") — sans ces delegates, le `!` planterait.
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('affiche le message fourni et le bouton "Réessayer"', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        ErrorRetryState(message: 'Une erreur est survenue', onRetry: () {}),
      ),
    );

    expect(find.text('Une erreur est survenue'), findsOneWidget);
    // `SecondaryButton` met son libellé en majuscules à l'affichage.
    expect(find.text('RÉESSAYER'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('taper "Réessayer" appelle onRetry', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      _wrap(
        ErrorRetryState(
          message: 'Une erreur est survenue',
          onRetry: () => retried = true,
        ),
      ),
    );

    await tester.tap(find.text('RÉESSAYER'));
    await tester.pump();

    expect(retried, isTrue);
  });

  testWidgets('en locale anglaise, le bouton affiche "Retry"', (tester) async {
    await tester.pumpWidget(
      _wrap(
        ErrorRetryState(message: 'Something went wrong', onRetry: () {}),
        locale: const Locale('en'),
      ),
    );

    expect(find.text('RETRY'), findsOneWidget);
    expect(find.text('RÉESSAYER'), findsNothing);
  });
}
