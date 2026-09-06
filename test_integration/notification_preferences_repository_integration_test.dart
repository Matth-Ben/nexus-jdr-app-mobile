import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/profile/data/notification_preferences_repository.dart';
import 'package:personnages/features/profile/domain/notification_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/test_environment.dart';

/// Test d'intégration de `SupabaseNotificationPreferencesRepository` contre
/// un vrai stack Supabase local (voir `test_integration/README.md`) : la
/// table `notification_preferences` (chantier "Notifications" —
/// `docs/cahier-des-charges/15-profil-parametres.md` section 3) n'a jamais
/// de ligne créée à l'inscription (voir la doc de classe de
/// `NotificationPreferences`) — ce fichier vérifie la vraie policy RLS
/// (`user_id = auth.uid()`) et le comportement d'upsert **partiel** reconstruit
/// côté client (`fetch` + `copyWith` + `upsert` complet, voir la doc de
/// classe du repository), jamais exercés par un double factice.
void main() {
  group('SupabaseNotificationPreferencesRepository (intégration)', () {
    late SupabaseClient client;
    late SupabaseNotificationPreferencesRepository repository;

    setUpAll(() async {
      client = createTestSupabaseClient();
      await signUpTestUser(client);
      repository = SupabaseNotificationPreferencesRepository(client);
    });

    test(
      'fetch() sans ligne existante retourne NotificationPreferences.defaults',
      () async {
        final prefs = await repository.fetch();

        expect(prefs, const NotificationPreferences.defaults());
      },
    );

    test('update() avec un seul paramètre crée la ligne avec les défauts pour '
        'les autres colonnes', () async {
      final prefs = await repository.update(pushEnabled: false);

      expect(prefs.pushEnabled, isFalse);
      expect(prefs.pushRestReminder, isTrue);
      expect(prefs.pushAccessRevoked, isTrue);
      expect(prefs.emailDigestEnabled, isFalse);

      final refetched = await repository.fetch();
      expect(refetched, prefs);
    });

    test('update() partiel : ne modifie que le(s) paramètre(s) nommé(s), '
        'préserve les autres colonnes déjà enregistrées (jamais un `UPDATE` '
        'qui réinitialiserait la ligne aux défauts)', () async {
      await repository.update(
        pushEnabled: false,
        pushRestReminder: false,
        emailDigestEnabled: true,
      );

      final updated = await repository.update(pushAccessRevoked: false);

      expect(updated.pushEnabled, isFalse);
      expect(updated.pushRestReminder, isFalse);
      expect(updated.pushAccessRevoked, isFalse);
      expect(updated.emailDigestEnabled, isTrue);
    });

    group('isolation cross-utilisateur (RLS + filtre user_id)', () {
      // Chaque ligne `notification_preferences` est scopée par `user_id`
      // (clé primaire) et lue/écrite exclusivement via `auth.uid()` (voir
      // `_requireOwnerId` du repository) — contrairement à `characters`
      // (`character_detail_repository_integration_test.dart`), il n'existe
      // pas d'identifiant de ressource à passer en paramètre pour viser la
      // ligne d'un autre joueur : le risque à couvrir est plutôt qu'un
      // deuxième utilisateur ne voie/modifie jamais accidentellement la
      // ligne du premier en lisant/écrivant depuis sa propre session.
      late SupabaseClient otherClient;
      late SupabaseNotificationPreferencesRepository otherRepository;

      setUpAll(() async {
        otherClient = createTestSupabaseClient();
        await signUpTestUser(otherClient);
        otherRepository = SupabaseNotificationPreferencesRepository(
          otherClient,
        );
      });

      test('les préférences enregistrées par un joueur ne sont jamais visibles '
          'ni modifiées par un autre', () async {
        // `pushAccessRevoked: true` fixé explicitement ici (plutôt que de
        // compter sur le défaut) : la ligne de ce premier joueur a déjà été
        // modifiée par les tests précédents de ce fichier (même `client`/
        // `repository`, jamais réinitialisés entre tests), donc son état
        // avant cet appel n'est pas garanti.
        await repository.update(
          pushEnabled: false,
          pushAccessRevoked: true,
          emailDigestEnabled: true,
        );

        // Un second joueur, qui n'a encore rien enregistré, ne voit que
        // les défauts — jamais la ligne du premier joueur.
        final otherPrefsBefore = await otherRepository.fetch();
        expect(otherPrefsBefore, const NotificationPreferences.defaults());

        // Le second joueur enregistre ses propres préférences...
        final otherPrefsAfter = await otherRepository.update(
          pushEnabled: true,
          pushAccessRevoked: false,
        );
        expect(otherPrefsAfter.pushEnabled, isTrue);
        expect(otherPrefsAfter.pushAccessRevoked, isFalse);

        // ...sans jamais affecter la ligne du premier joueur.
        final firstPrefsAfter = await repository.fetch();
        expect(firstPrefsAfter.pushEnabled, isFalse);
        expect(firstPrefsAfter.emailDigestEnabled, isTrue);
        expect(firstPrefsAfter.pushAccessRevoked, isTrue);
      });
    });
  });
}
