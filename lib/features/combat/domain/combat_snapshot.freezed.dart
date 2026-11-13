// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'combat_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CombatSnapshot {

 Combat get combat; List<CombatParticipant> get participants;
/// Create a copy of CombatSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CombatSnapshotCopyWith<CombatSnapshot> get copyWith => _$CombatSnapshotCopyWithImpl<CombatSnapshot>(this as CombatSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CombatSnapshot&&(identical(other.combat, combat) || other.combat == combat)&&const DeepCollectionEquality().equals(other.participants, participants));
}


@override
int get hashCode => Object.hash(runtimeType,combat,const DeepCollectionEquality().hash(participants));

@override
String toString() {
  return 'CombatSnapshot(combat: $combat, participants: $participants)';
}


}

/// @nodoc
abstract mixin class $CombatSnapshotCopyWith<$Res>  {
  factory $CombatSnapshotCopyWith(CombatSnapshot value, $Res Function(CombatSnapshot) _then) = _$CombatSnapshotCopyWithImpl;
@useResult
$Res call({
 Combat combat, List<CombatParticipant> participants
});


$CombatCopyWith<$Res> get combat;

}
/// @nodoc
class _$CombatSnapshotCopyWithImpl<$Res>
    implements $CombatSnapshotCopyWith<$Res> {
  _$CombatSnapshotCopyWithImpl(this._self, this._then);

  final CombatSnapshot _self;
  final $Res Function(CombatSnapshot) _then;

/// Create a copy of CombatSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? combat = null,Object? participants = null,}) {
  return _then(CombatSnapshot(
combat: null == combat ? _self.combat : combat // ignore: cast_nullable_to_non_nullable
as Combat,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<CombatParticipant>,
  ));
}
/// Create a copy of CombatSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CombatCopyWith<$Res> get combat {
  
  return $CombatCopyWith<$Res>(_self.combat, (value) {
    return _then(_self.copyWith(combat: value));
  });
}
}


/// Adds pattern-matching-related methods to [CombatSnapshot].
extension CombatSnapshotPatterns on CombatSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CombatSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CombatSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CombatSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _CombatSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CombatSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _CombatSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Combat combat,  List<CombatParticipant> participants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CombatSnapshot() when $default != null:
return $default(_that.combat,_that.participants);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Combat combat,  List<CombatParticipant> participants)  $default,) {final _that = this;
switch (_that) {
case _CombatSnapshot():
return $default(_that.combat,_that.participants);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Combat combat,  List<CombatParticipant> participants)?  $default,) {final _that = this;
switch (_that) {
case _CombatSnapshot() when $default != null:
return $default(_that.combat,_that.participants);case _:
  return null;

}
}

}

/// @nodoc


class _CombatSnapshot extends CombatSnapshot {
  const _CombatSnapshot({required this.combat, required  List<CombatParticipant> participants}): _participants = participants,super._();
  

@override final  Combat combat;
 final  List<CombatParticipant> _participants;
@override List<CombatParticipant> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}


/// Create a copy of CombatSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CombatSnapshotCopyWith<_CombatSnapshot> get copyWith => __$CombatSnapshotCopyWithImpl<_CombatSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CombatSnapshot&&(identical(other.combat, combat) || other.combat == combat)&&const DeepCollectionEquality().equals(other._participants, _participants));
}


@override
int get hashCode => Object.hash(runtimeType,combat,const DeepCollectionEquality().hash(_participants));

@override
String toString() {
  return 'CombatSnapshot(combat: $combat, participants: $participants)';
}


}

/// @nodoc
abstract mixin class _$CombatSnapshotCopyWith<$Res> implements $CombatSnapshotCopyWith<$Res> {
  factory _$CombatSnapshotCopyWith(_CombatSnapshot value, $Res Function(_CombatSnapshot) _then) = __$CombatSnapshotCopyWithImpl;
@override @useResult
$Res call({
 Combat combat, List<CombatParticipant> participants
});


@override $CombatCopyWith<$Res> get combat;

}
/// @nodoc
class __$CombatSnapshotCopyWithImpl<$Res>
    implements _$CombatSnapshotCopyWith<$Res> {
  __$CombatSnapshotCopyWithImpl(this._self, this._then);

  final _CombatSnapshot _self;
  final $Res Function(_CombatSnapshot) _then;

/// Create a copy of CombatSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? combat = null,Object? participants = null,}) {
  return _then(_CombatSnapshot(
combat: null == combat ? _self.combat : combat // ignore: cast_nullable_to_non_nullable
as Combat,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<CombatParticipant>,
  ));
}

/// Create a copy of CombatSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CombatCopyWith<$Res> get combat {
  
  return $CombatCopyWith<$Res>(_self.combat, (value) {
    return _then(_self.copyWith(combat: value));
  });
}
}

// dart format on
