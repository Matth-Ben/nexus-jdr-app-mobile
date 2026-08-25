import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/character_creation_failure.dart';

const String _networkErrorMessage =
    'Impossible de contacter le serveur. Vérifiez votre connexion internet '
    'et réessayez.';

const String _defaultErrorMessage = 'Une erreur est survenue. Réessayez.';

/// Traduit une [PostgrestException] Supabase en [CharacterCreationFailure]
/// avec un message utilisateur en français — même principe que
/// `mapCharacterError` (`features/characters/data/character_error_mapper.dart`).
///
/// [fallbackMessage] permet à chaque appelant (`data/character_creation_repository.dart`)
/// de fournir un message générique adapté à l'opération en cours (charger le
/// catalogue vs enregistrer une étape), utilisé quand Postgrest ne renvoie
/// aucun message exploitable.
CharacterCreationFailure mapCharacterCreationError(
  PostgrestException error, {
  String fallbackMessage = _defaultErrorMessage,
}) {
  // Code Postgres générique de refus RLS.
  if (error.code == '42501') {
    return const CharacterCreationFailure(
      "Vous n'avez pas accès à cette action.",
    );
  }

  return CharacterCreationFailure(
    error.message.isNotEmpty ? error.message : fallbackMessage,
  );
}

/// Message générique pour toute erreur qui n'est pas une [PostgrestException]
/// (ex. absence de réseau).
CharacterCreationFailure mapUnknownCharacterCreationError() =>
    const CharacterCreationFailure(_networkErrorMessage);
