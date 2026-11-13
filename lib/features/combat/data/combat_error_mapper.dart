import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/transport_failure.dart';
import '../domain/combat_failure.dart';

/// Traduit une [PostgrestException] d'une RPC de combat en [CombatFailure] :
/// le `message` est un code stable (`combat_not_found`, `gm_absent`...), le
/// SQLSTATE ([PostgrestException.code]) est conservé pour le diagnostic.
/// Un code inconnu donne [CombatFailureKind.unknown] (message brut conservé).
CombatFailure mapCombatPostgrestError(PostgrestException error) {
  return CombatFailure(
    CombatFailureKind.fromServerCode(error.message),
    rawMessage: error.message,
    sqlState: error.code,
  );
}

/// Traduit toute autre erreur : un échec de transport (délai, socket...) donne
/// [CombatFailureKind.network], le reste [CombatFailureKind.unknown].
CombatFailure mapCombatUnknownError(Object error) {
  if (error is CombatFailure) return error;
  if (isTransportFailure(error)) return const CombatFailure.network();
  return CombatFailure(CombatFailureKind.unknown, rawMessage: '$error');
}
