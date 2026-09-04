// Tests de widget de la sheet de choix de source d'avatar
// (`presentation/widgets/avatar_edit_sheet.dart`) — options affichées selon
// `hasAvatar`, flux "Retirer la photo" (confirmation, appel au repository,
// SnackBar succès/erreur), et absence de crash pour "Prendre une
// photo"/"Choisir dans la galerie" (le canal `image_picker` n'est pas
// disponible dans `flutter test`, voir `_pickAndCrop` : l'exception est
// avalée, aucune navigation supplémentaire n'a lieu).

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/destructive_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/domain/auth_failure.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/profile/presentation/widgets/avatar_edit_sheet.dart';

class _FakeAuthRepository implements AuthRepository {
  final Completer<void> gate = Completer<void>();
  bool gateRemoveAvatar = false;

  int removeAvatarCallCount = 0;
  Object? errorToThrow;

  @override
  Future<void> removeAvatar() async {
    removeAvatarCallCount++;
    if (gateRemoveAvatar) await gate.future;
    final error = errorToThrow;
    if (error != null) throw error;
  }

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUp({required String email, required String password}) async {}

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
}

Future<_FakeAuthRepository> _pumpSheet(
  WidgetTester tester, {
  String? avatarUrl,
}) async {
  final repository = _FakeAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => showAvatarEditSheet(
                  context,
                  ref: ref,
                  avatarUrl: avatarUrl,
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets(
    'sans avatar : "Prendre une photo"/"Choisir dans la galerie" seulement, '
    'pas "Retirer la photo"',
    (tester) async {
      await _pumpSheet(tester);

      expect(find.text('Prendre une photo'), findsOneWidget);
      expect(find.text('Choisir dans la galerie'), findsOneWidget);
      expect(find.text('Retirer la photo'), findsNothing);
      expect(
        find.text('Utiliser une URL'),
        findsNothing,
        reason:
            'retiré pour l\'avatar (spec direction-artistique de la tâche) '
            '— contrairement au portrait de personnage',
      );
    },
  );

  testWidgets('avec un avatar déjà défini : "Retirer la photo" proposée', (
    tester,
  ) async {
    await _pumpSheet(tester, avatarUrl: 'https://exemple.com/avatar.png');

    expect(find.text('Retirer la photo'), findsOneWidget);
  });

  testWidgets(
    '"Retirer la photo" ouvre la confirmation "Retirer la photo ?", '
    '"Annuler" ne fait aucun appel réseau',
    (tester) async {
      final repository = await _pumpSheet(
        tester,
        avatarUrl: 'https://exemple.com/avatar.png',
      );

      await tester.tap(find.text('Retirer la photo'));
      await tester.pumpAndSettle();

      expect(find.text('Retirer la photo ?'), findsOneWidget);

      await tester.tap(find.widgetWithText(SecondaryButton, 'ANNULER'));
      await tester.pumpAndSettle();

      expect(repository.removeAvatarCallCount, 0);
    },
  );

  testWidgets(
    'confirmer "Retirer" appelle `AuthRepository.removeAvatar` et affiche '
    'le SnackBar "Photo retirée."',
    (tester) async {
      final repository = await _pumpSheet(
        tester,
        avatarUrl: 'https://exemple.com/avatar.png',
      );

      await tester.tap(find.text('Retirer la photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(DestructiveButton, 'Retirer'));
      await tester.pumpAndSettle();

      expect(repository.removeAvatarCallCount, 1);
      expect(find.text('Photo retirée.'), findsOneWidget);
    },
  );

  testWidgets(
    'échec `AuthFailure` de `removeAvatar` : SnackBar avec le message de '
    'l\'échec',
    (tester) async {
      final repository = await _pumpSheet(
        tester,
        avatarUrl: 'https://exemple.com/avatar.png',
      );
      repository.errorToThrow = const AuthFailure('Erreur serveur.');

      await tester.tap(find.text('Retirer la photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(DestructiveButton, 'Retirer'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur serveur.'), findsOneWidget);
    },
  );

  testWidgets(
    'échec inattendu (pas une AuthFailure) de `removeAvatar` : SnackBar '
    'générique "Impossible de mettre à jour l\'avatar. Réessayez."',
    (tester) async {
      final repository = await _pumpSheet(
        tester,
        avatarUrl: 'https://exemple.com/avatar.png',
      );
      repository.errorToThrow = Exception('boom');

      await tester.tap(find.text('Retirer la photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(DestructiveButton, 'Retirer'));
      await tester.pumpAndSettle();

      expect(
        find.text("Impossible de mettre à jour l'avatar. Réessayez."),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'taper "Prendre une photo"/"Choisir dans la galerie" ne fait pas planter '
    'la sheet (canal `image_picker` indisponible dans `flutter test` — '
    'exception avalée par `_pickAndCrop`, aucune navigation supplémentaire)',
    (tester) async {
      await _pumpSheet(tester);

      await tester.tap(find.text('Prendre une photo'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
