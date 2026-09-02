import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_validators.dart';

const String _networkErrorMessage =
    'Impossible de contacter le serveur. Vérifiez votre connexion internet '
    'et réessayez.';

const String _genericErrorMessage = 'Une erreur est survenue. Réessayez.';

/// Traduit une [AuthException] Supabase en [AuthFailure] avec un message
/// utilisateur en français, pour ne jamais afficher un message brut non
/// traduit à l'écran (voir `AuthRepository`, qui est l'unique appelant côté
/// app).
///
/// Se base d'abord sur `error.code` (identifiants stables documentés par
/// Supabase : https://supabase.com/docs/guides/auth/debugging/error-codes),
/// avec un repli sur le contenu de `error.message` quand le code n'est pas
/// renseigné (certaines erreurs, notamment réseau, n'en portent pas).
AuthFailure mapAuthException(AuthException error) {
  // `AuthRetryableFetchException` : type dédié du SDK pour toute erreur
  // survenue *avant* la réception d'une réponse HTTP (ex. absence de réseau,
  // CORS) — voir `package:gotrue/src/fetch.dart` (`_handleRequest`), qui
  // l'utilise pour envelopper systématiquement les exceptions de transport,
  // avant même qu'elles puissent atteindre le `catch` générique
  // (`mapUnknownError`) de ce dépôt. Sans ce cas particulier, un échec
  // réseau afficherait le message brut de l'exception Dart sous-jacente
  // (ex. "Exception: Failed host lookup") au lieu du message français
  // attendu.
  if (error is AuthRetryableFetchException) {
    return mapUnknownError();
  }

  final code = error.code;
  final message = error.message.toLowerCase();

  if (code == 'invalid_credentials' ||
      message.contains('invalid login credentials')) {
    return const AuthFailure('Adresse e-mail ou mot de passe incorrect.');
  }

  if (code == 'email_exists' ||
      code == 'user_already_exists' ||
      code == 'identity_already_exists' ||
      // Couvre à la fois "already registered" et "has already been
      // registered" (les deux formulations existent côté GoTrue selon les
      // versions), sans faux positif : les deux mots doivent être présents.
      (message.contains('already') && message.contains('registered'))) {
    return const AuthFailure(
      'Un compte existe déjà avec cette adresse e-mail.',
    );
  }

  if (code == 'weak_password') {
    return AuthFailure(
      'Le mot de passe doit contenir au moins '
      '${AuthValidators.minPasswordLength} caractères.',
    );
  }

  if (code == 'email_not_confirmed') {
    return const AuthFailure(
      "Confirmez votre adresse e-mail avant de vous connecter "
      "(vérifiez votre boîte de réception).",
    );
  }

  if (code == 'validation_failed' && message.contains('email')) {
    return const AuthFailure('Adresse e-mail invalide.');
  }

  if (code == 'over_request_rate_limit' ||
      code == 'over_email_send_rate_limit') {
    return const AuthFailure(
      'Trop de tentatives. Réessayez dans quelques instants.',
    );
  }

  return AuthFailure(
    error.message.isNotEmpty ? error.message : _genericErrorMessage,
  );
}

/// Message générique pour toute erreur qui n'est pas une [AuthException]
/// (ex. absence de réseau).
AuthFailure mapUnknownError() => const AuthFailure(_networkErrorMessage);
