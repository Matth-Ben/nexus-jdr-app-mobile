import 'package:freezed_annotation/freezed_annotation.dart';

import 'character_vital_status.dart';
import 'group_role.dart';

part 'group_member.freezed.dart';

/// Un membre d'un groupe, tel qu'affiché sur l'onglet "Membres" de l'écran
/// "Groupe" (`presentation/widgets/group_member_card.dart`) —
/// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.2.
///
/// Combine `group_members` (rôle) avec le sous-ensemble restreint de
/// `characters` que la RLS de groupe autorise à lire pour un coéquipier
/// (portrait, nom, race, classe, niveau, PV, PV temp., statut) — **n'affiche
/// jamais que ce sous-ensemble**, même discipline que côté RLS (voir la doc
/// de `GroupRepository.fetchGroupDetail`).
///
/// **Trois états possibles** (colonne `group_members.is_game_master`, voir
/// la migration web `20261016090000_group_members_orphan_character.sql`) :
/// - **avec personnage** : [characterId] non-null ([isGameMaster] toujours
///   `false` dans ce cas, contrainte posée côté base).
/// - **MJ volontaire** : [characterId] `null`, [isGameMaster] `true` — suit
///   le groupe sans fiche de personnage, par choix (voir `GroupJoinScreen`/
///   `GroupCreateScreen`). Au plus un MJ volontaire par groupe.
/// - **orphelin** ([isAwaitingCharacter]) : [characterId] `null`,
///   [isGameMaster] `false` — son personnage a été supprimé (`character_id`
///   passe à `null` côté serveur, `on delete set null`) ; doit rattacher un
///   nouveau personnage via `GroupRepository.setGroupCharacter` avant de
///   continuer à suivre ce groupe normalement (voir
///   `GroupCharacterReassignmentScreen`).
///
/// Tous les champs qui n'ont de sens que pour un personnage ([portraitUrl],
/// [raceName], [className], [level], [currentHp], [maxHp], [temporaryHp],
/// [isDead], [armorClass], [armorClassBonus]) sont `null` pour les deux cas
/// sans personnage (MJ volontaire ET orphelin) — [name] devient alors le nom
/// de COMPTE résolu via la colonne calculée PostgREST
/// `group_members_display_name` (voir `GroupMemberRowMapper`), qui résout le
/// vrai nom pour N'IMPORTE QUEL membre (contrairement à l'ancien mécanisme
/// limité au MJ lui-même).
@freezed
abstract class GroupMember with _$GroupMember {
  const GroupMember._();

  const factory GroupMember({
    String? characterId,
    required String userId,
    required GroupRole role,
    required String name,
    required bool isGameMaster,
    String? portraitUrl,
    String? raceName,
    String? className,
    int? level,
    int? currentHp,
    int? maxHp,
    int? temporaryHp,
    bool? isDead,
    String? accountDisplayName,

    /// Classe d'Armure totale (déjà `ArmorClassCalculator.compute` +
    /// [armorClassBonus]), affichée sous la ligne PV de l'onglet "Membres"
    /// (`group_members_tab_body.dart`) — voir `GroupMemberRowMapper` pour le
    /// calcul. `null` pour un membre sans personnage (MJ volontaire ou
    /// orphelin), même règle que [currentHp]/[maxHp].
    int? armorClass,

    /// `characters.armor_class_bonus` brut (bonus manuel), `0` si aucun bonus
    /// n'est actif — distinct d'[armorClass] (qui l'inclut déjà) pour piloter
    /// l'affichage du suffixe signé (`SignedModifierFormatter`) uniquement
    /// quand il est non nul. `null` pour un membre sans personnage, même
    /// règle qu'[armorClass].
    int? armorClassBonus,
  }) = _GroupMember;

  /// `true` si ce membre suit le groupe sans personnage et sans avoir choisi
  /// le rôle de MJ — son personnage a été supprimé (voir la doc de classe).
  /// Doit rattacher un nouveau personnage via
  /// `GroupRepository.setGroupCharacter` pour continuer à suivre ce groupe
  /// normalement.
  bool get isAwaitingCharacter => characterId == null && !isGameMaster;

  /// `null` si ce membre n'a pas de personnage (MJ volontaire OU orphelin —
  /// aucun statut vital n'a de sens sans fiche de personnage). Sinon,
  /// délègue à [CharacterVitalStatusResolver].
  CharacterVitalStatus? get vitalStatus {
    if (characterId == null) return null;
    return CharacterVitalStatusResolver.resolve(
      currentHp: currentHp ?? 0,
      isDead: isDead ?? false,
    );
  }

  /// Ratio de remplissage de la jauge PV — même formule que
  /// `CharacterDetail.hpRatio`. `0` si ce membre n'a pas de personnage (MJ
  /// volontaire ou orphelin, jamais affiché dans ces cas, voir
  /// `group_members_tab_body.dart`).
  double get hpRatio {
    final max = maxHp;
    final current = currentHp;
    if (characterId == null || max == null || current == null || max <= 0) {
      return 0;
    }
    return (current / max).clamp(0, 1).toDouble();
  }

  /// "Race · Classe · Niv. X", en omettant les segments non résolus — même
  /// règle que `CharacterCard._summaryLine`. Chaîne vide si ce membre n'a pas
  /// de personnage (MJ volontaire ou orphelin, jamais affiché dans ces cas).
  String get summaryLine {
    if (characterId == null) return '';
    final segments = [?raceName, ?className, if (level != null) 'Niv. $level'];
    return segments.join(' · ');
  }
}
