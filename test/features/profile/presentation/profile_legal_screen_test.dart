// Tests de widget de l'écran "Mentions légales / CGU"
// (`presentation/profile_legal_screen.dart`) — bandeau bois "MENTIONS
// LÉGALES / CGU" + retour, gabarit "texte légal long" identique à
// `ProfilePrivacyPolicyScreen` (sections `LegalSectionBlock` séparées par
// un `Divider`), texte final validé par le chef de projet (contrôlé par
// sondage), pied de page "Dernière mise à jour".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/legal_section_block.dart';
import 'package:personnages/features/profile/presentation/profile_legal_screen.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<void> _pumpScreen(
  WidgetTester tester, {
  Locale locale = const Locale('fr'),
}) async {
  await tester.pumpWidget(
    MaterialApp.router(
      // `ProfileLegalScreen` lit `AppLocalizations.of(context)!` (chantier
      // "traduction de l'app" Phase B) — sans ces delegates, l'appel
      // renverrait `null` et le `!` planterait. `fr` par défaut, `en` passé
      // explicitement par les tests du groupe "locale anglaise" ci-dessous.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.push('/profile/help/legal'),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/profile/help/legal',
            builder: (context, state) => const ProfileLegalScreen(),
          ),
        ],
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('affiche le bandeau bois "MENTIONS LÉGALES / CGU"', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.text('MENTIONS LÉGALES / CGU'), findsOneWidget);
  });

  testWidgets('affiche les 7 sections attendues, dans l\'ordre', (
    tester,
  ) async {
    await _pumpScreen(tester);

    for (final title in const [
      'Éditeur',
      'Hébergement',
      "Objet de l'application",
      "Conditions d'utilisation",
      'Propriété intellectuelle',
      'Résiliation',
      'Droit applicable',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.byType(LegalSectionBlock), findsNWidgets(7));
  });

  testWidgets(
    'affiche le contenu exact validé (échantillon : placeholder éditeur, '
    'contact, droit applicable)',
    (tester) async {
      await _pumpScreen(tester);

      expect(find.text('Matthias Benoit'), findsOneWidget);
      expect(find.text('Contact : support@nexus-jdr.app'), findsOneWidget);
      expect(
        find.text('Ces mentions sont soumises au droit français.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'la propriété intellectuelle renvoie aux attributions du SRD, sans '
    'mention d\'Open5e (licence étape 1, fin du texte PROVISOIRE)',
    (tester) async {
      await _pumpScreen(tester);

      expect(
        find.text(
          'Une partie du contenu de règles de Donjons & Dragons 5e provient '
          'du System Reference Document (SRD 5.1 et 5.2), sous licence '
          'Creative Commons Attribution 4.0 International (CC BY 4.0) ; le '
          "reste du contenu de jeu n'est pas issu du SRD et n'est pas "
          "couvert par cette licence. Les déclarations d'attribution et les "
          'modifications apportées figurent dans « Crédits & licences ». Le '
          'code, le design et la marque « Nexus JDR » appartiennent à '
          "l'éditeur de l'application.",
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Open5e'), findsNothing);
    },
  );

  testWidgets('sépare chaque section par un Divider (6 séparateurs pour '
      '7 sections, jamais après la dernière)', (tester) async {
    await _pumpScreen(tester);

    expect(find.byType(Divider), findsNWidgets(6));
  });

  testWidgets('affiche le pied de page "Dernière mise à jour"', (tester) async {
    await _pumpScreen(tester);

    await tester.ensureVisible(
      find.text('Dernière mise à jour : 25 novembre 2026'),
    );
    final footer = tester.widget<Text>(
      find.text('Dernière mise à jour : 25 novembre 2026'),
    );
    expect(footer.style?.fontSize, 11);
    expect(footer.style?.color, AppColors.textMuted);
  });

  testWidgets('le bandeau bois propose un retour fonctionnel', (tester) async {
    await _pumpScreen(tester);
    expect(find.text('Ouvrir'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir'), findsOneWidget);
  });

  group('locale anglaise', () {
    testWidgets('affiche le bandeau bois et les sections en anglais', (
      tester,
    ) async {
      await _pumpScreen(tester, locale: const Locale('en'));

      expect(find.text('LEGAL NOTICE / TERMS'), findsOneWidget);
      expect(find.text('Publisher'), findsOneWidget);
      expect(find.text('Matthias Benoit'), findsOneWidget);
      expect(
        find.text('This notice is governed by French law.'),
        findsOneWidget,
      );
    });
  });
}
