// Tests de l'écran "Aide et support"
// (`presentation/profile_help_screen.dart`) :
// - tests de widget : bandeau bois + retour, les 3 tuiles (icônes dédiées)
//   et le `SnackBar` "Bientôt disponible" des 2 tuiles placeholder
//   ("FAQ / Centre d'aide", "Mentions légales / CGU").
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
// Aucune donnée à charger à l'ouverture de l'écran (100% synchrone) : pas de
// provider à overrider, contrairement à `profile_privacy_screen_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/features/profile/presentation/profile_help_screen.dart';

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
          ],
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('affiche le bandeau bois et les 3 tuiles avec leurs icônes '
      'dédiées', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('AIDE ET SUPPORT'), findsOneWidget);
    for (final label in const [
      'FAQ / Centre d\'aide',
      'Contacter le support',
      'Mentions légales / CGU',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    expect(find.byIcon(Icons.gavel_outlined), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
  });

  for (final label in const [
    'FAQ / Centre d\'aide',
    'Mentions légales / CGU',
  ]) {
    testWidgets('taper "$label" affiche le SnackBar "Bientôt disponible"', (
      tester,
    ) async {
      await _pumpScreen(tester);

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(find.text('Bientôt disponible'), findsOneWidget);
    });
  }

  testWidgets('le bandeau bois propose un retour fonctionnel', (tester) async {
    await _pumpScreen(tester);
    expect(find.text('Ouvrir'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir'), findsOneWidget);
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
