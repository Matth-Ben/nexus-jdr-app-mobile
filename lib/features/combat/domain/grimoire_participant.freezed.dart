// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grimoire_participant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GrimoireParticipant {

/// Identifiant tiré au hasard par Grimoire pour ce combat.
 String get id; ParticipantKind get kind; String get name;/// Personnage Nexus d'un `pc` relié ; `null` pour un `npc` ou un `pc`
/// non relié.
 String? get characterId;/// Compte du joueur (« Toi ») ; `null` tant que Grimoire ne le connaît pas.
 String? get userId;/// `null` : « Initiative à saisir ».
 int? get initiative; ParticipantStatus get status;
/// Create a copy of GrimoireParticipant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrimoireParticipantCopyWith<GrimoireParticipant> get copyWith => _$GrimoireParticipantCopyWithImpl<GrimoireParticipant>(this as GrimoireParticipant, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrimoireParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.initiative, initiative) || other.initiative == initiative)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,name,characterId,userId,initiative,status);

@override
String toString() {
  return 'GrimoireParticipant(id: $id, kind: $kind, name: $name, characterId: $characterId, userId: $userId, initiative: $initiative, status: $status)';
}


}

/// @nodoc
abstract mixin class $GrimoireParticipantCopyWith<$Res>  {
  factory $GrimoireParticipantCopyWith(GrimoireParticipant value, $Res Function(GrimoireParticipant) _then) = _$GrimoireParticipantCopyWithImpl;
@useResult
$Res call({
 String id, ParticipantKind kind, String name, String? characterId, String? userId, int? initiative, ParticipantStatus status
});




}
/// @nodoc
class _$GrimoireParticipantCopyWithImpl<$Res>
    implements $GrimoireParticipantCopyWith<$Res> {
  _$GrimoireParticipantCopyWithImpl(this._self, this._then);

  final GrimoireParticipant _self;
  final $Res Function(GrimoireParticipant) _then;

/// Create a copy of GrimoireParticipant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? name = null,Object? characterId = freezed,Object? userId = freezed,Object? initiative = freezed,Object? status = null,}) {
  return _then(GrimoireParticipant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ParticipantKind,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,characterId: freezed == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,initiative: freezed == initiative ? _self.initiative : initiative // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ParticipantStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [GrimoireParticipant].
extension GrimoireParticipantPatterns on GrimoireParticipant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrimoireParticipant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrimoireParticipant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrimoireParticipant value)  $default,){
final _that = this;
switch (_that) {
case _GrimoireParticipant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrimoireParticipant value)?  $default,){
final _that = this;
switch (_that) {
case _GrimoireParticipant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ParticipantKind kind,  String name,  String? characterId,  String? userId,  int? initiative,  ParticipantStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrimoireParticipant() when $default != null:
return $default(_that.id,_that.kind,_that.name,_that.characterId,_that.userId,_that.initiative,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ParticipantKind kind,  String name,  String? characterId,  String? userId,  int? initiative,  ParticipantStatus status)  $default,) {final _that = this;
switch (_that) {
case _GrimoireParticipant():
return $default(_that.id,_that.kind,_that.name,_that.characterId,_that.userId,_that.initiative,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ParticipantKind kind,  String name,  String? characterId,  String? userId,  int? initiative,  ParticipantStatus status)?  $default,) {final _that = this;
switch (_that) {
case _GrimoireParticipant() when $default != null:
return $default(_that.id,_that.kind,_that.name,_that.characterId,_that.userId,_that.initiative,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _GrimoireParticipant extends GrimoireParticipant {
  const _GrimoireParticipant({required this.id, required this.kind, required this.name, this.characterId, this.userId, this.initiative, this.status = ParticipantStatus.active}): super._();
  

/// Identifiant tiré au hasard par Grimoire pour ce combat.
@override final  String id;
@override final  ParticipantKind kind;
@override final  String name;
/// Personnage Nexus d'un `pc` relié ; `null` pour un `npc` ou un `pc`
/// non relié.
@override final  String? characterId;
/// Compte du joueur (« Toi ») ; `null` tant que Grimoire ne le connaît pas.
@override final  String? userId;
/// `null` : « Initiative à saisir ».
@override final  int? initiative;
@override@JsonKey() final  ParticipantStatus status;

/// Create a copy of GrimoireParticipant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrimoireParticipantCopyWith<_GrimoireParticipant> get copyWith => __$GrimoireParticipantCopyWithImpl<_GrimoireParticipant>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrimoireParticipant&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.characterId, characterId) || other.characterId == characterId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.initiative, initiative) || other.initiative == initiative)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,name,characterId,userId,initiative,status);

@override
String toString() {
  return 'GrimoireParticipant(id: $id, kind: $kind, name: $name, characterId: $characterId, userId: $userId, initiative: $initiative, status: $status)';
}


}

/// @nodoc
abstract mixin class _$GrimoireParticipantCopyWith<$Res> implements $GrimoireParticipantCopyWith<$Res> {
  factory _$GrimoireParticipantCopyWith(_GrimoireParticipant value, $Res Function(_GrimoireParticipant) _then) = __$GrimoireParticipantCopyWithImpl;
@override @useResult
$Res call({
 String id, ParticipantKind kind, String name, String? characterId, String? userId, int? initiative, ParticipantStatus status
});




}
/// @nodoc
class __$GrimoireParticipantCopyWithImpl<$Res>
    implements _$GrimoireParticipantCopyWith<$Res> {
  __$GrimoireParticipantCopyWithImpl(this._self, this._then);

  final _GrimoireParticipant _self;
  final $Res Function(_GrimoireParticipant) _then;

/// Create a copy of GrimoireParticipant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? name = null,Object? characterId = freezed,Object? userId = freezed,Object? initiative = freezed,Object? status = null,}) {
  return _then(_GrimoireParticipant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ParticipantKind,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,characterId: freezed == characterId ? _self.characterId : characterId // ignore: cast_nullable_to_non_nullable
as String?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,initiative: freezed == initiative ? _self.initiative : initiative // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ParticipantStatus,
  ));
}


}

// dart format on
