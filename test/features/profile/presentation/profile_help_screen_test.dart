// Tests de l'écran "Aide et support"
// (`presentation/profile_help_screen.dart`) :
// - tests de widget : bandeau bois + retour, les 3 en-têtes de section
//   ("QUESTIONS FRÉQUENTES"/"NOUS CONTACTER"/"À PROPOS"), les 3 cartes
//   `SettingsListCard` regroupant leurs tuiles (icônes dédiées), la
//   navigation des 5 tuiles qui poussent désormais un écran réel (3
//   questions FAQ + "Voir toutes les questions" vers `ProfileFaqScreen`,
//   "Mentions légales / CGU" vers `ProfileLegalScreen`, "Crédits & licences"
//   vers `ProfileCreditsScreen`), l'ouverture de la sheet "SIGNALER UN BUG"
//   (déplacée ici depuis le hub `profile_screen.dart`, voir sa doc de
//   classe), les 2 textes d'aide sous "NOUS CONTACTER"/"À PROPOS", le pied
//   de page version.
// - tests unitaires de [buildSupportEmailUri] (adresse/sujet/corps du
//   message) — même fichier que les tests de widget de l'écran qui
//   l'utilise, même organisation que `computeAuthRedirect` dans
//   `test/core/router/app_router_test.dart`.
//
// "Contacter le support" n'est volontairement jamais tapée dans les tests de
// widget ci-dessous : elle déclenche `PackageInfo.fromPlatform()` puis
// `canLaunchUrl`/`launchUrl` (`url_launcher`), tous deux dépendants d'un
// canal de plateforme natif non mocké ici — la construction de l'e-mail
// (adresse/sujet/corps) est testée séparément et de façon pure via
// [buildSupportEmailUri], sans jamais passer par `launchUrl`.
//
// Aucune donnée à charger à l'ouverture de l'écran (100% synchrone en dehors
// du pied de page version) : pas de provider à overrider hormis
// `PackageInfo.setMockInitialValues` (canal de plateforme natif lu par
// `packageInfoProvider`, même mécanisme que `profile_screen_test.dart`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/core/widgets/settings_list_card.dart';
import 'package:personnages/features/profile/presentation/profile_credits_screen.dart';
import 'package:personnages/features/profile/presentation/profile_faq_screen.dart';
import 'package:personnages/features/profile/presentation/profile_help_screen.dart';
import 'package:personnages/features/profile/presentation/profile_legal_screen.dart';

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => context.push('/profile/help'),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/profile/help',
              builder: (context, state) => const ProfileHelpScreen(),
            ),
            GoRoute(
              path: '/profile/help/legal',
              builder: (context, state) => const ProfileLegalScreen(),
            ),
            GoRoute(
              path: '/profile/help/credits',
              builder: (context, state) => const ProfileCreditsScreen(),
            ),
            GoRoute(
              path: '/profile/help/faq',
              builder: (context, state) {
                final question = state.uri.queryParameters['question'];
                return ProfileFaqScreen(
                  initialQuestionId: question == null
                      ? null
                      : int.parse(question),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Nexus JDR — Personnages',
      packageName: 'app.nexusjdr.personnages',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('affiche le bandeau bois et les 3 en-têtes de section', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.text('AIDE ET SUPPORT'), findsOneWidget);
    expect(find.text('QUESTIONS FRÉQUENTES'), findsOneWidget);
    expect(find.text('NOUS CONTACTER'), findsOneWidget);
    expect(find.text('À PROPOS'), findsOneWidget);
  });

  testWidgets('section "QUESTIONS FRÉQUENTES" : 3 questions + "Voir toutes les '
      'questions" (chevron par défaut, poussent un écran interne, pas '
      'l\'icône de lien externe), regroupées dans un SettingsListCard', (
    tester,
  ) async {
    await _pumpScreen(tester);

    for (final label in const [
      'Comment importer un personnage aidedd.org ?',
      'Comment rejoindre l\'histoire de mon MJ ?',
      'Mes personnages sont-ils sauvegardés hors ligne ?',
      'Voir toutes les questions',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byIcon(Icons.north_east), findsNothing);
  });

  for (final entry in const {
    'Comment importer un personnage aidedd.org ?': 1,
    'Comment rejoindre l\'histoire de mon MJ ?': 2,
    'Mes personnages sont-ils sauvegardés hors ligne ?': 3,
  }.entries) {
    testWidgets(
      'taper "${entry.key}" pousse ProfileFaqScreen en pré-ouvrant la '
      'question ${entry.value}',
      (tester) async {
        await _pumpScreen(tester);

        await tester.ensureVisible(find.text(entry.key));
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();

        expect(find.text('QUESTIONS FRÉQUENTES'), findsOneWidget);
        final screen = tester.widget<ProfileFaqScreen>(
          find.byType(ProfileFaqScreen),
        );
        expect(screen.initialQuestionId, entry.value);
      },
    );
  }

  testWidgets('taper "Voir toutes les questions" pousse ProfileFaqScreen sans '
      'pré-ouverture', (tester) async {
    await _pumpScreen(tester);

    await tester.ensureVisible(find.text('Voir toutes les questions'));
    await tester.tap(find.text('Voir toutes les questions'));
    await tester.pumpAndSettle();

    final screen = tester.widget<ProfileFaqScreen>(
      find.byType(ProfileFaqScreen),
    );
    expect(screen.initialQuestionId, isNull);
  });

  testWidgets('taper "Mentions légales / CGU" pousse l\'écran dédié', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.ensureVisible(find.text('Mentions légales / CGU'));
    await tester.tap(find.text('Mentions légales / CGU'));
    await tester.pumpAndSettle();

    expect(find.text('MENTIONS LÉGALES / CGU'), findsOneWidget);
    expect(find.byType(ProfileLegalScreen), findsOneWidget);
  });

  testWidgets('taper "Crédits & licences" pousse l\'écran dédié', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.ensureVisible(find.text('Crédits & licences'));
    await tester.tap(find.text('Crédits & licences'));
    await tester.pumpAndSettle();

    expect(find.text('CRÉDITS & LICENCES'), findsOneWidget);
    expect(find.byType(ProfileCreditsScreen), findsOneWidget);
  });

  testWidgets(
    'section "NOUS CONTACTER" : "Contacter le support" + "Signaler un bug" '
    'regroupées dans un SettingsListCard, avec leur texte d\'aide',
    (tester) async {
      await _pumpScreen(tester);

      expect(find.text('Contacter le support'), findsOneWidget);
      expect(find.text('Signaler un bug'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
      expect(
        find.text(
          'Réponse sous 48h en semaine. Un aperçu des infos techniques '
          "de l'appareil est joint automatiquement.",
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('taper "Signaler un bug" ouvre la sheet "SIGNALER UN BUG"', (
    tester,
  ) async {
    await _pumpScreen(tester);

    await tester.tap(find.text('Signaler un bug'));
    await tester.pumpAndSettle();

    expect(find.text('SIGNALER UN BUG'), findsOneWidget);
  });

  testWidgets(
    'section "À PROPOS" : "Mentions légales / CGU" + "Crédits & licences" '
    'regroupées dans un SettingsListCard, avec son texte d\'aide',
    (tester) async {
      await _pumpScreen(tester);

      expect(find.text('Mentions légales / CGU'), findsOneWidget);
      expect(find.text('Crédits & licences'), findsOneWidget);
      expect(find.byIcon(Icons.gavel_outlined), findsOneWidget);
      expect(find.byIcon(Icons.copyright_outlined), findsOneWidget);
      expect(
        find.text(
          'Contenu D&D 5e sous licence Open5e / SRD. Voir les crédits '
          'complets pour le détail des sources.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('les 3 sections sont bien regroupées dans 3 SettingsListCard', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.byType(SettingsListCard), findsNWidgets(3));
  });

  testWidgets('le bandeau bois propose un retour fonctionnel', (tester) async {
    await _pumpScreen(tester);
    expect(find.text('Ouvrir'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir'), findsOneWidget);
  });

  testWidgets('le pied de page affiche la version lue dynamiquement '
      '(`package_info_plus`, mockée ici via `setMockInitialValues`) — même '
      'mécanisme que `profile_screen.dart`', (tester) async {
    await _pumpScreen(tester);

    await tester.ensureVisible(find.text('Nexus JDR — Personnages · v1.0.0'));
    expect(find.text('Nexus JDR — Personnages · v1.0.0'), findsOneWidget);
  });

  group('buildSupportEmailUri', () {
    PackageInfo packageInfo({
      String version = '1.2.3',
      String buildNumber = '42',
    }) {
      return PackageInfo(
        appName: 'Nexus JDR — Personnages',
        packageName: 'app.nexusjdr.personnages',
        version: version,
        buildNumber: buildNumber,
      );
    }

    test('adresse et sujet fixes du contrat "Contacter le support"', () {
      final uri = buildSupportEmailUri(packageInfo());

      expect(uri.scheme, 'mailto');
      expect(uri.path, supportEmailAddress);
      expect(uri.path, 'support@nexus-jdr.app');
      expect(uri.queryParameters['subject'], 'Support Nexus JDR — Personnages');
    });

    // Régression : `Uri(queryParameters: {...})` encode les espaces en `+`
    // (convention `application/x-www-form-urlencoded`), que le schéma
    // `mailto:` (RFC 6068) ne traite PAS comme équivalent de l'espace — de
    // nombreux clients mail (Gmail Android, Apple Mail) afficheraient alors
    // un `+` littéral à la place de chaque espace du sujet/corps.
    // `uri.queryParameters['subject']`/`['body']` redécode via ce même
    // mécanisme symétrique (`+` → espace) : un round-trip cohérent en
    // interne, mais qui ne reflète pas ce qu'un client mail tiers reçoit
    // réellement. On inspecte donc ici la chaîne brute (`uri.query`) plutôt
    // que l'accesseur `queryParameters`.
    test('encode les espaces du sujet/corps en %20, jamais en + littéral', () {
      final uri = buildSupportEmailUri(packageInfo());

      expect(uri.query, isNot(contains('+')));
      expect(uri.query, contains(Uri.encodeComponent('Support Nexus JDR')));
      expect(uri.query, contains('Support%20Nexus%20JDR'));
    });

    test('le corps du message commence par "Bonjour," et contient la '
        'version/le build number, sans régresser accents/sauts de ligne', () {
      final uri = buildSupportEmailUri(
        packageInfo(version: '1.2.3', buildNumber: '42'),
      );
      final body = uri.queryParameters['body']!;

      expect(body, startsWith('Bonjour,'));
      expect(body, contains('Version : v1.2.3 (build 42)'));
      expect(body, contains('\n'));
      expect(body, contains('é'));
      expect(body, contains('è'));
    });
  });
}
