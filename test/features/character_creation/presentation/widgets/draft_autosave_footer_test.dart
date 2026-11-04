// Tests de widget du pied de page "Brouillon sauvegardé automatiquement ·
// Abandonner" (`presentation/widgets/draft_autosave_footer.dart`) — même
// patron minimal que `creation_mode_title_test.dart` : un `ProviderScope`,
// pas de dépôt réseau à doubler (le widget ne lit que
// `characterEditSessionControllerProvider`).
//
// Les écrans de l'assistant couvrent déjà ce pied de page en contexte
// français ; ce fichier ajoute la couverture isolée du widget partagé et sa
// variante anglaise (jamais testée jusqu'ici).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/character_edit_snapshot.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_edit_session_provider.dart';
import 'package:personnages/features/character_creation/presentation/widgets/draft_autosave_footer.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<ProviderContainer> _pumpFooter(
  WidgetTester tester, {
  Locale locale = const Locale('fr'),
  required VoidCallback onAbandon,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DraftAutosaveFooter(onAbandon: onAbandon)),
      ),
    ),
  );
  return container;
}

void _startEditSession(ProviderContainer container) {
  container
      .read(characterEditSessionControllerProvider.notifier)
      .start(
        const CharacterEditSession(
          snapshot: CharacterEditSnapshot(
            characterId: 'c1',
            name: 'Brunhilde',
            primaryClassId: 2,
            primaryClassLevel: 1,
            totalLevel: 1,
            maxHp: 10,
            currentHp: 10,
          ),
          originalDraft: CharacterCreationDraft(raceId: 1),
        ),
      );
}

void main() {
  testWidgets(
    'hors mode modification : préfixe "Brouillon sauvegardé automatiquement" '
    'et lien "Abandonner", qui déclenche [onAbandon]',
    (tester) async {
      var abandonTapped = false;
      await _pumpFooter(tester, onAbandon: () => abandonTapped = true);

      expect(
        find.textContaining('Brouillon sauvegardé automatiquement'),
        findsOneWidget,
      );
      expect(find.text('Abandonner'), findsOneWidget);

      await tester.tap(find.text('Abandonner'));
      expect(abandonTapped, isTrue);
    },
  );

  testWidgets('en mode modification : préfixe "Modification en cours" et lien '
      '"Annuler les modifications"', (tester) async {
    var abandonTapped = false;
    final container = await _pumpFooter(
      tester,
      onAbandon: () => abandonTapped = true,
    );
    _startEditSession(container);
    await tester.pump();

    expect(find.textContaining('Modification en cours'), findsOneWidget);
    expect(find.text('Annuler les modifications'), findsOneWidget);

    await tester.tap(find.text('Annuler les modifications'));
    expect(abandonTapped, isTrue);
  });

  group('traduction anglaise', () {
    testWidgets(
      'hors mode modification : préfixe et lien "Abandon" en anglais',
      (tester) async {
        await _pumpFooter(tester, locale: const Locale('en'), onAbandon: () {});

        expect(
          find.textContaining('Draft saved automatically'),
          findsOneWidget,
        );
        expect(find.text('Abandon'), findsOneWidget);
      },
    );

    testWidgets(
      'en mode modification : préfixe et lien "Cancel changes" en anglais',
      (tester) async {
        final container = await _pumpFooter(
          tester,
          locale: const Locale('en'),
          onAbandon: () {},
        );
        _startEditSession(container);
        await tester.pump();

        expect(find.textContaining('Editing in progress'), findsOneWidget);
        expect(find.text('Cancel changes'), findsOneWidget);
      },
    );
  });
}
