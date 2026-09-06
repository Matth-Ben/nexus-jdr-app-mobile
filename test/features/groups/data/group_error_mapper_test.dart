import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/data/group_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapGroupError', () {
    test('42501 (RLS) -> message dédié', () {
      final failure = mapGroupError(
        const PostgrestException(message: 'permission denied', code: '42501'),
      );
      expect(failure.message, "Vous n'avez pas accès à ce groupe.");
    });

    test('message non vide -> réutilisé tel quel', () {
      final failure = mapGroupError(
        const PostgrestException(message: 'Erreur serveur', code: '500'),
      );
      expect(failure.message, 'Erreur serveur');
    });

    test('message vide -> message réseau générique', () {
      final failure = mapGroupError(const PostgrestException(message: ''));
      expect(
        failure.message,
        'Impossible de contacter le serveur. Vérifiez votre connexion '
        'internet et réessayez.',
      );
    });
  });

  test('mapUnknownGroupError -> message réseau générique', () {
    expect(
      mapUnknownGroupError().message,
      'Impossible de contacter le serveur. Vérifiez votre connexion '
      'internet et réessayez.',
    );
  });
}
