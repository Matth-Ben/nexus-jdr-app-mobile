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

/// Même route `/profile/help/faq` que `appRouter` (`core/router/app_router.dart`,
/// builder reproduit à l'identique) — isolée ici (plutôt qu'un accès direct à
/// `appRouter`, qui dépend d'un `SupabaseClient` réel, même rationale que
/// `_buildJoinRoutesTestRouter`) pour vérifier que `int.tryParse` protège
/// bien le builder contre un `?question=` malformé (non-régression suggérée
/// en revue de code : `int.parse` aurait levé une `FormatException` non
/// rattrapée pour une valeur non numérique).
GoRouter _buildFaqRouteTestRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/profile/help/faq',
        builder: (context, state) {
          final question = state.uri.queryParameters['question'];
          return Scaffold(
            body: Center(
              child: Text(
                'FAQ id=${question == null ? null : int.tryParse(question)}',
              ),
            ),
          );
        },
      ),
    ],
  );
}

void main() {
  group('route /profile/help/faq : ?question= malformé ne fait jamais '
      'planter le builder', () {
    testWidgets('?question=abc (non numérique) résout la route sans '
        'exception, id considéré absent (comme sans query)', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _buildFaqRouteTestRouter(
            '/profile/help/faq?question=abc',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FAQ id=null'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('?question=3 (numérique) résout bien l\'id attendu', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: _buildFaqRouteTestRouter(
            '/profile/help/faq?question=3',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FAQ id=3'), findsOneWidget);
    });
  });

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

    group('/p/* (vue en lecture seule d\'un personnage partagé) : jamais '
        'derrière le mur d\'authentification', () {
      test('non connecté sur /p/{token} ne redirige pas vers /login', () {
        expect(
          computeAuthRedirect(isLoggedIn: false, location: '/p/abc123'),
          isNull,
        );
      });

      test('connecté sur /p/{token} ne redirige pas non plus', () {
        expect(
          computeAuthRedirect(isLoggedIn: true, location: '/p/abc123'),
          isNull,
        );
      });

      test('connecté, needsOnboarding vrai, sur /p/{token} : ne redirige '
          'toujours pas vers /onboarding (exempté avant même d\'atteindre ce '
          'bloc)', () {
        expect(
          computeAuthRedirect(
            isLoggedIn: true,
            location: '/p/abc123',
            needsOnboarding: true,
          ),
          isNull,
        );
      });
    });

    group('gate d\'onboarding (needsOnboarding)', () {
      test('needsOnboarding par défaut (omis) : aucune redirection ajoutée, '
          'comportement inchangé pour tout appelant existant', () {
        expect(computeAuthRedirect(isLoggedIn: true, location: '/'), isNull);
      });

      test('non connecté, needsOnboarding vrai : reste prioritairement renvoyé '
          'vers /login (le bloc onboarding n\'est jamais évalué avant '
          'd\'être connecté)', () {
        expect(
          computeAuthRedirect(
            isLoggedIn: false,
            location: '/',
            needsOnboarding: true,
          ),
          '/login',
        );
      });

      test('connecté, needsOnboarding vrai, sur "/" : redirigé vers '
          '/onboarding', () {
        expect(
          computeAuthRedirect(
            isLoggedIn: true,
            location: '/',
            needsOnboarding: true,
          ),
          '/onboarding',
        );
      });

      test('connecté, needsOnboarding vrai, déjà sur /onboarding : ne redirige '
          'pas (pas de boucle)', () {
        expect(
          computeAuthRedirect(
            isLoggedIn: true,
            location: '/onboarding',
            needsOnboarding: true,
          ),
          isNull,
        );
      });

      test('connecté, needsOnboarding faux (déjà vu), sur "/" : ne redirige '
          'pas vers /onboarding', () {
        expect(
          computeAuthRedirect(
            isLoggedIn: true,
            location: '/',
            needsOnboarding: false,
          ),
          isNull,
        );
      });

      test('connecté, needsOnboarding vrai, sur un deep link /join/{code} : '
          'exempté, ne redirige jamais vers /onboarding (rationale : un lien '
          'd\'invitation MJ→joueur ne doit jamais être retardé par le '
          'tutoriel, voir la doc de classe de `computeAuthRedirect`)', () {
        expect(
          computeAuthRedirect(
            isLoggedIn: true,
            location: '/join/AB3F7K',
            needsOnboarding: true,
          ),
          isNull,
        );
      });

      test('connecté, needsOnboarding vrai, sur /join/step-2?code=... : '
          'exempté lui aussi (préfixe /join couvre toutes les étapes du '
          'flux)', () {
        expect(
          computeAuthRedirect(
            isLoggedIn: true,
            location: '/join/step-2?code=AB3F7K',
            needsOnboarding: true,
          ),
          isNull,
        );
      });

      test('connecté, needsOnboarding vrai, sur une route normale quelconque '
          '(ex. /groups) : redirigé vers /onboarding', () {
        expect(
          computeAuthRedirect(
            isLoggedIn: true,
            location: '/groups',
            needsOnboarding: true,
          ),
          '/onboarding',
        );
      });

      test('connecté, needsOnboarding vrai, sur un deep link /join/{code} avec '
          'une query string (ex. /join/ABC123?foo=bar) : toujours exempté - '
          '`startsWith(\'/join\')` ne depend pas de la presence ni du contenu '
          'd\'une query', () {
        expect(
          computeAuthRedirect(
            isLoggedIn: true,
            location: '/join/ABC123?foo=bar',
            needsOnboarding: true,
          ),
          isNull,
        );
      });

      test('non connecté, needsOnboarding vrai, sur un deep link protégé '
          '(/join/AB3F7K) : needsOnboarding n\'interfère pas avec la reprise '
          'du parcours après connexion, la destination reste encodée en '
          '?redirect= exactement comme needsOnboarding=false', () {
        expect(
          computeAuthRedirect(
            isLoggedIn: false,
            location: '/join/AB3F7K',
            needsOnboarding: true,
          ),
          '/login?redirect=%2Fjoin%2FAB3F7K',
        );
      });

      test('connecté, needsOnboarding vrai, sur /login (sans ?redirect=) : un '
          'SEUL appel à `computeAuthRedirect` renvoie "/" (pas "/onboarding" '
          'directement) - le bloc `isOnLoginRoute` de la fonction retourne '
          'avant d\'atteindre le bloc `needsOnboarding` ; voir le test de la '
          'chaîne de redirections ci-dessous pour la destination FINALE '
          'réellement atteinte par `go_router` (qui ré-évalue `redirect` sur '
          'chaque nouvelle location jusqu\'à obtenir `null`, voir '
          '`go_router-18.0.0/lib/src/configuration.dart::applyTopLegacyRedirect`)', () {
        expect(
          computeAuthRedirect(
            isLoggedIn: true,
            location: '/login',
            needsOnboarding: true,
          ),
          '/',
        );
      });

      test('connecté, needsOnboarding vrai, sur /login : la CHAÎNE complète de '
          'redirections (telle que `go_router` la ré-évalue réellement, pas '
          'un seul appel isolé) atteint bien /onboarding, pas juste "/" - '
          '/login -> "/" -> "/onboarding" -> null', () {
        final destination = _followRedirectChain(
          isLoggedIn: true,
          initialLocation: '/login',
          needsOnboarding: true,
        );

        expect(destination, '/onboarding');
      });
    });
  });
}

