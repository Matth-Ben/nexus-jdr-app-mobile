// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'combat_participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CombatParticipant _$CombatParticipantFromJson(Map<String, dynamic> json) =>
    _CombatParticipant(
      id: json['id'] as String,
      combatId: json['combat_id'] as String,
      groupId: json['group_id'] as String,
      characterId: json['character_id'] as String?,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      kind: $enumDecode(_$ParticipantKindEnumMap, json['kind']),
      initiative: (json['initiative'] as num?)?.toInt(),
      sortOrder: (json['sort_order'] as num).toInt(),
      status: $enumDecode(_$ParticipantStatusEnumMap, json['status']),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$CombatParticipantToJson(_CombatParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'combat_id': instance.combatId,
      'group_id': instance.groupId,
      'character_id': instance.characterId,
      'user_id': instance.userId,
      'name': instance.name,
      'kind': _$ParticipantKindEnumMap[instance.kind]!,
      'initiative': instance.initiative,
      'sort_order': instance.sortOrder,
      'status': _$ParticipantStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$ParticipantKindEnumMap = {
  ParticipantKind.pc: 'pc',
  ParticipantKind.npc: 'npc',
};

const _$ParticipantStatusEnumMap = {
  ParticipantStatus.active: 'active',
  ParticipantStatus.removed: 'removed',
  ParticipantStatus.waiting: 'waiting',
};
