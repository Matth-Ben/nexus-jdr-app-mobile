// `@JsonSerializable` posé sur la factory freezed (usage documenté par freezed).
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'combat_enums.dart';

part 'combat.freezed.dart';
part 'combat.g.dart';

/// Ligne `combats` d'un groupe (lecture seule côté client : toute écriture
/// passe par une RPC, voir `CombatRepository`).
///
/// [currentParticipantId] vient toujours du serveur (jamais calculé côté
/// client) ; il vaut `null` en V1 (« aucun tour actif »).
@freezed
abstract class Combat with _$Combat {
  const Combat._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Combat({
    required String id,
    required String groupId,
    required CombatStatus status,
    required int round,
    String? currentParticipantId,
    String? startedBy,
    DateTime? createdAt,
    DateTime? endedAt,
  }) = _Combat;

  factory Combat.fromJson(Map<String, dynamic> json) => _$CombatFromJson(json);

  bool get isActive => status == CombatStatus.active;
}
