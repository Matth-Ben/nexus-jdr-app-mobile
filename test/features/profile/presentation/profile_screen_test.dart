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
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/core/sync/sync_alerts_panel_providers.dart';
import 'package:personnages/core/sync/sync_clock_provider.dart';
import 'package:personnages/core/sync/sync_status_providers.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/theme/app_typography.dart';
import 'package:personnages/core/widgets/menu_tile.dart';
import 'package:personnages/core/widgets/profile_avatar.dart';
import 'package:personnages/core/widgets/settings_list_card.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/domain/auth_failure.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/profile/data/notification_preferences_repository.dart';
import 'package:personnages/features/profile/domain/notification_preferences.dart';
import 'package:personnages/features/profile/presentation/profile_edit_screen.dart';
import 'package:personnages/features/profile/presentation/profile_help_screen.dart';
import 'package:personnages/features/profile/presentation/profile_language_screen.dart';
import 'package:personnages/features/profile/presentation/profile_notifications_screen.dart';
import 'package:personnages/features/profile/presentation/profile_privacy_screen.dart';
import 'package:personnages/features/profile/presentation/profile_screen.dart';
import 'package:personnages/features/profile/presentation/providers/notification_preferences_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    bool? pushNewVersionAvailable,
    bool? emailDigestEnabled,
  }) async => const NotificationPreferences.defaults();
}

class _FakeAuthRepository implements AuthRepository {
  int signOutCallCount = 0;
  Object? signOutErrorToThrow;

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
    String? displayName,
  }) async => false;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    final error = signOutErrorToThrow;
    if (error != null) throw error;
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

  @override
  Future<void> markOnboardingSeen() async {}
}

