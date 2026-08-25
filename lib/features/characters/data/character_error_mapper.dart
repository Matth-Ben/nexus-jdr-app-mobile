import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/character_failure.dart';

const String _networkErrorMessage =
    'Impossible de contacter le serveur. Vérifiez votre connexion internet '
    'et réessayez.';

const String _genericErrorMessage =
    'Impossible de charger vos personnages. Réessayez.';

/// Traduit une [PostgrestException] Supabase en [CharacterFailure] avec un
/// message utilisateur en français — même principe que `mapAuthException`
/// (`features/auth/data/auth_error_mapper.dart`).
CharacterFailure mapCharacterError(PostgrestException error) {
  // Code Postgres générique de refus RLS. Ne devrait normalement jamais se
  // produire ici puisque la requête filtre déjà explicitement sur
  // `owner_id` (voir `character_repository.dart`), mais un message dédié
  // reste plus clair qu'un message Postgrest brut si la policy RLS venait à
  // changer côté serveur.
  if (error.code == '42501') {
    return const CharacterFailure("Vous n'avez pas accès à ces personnages.");
  }

  return CharacterFailure(
    error.message.isNotEmpty ? error.message : _genericErrorMessage,
  );
}

/// Message générique pour toute erreur qui n'est pas une [PostgrestException]
/// (ex. absence de réseau).
CharacterFailure mapUnknownCharacterError() =>
    const CharacterFailure(_networkErrorMessage);
