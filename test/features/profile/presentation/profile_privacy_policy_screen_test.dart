// Tests de widget de l'écran "Politique de confidentialité"
// (`presentation/profile_privacy_policy_screen.dart`) — bandeau bois
// "POLITIQUE DE CONFIDENTIALITÉ" + retour, gabarit "texte légal long" (pas
// de carte englobante, sections `LegalSectionBlock` séparées par un
// `Divider`), texte final validé par le chef de projet (contrôlé par
// sondage plutôt qu'exhaustivement, voir les tests ci-dessous), pied de
// page "Dernière mise à jour".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/legal_section_block.dart';
import 'package:personnages/features/profile/presentation/profile_privacy_policy_screen.dart';

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
                  onPressed: () => context.push('/profile/privacy/policy'),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/profile/privacy/policy',
            builder: (context, state) => const ProfilePrivacyPolicyScreen(),
          ),
        ],
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('affiche le bandeau bois "POLITIQUE DE CONFIDENTIALITÉ"', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.text('POLITIQUE DE CONFIDENTIALITÉ'), findsOneWidget);
  });

  testWidgets('affiche les 8 sections attendues, dans l\'ordre', (
    tester,
  ) async {
    await _pumpScreen(tester);

    for (final title in const [
      'Introduction',
      'Données collectées',
      'Pourquoi ces données',
      'Stockage et hébergement',
      'Conservation',
      'Tes droits',
      'Sécurité',
      'Contact et éditeur',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.byType(LegalSectionBlock), findsNWidgets(8));
  });

  testWidgets(
    'affiche le contenu exact validé (échantillon : introduction, e-mail '
    'de contact, placeholder éditeur)',
    (tester) async {
      await _pumpScreen(tester);

      expect(
        find.text(
          'Cette politique explique quelles données Nexus JDR — '
          'Personnages collecte, pourquoi, et comment tu peux y '
          "accéder, les exporter ou les supprimer. Elle s'applique à "
          "cette application ainsi qu'à l'app web « Histoires », qui "
          'partagent le même compte.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Pour toute question : support@nexus-jdr.app'),
        findsOneWidget,
      );
      expect(
        find.text('[À COMPLÉTER : identité de l\'éditeur]'),
        findsOneWidget,
      );
    },
  );

  testWidgets('sépare chaque section par un Divider (7 séparateurs pour '
      '8 sections, jamais après la dernière)', (tester) async {
    await _pumpScreen(tester);

    expect(find.byType(Divider), findsNWidgets(7));
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
