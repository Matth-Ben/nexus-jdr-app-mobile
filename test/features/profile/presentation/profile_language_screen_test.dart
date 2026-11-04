// Tests de widget de l'écran "Langue" (`presentation/profile_language_screen.dart`)
// — chantier "traduction de l'app" Phase A : affichage des 3
// `SelectableOptionTile`, sélection active selon la préférence persistée
// (`LocalePreferenceController`), bascule immédiate au tap (sans bouton
// "Valider", sans `SnackBar` de confirmation, l'écran reste affiché) et
// re-rendu des libellés de CET écran dans la langue forcée.
//
// `MaterialApp.router(locale: ...)` est câblé sur
// `localePreferenceControllerProvider`, exactement comme
// `main.dart::NexusJdrApp` — sans ce câblage, le re-rendu instantané des
// libellés (preuve visuelle de la bascule, spec direction-artistique) ne
// serait pas reproduit par ce test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/i18n/locale_preference_provider.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';
import 'package:personnages/features/profile/presentation/profile_language_screen.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpScreen(
  WidgetTester tester, {
  // Simule la langue de l'appareil, lue par Flutter quand la préférence
  // forcée est `null` ("Langue du téléphone") — `fr` par défaut dans ces
  // tests pour rendre la résolution de langue déterministe (l'environnement
  // `flutter test` n'a sinon aucune garantie documentée sur la langue de son
  // appareil simulé), voir [MaterialApp.locale]/`main.dart::NexusJdrApp`.
  Locale deviceLocale = const Locale('fr'),
}) async {
  // `MaterialApp`/`WidgetsApp` résout la langue à partir de `.locales`
  // (liste, `basicLocaleListResolution`), pas seulement de `.locale` — les
  // deux doivent être surchargés pour que la résolution par défaut de
  // Flutter (`locale: null`, "Langue du téléphone") retienne bien
  // [deviceLocale] plutôt que la vraie langue de l'environnement `flutter
  // test`.
  tester.platformDispatcher.localeTestValue = deviceLocale;
  tester.platformDispatcher.localesTestValue = [deviceLocale];
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  await tester.pumpWidget(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final locale = ref.watch(localePreferenceControllerProvider);
          return MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            routerConfig: GoRouter(
              initialLocation: '/profile/language',
              routes: [
                GoRoute(
                  path: '/profile/language',
                  builder: (context, state) => const ProfileLanguageScreen(),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SelectableOptionTile _tileFor(WidgetTester tester, String title) {
  return tester
      .widgetList<SelectableOptionTile>(find.byType(SelectableOptionTile))
      .firstWhere((tile) => tile.title == title);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'affiche les 3 options dans l\'ordre, avec le sous-titre bilingue et '
    'sans le détail de "Langue du téléphone" tant qu\'elle n\'est pas '
    'sélectionnée',
    (tester) async {
      await _pumpScreen(tester);

      expect(find.text('LANGUE'), findsOneWidget);
      final titles = tester
          .widgetList<SelectableOptionTile>(find.byType(SelectableOptionTile))
          .map((tile) => tile.title)
          .toList();
      expect(titles, ['Langue du téléphone', 'Français', 'English']);
      expect(find.text('Phone language'), findsOneWidget);
    },
  );

  testWidgets(
    'préférence par défaut (rien de persisté) -> "Langue du téléphone" '
    'sélectionnée, avec son détail bilingue visible ; les 2 autres non '
    'sélectionnées',
    (tester) async {
      await _pumpScreen(tester);

      expect(_tileFor(tester, 'Langue du téléphone').selected, isTrue);
      expect(_tileFor(tester, 'Français').selected, isFalse);
      expect(_tileFor(tester, 'English').selected, isFalse);
      expect(
        find.textContaining('Suit la langue de l\'appareil'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'préférence persistée \'fr\' -> "Français" sélectionnée, les 2 autres '
    'non sélectionnées, et le détail de "Langue du téléphone" masqué',
    (tester) async {
      SharedPreferences.setMockInitialValues({'locale_preference': 'fr'});

      await _pumpScreen(tester);

      expect(_tileFor(tester, 'Langue du téléphone').selected, isFalse);
      expect(_tileFor(tester, 'Français').selected, isTrue);
      expect(_tileFor(tester, 'English').selected, isFalse);
      expect(
        find.textContaining('Suit la langue de l\'appareil'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'préférence persistée \'en\' -> "English" sélectionnée (écran lui-même '
    'affiché en anglais)',
    (tester) async {
      SharedPreferences.setMockInitialValues({'locale_preference': 'en'});

      await _pumpScreen(tester);

      expect(find.text('LANGUAGE'), findsOneWidget);
      expect(_tileFor(tester, 'Phone language').selected, isFalse);
      expect(_tileFor(tester, 'Français').selected, isFalse);
      expect(_tileFor(tester, 'English').selected, isTrue);
    },
  );

  testWidgets(
    'taper "English" bascule immédiatement : la sélection change sans '
    'bouton "Valider", sans SnackBar, et le titre de CET écran se re-rend '
    'en anglais (preuve visuelle de la bascule)',
    (tester) async {
      await _pumpScreen(tester);
      expect(find.text('LANGUE'), findsOneWidget);

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.text('LANGUAGE'), findsOneWidget);
      expect(find.text('LANGUE'), findsNothing);
      expect(_tileFor(tester, 'Phone language').selected, isFalse);
      expect(_tileFor(tester, 'Français').selected, isFalse);
      expect(_tileFor(tester, 'English').selected, isTrue);
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets(
    'taper "Français" après avoir forcé l\'anglais revient immédiatement '
    'au français, sans SnackBar',
    (tester) async {
      SharedPreferences.setMockInitialValues({'locale_preference': 'en'});
      await _pumpScreen(tester);
      expect(find.text('LANGUAGE'), findsOneWidget);

      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();

      expect(find.text('LANGUE'), findsOneWidget);
      expect(_tileFor(tester, 'Français').selected, isTrue);
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets(
    'taper "Langue du téléphone" après avoir forcé l\'anglais revient à la '
    'préférence par défaut (suit l\'appareil), sans SnackBar',
    (tester) async {
      SharedPreferences.setMockInitialValues({'locale_preference': 'en'});
      await _pumpScreen(tester);

      await tester.tap(find.text('Phone language'));
      await tester.pumpAndSettle();

      expect(find.text('LANGUE'), findsOneWidget);
      expect(_tileFor(tester, 'Langue du téléphone').selected, isTrue);
      expect(find.byType(SnackBar), findsNothing);
    },
  );
}
