import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/router/app_router.dart';

/// Mêmes 4 routes `/join*` que `appRouter` (`core/router/app_router.dart`),
/// dans le même ordre de déclaration — reproduites ici (plutôt qu'un accès
/// direct à `appRouter`, qui dépend d'un `SupabaseClient` réel) pour vérifier
/// que `/join/:code` (segment dynamique, point d'entrée du deep link
/// universel) ne "avale" jamais `/join/step-2`/`/join/step-3` (segments
/// statiques) — non-régression suggérée en revue de code (vérifiée
/// manuellement comme non buguée à l'introduction du flux, mais jamais
/// testée jusqu'ici).
GoRouter _buildJoinRoutesTestRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/join',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Étape 1 code=${state.uri.queryParameters['code']}'),
          ),
        ),
      ),
      GoRoute(
        path: '/join/step-2',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Étape 2 code=${state.uri.queryParameters['code']}'),
          ),
        ),
      ),
      GoRoute(
        path: '/join/step-3',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Étape 3 code=${state.uri.queryParameters['code']}'),
          ),
        ),
      ),
      GoRoute(
        path: '/join/:code',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Deep link code=${state.pathParameters['code']}'),
          ),
        ),
      ),
    ],
  );
}

void main() {
  group('routes /join* : /join/:code (deep link) ne masque jamais /join/step-2 '
      'et /join/step-3 (segments statiques)', () {
    testWidgets('/join/step-2?code=AB3F7K résout la route statique '
        'étape 2/4, pas /join/:code', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _buildJoinRoutesTestRouter('/join/step-2?code=AB3F7K'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Étape 2 code=AB3F7K'), findsOneWidget);
      expect(find.textContaining('Deep link'), findsNothing);
    });

    testWidgets('/join/step-3?code=AB3F7K résout la route statique '
        'étape 3/4, pas /join/:code', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _buildJoinRoutesTestRouter('/join/step-3?code=AB3F7K'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Étape 3 code=AB3F7K'), findsOneWidget);
      expect(find.textContaining('Deep link'), findsNothing);
    });

    testWidgets(
      '/join/AB3F7K (deep link universel) résout bien /join/:code, avec '
      'le code extrait du segment de chemin',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: _buildJoinRoutesTestRouter('/join/AB3F7K'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Deep link code=AB3F7K'), findsOneWidget);
      },
    );
  });

  group('computeAuthRedirect', () {
    test('non connecté sur "/" est renvoyé vers /login (sans ?redirect=)', () {
      expect(computeAuthRedirect(isLoggedIn: false, location: '/'), '/login');
    });

    test('non connecté déjà sur /login reste sur /login (pas de boucle)', () {
      expect(
        computeAuthRedirect(isLoggedIn: false, location: '/login'),
        isNull,
      );
    });

    test('connecté sur /login (sans ?redirect=) est renvoyé vers /', () {
      expect(computeAuthRedirect(isLoggedIn: true, location: '/login'), '/');
    });

    test('connecté sur une route normale ne redirige pas', () {
      expect(computeAuthRedirect(isLoggedIn: true, location: '/'), isNull);
    });

    group('reprise du parcours après connexion (deep link)', () {
      test('non connecté sur une route protégée non triviale (ex. deep link '
          '"Rejoindre une histoire") est renvoyé vers /login avec la '
          'destination encodée en ?redirect=', () {
        expect(
          computeAuthRedirect(isLoggedIn: false, location: '/join/AB3F7K'),
          '/login?redirect=%2Fjoin%2FAB3F7K',
        );
      });

      test('préserve aussi les paramètres de query de la destination visée '
          '(ex. /join/step-2?code=...)', () {
        expect(
          computeAuthRedirect(
            isLoggedIn: false,
            location: '/join/step-2?code=AB3F7K',
          ),
          '/login?redirect=%2Fjoin%2Fstep-2%3Fcode%3DAB3F7K',
        );
      });

      test('connecté sur /login?redirect=... est renvoyé vers la destination '
          'décodée, pas vers "/"', () {
        expect(
          computeAuthRedirect(
            isLoggedIn: true,
            location: '/login?redirect=%2Fjoin%2FAB3F7K',
          ),
          '/join/AB3F7K',
        );
      });

      test('connecté sur /login?redirect=... avec query imbriquée est '
          'renvoyé vers la destination complète, query comprise', () {
        expect(
          computeAuthRedirect(
            isLoggedIn: true,
            location: '/login?redirect=%2Fjoin%2Fstep-2%3Fcode%3DAB3F7K',
          ),
          '/join/step-2?code=AB3F7K',
        );
      });

      test('un caractère spécial (`#`/`&`) dans le code d\'invitation ne '
          'casse jamais la destination encodée (round-trip complet)', () {
        const original = '/join/AB#F&K';

        final toLogin = computeAuthRedirect(
          isLoggedIn: false,
          location: original,
        )!;
        final backToOriginal = computeAuthRedirect(
          isLoggedIn: true,
          location: toLogin,
        );

        expect(backToOriginal, original);
      });
    });
  });
}
