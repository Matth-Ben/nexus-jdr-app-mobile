import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/data/group_error_mapper.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapGroupError', () {
    test('42501 (RLS) -> message dédié + code accessDenied', () {
      final failure = mapGroupError(
        const PostgrestException(message: 'permission denied', code: '42501'),
      );
      expect(failure.message, "Vous n'avez pas accès à ce groupe.");
      expect(failure.code, GroupErrorCode.accessDenied);
    });

    test('message non vide -> réutilisé tel quel, code generic', () {
      final failure = mapGroupError(
        const PostgrestException(message: 'Erreur serveur', code: '500'),
      );
      expect(failure.message, 'Erreur serveur');
      expect(failure.code, GroupErrorCode.generic);
    });

    test('message vide -> message réseau générique, code generic', () {
      final failure = mapGroupError(const PostgrestException(message: ''));
      expect(
        failure.message,
        'Impossible de contacter le serveur. Vérifiez votre connexion '
        'internet et réessayez.',
      );
      expect(failure.code, GroupErrorCode.generic);
    });
  });

  test('mapUnknownGroupError -> message réseau générique + code network', () {
    final failure = mapUnknownGroupError();
    expect(
      failure.message,
      'Impossible de contacter le serveur. Vérifiez votre connexion '
      'internet et réessayez.',
    );
    expect(failure.code, GroupErrorCode.network);
  });
}
