import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/data/group_invite_error_mapper.dart';
import 'package:personnages/features/groups/domain/group_invite_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapGroupInviteError', () {
    test('error: invalid_code -> GroupInviteFailureKind.invalidCode', () {
      final failure = mapGroupInviteError(
        const FunctionsHttpException(
          status: 404,
          details: {'error': 'invalid_code', 'message': 'Code invalide.'},
        ),
      );

      expect(failure.kind, GroupInviteFailureKind.invalidCode);
      expect(failure.serverMessage, 'Code invalide.');
    });

    test(
      'error: already_in_group -> GroupInviteFailureKind.alreadyInGroup',
      () {
        final failure = mapGroupInviteError(
          const FunctionsHttpException(
            status: 409,
            details: {
              'error': 'already_in_group',
              'message': 'Déjà membre de ce groupe.',
            },
          ),
        );

        expect(failure.kind, GroupInviteFailureKind.alreadyInGroup);
      },
    );

    test('error inconnu/internal_error -> GroupInviteFailureKind.generic', () {
      final failure = mapGroupInviteError(
        const FunctionsHttpException(
          status: 500,
          details: {'error': 'internal_error', 'message': 'Erreur serveur.'},
        ),
      );

      expect(failure.kind, GroupInviteFailureKind.generic);
      expect(failure.serverMessage, 'Erreur serveur.');
    });

    test('FunctionsHttpException sans corps JSON exploitable -> generic', () {
      final failure = mapGroupInviteError(
        const FunctionsHttpException(status: 500, details: 'texte brut'),
      );

      expect(failure.kind, GroupInviteFailureKind.generic);
    });

    test('toute exception qui n\'est pas une FunctionsHttpException -> '
        'generic', () {
      final failure = mapGroupInviteError(StateError('boom'));
      expect(failure.kind, GroupInviteFailureKind.generic);
    });
  });
}
