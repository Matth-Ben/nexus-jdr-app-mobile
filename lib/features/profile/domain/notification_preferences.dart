/// Préférences de notifications du joueur connecté (`notification_preferences`,
/// table du chantier backend "Notifications" —
/// `docs/cahier-des-charges/15-profil-parametres.md` section 3, appliquée
/// côté dépôt web `markdown-editor`) : écran "Préférences de notifications"
/// (`presentation/profile_notifications_screen.dart`, route
/// `/profile/notifications`).
///
/// Volontairement une classe simple (pas `freezed`) : même précédent que
/// `features/characters/domain/character_detail_class_row.dart::CharacterDetailClassRow`
/// — une donnée à 4 booléens, sans logique de sérialisation complexe (jamais
/// générée depuis le schéma Supabase, contrairement aux modèles de
/// `character_creation/`).
///
/// **Absence de ligne `notification_preferences` == ces valeurs par défaut**
/// (même convention que `character_spell_slots`, voir
/// `data/notification_preferences_repository.dart`) : ne jamais créer de
/// ligne à la création de compte, le défaut se gère uniquement côté lecture.
///
/// **Seulement 2 des 3 déclencheurs push de `15-profil-parametres.md`
/// section 3.1** : "Invitation à rejoindre une histoire reçue" n'a
/// volontairement aucun interrupteur ici (décision chef de projet, pas un
/// oubli) — le modèle d'invitation actuel est un code partagé hors bande
/// (`stories.invite_code`), pas une invitation nominative par joueur ; il
/// n'existe donc aucun événement serveur "invitation reçue par CET
/// utilisateur" à notifier tant que les invitations nominatives
/// (`12-partage-et-groupes.md` section 5.7, "extension future") ne sont pas
/// construites. À ajouter ici le jour où ce chantier existe.
class NotificationPreferences {
  const NotificationPreferences({
    this.pushEnabled = true,
    this.pushRestReminder = true,
    this.pushAccessRevoked = true,
    this.emailDigestEnabled = false,
  });

  /// Équivalent à `const NotificationPreferences()` — nommé explicitement
  /// pour les sites d'appel qui documentent l'intention "aucune ligne en
  /// base" (`SupabaseNotificationPreferencesRepository.fetch`), plutôt que le
  /// constructeur par défaut nu.
  const NotificationPreferences.defaults() : this();

  /// Interrupteur global "Activer les notifications push"
  /// (`_ToggleRow` de tête du groupe "NOTIFICATIONS PUSH") : à `false`,
  /// [pushRestReminder]/[pushAccessRevoked] sont sans effet côté backend
  /// (edge function FCM) et grisés côté UI (voir la doc de classe de
  /// `ProfileNotificationsScreen`).
  final bool pushEnabled;

  /// "Rappel de repos long" — dépend de [pushEnabled].
  final bool pushRestReminder;

  /// "Accès à une histoire retiré" — dépend de [pushEnabled].
  final bool pushAccessRevoked;

  /// "Recevoir un résumé par email" — indépendant de [pushEnabled] (canal
  /// email, pas push).
  final bool emailDigestEnabled;

  /// Construit depuis une ligne PostgREST `notification_preferences` — les
  /// valeurs par défaut de chaque paramètre nommé ne servent que de filet si
  /// jamais une colonne venait à manquer d'une ligne par ailleurs bien
  /// présente (ex. migration partielle), jamais le chemin normal d'une ligne
  /// absente (voir [defaults]/la doc de classe).
  factory NotificationPreferences.fromRow(Map<String, dynamic> row) {
    return NotificationPreferences(
      pushEnabled: row['push_enabled'] as bool? ?? true,
      pushRestReminder: row['push_rest_reminder'] as bool? ?? true,
      pushAccessRevoked: row['push_access_revoked'] as bool? ?? true,
      emailDigestEnabled: row['email_digest_enabled'] as bool? ?? false,
    );
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? pushRestReminder,
    bool? pushAccessRevoked,
    bool? emailDigestEnabled,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      pushRestReminder: pushRestReminder ?? this.pushRestReminder,
      pushAccessRevoked: pushAccessRevoked ?? this.pushAccessRevoked,
      emailDigestEnabled: emailDigestEnabled ?? this.emailDigestEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationPreferences &&
      other.pushEnabled == pushEnabled &&
      other.pushRestReminder == pushRestReminder &&
      other.pushAccessRevoked == pushAccessRevoked &&
      other.emailDigestEnabled == emailDigestEnabled;

  @override
  int get hashCode => Object.hash(
    pushEnabled,
    pushRestReminder,
    pushAccessRevoked,
    emailDigestEnabled,
  );
}
