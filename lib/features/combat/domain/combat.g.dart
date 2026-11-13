// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Combat _$CombatFromJson(Map<String, dynamic> json) => _Combat(
  id: json['id'] as String,
  groupId: json['group_id'] as String,
  status: $enumDecode(_$CombatStatusEnumMap, json['status']),
  round: (json['round'] as num).toInt(),
  currentParticipantId: json['current_participant_id'] as String?,
  startedBy: json['started_by'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  endedAt: json['ended_at'] == null
      ? null
      : DateTime.parse(json['ended_at'] as String),
);

Map<String, dynamic> _$CombatToJson(_Combat instance) => <String, dynamic>{
  'id': instance.id,
  'group_id': instance.groupId,
  'status': _$CombatStatusEnumMap[instance.status]!,
  'round': instance.round,
  'current_participant_id': instance.currentParticipantId,
  'started_by': instance.startedBy,
  'created_at': instance.createdAt?.toIso8601String(),
  'ended_at': instance.endedAt?.toIso8601String(),
};

const _$CombatStatusEnumMap = {
  CombatStatus.active: 'active',
  CombatStatus.ended: 'ended',
};
