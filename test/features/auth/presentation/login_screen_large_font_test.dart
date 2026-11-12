// F21 (`docs/retours-utilisateurs.md`, gravité haute) : avec une police
// système agrandie, l'écran de connexion doit rester entièrement utilisable
// (saisie, bouton, « Mot de passe oublié ? », connexion sociale), quitte à
// défiler — sinon le joueur ne peut plus se connecter.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/social_auth_button.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/presentation/login_screen.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';

class _FakeAuthRepository implements AuthRepository {
  int signInCallCount = 0;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
  }

  @override
  Future<void> deleteAccount() async {}

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
  Future<void> signOut() async {}

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

void main() {
  const surfaces = <Size>[
    Size(360, 640),
    Size(320, 568),
    Size(480, 800),
    Size(320, 533),
    Size(240, 400),
  ];
  const scales = <double>[1.3, 2.0];

  Future<_FakeAuthRepository> pump(
    WidgetTester tester,
    Size surface,
    double scale,
  ) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          appleSignInSupportedProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const LoginScreen(),
        ),
      ),
    );
    return repository;
  }

  for (final surface in surfaces) {
    for (final scale in scales) {
      final label =
          '${surface.width.toInt()}x${surface.height.toInt()} police x$scale';

      testWidgets('connexion, $label : aucun débordement et tout est '
          'atteignable en défilant', (tester) async {
        final repository = await pump(tester, surface, scale);
        expect(tester.takeException(), isNull);

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'nom@exemple.com',
        );
        await tester.enterText(find.byType(TextFormField).at(1), 'motdepasse1');

        final submit = find.byType(PrimaryButton);
        await tester.ensureVisible(submit);
        await tester.pumpAndSettle();
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(repository.signInCallCount, 1);

        for (final finder in [
          find.text('Mot de passe oublié ?'),
          find.byType(SocialAuthButton).first,
          find.byType(SocialAuthButton).last,
        ]) {
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          expect(finder, findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('inscription, $label : aucun débordement', (tester) async {
        await pump(tester, surface, scale);
        final link = find.text('Créer un compte');
        await tester.ensureVisible(link);
        await tester.pumpAndSettle();
        await tester.tap(link);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  }
}
