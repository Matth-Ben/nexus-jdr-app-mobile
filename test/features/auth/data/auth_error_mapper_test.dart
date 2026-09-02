import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/auth/data/auth_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapAuthException', () {
    test('identifiants incorrects (via code) -> message dédié', () {
      const error = AuthException(
        'Invalid login credentials',
        code: 'invalid_credentials',
      );

      expect(
        mapAuthException(error).message,
        'Adresse e-mail ou mot de passe incorrect.',
      );
    });

    test(
      'identifiants incorrects (via message, sans code) -> message dédié',
      () {
        const error = AuthException('Invalid login credentials');

        expect(
          mapAuthException(error).message,
          'Adresse e-mail ou mot de passe incorrect.',
        );
      },
    );

    test('e-mail déjà utilisé (email_exists) -> message dédié', () {
      const error = AuthException(
        'A user with this email address has already been registered',
        code: 'email_exists',
      );

      expect(
        mapAuthException(error).message,
        'Un compte existe déjà avec cette adresse e-mail.',
      );
    });

    test('e-mail déjà utilisé (user_already_exists) -> message dédié', () {
      const error = AuthException(
        'User already registered',
        code: 'user_already_exists',
      );

      expect(
        mapAuthException(error).message,
        'Un compte existe déjà avec cette adresse e-mail.',
      );
    });

    test('e-mail déjà utilisé (identity_already_exists) -> message dédié', () {
      const error = AuthException(
        'Identity already exists',
        code: 'identity_already_exists',
      );

      expect(
        mapAuthException(error).message,
        'Un compte existe déjà avec cette adresse e-mail.',
      );
    });

    test('e-mail déjà utilisé (via message "already registered", sans code) '
        '-> message dédié', () {
      // Message historique exact renvoyé par GoTrue quand le code n'est
      // pas renseigné (avant l'introduction des codes d'erreur stables).
      const error = AuthException('User already registered');

      expect(
        mapAuthException(error).message,
        'Un compte existe déjà avec cette adresse e-mail.',
      );
    });

    test('e-mail déjà utilisé (via message "has already been registered", '
        'sans code) -> message dédié', () {
      const error = AuthException(
        'A user with this email address has already been registered',
      );

      expect(
        mapAuthException(error).message,
        'Un compte existe déjà avec cette adresse e-mail.',
      );
    });

    test('mot de passe trop faible -> message dédié', () {
      const error = AuthException(
        'Password should be at least 6 characters',
        code: 'weak_password',
      );

      expect(mapAuthException(error).message, contains('mot de passe'));
    });

    test('e-mail non confirmé -> message dédié', () {
      const error = AuthException(
        'Email not confirmed',
        code: 'email_not_confirmed',
      );

      expect(
        mapAuthException(error).message,
        contains('Confirmez votre adresse e-mail'),
      );
    });

    test('e-mail invalide côté serveur (validation_failed + "email" dans le '
        'message) -> message dédié', () {
      const error = AuthException(
        'Unable to validate email address: invalid format',
        code: 'validation_failed',
      );

      expect(mapAuthException(error).message, 'Adresse e-mail invalide.');
    });

    test('validation_failed sans "email" dans le message -> repli générique '
        '(pas de faux positif)', () {
      const error = AuthException(
        'Unable to validate request',
        code: 'validation_failed',
      );

      expect(
        mapAuthException(error).message,
        isNot('Adresse e-mail invalide.'),
      );
    });

    test('trop de tentatives (over_request_rate_limit) -> message dédié', () {
      const error = AuthException(
        'Rate limit exceeded',
        code: 'over_request_rate_limit',
      );

      expect(
        mapAuthException(error).message,
        'Trop de tentatives. Réessayez dans quelques instants.',
      );
    });

    test(
      'trop de tentatives (over_email_send_rate_limit) -> message dédié',
      () {
        const error = AuthException(
          'Email rate limit exceeded',
          code: 'over_email_send_rate_limit',
        );

        expect(
          mapAuthException(error).message,
          'Trop de tentatives. Réessayez dans quelques instants.',
        );
      },
    );

    test('code inconnu -> repli sur le message brut de Supabase', () {
      const error = AuthException('Something went wrong', code: 'unknown_code');

      expect(mapAuthException(error).message, 'Something went wrong');
    });

    test('pas de code ni de message -> message générique', () {
      const error = AuthException('');

      expect(mapAuthException(error).message, isNotEmpty);
    });

    test(
      'AuthRetryableFetchException (échec avant réponse HTTP, ex. absence '
      'de réseau) -> même message que mapUnknownError, pas le message brut '
      "de l'exception Dart sous-jacente",
      () {
        final error = AuthRetryableFetchException(
          message: 'Exception: Failed host lookup',
        );

        expect(mapAuthException(error).message, mapUnknownError().message);
      },
    );
  });

  test('mapUnknownError renvoie un message réseau explicite', () {
    expect(mapUnknownError().message, contains('connexion internet'));
  });
}