class _AlwaysOnlineConnectivityChecker implements ConnectivityChecker {
  @override
  Future<bool> hasConnection() async => true;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
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
    // `ProfileLanguageScreen` lit `localePreferenceControllerProvider`
    // (`core/i18n/locale_preference_provider.dart`), qui résout
    // `SharedPreferences.getInstance()` — nécessaire dès que le test navigue
    // vers "Langue" (voir `SharedPreferences.setMockInitialValues`, même
    // convention que `analytics_preferences_provider_test.dart`).
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget({
    required User? user,
    Locale locale = const Locale('fr'),
    List<Override> extraOverrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(user),
        ...extraOverrides,
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        connectivityCheckerProvider.overrideWithValue(
          _AlwaysOnlineConnectivityChecker(),
        ),
        notificationPreferencesRepositoryProvider.overrideWithValue(
          _FakeNotificationPreferencesRepository(),
        ),
      ],
      child: MaterialApp.router(
        // `ProfileScreen`/`ProfileLanguageScreen` lisent `AppLocalizations.of
        // (context)!` (chantier "traduction de l'app" Phase A, poursuivi en
        // Phase B pour le reste de cet écran) — sans ces delegates, l'appel
        // renverrait `null` et le `!` planterait. `fr` par défaut (plutôt que
        // `null`, qui suivrait la langue réelle, non garantie, de
        // l'environnement `flutter test`), `en` passé explicitement par le
        // groupe "locale anglaise" ci-dessous.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
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
            GoRoute(
              path: '/profile/language',
              builder: (context, state) => const ProfileLanguageScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pumpProfile(
    WidgetTester tester, {
    required User? user,
    Locale locale = const Locale('fr'),
  }) async {
    await tester.pumpWidget(buildTestWidget(user: user, locale: locale));
    await tester.tap(find.text('Ouvrir le profil'));
    await tester.pumpAndSettle();
  }

  group('dernière synchronisation (T2 du chantier hors-ligne)', () {
    final now = DateTime(2026, 11, 10, 15, 0);

    List<Override> syncOverrides({DateTime? lastSync, int pending = 0}) => [
      syncClockProvider.overrideWithValue(() => now),
      lastSyncAtProvider.overrideWith((ref) => Stream.value(lastSync)),
      pendingWriteCountProvider().overrideWith((ref) => Stream.value(pending)),
    ];

    Future<void> pumpProfile(
      WidgetTester tester, {
      DateTime? lastSync,
      int pending = 0,
      Locale locale = const Locale('fr'),
    }) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        buildTestWidget(
          user: _fakeUser(),
          locale: locale,
          extraOverrides: syncOverrides(lastSync: lastSync, pending: pending),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ouvrir le profil'));
      await tester.pumpAndSettle();
    }

    testWidgets('relatif, au-dessus de la version, police corps 12 muted', (
      tester,
    ) async {
      await pumpProfile(
        tester,
        lastSync: now.subtract(const Duration(minutes: 5)),
      );

      final syncFinder = find.text('Dernière synchronisation : il y a 5 min');
      expect(syncFinder, findsOneWidget);
      final style = tester.widget<Text>(syncFinder).style!;
      expect(style.fontSize, 12);
      expect(
        style.fontFamily,
        isNot(AppTypography.display(fontSize: 12).fontFamily),
      );
      expect(
        tester.getBottomLeft(syncFinder).dy,
        lessThanOrEqualTo(
          tester.getTopLeft(find.textContaining('Nexus JDR — Personnages')).dy,
        ),
        reason: 'juste au-dessus de la version',
      );
    });

    testWidgets('jamais synchronisé + modifications en attente : « jamais · '
        'N en attente »', (tester) async {
      await pumpProfile(tester, pending: 2);
      expect(
        find.text('Dernière synchronisation : jamais · 2 en attente'),
        findsOneWidget,
      );
    });

    testWidgets('au-delà de 24 h : date absolue locale ; un seul libellé '
        "d'accessibilité", (tester) async {
      await pumpProfile(tester, lastSync: DateTime(2026, 11, 7, 14, 32));
      expect(
        find.text('Dernière synchronisation : 7 nov. 2026 à 14:32'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Dernière synchronisation : 7 nov. 2026 à 14:32'),
        findsOneWidget,
      );
    });

    testWidgets('anglais', (tester) async {
      await pumpProfile(
        tester,
        lastSync: now.subtract(const Duration(hours: 3)),
        locale: const Locale('en'),
      );
      expect(find.text('Last sync: 3 h ago'), findsOneWidget);
    });
  });

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

  testWidgets(
    'le bandeau bois d\'identité (avatar/pseudo/e-mail) occupe toute la '
    'largeur de l\'écran — pas seulement la largeur de son contenu',
    (tester) async {
      await pumpProfile(tester, user: _fakeUser(fullName: 'Aranea'));

      final identityColoredBox = find.ancestor(
        of: find.byType(ProfileAvatar),
        matching: find.byType(ColoredBox),
      );
      expect(identityColoredBox, findsOneWidget);

      final scaffoldWidth = tester.getSize(find.byType(Scaffold)).width;
      final identityWidth = tester.getSize(identityColoredBox).width;
      expect(identityWidth, scaffoldWidth);
    },
  );

  testWidgets('affiche le bandeau "Compte lié à l\'app Histoires"', (
    tester,
  ) async {
    await pumpProfile(tester, user: _fakeUser());

    expect(find.text("Compte lié à l'app Histoires"), findsOneWidget);
  });

  testWidgets(
    'affiche les 6 lignes de menu (regroupées dans un SettingsListCard) avec '
    'leurs icônes dédiées, sans "Signaler un bug" — "Langue" en 2e position, '
    'entre "Notifications" et "Confidentialité et données"',
    (tester) async {
      await pumpProfile(tester, user: _fakeUser());

      for (final label in const [
        'Modifier le profil',
        'Notifications',
        'Langue',
        'Confidentialité et données',
        'Alertes de synchronisation',
        'Aide et support',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Signaler un bug'), findsNothing);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);
      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.byIcon(Icons.bug_report_outlined), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(6));
      expect(find.byType(SettingsListCard), findsOneWidget);

      // "Langue" est bien entre "Notifications" et "Confidentialité et
      // données" dans l'arborescence (pas juste présente ailleurs dans la
      // page).
      final menuTiles = tester
          .widgetList<MenuTile>(find.byType(MenuTile))
          .map((tile) => tile.label)
          .toList();
      expect(menuTiles, [
        'Modifier le profil',
        'Notifications',
        'Langue',
        'Confidentialité et données',
        'Alertes de synchronisation',
        'Aide et support',
      ]);
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

  testWidgets('taper "Langue" pousse `ProfileLanguageScreen` '
      '(`/profile/language`)', (tester) async {
    await pumpProfile(tester, user: _fakeUser());

    await tester.tap(find.text('Langue'));
    await tester.pumpAndSettle();

    // `ProfileLanguageScreen` (route `/profile/language`) : bandeau bois
    // "LANGUE" + ses 3 tuiles, voir `profile_language_screen_test.dart` pour
    // le détail de cet écran.
    expect(find.text('LANGUE'), findsOneWidget);
    expect(find.text('Langue du téléphone'), findsOneWidget);
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

      // Le hub compte une ligne de plus (alertes de synchro) : « Aide et
      // support » peut dépasser le viewport de test, on la rend visible.
      await tester.ensureVisible(find.text('Aide et support'));
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

  testWidgets(
    'D31 : si `AuthRepository.signOut` est bloqué par des écritures PV/XP '
    'encore en attente (AuthFailure), affiche son message dans un SnackBar '
    'au lieu de le laisser silencieux — l\'écran reste affiché (pas de '
    'déconnexion)',
    (tester) async {
      fakeAuthRepository.signOutErrorToThrow = const AuthFailure(
        pendingHpXpWritesBlockedMessage,
      );
      await pumpProfile(tester, user: _fakeUser());

      await tester.ensureVisible(find.text('Se déconnecter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();

      expect(fakeAuthRepository.signOutCallCount, 1);
      expect(find.text(pendingHpXpWritesBlockedMessage), findsOneWidget);
      // L'écran de profil reste affiché : la déconnexion a bien été
      // bloquée, jamais effectuée silencieusement.
      expect(find.text('PROFIL'), findsOneWidget);
    },
  );

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

  group('alertes de synchronisation (fiche A)', () {
    final now = DateTime(2026, 11, 12, 12);

    SyncAlert alert(int id, String name, {SyncAlertKind? kind}) => SyncAlert(
      id: id,
      ownerId: 'fake-user-id',
      kind: kind ?? SyncAlertKind.abandon,
      characterId: 'c$id',
      characterName: name,
      dataKind: 'hp',
      serverValue: const {'currentHp': 7, 'maxHp': 12},
      createdAt: now.subtract(Duration(minutes: id)),
    );

    List<Override> overrides(List<SyncAlert> alerts) => [
      syncClockProvider.overrideWithValue(() => now),
      syncAlertsProvider.overrideWith((ref) => Stream.value(alerts)),
      sortedSyncAlertsProvider.overrideWith((ref) => Stream.value(alerts)),
    ];

    Future<void> pump(
      WidgetTester tester,
      List<SyncAlert> alerts, {
      Locale locale = const Locale('fr'),
    }) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        buildTestWidget(
          user: _fakeUser(),
          locale: locale,
          extraOverrides: overrides(alerts),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ouvrir le profil'));
      await tester.pumpAndSettle();
    }

    Finder row(String label) =>
        find.ancestor(of: find.text(label), matching: find.byType(MenuTile));

    testWidgets('aucune alerte : icône sync, sous-libellé « Aucune », pas de '
        'badge ; le tap ouvre le panneau vide', (tester) async {
      await pump(tester, const []);

      expect(row('Alertes de synchronisation'), findsOneWidget);
      expect(find.text('Aucune'), findsOneWidget);
      final tile = tester.widget<MenuTile>(row('Alertes de synchronisation'));
      expect(tile.icon, Icons.sync);
      expect(tile.badgeText, isNull);
      expect(
        tester.getSize(row('Alertes de synchronisation')).height,
        greaterThanOrEqualTo(44),
      );

      await tester.tap(find.text('Alertes de synchronisation'));
      await tester.pumpAndSettle();
      expect(find.text('ALERTES DE SYNCHRO'), findsOneWidget);
      expect(find.text('Aucune alerte de synchronisation.'), findsOneWidget);
    });

    testWidgets('2 alertes : badge « 2 » brick (chiffre dans le texte), icône '
        'sync_problem brick, le tap ouvre le panneau avec les alertes', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, [alert(1, 'Aria'), alert(2, 'Borin')]);

      final tile = tester.widget<MenuTile>(row('Alertes de synchronisation'));
      expect(tile.badgeText, '2');
      expect(tile.icon, Icons.sync_problem);
      expect(tile.iconColor, AppColors.accentBrick);
      expect(find.text('Aucune'), findsNothing);
      expect(
        find.descendant(
          of: row('Alertes de synchronisation'),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Alertes de synchronisation : 2 alertes. Ouvrir la liste.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Alertes de synchronisation'));
      await tester.pumpAndSettle();
      expect(find.text('ALERTES DE SYNCHRO'), findsOneWidget);
      expect(find.textContaining('PV de Aria'), findsOneWidget);
      expect(find.textContaining('PV de Borin'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('1 alerte, anglais : « Sync alerts », badge « 1 »', (
      tester,
    ) async {
      await pump(tester, [alert(1, 'Aria')], locale: const Locale('en'));
      expect(find.text('Sync alerts'), findsOneWidget);
      expect(tester.widget<MenuTile>(row('Sync alerts')).badgeText, '1');
      await tester.tap(find.text('Sync alerts'));
      await tester.pumpAndSettle();
      expect(find.text('SYNC ALERTS'), findsOneWidget);
    });

    testWidgets('la ligne « Dernière synchronisation » du pied de page reste '
        'un simple texte d\'état', (tester) async {
      await pump(tester, [alert(1, 'Aria')]);
      final footer = find.text('Dernière synchronisation : jamais');
      expect(footer, findsOneWidget);
      expect(
        find.ancestor(of: footer, matching: find.byType(InkWell)),
        findsNothing,
      );
    });
  });

  group('locale anglaise', () {
    // Même rationale que `login_screen_test.dart`/
    // `profile_credits_screen_test.dart` (chantier "traduction de l'app"
    // Phase B) : vérifie qu'un texte anglais s'affiche réellement, pas
    // seulement que l'écran ne plante pas. Périmètre de ce lot
    // (profile_screen.dart) : titre du bandeau, 4 entrées de menu encore en
    // dur, "Se déconnecter" — "Langue" déjà couverte par
    // `profile_language_screen_test.dart` (Phase A).
    testWidgets('affiche le bandeau bois et les entrées de menu en anglais', (
      tester,
    ) async {
      await pumpProfile(tester, user: _fakeUser(), locale: const Locale('en'));

      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Privacy & data'), findsOneWidget);
      expect(find.text('Help & support'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });
  });
}
