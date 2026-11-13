// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'combat_view_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CombatViewState {

 CombatPhase get phase;/// Dernier état connu (combat actif, ou combat juste terminé).
 CombatSnapshot? get snapshot;/// Horodatage (horloge injectée) du dernier refetch réussi.
 DateTime? get lastKnownAt;/// `true` si le dernier refetch a échoué alors qu'un état était déjà
/// connu : l'état affiché est périmé, lecture seule.
 bool get isStale;/// Dernier échec (refetch ou premier chargement).
 CombatFailure? get failure;
/// Create a copy of CombatViewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CombatViewStateCopyWith<CombatViewState> get copyWith => _$CombatViewStateCopyWithImpl<CombatViewState>(this as CombatViewState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CombatViewState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&(identical(other.lastKnownAt, lastKnownAt) || other.lastKnownAt == lastKnownAt)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,phase,snapshot,lastKnownAt,isStale,failure);

@override
String toString() {
  return 'CombatViewState(phase: $phase, snapshot: $snapshot, lastKnownAt: $lastKnownAt, isStale: $isStale, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CombatViewStateCopyWith<$Res>  {
  factory $CombatViewStateCopyWith(CombatViewState value, $Res Function(CombatViewState) _then) = _$CombatViewStateCopyWithImpl;
@useResult
$Res call({
 CombatPhase phase, CombatSnapshot? snapshot, DateTime? lastKnownAt, bool isStale, CombatFailure? failure
});


$CombatSnapshotCopyWith<$Res>? get snapshot;

}
/// @nodoc
class _$CombatViewStateCopyWithImpl<$Res>
    implements $CombatViewStateCopyWith<$Res> {
  _$CombatViewStateCopyWithImpl(this._self, this._then);

  final CombatViewState _self;
  final $Res Function(CombatViewState) _then;

/// Create a copy of CombatViewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? snapshot = freezed,Object? lastKnownAt = freezed,Object? isStale = null,Object? failure = freezed,}) {
  return _then(CombatViewState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as CombatPhase,snapshot: freezed == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as CombatSnapshot?,lastKnownAt: freezed == lastKnownAt ? _self.lastKnownAt : lastKnownAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as CombatFailure?,
  ));
}
/// Create a copy of CombatViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CombatSnapshotCopyWith<$Res>? get snapshot {
    if (_self.snapshot == null) {
    return null;
  }

  return $CombatSnapshotCopyWith<$Res>(_self.snapshot!, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}
}


/// Adds pattern-matching-related methods to [CombatViewState].
extension CombatViewStatePatterns on CombatViewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CombatViewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CombatViewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CombatViewState value)  $default,){
final _that = this;
switch (_that) {
case _CombatViewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CombatViewState value)?  $default,){
final _that = this;
switch (_that) {
case _CombatViewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CombatPhase phase,  CombatSnapshot? snapshot,  DateTime? lastKnownAt,  bool isStale,  CombatFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CombatViewState() when $default != null:
return $default(_that.phase,_that.snapshot,_that.lastKnownAt,_that.isStale,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CombatPhase phase,  CombatSnapshot? snapshot,  DateTime? lastKnownAt,  bool isStale,  CombatFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _CombatViewState():
return $default(_that.phase,_that.snapshot,_that.lastKnownAt,_that.isStale,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CombatPhase phase,  CombatSnapshot? snapshot,  DateTime? lastKnownAt,  bool isStale,  CombatFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _CombatViewState() when $default != null:
return $default(_that.phase,_that.snapshot,_that.lastKnownAt,_that.isStale,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _CombatViewState extends CombatViewState {
  const _CombatViewState({required this.phase, this.snapshot, this.lastKnownAt, this.isStale = false, this.failure}): super._();
  

@override final  CombatPhase phase;
/// Dernier état connu (combat actif, ou combat juste terminé).
@override final  CombatSnapshot? snapshot;
/// Horodatage (horloge injectée) du dernier refetch réussi.
@override final  DateTime? lastKnownAt;
/// `true` si le dernier refetch a échoué alors qu'un état était déjà
/// connu : l'état affiché est périmé, lecture seule.
@override@JsonKey() final  bool isStale;
/// Dernier échec (refetch ou premier chargement).
@override final  CombatFailure? failure;

/// Create a copy of CombatViewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CombatViewStateCopyWith<_CombatViewState> get copyWith => __$CombatViewStateCopyWithImpl<_CombatViewState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CombatViewState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&(identical(other.lastKnownAt, lastKnownAt) || other.lastKnownAt == lastKnownAt)&&(identical(other.isStale, isStale) || other.isStale == isStale)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,phase,snapshot,lastKnownAt,isStale,failure);

@override
String toString() {
  return 'CombatViewState(phase: $phase, snapshot: $snapshot, lastKnownAt: $lastKnownAt, isStale: $isStale, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$CombatViewStateCopyWith<$Res> implements $CombatViewStateCopyWith<$Res> {
  factory _$CombatViewStateCopyWith(_CombatViewState value, $Res Function(_CombatViewState) _then) = __$CombatViewStateCopyWithImpl;
@override @useResult
$Res call({
 CombatPhase phase, CombatSnapshot? snapshot, DateTime? lastKnownAt, bool isStale, CombatFailure? failure
});


@override $CombatSnapshotCopyWith<$Res>? get snapshot;

}
/// @nodoc
class __$CombatViewStateCopyWithImpl<$Res>
    implements _$CombatViewStateCopyWith<$Res> {
  __$CombatViewStateCopyWithImpl(this._self, this._then);

  final _CombatViewState _self;
  final $Res Function(_CombatViewState) _then;

/// Create a copy of CombatViewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? snapshot = freezed,Object? lastKnownAt = freezed,Object? isStale = null,Object? failure = freezed,}) {
  return _then(_CombatViewState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as CombatPhase,snapshot: freezed == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as CombatSnapshot?,lastKnownAt: freezed == lastKnownAt ? _self.lastKnownAt : lastKnownAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isStale: null == isStale ? _self.isStale : isStale // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as CombatFailure?,
  ));
}

/// Create a copy of CombatViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CombatSnapshotCopyWith<$Res>? get snapshot {
    if (_self.snapshot == null) {
    return null;
  }

  return $CombatSnapshotCopyWith<$Res>(_self.snapshot!, (value) {
    return _then(_self.copyWith(snapshot: value));
  });
}
}

// dart format on
