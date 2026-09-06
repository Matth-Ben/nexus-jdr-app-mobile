// Tests de `NotificationPreferences` (`features/profile/domain/`) : valeurs
// par défaut (`defaults`/constructeur nu), et `fromRow` (parsing d'une ligne
// PostgREST `notification_preferences`, avec filet de valeurs par défaut si
// une colonne venait à manquer).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/profile/domain/notification_preferences.dart';

void main() {
  group('NotificationPreferences.defaults', () {
    test('pushEnabled/pushRestReminder/pushAccessRevoked à true, '
        'emailDigestEnabled à false', () {
      const prefs = NotificationPreferences.defaults();

      expect(prefs.pushEnabled, isTrue);
      expect(prefs.pushRestReminder, isTrue);
      expect(prefs.pushAccessRevoked, isTrue);
      expect(prefs.emailDigestEnabled, isFalse);
    });

    test('équivalent au constructeur nu', () {
      expect(
        const NotificationPreferences.defaults(),
        const NotificationPreferences(),
      );
    });
  });

  group('NotificationPreferences.fromRow', () {
    test('lit chaque colonne telle quelle', () {
      final prefs = NotificationPreferences.fromRow(const {
        'push_enabled': false,
        'push_rest_reminder': false,
        'push_access_revoked': true,
        'email_digest_enabled': true,
      });

      expect(prefs.pushEnabled, isFalse);
      expect(prefs.pushRestReminder, isFalse);
      expect(prefs.pushAccessRevoked, isTrue);
      expect(prefs.emailDigestEnabled, isTrue);
    });

    test('colonne manquante : filet de valeur par défaut pour cette colonne '
        'seulement', () {
      final prefs = NotificationPreferences.fromRow(const {
        'push_enabled': false,
      });

      expect(prefs.pushEnabled, isFalse);
      expect(prefs.pushRestReminder, isTrue);
      expect(prefs.pushAccessRevoked, isTrue);
      expect(prefs.emailDigestEnabled, isFalse);
    });

    test('ligne vide : équivalent à `defaults`', () {
      expect(
        NotificationPreferences.fromRow(const {}),
        const NotificationPreferences.defaults(),
      );
    });
  });

  group('NotificationPreferences.copyWith', () {
    test('ne modifie que les champs nommés non-null', () {
      const prefs = NotificationPreferences.defaults();

      final updated = prefs.copyWith(pushEnabled: false);

      expect(updated.pushEnabled, isFalse);
      expect(updated.pushRestReminder, isTrue);
      expect(updated.pushAccessRevoked, isTrue);
      expect(updated.emailDigestEnabled, isFalse);
    });
  });

  group('NotificationPreferences.==', () {
    test('deux instances aux mêmes valeurs sont égales', () {
      const a = NotificationPreferences(
        pushEnabled: false,
        pushRestReminder: true,
        pushAccessRevoked: false,
        emailDigestEnabled: true,
      );
      const b = NotificationPreferences(
        pushEnabled: false,
        pushRestReminder: true,
        pushAccessRevoked: false,
        emailDigestEnabled: true,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('une valeur différente rend les instances distinctes', () {
      const a = NotificationPreferences.defaults();
      const b = NotificationPreferences(emailDigestEnabled: true);

      expect(a, isNot(b));
    });
  });
}
