import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/auth/domain/auth_validators.dart';

void main() {
  group('AuthValidators.email', () {
    test('rejette une valeur vide', () {
      expect(AuthValidators.email(''), isNotNull);
    });

    test('rejette une valeur composée uniquement d\'espaces', () {
      expect(AuthValidators.email('   '), isNotNull);
    });

    test('rejette un format invalide (pas de @)', () {
      expect(AuthValidators.email('pas-un-email'), isNotNull);
    });

    test('rejette un format invalide (pas de domaine)', () {
      expect(AuthValidators.email('nom@'), isNotNull);
    });

    test('rejette un domaine sans point (pas de TLD)', () {
      expect(AuthValidators.email('nom@exemplecom'), isNotNull);
    });

    test('rejette une valeur avec un espace interne', () {
      expect(AuthValidators.email('nom exemple@test.com'), isNotNull);
    });

    test('rejette une valeur avec un double @', () {
      expect(AuthValidators.email('nom@@exemple.com'), isNotNull);
    });

    test('accepte une adresse valide', () {
      expect(AuthValidators.email('nom@exemple.com'), isNull);
    });

    test('accepte une adresse valide entourée d\'espaces (trim)', () {
      expect(AuthValidators.email('  nom@exemple.com  '), isNull);
    });
  });

  group('AuthValidators.password', () {
    test('rejette une valeur vide', () {
      expect(AuthValidators.password(''), isNotNull);
    });

    test('rejette un mot de passe trop court', () {
      expect(AuthValidators.password('abc'), isNotNull);
    });

    test('rejette un mot de passe juste en dessous de la longueur minimale '
        '(frontière)', () {
      final tooShort = 'a' * (AuthValidators.minPasswordLength - 1);
      expect(AuthValidators.password(tooShort), isNotNull);
    });

    test('accepte un mot de passe exactement à la longueur minimale '
        '(frontière)', () {
      final exact = 'a' * AuthValidators.minPasswordLength;
      expect(AuthValidators.password(exact), isNull);
    });

    test('accepte un mot de passe de longueur suffisante', () {
      expect(AuthValidators.password('abcdef'), isNull);
    });
  });

  group('AuthValidators.passwordConfirmation', () {
    test('rejette une valeur vide', () {
      expect(AuthValidators.passwordConfirmation('', 'abcdef'), isNotNull);
    });

    test('rejette une valeur différente du mot de passe', () {
      expect(
        AuthValidators.passwordConfirmation('autrechose', 'abcdef'),
        isNotNull,
      );
    });

    test('rejette une valeur qui ne diffère que par la casse', () {
      expect(
        AuthValidators.passwordConfirmation('ABCDEF', 'abcdef'),
        isNotNull,
      );
    });

    test('accepte une valeur identique au mot de passe', () {
      expect(AuthValidators.passwordConfirmation('abcdef', 'abcdef'), isNull);
    });
  });
}
