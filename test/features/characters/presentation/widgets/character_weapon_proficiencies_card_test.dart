// Tests de widget de `CharacterWeaponProficienciesCard` — câblage du tap sur
// une chip vers `onTapToken` (voir sa doc de classe).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/character_weapon_proficiencies_card.dart';
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
          body: CharacterWeaponProficienciesCard(
            names: const ['courantes', 'martiales'],
            onTapToken: (_) {},
          ),
        ),
      ),
    );

    expect(find.text("MAÎTRISES D'ARMES"), findsOneWidget);
    expect(find.text('courantes'), findsOneWidget);
    expect(find.text('martiales'), findsOneWidget);
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
          body: CharacterWeaponProficienciesCard(
            names: const ['courantes', 'dagues'],
            onTapToken: tapped.add,
          ),
        ),
      ),
    );

    await tester.tap(find.text('dagues'));
    expect(tapped, ['dagues']);

    await tester.tap(find.text('courantes'));
    expect(tapped, ['dagues', 'courantes']);
  });

  testWidgets(
    'deux chips courts restent côte à côte, pas chacun sur sa propre ligne '
    '(régression du 2026-10-03 : un `Center` à l\'intérieur du `Wrap` '
    'forçait chaque chip à occuper toute la largeur disponible)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: CharacterWeaponProficienciesCard(
              names: const ['courantes', 'martiales'],
              onTapToken: (_) {},
            ),
          ),
        ),
      );

      final firstTop = tester.getTopLeft(find.text('courantes')).dy;
      final secondTop = tester.getTopLeft(find.text('martiales')).dy;
      expect(
        firstTop,
        secondTop,
        reason:
            'les deux chips doivent être sur la même ligne horizontale, '
            'pas empilés verticalement',
      );

      final firstRight = tester.getTopRight(find.text('courantes')).dx;
      final secondLeft = tester.getTopLeft(find.text('martiales')).dx;
      expect(
        secondLeft,
        greaterThan(firstRight),
        reason: 'le second chip doit être à droite du premier, pas dessous',
      );
    },
  );

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
            body: CharacterWeaponProficienciesCard(
              names: const ['courantes'],
              onTapToken: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('WEAPON PROFICIENCIES'), findsOneWidget);
    });
  });
}
