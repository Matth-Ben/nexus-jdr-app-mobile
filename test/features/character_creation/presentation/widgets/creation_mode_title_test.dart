// Tests de widget du libellé de bandeau bois « CRÉATION »/« MODIFICATION »
// (`presentation/widgets/creation_mode_title.dart`) — même patron minimal que
// `step_help_sheet_test.dart` : un `ProviderScope`, pas de dépôt réseau à
// doubler (le widget ne lit que `characterEditSessionControllerProvider`).
//
// Les écrans de l'assistant (`race_step_screen_test.dart` et consorts)
// couvrent déjà ce libellé en contexte français ; ce fichier ajoute la
// couverture isolée du widget partagé, dont la variante anglaise (jamais
// testée jusqu'ici, voir D153).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/character_edit_snapshot.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_edit_session_provider.dart';
import 'package:personnages/features/character_creation/presentation/widgets/creation_mode_title.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<ProviderContainer> _pumpTitle(
  WidgetTester tester, {
  Locale locale = const Locale('fr'),
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
        home: const Scaffold(
          body: CreationModeTitle(style: TextStyle(fontSize: 14)),
        ),
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets('affiche "CRÉATION" hors mode modification', (tester) async {
    await _pumpTitle(tester);

    expect(find.text('CRÉATION'), findsOneWidget);
    expect(find.text('MODIFICATION'), findsNothing);
  });

  testWidgets(
    'affiche "MODIFICATION" quand une CharacterEditSession est ouverte',
    (tester) async {
      final container = await _pumpTitle(tester);
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
      await tester.pump();

      expect(find.text('MODIFICATION'), findsOneWidget);
      expect(find.text('CRÉATION'), findsNothing);
    },
  );

  group('traduction anglaise', () {
    testWidgets('affiche "CREATION" hors mode modification', (tester) async {
      await _pumpTitle(tester, locale: const Locale('en'));

      expect(find.text('CREATION'), findsOneWidget);
    });

    testWidgets(
      'affiche "EDITING" quand une CharacterEditSession est ouverte',
      (tester) async {
        final container = await _pumpTitle(tester, locale: const Locale('en'));
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
        await tester.pump();

        expect(find.text('EDITING'), findsOneWidget);
      },
    );
  });
}
