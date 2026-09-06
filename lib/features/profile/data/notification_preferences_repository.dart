import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/notification_preferences.dart';
import '../domain/profile_failure.dart';

/// Passerelle `notification_preferences` (table du chantier backend
/// "Notifications" — `docs/cahier-des-charges/15-profil-parametres.md`
/// section 3), consommée par `presentation/profile_notifications_screen.dart`
/// via `presentation/providers/notification_preferences_providers.dart`.
///
/// Abstraction (plutôt qu'une classe concrète directement injectée) pour
/// permettre aux tests de fournir un double sans jamais toucher à
/// `Supabase.instance.client` — même principe que
/// `features/characters/data/character_repository.dart::CharacterRepository`.
abstract class NotificationPreferencesRepository {
  /// Lit la ligne `notification_preferences` du joueur connecté — retourne
  /// [NotificationPreferences.defaults] si elle est absente (convention
  /// "absence de ligne == valeurs par défaut", voir la doc de classe de
  /// [NotificationPreferences]), jamais une exception pour ce cas précis.
  Future<NotificationPreferences> fetch();

  /// Upsert **partiel** : seuls les paramètres nommés non-`null` sont
  /// modifiés, les autres colonnes sont réécrites telles quelles depuis
  /// l'existant (ou les valeurs par défaut si la ligne n'existait pas encore
  /// — c'est cet appel qui la crée le cas échéant, jamais un appel
  /// séparé à la création de compte). Retourne l'état complet qui vient
  /// d'être enregistré.
  Future<NotificationPreferences> update({
    bool? pushEnabled,
    bool? pushRestReminder,
    bool? pushAccessRevoked,
    bool? emailDigestEnabled,
  });
}

class SupabaseNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  SupabaseNotificationPreferencesRepository(this._client);

  final SupabaseClient _client;

  static const String _table = 'notification_preferences';

  @override
  Future<NotificationPreferences> fetch() async {
    final row = await _client
        .from(_table)
        .select()
        .eq('user_id', _requireOwnerId())
        .maybeSingle();
    if (row == null) return const NotificationPreferences.defaults();
    return NotificationPreferences.fromRow(row);
  }

  @override
  Future<NotificationPreferences> update({
    bool? pushEnabled,
    bool? pushRestReminder,
    bool? pushAccessRevoked,
    bool? emailDigestEnabled,
  }) async {
    final ownerId = _requireOwnerId();
    // Fusionne avec l'état actuel (ligne existante ou défauts) avant
    // l'upsert : PostgREST `upsert` réécrit la ligne entière, jamais un
    // `UPDATE` partiel façon `PATCH` — voir la doc de classe.
    final current = await fetch();
    final merged = current.copyWith(
      pushEnabled: pushEnabled,
      pushRestReminder: pushRestReminder,
      pushAccessRevoked: pushAccessRevoked,
      emailDigestEnabled: emailDigestEnabled,
    );

    final row = await _client
        .from(_table)
        .upsert({
          'user_id': ownerId,
          'push_enabled': merged.pushEnabled,
          'push_rest_reminder': merged.pushRestReminder,
          'push_access_revoked': merged.pushAccessRevoked,
          'email_digest_enabled': merged.emailDigestEnabled,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'user_id')
        .select()
        .single();
    return NotificationPreferences.fromRow(row);
  }

  /// Identifiant du joueur connecté, ou lève une [ProfileFailure] "session
  /// expirée" — même message/rationale que
  /// `character_repository.dart::_requireOwnerId`.
  String _requireOwnerId() {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw const ProfileFailure(
        'Session expirée. Reconnectez-vous pour continuer.',
      );
    }
    return ownerId;
  }
}
