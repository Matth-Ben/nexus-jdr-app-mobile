import 'package:supabase_flutter/supabase_flutter.dart';

/// Passerelle `user_push_tokens` (table du chantier backend "Notifications" —
/// `docs/cahier-des-charges/15-profil-parametres.md` section 3), consommée
/// exclusivement par [PushTokenRegistrar] (`push_token_registrar.dart`).
///
/// Abstraction (plutôt qu'une classe concrète directement injectée) pour
/// permettre aux tests de fournir un double sans jamais toucher à
/// `Supabase.instance.client` — même principe que
/// `features/profile/data/notification_preferences_repository.dart`.
abstract class PushTokenRepository {
  /// Réclame `(token, platform)` pour l'utilisateur courant via la fonction
  /// RPC `claim_push_token` (dépôt web, `SECURITY DEFINER`) — jamais un
  /// upsert direct sur la table : un jeton FCM peut déjà appartenir à un
  /// AUTRE utilisateur (ex. réinstallation de l'app sous un autre compte sur
  /// le même appareil), ce qu'une policy RLS classique (scoped au
  /// propriétaire actuel de la ligne) ne peut pas autoriser sans s'ouvrir à
  /// une policy UPDATE trop permissive. La fonction force côté serveur
  /// `user_id = auth.uid()` quoi qu'on lui passe, donc réclamer un jeton ne
  /// peut jamais se faire "au nom" de quelqu'un d'autre.
  ///
  /// Silencieux si personne n'est connecté (session expirée entre la lecture
  /// du jeton et cet appel) : best-effort, jamais d'exception propagée —
  /// voir la doc de classe de [PushTokenRegistrar].
  Future<void> upsertToken({required String token, required String platform});
}

class SupabasePushTokenRepository implements PushTokenRepository {
  SupabasePushTokenRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsertToken({
    required String token,
    required String platform,
  }) async {
    if (_client.auth.currentUser?.id == null) return;

    await _client.rpc(
      'claim_push_token',
      params: {'p_token': token, 'p_platform': platform},
    );
  }
}
