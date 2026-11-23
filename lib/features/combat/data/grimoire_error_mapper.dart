import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/grimoire_failure.dart';

/// Traduit une [PostgrestException] d'une fonction `api_v1` du combat mené
/// depuis Grimoire en [GrimoireFailure] : le client se fie au `message` (code
/// stable du contrat DeepCore §6), jamais au statut HTTP. Pour `rate_limited`,
/// `details` porte les secondes à attendre.
GrimoireFailure mapGrimoirePostgrestError(PostgrestException error) {
  final kind = GrimoireFailureKind.fromServerCode(error.message);
  return GrimoireFailure(
    kind,
    retryAfterSeconds: kind == GrimoireFailureKind.rateLimited
        ? _seconds(error.details)
        : null,
    rawMessage: error.message,
  );
}

/// Toute autre erreur (transport, réponse illisible) : [GrimoireFailureKind.other].
GrimoireFailure mapGrimoireUnknownError(Object error) {
  if (error is GrimoireFailure) return error;
  return GrimoireFailure(GrimoireFailureKind.other, rawMessage: '$error');
}

int? _seconds(Object? details) {
  if (details is int) return details;
  if (details is double) return details.ceil();
  if (details is! String) return null;
  final match = RegExp(r'\d+').firstMatch(details);
  return match == null ? null : int.tryParse(match.group(0)!);
}
