// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'combat.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Combat {

 String get id; String get groupId; CombatStatus get status; int get round; String? get currentParticipantId; String? get startedBy; DateTime? get createdAt; DateTime? get endedAt;
/// Create a copy of Combat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CombatCopyWith<Combat> get copyWith => _$CombatCopyWithImpl<Combat>(this as Combat, _$identity);

  /// Serializes this Combat to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Combat&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.status, status) || other.status == status)&&(identical(other.round, round) || other.round == round)&&(identical(other.currentParticipantId, currentParticipantId) || other.currentParticipantId == currentParticipantId)&&(identical(other.startedBy, startedBy) || other.startedBy == startedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,groupId,status,round,currentParticipantId,startedBy,createdAt,endedAt);

@override
String toString() {
  return 'Combat(id: $id, groupId: $groupId, status: $status, round: $round, currentParticipantId: $currentParticipantId, startedBy: $startedBy, createdAt: $createdAt, endedAt: $endedAt)';
}


}

/// @nodoc
abstract mixin class $CombatCopyWith<$Res>  {
  factory $CombatCopyWith(Combat value, $Res Function(Combat) _then) = _$CombatCopyWithImpl;
@useResult
$Res call({
 String id, String groupId, CombatStatus status, int round, String? currentParticipantId, String? startedBy, DateTime? createdAt, DateTime? endedAt
});




}
/// @nodoc
class _$CombatCopyWithImpl<$Res>
    implements $CombatCopyWith<$Res> {
  _$CombatCopyWithImpl(this._self, this._then);

  final Combat _self;
  final $Res Function(Combat) _then;

/// Create a copy of Combat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? groupId = null,Object? status = null,Object? round = null,Object? currentParticipantId = freezed,Object? startedBy = freezed,Object? createdAt = freezed,Object? endedAt = freezed,}) {
  return _then(Combat(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CombatStatus,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,currentParticipantId: freezed == currentParticipantId ? _self.currentParticipantId : currentParticipantId // ignore: cast_nullable_to_non_nullable
as String?,startedBy: freezed == startedBy ? _self.startedBy : startedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Combat].
extension CombatPatterns on Combat {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Combat value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Combat() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Combat value)  $default,){
final _that = this;
switch (_that) {
case _Combat():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Combat value)?  $default,){
final _that = this;
switch (_that) {
case _Combat() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String groupId,  CombatStatus status,  int round,  String? currentParticipantId,  String? startedBy,  DateTime? createdAt,  DateTime? endedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Combat() when $default != null:
return $default(_that.id,_that.groupId,_that.status,_that.round,_that.currentParticipantId,_that.startedBy,_that.createdAt,_that.endedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String groupId,  CombatStatus status,  int round,  String? currentParticipantId,  String? startedBy,  DateTime? createdAt,  DateTime? endedAt)  $default,) {final _that = this;
switch (_that) {
case _Combat():
return $default(_that.id,_that.groupId,_that.status,_that.round,_that.currentParticipantId,_that.startedBy,_that.createdAt,_that.endedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String groupId,  CombatStatus status,  int round,  String? currentParticipantId,  String? startedBy,  DateTime? createdAt,  DateTime? endedAt)?  $default,) {final _that = this;
switch (_that) {
case _Combat() when $default != null:
return $default(_that.id,_that.groupId,_that.status,_that.round,_that.currentParticipantId,_that.startedBy,_that.createdAt,_that.endedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake)
class _Combat extends Combat {
  const _Combat({required this.id, required this.groupId, required this.status, required this.round, this.currentParticipantId, this.startedBy, this.createdAt, this.endedAt}): super._();
  factory _Combat.fromJson(Map<String, dynamic> json) => _$CombatFromJson(json);

@override final  String id;
@override final  String groupId;
@override final  CombatStatus status;
@override final  int round;
@override final  String? currentParticipantId;
@override final  String? startedBy;
@override final  DateTime? createdAt;
@override final  DateTime? endedAt;

/// Create a copy of Combat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CombatCopyWith<_Combat> get copyWith => __$CombatCopyWithImpl<_Combat>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CombatToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Combat&&(identical(other.id, id) || other.id == id)&&(identical(other.groupId, groupId) || other.groupId == groupId)&&(identical(other.status, status) || other.status == status)&&(identical(other.round, round) || other.round == round)&&(identical(other.currentParticipantId, currentParticipantId) || other.currentParticipantId == currentParticipantId)&&(identical(other.startedBy, startedBy) || other.startedBy == startedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,groupId,status,round,currentParticipantId,startedBy,createdAt,endedAt);

@override
String toString() {
  return 'Combat(id: $id, groupId: $groupId, status: $status, round: $round, currentParticipantId: $currentParticipantId, startedBy: $startedBy, createdAt: $createdAt, endedAt: $endedAt)';
}


}

/// @nodoc
abstract mixin class _$CombatCopyWith<$Res> implements $CombatCopyWith<$Res> {
  factory _$CombatCopyWith(_Combat value, $Res Function(_Combat) _then) = __$CombatCopyWithImpl;
@override @useResult
$Res call({
 String id, String groupId, CombatStatus status, int round, String? currentParticipantId, String? startedBy, DateTime? createdAt, DateTime? endedAt
});




}
/// @nodoc
class __$CombatCopyWithImpl<$Res>
    implements _$CombatCopyWith<$Res> {
  __$CombatCopyWithImpl(this._self, this._then);

  final _Combat _self;
  final $Res Function(_Combat) _then;

/// Create a copy of Combat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? groupId = null,Object? status = null,Object? round = null,Object? currentParticipantId = freezed,Object? startedBy = freezed,Object? createdAt = freezed,Object? endedAt = freezed,}) {
  return _then(_Combat(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,groupId: null == groupId ? _self.groupId : groupId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CombatStatus,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,currentParticipantId: freezed == currentParticipantId ? _self.currentParticipantId : currentParticipantId // ignore: cast_nullable_to_non_nullable
as String?,startedBy: freezed == startedBy ? _self.startedBy : startedBy // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
