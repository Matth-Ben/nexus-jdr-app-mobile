import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/auth/domain/auth_validators.dart';
import 'package:personnages/l10n/app_localizations_en.dart';
import 'package:personnages/l10n/app_localizations_fr.dart';

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

  group('avec AppLocalizations fourni (branche migrée, voir la doc de '
      'classe de AuthValidators)', () {
    // Trou de couverture signalé par `qa-testeur` (chantier "traduction de
    // l'app" Phase B, lot "Auth") : jusqu'ici seul le repli français par
    // défaut (appel sans `l10n`, groupes ci-dessus) était couvert — aucun
    // test n'exerçait la branche qui résout réellement le message via
    // `AppLocalizations`, ni ne vérifiait que la langue effectivement
    // retournée correspond à l'instance passée (FR vs EN).
    final fr = AppLocalizationsFr();
    final en = AppLocalizationsEn();

    group('AuthValidators.email', () {
      test('valeur vide -> message localisé FR', () {
        expect(AuthValidators.email('', fr), 'Saisissez votre adresse e-mail.');
      });

      test('valeur vide -> message localisé EN', () {
        expect(AuthValidators.email('', en), 'Enter your email address.');
      });

      test('format invalide -> message localisé FR', () {
        expect(
          AuthValidators.email('pas-un-email', fr),
          'Adresse e-mail invalide.',
        );
      });

      test('format invalide -> message localisé EN', () {
        expect(
          AuthValidators.email('pas-un-email', en),
          'Invalid email address.',
        );
      });

      test('valeur valide -> aucun message (FR comme EN)', () {
        expect(AuthValidators.email('nom@exemple.com', fr), isNull);
        expect(AuthValidators.email('nom@exemple.com', en), isNull);
      });
    });

    group('AuthValidators.password', () {
      test('valeur vide -> message localisé FR', () {
        expect(
          AuthValidators.password('', fr),
          'Saisissez votre mot de passe.',
        );
      });

      test('valeur vide -> message localisé EN', () {
        expect(AuthValidators.password('', en), 'Enter your password.');
      });

      test('trop court -> message localisé FR avec la longueur minimale', () {
        expect(
          AuthValidators.password('abc', fr),
          'Le mot de passe doit contenir au moins '
          '${AuthValidators.minPasswordLength} caractères.',
        );
      });

      test('trop court -> message localisé EN avec la longueur minimale', () {
        expect(
          AuthValidators.password('abc', en),
          'Password must be at least '
          '${AuthValidators.minPasswordLength} characters long.',
        );
      });

      test('valeur valide -> aucun message (FR comme EN)', () {
        expect(AuthValidators.password('abcdef', fr), isNull);
        expect(AuthValidators.password('abcdef', en), isNull);
      });
    });

    group('AuthValidators.passwordConfirmation', () {
      test('valeur vide -> message localisé FR', () {
        expect(
          AuthValidators.passwordConfirmation('', 'abcdef', fr),
          'Confirmez votre mot de passe.',
        );
      });

      test('valeur vide -> message localisé EN', () {
        expect(
          AuthValidators.passwordConfirmation('', 'abcdef', en),
          'Confirm your password.',
        );
      });

      test('ne correspond pas -> message localisé FR', () {
        expect(
          AuthValidators.passwordConfirmation('autrechose', 'abcdef', fr),
          'Les mots de passe ne correspondent pas.',
        );
      });

      test('ne correspond pas -> message localisé EN', () {
        expect(
          AuthValidators.passwordConfirmation('autrechose', 'abcdef', en),
          "Passwords don't match.",
        );
      });

      test('valeur identique -> aucun message (FR comme EN)', () {
        expect(
          AuthValidators.passwordConfirmation('abcdef', 'abcdef', fr),
          isNull,
        );
        expect(
          AuthValidators.passwordConfirmation('abcdef', 'abcdef', en),
          isNull,
        );
      });
    });
  });
}
