// Langue du compte (`user_metadata.locale`, lue par `notify-group`) : écrite
// seulement quand elle change, à la connexion et au changement de langue ;
// hors ligne, à la prochaine occasion.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/features/auth/data/auth_state_stream.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/profile/data/account_locale_repository.dart';
import 'package:personnages/features/profile/presentation/providers/account_locale_providers.dart';
import 'package:personnages/features/profile/presentation/widgets/account_locale_reporter.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../support/fake_connectivity_checker.dart';

class _Repository implements AccountLocaleRepository {
  bool signedIn = true;
  String? locale;
  Object? error;
  final List<String> writes = [];

  @override
  bool get hasAccount => signedIn;

  @override
  String? currentLocale() => locale;

  @override
  Future<void> writeLocale(String languageCode) async {
    final failure = error;
    if (failure != null) throw failure;
    writes.add(languageCode);
    // Comme la session locale après `updateUser`.
    locale = languageCode;
  }
}

class _AuthStream implements AuthStateStream {
  final controller = StreamController<AuthState>.broadcast();

  @override
  Stream<AuthState> get onAuthStateChange => controller.stream;
}

Session _session() => Session(
  accessToken: 'jeton',
  tokenType: 'bearer',
  user: User(
    id: 'user-1',
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00Z',
  ),
);

void main() {
  late _Repository repository;
  late FakeConnectivityChecker connectivity;
  late _AuthStream auth;
  late ProviderContainer container;

  setUp(() {
    repository = _Repository();
    connectivity = FakeConnectivityChecker();
    auth = _AuthStream();
    container = ProviderContainer(
      overrides: [
        accountLocaleRepositoryProvider.overrideWithValue(repository),
        connectivityCheckerProvider.overrideWithValue(connectivity),
        authStateStreamProvider.overrideWithValue(auth),
      ],
    );
    // Ordre inverse à l'exécution : conteneur libéré d'abord (plus aucun
    // abonné), puis les faux flux fermés.
    addTearDown(auth.controller.close);
    addTearDown(connectivity.close);
    addTearDown(container.dispose);
  });

  AccountLocaleSync sync() => container.read(accountLocaleSyncProvider);

  test('code écrit : en, sinon fr (comme notify-group)', () {
    expect(accountLocaleCode('en'), 'en');
    expect(accountLocaleCode('EN'), 'en');
    expect(accountLocaleCode('fr'), 'fr');
    expect(accountLocaleCode('de'), 'fr');
  });

  test('déjà la bonne langue (casse ignorée) : aucune écriture', () async {
    repository.locale = 'FR';
    sync().reportAppLanguage('fr');
    await pumpEventQueue();
    expect(repository.writes, isEmpty);
  });

  test('langue différente : écrite une fois ; même langue ensuite : plus '
      'rien', () async {
    repository.locale = 'fr';
    sync().reportAppLanguage('en');
    await pumpEventQueue();
    expect(repository.writes, ['en']);
    sync()
      ..reportAppLanguage('en')
      ..reportAppLanguage('en');
    await sync().sync();
    await pumpEventQueue();
    expect(repository.writes, ['en']);
    sync().reportAppLanguage('fr');
    await pumpEventQueue();
    expect(repository.writes, ['en', 'fr']);
  });

  test('absente du compte : écrite', () async {
    sync().reportAppLanguage('fr');
    await pumpEventQueue();
    expect(repository.writes, ['fr']);
  });

  test('sans compte : rien ; à la connexion : écrite', () async {
    repository.signedIn = false;
    sync().reportAppLanguage('en');
    await pumpEventQueue();
    expect(repository.writes, isEmpty);
    repository.signedIn = true;
    auth.controller.add(AuthState(AuthChangeEvent.signedIn, _session()));
    await pumpEventQueue();
    expect(repository.writes, ['en']);
    // Reprise de session suivante, langue inchangée : rien.
    auth.controller.add(AuthState(AuthChangeEvent.initialSession, _session()));
    await pumpEventQueue();
    expect(repository.writes, ['en']);
  });

  test('hors ligne : rien, puis écrite au retour du réseau', () async {
    connectivity.connected = false;
    sync().reportAppLanguage('en');
    await pumpEventQueue();
    expect(repository.writes, isEmpty);
    connectivity.goOnline();
    await pumpEventQueue();
    expect(repository.writes, ['en']);
  });

  test('échec d\'écriture : silencieux, nouvel essai à la prochaine '
      'occasion', () async {
    repository.error = Exception('réseau');
    sync().reportAppLanguage('en');
    await pumpEventQueue();
    expect(repository.writes, isEmpty);
    repository.error = null;
    connectivity.emitRestored();
    await pumpEventQueue();
    expect(repository.writes, ['en']);
  });

  testWidgets('AccountLocaleReporter signale la langue affichée par l\'app, '
      'et son changement', (tester) async {
    repository.locale = 'fr';
    Widget app(Locale locale) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => AccountLocaleReporter(child: child!),
        home: const SizedBox.shrink(),
      ),
    );
    await tester.pumpWidget(app(const Locale('fr')));
    await tester.pumpAndSettle();
    expect(repository.writes, isEmpty);
    await tester.pumpWidget(app(const Locale('en')));
    await tester.pumpAndSettle();
    expect(repository.writes, ['en']);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
