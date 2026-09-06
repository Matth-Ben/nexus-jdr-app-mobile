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
@freezed
abstract class GroupMember with _$GroupMember {
  const GroupMember._();

  const factory GroupMember({
    required String characterId,
    required String userId,
    required GroupRole role,
    required String name,
    String? portraitUrl,
    String? raceName,
    String? className,
    required int level,
    required int currentHp,
    required int maxHp,
    required int temporaryHp,
    required bool isDead,
  }) = _GroupMember;

  /// Voir [CharacterVitalStatusResolver].
  CharacterVitalStatus get vitalStatus => CharacterVitalStatusResolver.resolve(
    currentHp: currentHp,
    isDead: isDead,
  );

  /// Ratio de remplissage de la jauge PV — même formule que
  /// `CharacterDetail.hpRatio`.
  double get hpRatio {
    if (maxHp <= 0) return 0;
    return (currentHp / maxHp).clamp(0, 1).toDouble();
  }

  /// "Race · Classe · Niv. X", en omettant les segments non résolus — même
  /// règle que `CharacterCard._summaryLine`.
  String get summaryLine {
    final segments = [?raceName, ?className, 'Niv. $level'];
    return segments.join(' · ');
  }
}
