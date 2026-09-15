// Tests de widget de l'écran "Profil" (`presentation/profile_screen.dart`) —
// avatar (statique/dynamique selon `user_metadata['avatar_url']`)/nom/e-mail
// (fallback "Aventurier" quand `user_metadata['full_name']` est absent/vide),
// bandeau "Compte lié à l'app Histoires", les 4 lignes de menu regroupées
// dans un `SettingsListCard` (navigation vers `ProfileEditScreen` pour
// "Modifier le profil", `ProfileNotificationsScreen` pour "Notifications",
// `ProfilePrivacyScreen` pour "Confidentialité et données",
// `ProfileHelpScreen` pour "Aide et support" — "Signaler un bug" a été
// retiré du hub au recettage direction-artistique du 13/09/2026, déplacé
// dans "Aide et support" dans une tâche suivante), bouton "Se déconnecter",
// pied de page version.
//
// `currentUserProvider`/`authRepositoryProvider` injectés via
// `overrideWithValue`, jamais `Supabase.instance.client` — même stratégie que
// `character_list_screen_test.dart`.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/settings_list_card.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/profile/data/notification_preferences_repository.dart';
import 'package:personnages/features/profile/domain/notification_preferences.dart';
import 'package:personnages/features/profile/presentation/profile_edit_screen.dart';
import 'package:personnages/features/profile/presentation/profile_help_screen.dart';
import 'package:personnages/features/profile/presentation/profile_notifications_screen.dart';
import 'package:personnages/features/profile/presentation/profile_privacy_screen.dart';
import 'package:personnages/features/profile/presentation/profile_screen.dart';
import 'package:personnages/features/profile/presentation/providers/notification_preferences_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Double minimal — seul `fetch` est exercé ici : cette suite ne fait que
/// vérifier que "Notifications" pousse bien `ProfileNotificationsScreen`,
/// jamais son contenu détaillé (couvert par
/// `profile_notifications_screen_test.dart`).
class _FakeNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  @override
  Future<NotificationPreferences> fetch() async =>
      const NotificationPreferences.defaults();

  @override
  Future<NotificationPreferences> update({
    bool? pushEnabled,
    bool? pushRestReminder,
    bool? pushAccessRevoked,
    bool? emailDigestEnabled,
  }) async => const NotificationPreferences.defaults();
}

class _FakeAuthRepository implements AuthRepository {
  int signOutCallCount = 0;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<bool> signUp({
    required String email,
    required String password,
  }) async => false;

  @override
  Future<void> signOut() async {
    signOutCallCount++;
  }

  @override
  Future<void> resetPasswordForEmail({required String email}) async {}

  @override
  Future<void> updateDisplayName({required String? displayName}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> updateEmail({required String newEmail}) async {}

  @override
  Future<String> updateAvatar({required Uint8List bytes}) async => '';

  @override
  Future<void> removeAvatar() async {}
}

class _AlwaysOnlineConnectivityChecker implements ConnectivityChecker {
  @override
  Future<bool> hasConnection() async => true;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}

User _fakeUser({
  String? fullName,
  String? avatarUrl,
  String email = 'joueur@exemple.com',
}) {
  return User(
    id: 'fake-user-id',
    appMetadata: const {},
    userMetadata: {'full_name': ?fullName, 'avatar_url': ?avatarUrl},
    aud: 'authenticated',
    email: email,
    createdAt: '2026-01-01T00:00:00Z',
  );
}

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Nexus JDR — Personnages',
      packageName: 'app.nexusjdr.personnages',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  late _FakeAuthRepository fakeAuthRepository;

  setUp(() {
    fakeAuthRepository = _FakeAuthRepository();
  });

