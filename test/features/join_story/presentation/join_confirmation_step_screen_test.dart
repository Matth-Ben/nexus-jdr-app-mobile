// Tests de widget de l'étape 2/4 "Confirmation" du flux "Rejoindre une
// histoire" — voir `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
// section 7.1. Le dépôt de test (`_FakeStoryInviteRepository`) est injecté
// via `overrideWithValue` sur `storyInviteRepositoryProvider`, même principe
// que `character_list_screen_test.dart`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/join_story/data/story_invite_repository.dart';
import 'package:personnages/features/join_story/domain/join_story_result.dart';
import 'package:personnages/features/join_story/domain/story_invite_failure.dart';
import 'package:personnages/features/join_story/domain/story_preview.dart';
import 'package:personnages/features/join_story/presentation/join_confirmation_step_screen.dart';
import 'package:personnages/features/join_story/presentation/providers/join_story_providers.dart';

class _FakeStoryInviteRepository implements StoryInviteRepository {
  StoryPreview? previewToReturn;
  Object? previewErrorToThrow;
  Completer<StoryPreview>? previewCompleter;
  int previewCallCount = 0;

  @override
  Future<StoryPreview> previewInvite(String code) async {
    previewCallCount++;
    if (previewCompleter != null) return previewCompleter!.future;
    if (previewErrorToThrow != null) throw previewErrorToThrow!;
    return previewToReturn ?? const StoryPreview(title: 'Histoire test');
  }

  @override
  Future<JoinStoryResult> joinStory({
    required String code,
    required String characterId,
  }) {
    throw UnimplementedError();
  }
}

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/join/step-2?code=AB3F7K',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Liste des personnages'))),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Étape 1 code=${state.uri.queryParameters['code']}'),
          ),
        ),
      ),
      GoRoute(
        path: '/join/step-2',
        builder: (context, state) => JoinConfirmationStepScreen(
          code: state.uri.queryParameters['code']!,
        ),
      ),
      GoRoute(
        path: '/join/step-3',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Étape 3 code=${state.uri.queryParameters['code']}'),
          ),
        ),
      ),
    ],
  );
}

Widget _buildTestWidget(_FakeStoryInviteRepository repository) {
  return ProviderScope(
    overrides: [storyInviteRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(routerConfig: _buildTestRouter()),
  );
}

void main() {
  late _FakeStoryInviteRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeStoryInviteRepository();
  });

  testWidgets('affiche un indicateur de chargement pendant la résolution', (
    tester,
  ) async {
    fakeRepository.previewCompleter = Completer<StoryPreview>();

    await tester.pumpWidget(_buildTestWidget(fakeRepository));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'affiche le titre et la couverture de l\'histoire une fois résolue, '
    'puis "Rejoindre" pousse l\'étape 3/4 avec le code',
    (tester) async {
      fakeRepository.previewToReturn = const StoryPreview(
        title: 'La Malédiction du Nord',
        coverUrl: 'https://example.com/cover.jpg',
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(find.text('La Malédiction du Nord'), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as NetworkImage).url,
        'https://example.com/cover.jpg',
      );

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('Étape 3 code=AB3F7K'), findsOneWidget);
    },
  );

  testWidgets('code invalide : affiche le message dédié et "Modifier le code" '
      'repousse l\'étape 1/4 avec le code pré-rempli', (tester) async {
    fakeRepository.previewErrorToThrow = const StoryInviteFailure(
      StoryInviteFailureKind.invalidCode,
      serverMessage: 'Code invalide.',
    );

    await tester.pumpWidget(_buildTestWidget(fakeRepository));
    await tester.pumpAndSettle();

    expect(
      find.text('Ce code d\'invitation n\'est pas valide.'),
      findsOneWidget,
    );
    expect(
      find.text('Vérifie le code transmis par ton MJ et réessaye.'),
      findsOneWidget,
    );

    await tester.tap(find.text('MODIFIER LE CODE'));
    await tester.pumpAndSettle();

    expect(find.text('Étape 1 code=AB3F7K'), findsOneWidget);
  });

  testWidgets(
    'invitation désactivée : affiche le message dédié avec "Modifier le '
    'code"',
    (tester) async {
      fakeRepository.previewErrorToThrow = const StoryInviteFailure(
        StoryInviteFailureKind.inviteDisabled,
      );

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(find.text('Cette invitation a été désactivée.'), findsOneWidget);
      expect(
        find.text('Demande à ton MJ de générer un nouveau lien.'),
        findsOneWidget,
      );
      expect(find.text('MODIFIER LE CODE'), findsOneWidget);
    },
  );

  testWidgets('erreur générique/réseau : affiche le message générique et '
      '"Réessayer" relance la requête', (tester) async {
    fakeRepository.previewErrorToThrow = const StoryInviteFailure(
      StoryInviteFailureKind.generic,
    );

    await tester.pumpWidget(_buildTestWidget(fakeRepository));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Impossible de contacter le serveur. Vérifiez votre connexion '
        'internet et réessayez.',
      ),
      findsOneWidget,
    );
    expect(fakeRepository.previewCallCount, 1);

    await tester.tap(find.text('RÉESSAYER'));
    await tester.pumpAndSettle();

    expect(fakeRepository.previewCallCount, 2);
  });

  testWidgets(
    'une exception qui n\'est pas une StoryInviteFailure est traitée comme '
    'générique',
    (tester) async {
      fakeRepository.previewErrorToThrow = StateError('boom');

      await tester.pumpWidget(_buildTestWidget(fakeRepository));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Impossible de contacter le serveur. Vérifiez votre connexion '
          'internet et réessayez.',
        ),
        findsOneWidget,
      );
    },
  );
}
