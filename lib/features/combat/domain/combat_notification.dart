/// Notifications push du combat : format des données d'ouverture (FCM `data`,
/// valeurs texte) envoyées par `notify-group` (contrat DeepCore
/// `docs/api-v1/contrat-temps-reel-combat.md` §5) : `{v: "1", type,
/// group_id}`.
///
/// **Réutilisable par le combat natif V2** (décision 59) : il enverra le même
/// format, donc le même routage (`docs/combat-grimoire-ui.md` §8).
library;

/// Types de notification de combat compris par Nexus. `reveal` (étape 10)
/// n'en fait pas partie.
enum CombatNotificationType {
  /// `combat_start` : début du combat.
  combatStart,

  /// `your_turn` : « À toi de jouer ».
  yourTurn,
}

/// Notification de combat : son type et le groupe concerné.
typedef CombatNotificationTarget = ({
  CombatNotificationType type,
  String groupId,
});

final RegExp _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Données au format versionné (`v` = `"1"`) : un type inconnu de ce format
/// est ignoré, jamais routé comme une autre notification.
bool isVersionedNotificationData(Map<String, dynamic> data) =>
    data['v']?.toString() == '1';

/// Notification de combat lue dans [data], ou `null` : autre format, type
/// inconnu (ignoré), ou `group_id` qui n'est pas un uuid (jamais placé tel
/// quel dans une route).
CombatNotificationTarget? parseCombatNotificationData(
  Map<String, dynamic> data,
) {
  if (!isVersionedNotificationData(data)) return null;
  final type = switch (data['type']) {
    'combat_start' => CombatNotificationType.combatStart,
    'your_turn' => CombatNotificationType.yourTurn,
    _ => null,
  };
  final groupId = data['group_id'];
  if (type == null || groupId is! String || !_uuid.hasMatch(groupId)) {
    return null;
  }
  return (type: type, groupId: groupId);
}
