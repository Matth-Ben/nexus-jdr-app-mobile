// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'combat_participant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CombatParticipant {

 String get id; String get combatId; String get groupId; String? get characterId; String? get userId; String get name; ParticipantKind get kind; int? get initiative; int get sortOrder; ParticipantStatus get status; DateTime? get createdAt;
/// Create a copy of CombatParticipant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CombatParticipantCopyWith<CombatParticipant> get copyWith => _$CombatParticipantCopyWithImpl<CombatParticipant>(this as CombatParticipant, _$identity);

  /// Serializes this CombatParticipant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CombatParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.combatId, combatId) || other.combatId == combatId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.initiative, initiative) || other.initiative == initiative)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,combatId,groupId,characterId,userId,name,kind,initiative,sortOrder,status,createdAt);

@override
String toString() {
  return 'CombatParticipant(id: $id, combatId: $combatId, groupId: $groupId, characterId: $characterId, userId: $userId, name: $name, kind: $kind, initiative: $initiative, sortOrder: $sortOrder, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CombatParticipantCopyWith<$Res>  {
  factory $CombatParticipantCopyWith(CombatParticipant value, $Res Function(CombatParticipant) _then) = _$CombatParticipantCopyWithImpl;
@useResult
$Res call({
 String id, String combatId, String groupId, String? characterId, String? userId, String name, ParticipantKind kind, int? initiative, int sortOrder, ParticipantStatus status, DateTime? createdAt
});




}
/// @nodoc
class _$CombatParticipantCopyWithImpl<$Res>
    implements $CombatParticipantCopyWith<$Res> {
  _$CombatParticipantCopyWithImpl(this._self, this._then);

  final CombatParticipant _self;
  final $Res Function(CombatParticipant) _then;

/// Create a copy of CombatParticipant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? combatId = null,Object? groupId = null,Object? characterId = freezed,Object? userId = freezed,Object? name = null,Object? kind = null,Object? initiative = freezed,Object? sortOrder = null,Object? status = null,Object? createdAt = freezed,}) {
  return _then(CombatParticipant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,combatId: null == combatId ? _self.combatId : combatId // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,characterId: freezed == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ParticipantKind,initiative: freezed == initiative ? _self.initiative : initiative // ignore: cast_nullable_to_non_nullable
as int?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ParticipantStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CombatParticipant].
extension CombatParticipantPatterns on CombatParticipant {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CombatParticipant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CombatParticipant() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CombatParticipant value)  $default,){
final _that = this;
switch (_that) {
case _CombatParticipant():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CombatParticipant value)?  $default,){
final _that = this;
switch (_that) {
case _CombatParticipant() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String combatId,  String groupId,  String? characterId,  String? userId,  String name,  ParticipantKind kind,  int? initiative,  int sortOrder,  ParticipantStatus status,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CombatParticipant() when $default != null:
return $default(_that.id,_that.combatId,_that.groupId,_that.characterId,_that.userId,_that.name,_that.kind,_that.initiative,_that.sortOrder,_that.status,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String combatId,  String groupId,  String? characterId,  String? userId,  String name,  ParticipantKind kind,  int? initiative,  int sortOrder,  ParticipantStatus status,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _CombatParticipant():
return $default(_that.id,_that.combatId,_that.groupId,_that.characterId,_that.userId,_that.name,_that.kind,_that.initiative,_that.sortOrder,_that.status,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String combatId,  String groupId,  String? characterId,  String? userId,  String name,  ParticipantKind kind,  int? initiative,  int sortOrder,  ParticipantStatus status,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CombatParticipant() when $default != null:
return $default(_that.id,_that.combatId,_that.groupId,_that.characterId,_that.userId,_that.name,_that.kind,_that.initiative,_that.sortOrder,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _CombatParticipant extends CombatParticipant {
  const _CombatParticipant({required this.id, required this.combatId, required this.groupId, this.characterId, this.userId, required this.name, required this.kind, this.initiative, required this.sortOrder, required this.status, this.createdAt}): super._();
  factory _CombatParticipant.fromJson(Map<String, dynamic> json) => _$CombatParticipantFromJson(json);

@override final  String id;
@override final  String combatId;
@override final  String groupId;
@override final  String? characterId;
@override final  String? userId;
@override final  String name;
@override final  ParticipantKind kind;
@override final  int? initiative;
@override final  int sortOrder;
@override final  ParticipantStatus status;
@override final  DateTime? createdAt;

/// Create a copy of CombatParticipant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CombatParticipantCopyWith<_CombatParticipant> get copyWith => __$CombatParticipantCopyWithImpl<_CombatParticipant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CombatParticipantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CombatParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.combatId, combatId) || other.combatId == combatId)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.initiative, initiative) || other.initiative == initiative)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,combatId,groupId,characterId,userId,name,kind,initiative,sortOrder,status,createdAt);

@override
String toString() {
  return 'CombatParticipant(id: $id, combatId: $combatId, groupId: $groupId, characterId: $characterId, userId: $userId, name: $name, kind: $kind, initiative: $initiative, sortOrder: $sortOrder, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CombatParticipantCopyWith<$Res> implements $CombatParticipantCopyWith<$Res> {
  factory _$CombatParticipantCopyWith(_CombatParticipant value, $Res Function(_CombatParticipant) _then) = __$CombatParticipantCopyWithImpl;
@override @useResult
$Res call({
 String id, String combatId, String groupId, String? characterId, String? userId, String name, ParticipantKind kind, int? initiative, int sortOrder, ParticipantStatus status, DateTime? createdAt
});




}
/// @nodoc
class __$CombatParticipantCopyWithImpl<$Res>
    implements _$CombatParticipantCopyWith<$Res> {
  __$CombatParticipantCopyWithImpl(this._self, this._then);

  final _CombatParticipant _self;
  final $Res Function(_CombatParticipant) _then;

/// Create a copy of CombatParticipant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? combatId = null,Object? groupId = null,Object? characterId = freezed,Object? userId = freezed,Object? name = null,Object? kind = null,Object? initiative = freezed,Object? sortOrder = null,Object? status = null,Object? createdAt = freezed,}) {
  return _then(_CombatParticipant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,combatId: null == combatId ? _self.combatId : combatId // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,characterId: freezed == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ParticipantKind,initiative: freezed == initiative ? _self.initiative : initiative // ignore: cast_nullable_to_non_nullable
as int?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ParticipantStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
