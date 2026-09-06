import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/group_failure.dart';

const String _networkErrorMessage =
    'Impossible de contacter le serveur. Vérifiez votre connexion internet '
    'et réessayez.';

/// Traduit une [PostgrestException] Supabase en [GroupFailure] avec un
/// message utilisateur en français — même principe que `mapCharacterError`.
GroupFailure mapGroupError(PostgrestException error) {
  if (error.code == '42501') {
    return const GroupFailure("Vous n'avez pas accès à ce groupe.");
  }
  return GroupFailure(
    error.message.isNotEmpty ? error.message : _networkErrorMessage,
  );
}

/// Message générique pour toute erreur qui n'est pas une [PostgrestException]
/// (ex. absence de réseau).
GroupFailure mapUnknownGroupError() => const GroupFailure(_networkErrorMessage);
