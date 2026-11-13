// `@JsonSerializable` posé sur la factory freezed (usage documenté par freezed).
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'combat_enums.dart';

part 'combat_participant.freezed.dart';
part 'combat_participant.g.dart';

/// Ligne `combat_participants` : nom + initiative, **aucune colonne PV**
/// (décision produit du 12/11/2026 : jamais de PV de monstre exposé).
@freezed
abstract class CombatParticipant with _$CombatParticipant {
  const CombatParticipant._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CombatParticipant({
    required String id,
    required String combatId,
    required String groupId,
    String? characterId,
    String? userId,
    required String name,
    required ParticipantKind kind,
    int? initiative,
    required int sortOrder,
    required ParticipantStatus status,
    DateTime? createdAt,
  }) = _CombatParticipant;

  factory CombatParticipant.fromJson(Map<String, dynamic> json) =>
      _$CombatParticipantFromJson(json);

  bool get isRemoved => status == ParticipantStatus.removed;

  bool get hasInitiative => initiative != null;
}