  Widget buildTestWidget({required User? user}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(user),
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        connectivityCheckerProvider.overrideWithValue(
          _AlwaysOnlineConnectivityChecker(),
        ),
        notificationPreferencesRepositoryProvider.overrideWithValue(
          _FakeNotificationPreferencesRepository(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => context.push('/profile'),
                    child: const Text('Ouvrir le profil'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/profile/edit',
              builder: (context, state) => const ProfileEditScreen(),
            ),
            GoRoute(
              path: '/profile/privacy',
              builder: (context, state) => const ProfilePrivacyScreen(),
            ),
            GoRoute(
              path: '/profile/help',
              builder: (context, state) => const ProfileHelpScreen(),
            ),
            GoRoute(
              path: '/profile/notifications',
              builder: (context, state) => const ProfileNotificationsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pumpProfile(WidgetTester tester, {required User? user}) async {
    await tester.pumpWidget(buildTestWidget(user: user));
    await tester.tap(find.text('Ouvrir le profil'));
    await tester.pumpAndSettle();
  }

  testWidgets('affiche le nom (`user_metadata[\'full_name\']`) et l\'e-mail de '
      '`currentUserProvider`', (tester) async {
    await pumpProfile(
      tester,
      user: _fakeUser(
        fullName: 'Aranea Nightsong',
        email: 'aranea@exemple.com',
      ),
    );

    expect(find.text('PROFIL'), findsOneWidget);
    expect(find.text('Aranea Nightsong'), findsOneWidget);
    expect(find.text('aranea@exemple.com'), findsOneWidget);
  });

  testWidgets('affiche "Aventurier" quand `full_name` est absent — fallback '
      "d'affichage uniquement, jamais une valeur stockée", (tester) async {
    await pumpProfile(tester, user: _fakeUser());

    expect(find.text('Aventurier'), findsOneWidget);
  });

  testWidgets('affiche "Aventurier" quand `full_name` est une chaîne blanche', (
    tester,
  ) async {
    await pumpProfile(tester, user: _fakeUser(fullName: '   '));

    expect(find.text('Aventurier'), findsOneWidget);
  });

  testWidgets('affiche le bandeau "Compte lié à l\'app Histoires"', (
    tester,
  ) async {
    await pumpProfile(tester, user: _fakeUser());

    expect(find.text("Compte lié à l'app Histoires"), findsOneWidget);
  });

  testWidgets(
    'affiche les 4 lignes de menu (regroupées dans un SettingsListCard) avec '
    'leurs icônes dédiées, sans "Signaler un bug"',
    (tester) async {
      await pumpProfile(tester, user: _fakeUser());

      for (final label in const [
        'Modifier le profil',
        'Notifications',
        'Confidentialité et données',
        'Aide et support',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Signaler un bug'), findsNothing);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.byIcon(Icons.bug_report_outlined), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(4));
      expect(find.byType(SettingsListCard), findsOneWidget);
    },
  );

  testWidgets(
    'taper "Modifier le profil" pousse `ProfileEditScreen` (`/profile/edit`)',
    (tester) async {
      await pumpProfile(tester, user: _fakeUser(fullName: 'Aranea'));

      await tester.tap(find.text('Modifier le profil'));
      await tester.pumpAndSettle();

      // `ProfileEditScreen` (route `/profile/edit`) : bandeau bois "MODIFIER
      // LE PROFIL" + édition inline (pseudo/avatar/e-mail/mot de passe),
      // voir `profile_edit_screen_test.dart` pour le détail de cet écran
      // (refonte du 13/09/2026, recettage direction-artistique — l'ancien
      // patron "4 lignes résumé" n'existe plus).
      expect(find.text('MODIFIER LE PROFIL'), findsOneWidget);
      expect(find.text('Pseudo'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
    },
  );

  testWidgets('avatar : silhouette par défaut sans `avatar_url`', (
    tester,
  ) async {
    await pumpProfile(tester, user: _fakeUser());

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byType(ClipOval), findsNothing);
  });

  testWidgets(
    'avatar : image réseau configurée sur `avatar_url` quand défini — '
    "même précaution que `portrait_frame_test.dart` : vérifie la "
    "configuration de l'`Image` (l'URL demandée) juste après construction, "
    "sans laisser le temps à l'échec réseau simulé (`flutter test` ne fait "
    'aucune requête réelle) de se propager vers son `errorBuilder`',
    (tester) async {
      const url = 'https://exemple.com/avatar.png';
      await tester.pumpWidget(buildTestWidget(user: _fakeUser(avatarUrl: url)));
      await tester.tap(find.text('Ouvrir le profil'));
      // Un seul `pump` (pas `pumpAndSettle`) : laisse la transition de route
      // se terminer sans laisser le temps à l'échec réseau simulé de
      // l'`Image` de se propager jusqu'à son `errorBuilder`.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ClipOval), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as NetworkImage).url, url);
    },
  );

  testWidgets('avatar : URL inaccessible (échec réseau/décodage) replie sur la '
      'silhouette par défaut plutôt que de laisser une icône d\'erreur brute', (
    tester,
  ) async {
    const url = 'https://exemple.com/avatar-introuvable.png';
    await pumpProfile(tester, user: _fakeUser(avatarUrl: url));
    // Laisse le temps à l'échec réseau simulé de se propager — voir
    // `portrait_frame_test.dart` pour le rationale détaillé de ce
    // `pumpAndSettle` supplémentaire.
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('taper "Notifications" pousse `ProfileNotificationsScreen` '
      '(`/profile/notifications`)', (tester) async {
    await pumpProfile(tester, user: _fakeUser());

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    // `ProfileNotificationsScreen` (route `/profile/notifications`) :
    // bandeau bois "NOTIFICATIONS", voir
    // `profile_notifications_screen_test.dart` pour le détail de cet
    // écran.
    expect(find.text('NOTIFICATIONS'), findsOneWidget);
  });

  testWidgets(
    'taper "Confidentialité et données" pousse `ProfilePrivacyScreen` '
    '(`/profile/privacy`)',
    (tester) async {
      await pumpProfile(tester, user: _fakeUser());

      await tester.tap(find.text('Confidentialité et données'));
      await tester.pumpAndSettle();

      // `ProfilePrivacyScreen` (route `/profile/privacy`) : bandeau bois
      // "CONFIDENTIALITÉ" + ses 3 tuiles, voir
      // `profile_privacy_screen_test.dart` pour le détail de cet écran.
      expect(find.text('CONFIDENTIALITÉ'), findsOneWidget);
      expect(find.text('Exporter mes données'), findsOneWidget);
    },
  );

  testWidgets(
    'taper "Aide et support" pousse `ProfileHelpScreen` (`/profile/help`)',
    (tester) async {
      await pumpProfile(tester, user: _fakeUser());

      await tester.tap(find.text('Aide et support'));
      await tester.pumpAndSettle();

      // `ProfileHelpScreen` (route `/profile/help`) : bandeau bois "AIDE ET
      // SUPPORT" + ses 3 tuiles, voir `profile_help_screen_test.dart` pour
      // le détail de cet écran.
      expect(find.text('AIDE ET SUPPORT'), findsOneWidget);
      expect(find.text('Contacter le support'), findsOneWidget);
    },
  );

  testWidgets('le bouton "Se déconnecter" appelle `AuthRepository.signOut`', (
    tester,
  ) async {
    await pumpProfile(tester, user: _fakeUser());

    // Le contenu scrollable dépasse la hauteur du viewport de test :
    // s'assure que le bouton (en bas de la liste) est bien visible avant
    // de taper dessus.
    await tester.ensureVisible(find.text('Se déconnecter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();

    expect(fakeAuthRepository.signOutCallCount, 1);
  });

  testWidgets('le bandeau bois "PROFIL" propose un retour fonctionnel', (
    tester,
  ) async {
    await pumpProfile(tester, user: _fakeUser());
    expect(find.text('Ouvrir le profil'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Ouvrir le profil'), findsOneWidget);
  });

  testWidgets('le pied de page affiche la version lue dynamiquement '
      '(`package_info_plus`, mockée ici via `setMockInitialValues`)', (
    tester,
  ) async {
    await pumpProfile(tester, user: _fakeUser());

    await tester.ensureVisible(find.text('Nexus JDR — Personnages · v1.0.0'));
    expect(find.text('Nexus JDR — Personnages · v1.0.0'), findsOneWidget);
  });
}
