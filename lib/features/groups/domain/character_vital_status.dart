/// Statut vivant/inconscient/mort d'un personnage, tel qu'affiché sur la
/// carte membre de l'écran "Groupe" (`presentation/widgets/group_member_card.dart`)
/// — voir `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2 :
/// "réutilise le statut mort déjà prévu ... en tant que simple flag manuel,
/// sans simulation des règles de mort complètes".
enum CharacterVitalStatus {
  /// PV courants > 0 et `characters.is_dead` faux — aucun badge affiché.
  alive,

  /// Dérivé : PV courants à 0 mais `characters.is_dead` toujours faux.
  unconscious,

  /// Stocké : `characters.is_dead` vrai, quels que soient les PV courants
  /// (prioritaire sur [unconscious] — un personnage marqué mort reste
  /// "mort" même si ses PV sont ensuite remontés sans avoir été
  /// "ressuscité" explicitement).
  dead,
}

/// Résolution pure du statut — voir [CharacterVitalStatus].
abstract final class CharacterVitalStatusResolver {
  static CharacterVitalStatus resolve({
    required int currentHp,
    required bool isDead,
  }) {
    if (isDead) return CharacterVitalStatus.dead;
    if (currentHp <= 0) return CharacterVitalStatus.unconscious;
    return CharacterVitalStatus.alive;
  }
}