/// Simule la boucle réelle de `go_router` (`GoRouter.redirect` /
/// `applyTopLegacyRedirect`, voir `go_router-18.0.0/lib/src/configuration
/// .dart`) : ré-applique [computeAuthRedirect] sur chaque nouvelle location
/// jusqu'à ce qu'elle renvoie `null`, et renvoie la destination finale
/// effectivement atteinte. `computeAuthRedirect` seul (un appel isolé) ne
/// renvoie que la PROCHAINE étape de la chaîne (ex. "/" depuis "/login"),
/// jamais la destination finale si plusieurs redirections s'enchaînent -
/// c'est exactement ce que ce test reproduit pour ne pas confondre un
/// comportement intermédiaire correct avec une régression.
///
/// Un garde-fou (`maxHops`) fait échouer le test plutôt que boucler
/// indéfiniment si jamais une régression introduisait un cycle - `go_router`
/// lui-même lève une exception ('redirect loop detected'/'too many
/// redirects') dans ce cas (voir `_addRedirect` du fichier cité ci-dessus).
String _followRedirectChain({
  required bool isLoggedIn,
  required String initialLocation,
  bool needsOnboarding = false,
  int maxHops = 5,
}) {
  var location = initialLocation;
  for (var hop = 0; hop < maxHops; hop++) {
    final next = computeAuthRedirect(
      isLoggedIn: isLoggedIn,
      location: location,
      needsOnboarding: needsOnboarding,
    );
    if (next == null) return location;
    location = next;
  }
  fail(
    'redirect loop detected (pas de null après $maxHops redirections, '
    'dernière location : "$location")',
  );
}
