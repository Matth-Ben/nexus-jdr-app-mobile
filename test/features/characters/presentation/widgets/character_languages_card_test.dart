// Tests de widget de `CharacterLanguagesCard` — voir sa documentation de
// classe. Même approche que `character_tool_proficiencies_card_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/character_languages_card.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester,
  List<String> names, {
  Locale locale = const Locale('fr'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      // `CharacterLanguagesCard` lit `AppLocalizations.of(context)!`
      // (chantier "traduction de l'app" Phase B, lot "Characters —
      // classe/race/maîtrises") : sans ces delegates, l'appel renverrait
      // `null` et le `!` planterait. `fr` par défaut, `en` passé
      // explicitement par le groupe "locale anglaise" plus bas.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: CharacterLanguagesCard(names: names)),
    ),
  );
}

void main() {
  testWidgets('affiche un chip par langue', (tester) async {
    await _pump(tester, const ['Nain', 'Elfique']);

    expect(find.text('LANGUES CONNUES'), findsOneWidget);
    expect(find.text('Nain'), findsOneWidget);
    expect(find.text('Elfique'), findsOneWidget);
  });

  testWidgets('affiche quand même le titre quand names est vide (appelant '
      'responsable de ne pas monter cette carte, voir '
      'character_skills_tab_body.dart)', (tester) async {
    await _pump(tester, const []);

    expect(find.text('LANGUES CONNUES'), findsOneWidget);
  });

  group('locale anglaise', () {
    // Même rationale que les autres lots du chantier "traduction de l'app"
    // Phase B : vérifie qu'un texte anglais s'affiche réellement.
    testWidgets('titre en anglais', (tester) async {
      await _pump(tester, const ['Nain'], locale: const Locale('en'));

      expect(find.text('KNOWN LANGUAGES'), findsOneWidget);
    });
  });
}
