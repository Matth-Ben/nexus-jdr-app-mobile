import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/auth/data/auth_error_mapper.dart';
import 'package:personnages/features/auth/domain/auth_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapAuthException', () {
    test('identifiants incorrects (via code) -> message dédié et code '
        'AuthErrorCode.invalidCredentials', () {
      const error = AuthException(
        'Invalid login credentials',
        code: 'invalid_credentials',
      );

      final failure = mapAuthException(error);
      expect(failure.message, 'Adresse e-mail ou mot de passe incorrect.');
      expect(failure.code, AuthErrorCode.invalidCredentials);
    });

    test('identifiants incorrects (via message, sans code) -> message dédié et '
        'code AuthErrorCode.invalidCredentials', () {
      const error = AuthException('Invalid login credentials');

      final failure = mapAuthException(error);
      expect(failure.message, 'Adresse e-mail ou mot de passe incorrect.');
      expect(failure.code, AuthErrorCode.invalidCredentials);
    });

    test('e-mail déjà utilisé (email_exists) -> message dédié et code '
        'AuthErrorCode.emailAlreadyExists', () {
      const error = AuthException(
        'A user with this email address has already been registered',
        code: 'email_exists',
      );

      final failure = mapAuthException(error);
      expect(
        failure.message,
        'Un compte existe déjà avec cette adresse e-mail.',
      );
      expect(failure.code, AuthErrorCode.emailAlreadyExists);
    });

    test('e-mail déjà utilisé (user_already_exists) -> message dédié et code '
        'AuthErrorCode.emailAlreadyExists', () {
      const error = AuthException(
        'User already registered',
        code: 'user_already_exists',
      );

      final failure = mapAuthException(error);
      expect(
        failure.message,
        'Un compte existe déjà avec cette adresse e-mail.',
      );
      expect(failure.code, AuthErrorCode.emailAlreadyExists);
    });

    test('e-mail déjà utilisé (identity_already_exists) -> message dédié et '
        'code AuthErrorCode.emailAlreadyExists', () {
      const error = AuthException(
        'Identity already exists',
        code: 'identity_already_exists',
      );

      final failure = mapAuthException(error);
      expect(
        failure.message,
        'Un compte existe déjà avec cette adresse e-mail.',
      );
      expect(failure.code, AuthErrorCode.emailAlreadyExists);
    });

    test('e-mail déjà utilisé (via message "already registered", sans code) '
        '-> message dédié et code AuthErrorCode.emailAlreadyExists', () {
      // Message historique exact renvoyé par GoTrue quand le code n'est
      // pas renseigné (avant l'introduction des codes d'erreur stables).
      const error = AuthException('User already registered');

      final failure = mapAuthException(error);
      expect(
        failure.message,
        'Un compte existe déjà avec cette adresse e-mail.',
      );
      expect(failure.code, AuthErrorCode.emailAlreadyExists);
    });

    test('e-mail déjà utilisé (via message "has already been registered", '
        'sans code) -> message dédié et code '
        'AuthErrorCode.emailAlreadyExists', () {
      const error = AuthException(
        'A user with this email address has already been registered',
      );

      final failure = mapAuthException(error);
      expect(
        failure.message,
        'Un compte existe déjà avec cette adresse e-mail.',
      );
      expect(failure.code, AuthErrorCode.emailAlreadyExists);
    });

    test('mot de passe trop faible -> message dédié et code '
        'AuthErrorCode.weakPassword', () {
      const error = AuthException(
        'Password should be at least 6 characters',
        code: 'weak_password',
      );

      final failure = mapAuthException(error);
      expect(failure.message, contains('mot de passe'));
      expect(failure.code, AuthErrorCode.weakPassword);
    });

    test('e-mail non confirmé -> message dédié et code '
        'AuthErrorCode.emailNotConfirmed', () {
      const error = AuthException(
        'Email not confirmed',
        code: 'email_not_confirmed',
      );

      final failure = mapAuthException(error);
      expect(failure.message, contains('Confirmez votre adresse e-mail'));
      expect(failure.code, AuthErrorCode.emailNotConfirmed);
    });

    test('e-mail invalide côté serveur (validation_failed + "email" dans le '
        'message) -> message dédié et code AuthErrorCode.invalidEmail', () {
      const error = AuthException(
        'Unable to validate email address: invalid format',
        code: 'validation_failed',
      );

      final failure = mapAuthException(error);
      expect(failure.message, 'Adresse e-mail invalide.');
      expect(failure.code, AuthErrorCode.invalidEmail);
    });

    test('validation_failed sans "email" dans le message -> repli générique '
        '(pas de faux positif), code AuthErrorCode.generic', () {
      const error = AuthException(
        'Unable to validate request',
        code: 'validation_failed',
      );

      final failure = mapAuthException(error);
      expect(failure.message, isNot('Adresse e-mail invalide.'));
      expect(failure.code, AuthErrorCode.generic);
    });

    test('trop de tentatives (over_request_rate_limit) -> message dédié et '
        'code AuthErrorCode.tooManyRequests', () {
      const error = AuthException(
        'Rate limit exceeded',
        code: 'over_request_rate_limit',
      );

      final failure = mapAuthException(error);
      expect(
        failure.message,
        'Trop de tentatives. Réessayez dans quelques instants.',
      );
      expect(failure.code, AuthErrorCode.tooManyRequests);
    });

    test('trop de tentatives (over_email_send_rate_limit) -> message dédié et '
        'code AuthErrorCode.tooManyRequests', () {
      const error = AuthException(
        'Email rate limit exceeded',
        code: 'over_email_send_rate_limit',
      );

      final failure = mapAuthException(error);
      expect(
        failure.message,
        'Trop de tentatives. Réessayez dans quelques instants.',
      );
      expect(failure.code, AuthErrorCode.tooManyRequests);
    });

    test('code inconnu -> repli sur le message brut de Supabase, code '
        'AuthErrorCode.generic', () {
      const error = AuthException('Something went wrong', code: 'unknown_code');

      final failure = mapAuthException(error);
      expect(failure.message, 'Something went wrong');
      expect(failure.code, AuthErrorCode.generic);
    });

    test('pas de code ni de message -> message générique, code '
        'AuthErrorCode.generic', () {
      const error = AuthException('');

      final failure = mapAuthException(error);
      expect(failure.message, isNotEmpty);
      expect(failure.code, AuthErrorCode.generic);
    });

    test('AuthRetryableFetchException (échec avant réponse HTTP, ex. absence '
        'de réseau) -> même message que mapUnknownError, pas le message brut '
        "de l'exception Dart sous-jacente, et code AuthErrorCode.network", () {
      final error = AuthRetryableFetchException(
        message: 'Exception: Failed host lookup',
      );

      final failure = mapAuthException(error);
      expect(failure.message, mapUnknownError().message);
      expect(failure.code, AuthErrorCode.network);
    });
  });

  test('mapUnknownError renvoie un message réseau explicite et le code '
      'AuthErrorCode.network', () {
    final failure = mapUnknownError();
    expect(failure.message, contains('connexion internet'));
    expect(failure.code, AuthErrorCode.network);
  });

  // `AuthErrorCode.browserLaunchFailed` n'est volontairement pas couvert ici
  // : ce code n'est jamais produit par `mapAuthException`/`mapUnknownError`
  // (ce fichier), mais construit directement par
  // `SupabaseAuthRepository.signInWithGoogle` quand `url_launcher` ne peut
  // pas ouvrir le navigateur système — voir les tests dédiés dans
  // `test/features/auth/data/auth_repository_test.dart`
  // (groupe `SupabaseAuthRepository.signInWithGoogle`), qui vérifient déjà
  // ce `.code` précis.
}
