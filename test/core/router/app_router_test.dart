import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/router/app_router.dart';

void main() {
  group('computeAuthRedirect', () {
    test('non connecté sur une route protégée est renvoyé vers /login', () {
      expect(
        computeAuthRedirect(isLoggedIn: false, matchedLocation: '/'),
        '/login',
      );
    });

    test('non connecté déjà sur /login reste sur /login (pas de boucle)', () {
      expect(
        computeAuthRedirect(isLoggedIn: false, matchedLocation: '/login'),
        isNull,
      );
    });

    test('connecté sur /login est renvoyé vers /', () {
      expect(
        computeAuthRedirect(isLoggedIn: true, matchedLocation: '/login'),
        '/',
      );
    });

    test('connecté sur une route normale ne redirige pas', () {
      expect(
        computeAuthRedirect(isLoggedIn: true, matchedLocation: '/'),
        isNull,
      );
    });
  });
}
