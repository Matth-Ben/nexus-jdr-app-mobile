// Tests de widget de l'écran "Crédits & licences"
// (`presentation/profile_credits_screen.dart`) — bandeau bois "CRÉDITS &
// LICENCES" + retour, 2 sections `LegalSectionBlock` ("Contenu de jeu"/
// "Bibliothèques open source"), bloc encadré CC-BY entre les deux (fond
// `parchmentCardAlt`, bordure `woodLight`), pied de page "Dernière mise à
// jour".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/theme/app_spacing.dart';
import 'package:personnages/core/widgets/legal_section_block.dart';
import 'package:personnages/features/profile/presentation/profile_credits_screen.dart';

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.push('/profile/help/credits'),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/profile/help/credits',
            builder: (context, state) => const ProfileCreditsScreen(),
          ),
        ],
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('affiche le bandeau bois "CRÉDITS & LICENCES"', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('CRÉDITS & LICENCES'), findsOneWidget);
  });

  testWidgets('affiche les 2 sections "Contenu de jeu"/"Bibliothèques '
      'open source"', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('Contenu de jeu'), findsOneWidget);
    expect(find.text('Bibliothèques open source'), findsOneWidget);
    expect(find.byType(LegalSectionBlock), findsNWidgets(2));
  });

  testWidgets('affiche le contenu exact validé (marques Wizards of the Coast, '
      'liste des bibliothèques, phrase de clôture)', (tester) async {
    await _pumpScreen(tester);

    expect(
      find.text(
        'Donjons & Dragons, D&D et leurs logos sont des marques de '
        "Wizards of the Coast LLC. Wizards of the Coast n'a ni "
        'produit, ni approuvé, ni autorisé cette application.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Flutter · Riverpod · Supabase Flutter'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Ainsi que les autres bibliothèques listées dans le fichier '
        "pubspec.yaml du projet, chacune sous sa licence open source "
        "d'origine.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('affiche le bloc encadré CC-BY (fond parchmentCardAlt, bordure '
      'woodLight) entre les 2 sections', (tester) async {
    await _pumpScreen(tester);

    expect(
      find.text(
        'Ce produit inclut des éléments du System Reference Document '
        '5.1 et 5.2, disponibles sur dndbeyond.com/srd et open5e.com, '
        'sous licence Creative Commons Attribution 4.0 International '
        '(creativecommons.org/licenses/by/4.0/legalcode).',
      ),
      findsOneWidget,
    );

    final licenseBoxDecoratedBox = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          (widget.decoration as BoxDecoration).color ==
              AppColors.parchmentCardAlt,
    );
    expect(licenseBoxDecoratedBox, findsOneWidget);
    final decoration =
        tester.widget<DecoratedBox>(licenseBoxDecoratedBox).decoration
            as BoxDecoration;
    expect(decoration.border?.top.color, AppColors.woodLight);
    expect(decoration.border?.top.width, AppBorders.cardEmphasisHalo);
  });

  testWidgets('affiche le pied de page "Dernière mise à jour"', (tester) async {
    await _pumpScreen(tester);

    await tester.ensureVisible(
      find.text('Dernière mise à jour : 15 septembre 2026'),
    );
    final footer = tester.widget<Text>(
      find.text('Dernière mise à jour : 15 septembre 2026'),
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
}
