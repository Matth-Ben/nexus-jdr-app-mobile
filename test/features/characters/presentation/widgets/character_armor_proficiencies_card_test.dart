// Tests de widget de `CharacterArmorProficienciesCard` — câblage du tap sur
// une chip vers `onTapToken` (voir sa doc de classe).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/character_armor_proficiencies_card.dart';
import 'package:personnages/l10n/app_localizations.dart';

void main() {
  testWidgets('affiche un chip par token', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        // `CharacterNameTagChip` (chaque token) lit
        // `AppLocalizations.of(context)!` quand `onTap` est fourni
        // (chantier "traduction de l'app" Phase B, lot "Characters —
        // liste") : sans ces delegates, l'appel renverrait `null` et le
        // `!` planterait.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Explicite (plutôt que de compter sur le repli de résolution de
        // locale) depuis que le titre de la carte lit aussi
        // `AppLocalizations.of(context)!` (chantier "traduction de l'app"
        // Phase B, lot "Characters — classe/race/maîtrises") : la locale
        // par défaut de l'environnement de test n'est pas garantie d'être
        // `fr` — régression trouvée en lançant la suite complète.
        locale: const Locale('fr'),
        home: Scaffold(
          body: CharacterArmorProficienciesCard(
            names: const ['légère', 'boucliers'],
            onTapToken: (_) {},
          ),
        ),
      ),
    );

    expect(find.text("MAÎTRISES D'ARMURES"), findsOneWidget);
    expect(find.text('légère'), findsOneWidget);
    expect(find.text('boucliers'), findsOneWidget);
  });

  testWidgets('taper un chip appelle onTapToken avec le token exact', (
    tester,
  ) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: CharacterArmorProficienciesCard(
            names: const ['légère', 'boucliers (non métalliques)'],
            onTapToken: tapped.add,
          ),
        ),
      ),
    );

    await tester.tap(find.text('boucliers (non métalliques)'));
    expect(tapped, ['boucliers (non métalliques)']);
  });

  group('locale anglaise', () {
    // Même rationale que les autres lots du chantier "traduction de l'app"
    // Phase B : vérifie qu'un texte anglais s'affiche réellement.
    testWidgets('titre en anglais', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: CharacterArmorProficienciesCard(
              names: const ['légère'],
              onTapToken: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('ARMOR PROFICIENCIES'), findsOneWidget);
    });
  });
}
