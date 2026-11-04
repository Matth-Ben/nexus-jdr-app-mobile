// Tests de widget de `CharacterToolProficienciesCard` — voir sa
// documentation de classe. Même approche que
// `character_armor_proficiencies_card_test.dart` : un simple
// `MaterialApp(home: ...)` suffit (pas de Riverpod, pas de réseau), via
// `CharacterNameTagChip` sans `onTap` (non interactive).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/character_tool_proficiencies_card.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester,
  List<String> names, {
  Locale locale = const Locale('fr'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      // `CharacterToolProficienciesCard` lit `AppLocalizations.of(context)!`
      // (chantier "traduction de l'app" Phase B, lot "Characters —
      // classe/race/maîtrises") : sans ces delegates, l'appel renverrait
      // `null` et le `!` planterait. `fr` par défaut, `en` passé
      // explicitement par le groupe "locale anglaise" plus bas.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: CharacterToolProficienciesCard(names: names)),
    ),
  );
}

void main() {
  testWidgets('affiche un chip par outil', (tester) async {
    await _pump(tester, const ['Outils de forgeron', 'Luth']);

    expect(find.text("MAÎTRISES D'OUTILS"), findsOneWidget);
    expect(find.text('Outils de forgeron'), findsOneWidget);
    expect(find.text('Luth'), findsOneWidget);
  });

  testWidgets('affiche quand même le titre quand names est vide (appelant '
      'responsable de ne pas monter cette carte, voir '
      'character_skills_tab_body.dart)', (tester) async {
    await _pump(tester, const []);

    expect(find.text("MAÎTRISES D'OUTILS"), findsOneWidget);
  });

  group('locale anglaise', () {
    // Même rationale que les autres lots du chantier "traduction de l'app"
    // Phase B : vérifie qu'un texte anglais s'affiche réellement.
    testWidgets('titre en anglais', (tester) async {
      await _pump(tester, const [
        'Outils de forgeron',
      ], locale: const Locale('en'));

      expect(find.text('TOOL PROFICIENCIES'), findsOneWidget);
    });
  });
}
