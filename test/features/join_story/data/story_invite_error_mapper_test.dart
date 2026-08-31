// Tests unitaires de `mapStoryInviteError` — voir sa documentation pour le
// rationale de l'extraction en fonction pure, testable sans réseau
// (`FunctionsHttpException` se construit directement).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/join_story/data/story_invite_error_mapper.dart';
import 'package:personnages/features/join_story/domain/story_invite_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapStoryInviteError', () {
    test('error: invalid_code -> StoryInviteFailureKind.invalidCode', () {
      final failure = mapStoryInviteError(
        const FunctionsHttpException(
          status: 404,
          details: {'error': 'invalid_code', 'message': 'Code invalide.'},
        ),
      );

      expect(failure, isA<StoryInviteFailure>());
      expect(failure.kind, StoryInviteFailureKind.invalidCode);
      expect(failure.serverMessage, 'Code invalide.');
    });

    test('error: invite_disabled -> StoryInviteFailureKind.inviteDisabled', () {
      final failure = mapStoryInviteError(
        const FunctionsHttpException(
          status: 403,
          details: {
            'error': 'invite_disabled',
            'message': 'Invitation désactivée par le MJ.',
          },
        ),
      );

      expect(failure.kind, StoryInviteFailureKind.inviteDisabled);
    });

    test(
      'error: character_not_owned -> StoryInviteFailureKind.characterNotOwned',
      () {
        final failure = mapStoryInviteError(
          const FunctionsHttpException(
            status: 403,
            details: {
              'error': 'character_not_owned',
              'message': 'Ce personnage ne vous appartient pas.',
            },
          ),
        );

        expect(failure.kind, StoryInviteFailureKind.characterNotOwned);
      },
    );

    test('error: already_joined -> StoryInviteFailureKind.alreadyJoined', () {
      final failure = mapStoryInviteError(
        const FunctionsHttpException(
          status: 409,
          details: {
            'error': 'already_joined',
            'message': 'Ce personnage est déjà rattaché à cette histoire.',
          },
        ),
      );

      expect(failure.kind, StoryInviteFailureKind.alreadyJoined);
    });

    test('error inconnu/internal_error -> StoryInviteFailureKind.generic', () {
      final failure = mapStoryInviteError(
        const FunctionsHttpException(
          status: 500,
          details: {'error': 'internal_error', 'message': 'Erreur serveur.'},
        ),
      );

      expect(failure.kind, StoryInviteFailureKind.generic);
      expect(failure.serverMessage, 'Erreur serveur.');
    });

    test('FunctionsHttpException sans corps JSON exploitable -> generic, sans '
        'lever d\'exception', () {
      final failure = mapStoryInviteError(
        const FunctionsHttpException(status: 500, details: 'texte brut'),
      );

      expect(failure.kind, StoryInviteFailureKind.generic);
    });

    test('FunctionsFetchException (pas de réponse reçue, ex. hors ligne) -> '
        'generic', () {
      final failure = mapStoryInviteError(
        const FunctionsFetchException(details: 'network unreachable'),
      );

      expect(failure.kind, StoryInviteFailureKind.generic);
    });

    test('toute autre exception inattendue -> generic', () {
      final failure = mapStoryInviteError(StateError('boom'));

      expect(failure.kind, StoryInviteFailureKind.generic);
    });
  });
}
