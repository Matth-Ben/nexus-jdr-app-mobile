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
/// **MJ sans personnage** (décision de Matthias du 12-13/10/2026, voir
/// `group_members.character_id` devenu nullable côté web PR #26) : un membre
/// peut suivre un groupe sans avoir de personnage, avec le rôle de MJ — "MJ
/// sans personnage" se déduit uniquement de [characterId] `null` ([isGameMaster]),
/// jamais d'un troisième cas de [GroupRole]. Tous les champs qui n'ont de
/// sens que pour un personnage ([portraitUrl], [raceName], [className],
/// [level], [currentHp], [maxHp], [temporaryHp], [isDead]) sont alors `null`
/// — [name] devient le nom de COMPTE du MJ plutôt qu'un nom de personnage
/// (voir `GroupMemberRowMapper`, qui ne peut résoudre ce nom que pour le MJ
/// lui-même via `auth.currentUser`, faute de colonne/fonction exposant le nom
/// de compte d'un AUTRE utilisateur — voir la doc de cette classe côté
/// mapper).
@freezed
abstract class GroupMember with _$GroupMember {
  const GroupMember._();

  const factory GroupMember({
    String? characterId,
    required String userId,
    required GroupRole role,
    required String name,
    String? portraitUrl,
    String? raceName,
    String? className,
    int? level,
    int? currentHp,
    int? maxHp,
    int? temporaryHp,
    bool? isDead,
  }) = _GroupMember;

  /// `true` si ce membre suit le groupe sans personnage, avec le rôle de
  /// MJ — voir la doc de classe. Au plus un membre MJ sans personnage par
  /// groupe (contrainte posée côté base, PR #26 du dépôt web).
  bool get isGameMaster => characterId == null;

  /// `null` pour un MJ sans personnage (aucun statut vital n'a de sens sans
  /// fiche de personnage) — voir [isGameMaster]. Sinon, délègue à
  /// [CharacterVitalStatusResolver].
  CharacterVitalStatus? get vitalStatus {
    if (isGameMaster) return null;
    return CharacterVitalStatusResolver.resolve(
      currentHp: currentHp ?? 0,
      isDead: isDead ?? false,
    );
  }

  /// Ratio de remplissage de la jauge PV — même formule que
  /// `CharacterDetail.hpRatio`. `0` pour un MJ sans personnage (jamais
  /// affiché dans ce cas, voir `group_members_tab_body.dart`).
  double get hpRatio {
    final max = maxHp;
    final current = currentHp;
    if (isGameMaster || max == null || current == null || max <= 0) return 0;
    return (current / max).clamp(0, 1).toDouble();
  }

  /// "Race · Classe · Niv. X", en omettant les segments non résolus — même
  /// règle que `CharacterCard._summaryLine`. Chaîne vide pour un MJ sans
  /// personnage (jamais affiché dans ce cas).
  String get summaryLine {
    if (isGameMaster) return '';
    final segments = [?raceName, ?className, if (level != null) 'Niv. $level'];
    return segments.join(' · ');
  }
}
