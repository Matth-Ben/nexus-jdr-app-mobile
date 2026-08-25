import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/character_creation_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('mapCharacterCreationError', () {
    test('code Postgres 42501 (refus RLS) -> message dédié, quel que soit '
        'le message brut', () {
      const error = PostgrestException(
        message: 'permission denied for table characters',
        code: '42501',
      );

      expect(
        mapCharacterCreationError(error).message,
        "Vous n'avez pas accès à cette action.",
      );
    });

    test('message Postgrest exploitable -> repris tel quel', () {
      const error = PostgrestException(
        message: 'null value in column "name" violates not-null constraint',
        code: '23502',
      );

      expect(
        mapCharacterCreationError(error).message,
        'null value in column "name" violates not-null constraint',
      );
    });

    test('message Postgrest vide -> repli sur le message fourni par '
        "l'appelant", () {
      const error = PostgrestException(message: '', code: '23502');

      expect(
        mapCharacterCreationError(
          error,
          fallbackMessage: "Impossible d'enregistrer votre choix. Réessayez.",
        ).message,
        "Impossible d'enregistrer votre choix. Réessayez.",
      );
    });

    test('message Postgrest vide sans fallback explicite -> message '
        'générique par défaut', () {
      const error = PostgrestException(message: '', code: '23502');

      expect(
        mapCharacterCreationError(error).message,
        'Une erreur est survenue. Réessayez.',
      );
    });
  });

  test(
    'mapUnknownCharacterCreationError renvoie un message réseau explicite',
    () {
      expect(
        mapUnknownCharacterCreationError().message,
        contains('connexion internet'),
      );
    },
  );
}
