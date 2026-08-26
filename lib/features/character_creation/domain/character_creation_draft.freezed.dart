// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_creation_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CharacterCreationDraft {

/// Race choisie à l'étape 1, `null` si race personnalisée ou pas encore
/// choisie.
 int? get raceId;/// Sous-race choisie à l'étape 1, `null` si la race n'a pas de sous-race
/// ou pas encore choisie.
 int? get subraceId;/// Texte libre de race personnalisée (étape 1), `null` si une race du
/// catalogue a été choisie à la place.
 String? get raceCustomText;/// Classe choisie à l'étape 2, `null` si pas encore choisie. Pas de
/// sous-classe ni de "classe personnalisée" à cette étape (décision du
/// chef de projet, voir `domain/class_catalog.dart`).
 int? get classId;
/// Create a copy of CharacterCreationDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterCreationDraftCopyWith<CharacterCreationDraft> get copyWith => _$CharacterCreationDraftCopyWithImpl<CharacterCreationDraft>(this as CharacterCreationDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterCreationDraft&&(identical(other.raceId, raceId) || other.raceId == raceId)&&(identical(other.subraceId, subraceId) || other.subraceId == subraceId)&&(identical(other.raceCustomText, raceCustomText) || other.raceCustomText == raceCustomText)&&(identical(other.classId, classId) || other.classId == classId));
}


@override
int get hashCode => Object.hash(runtimeType,raceId,subraceId,raceCustomText,classId);

@override
String toString() {
  return 'CharacterCreationDraft(raceId: $raceId, subraceId: $subraceId, raceCustomText: $raceCustomText, classId: $classId)';
}


}

/// @nodoc
abstract mixin class $CharacterCreationDraftCopyWith<$Res>  {
  factory $CharacterCreationDraftCopyWith(CharacterCreationDraft value, $Res Function(CharacterCreationDraft) _then) = _$CharacterCreationDraftCopyWithImpl;
@useResult
$Res call({
 int? raceId, int? subraceId, String? raceCustomText, int? classId
});




}
/// @nodoc
class _$CharacterCreationDraftCopyWithImpl<$Res>
    implements $CharacterCreationDraftCopyWith<$Res> {
  _$CharacterCreationDraftCopyWithImpl(this._self, this._then);

  final CharacterCreationDraft _self;
  final $Res Function(CharacterCreationDraft) _then;

/// Create a copy of CharacterCreationDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? raceId = freezed,Object? subraceId = freezed,Object? raceCustomText = freezed,Object? classId = freezed,}) {
  return _then(CharacterCreationDraft(
raceId: freezed == raceId ? _self.raceId : raceId // ignore: cast_nullable_to_non_nullable
as int?,subraceId: freezed == subraceId ? _self.subraceId : subraceId // ignore: cast_nullable_to_non_nullable
as int?,raceCustomText: freezed == raceCustomText ? _self.raceCustomText : raceCustomText // ignore: cast_nullable_to_non_nullable
as String?,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CharacterCreationDraft].
extension CharacterCreationDraftPatterns on CharacterCreationDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharacterCreationDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharacterCreationDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharacterCreationDraft value)  $default,){
final _that = this;
switch (_that) {
case _CharacterCreationDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharacterCreationDraft value)?  $default,){
final _that = this;
switch (_that) {
case _CharacterCreationDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? raceId,  int? subraceId,  String? raceCustomText,  int? classId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterCreationDraft() when $default != null:
return $default(_that.raceId,_that.subraceId,_that.raceCustomText,_that.classId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? raceId,  int? subraceId,  String? raceCustomText,  int? classId)  $default,) {final _that = this;
switch (_that) {
case _CharacterCreationDraft():
return $default(_that.raceId,_that.subraceId,_that.raceCustomText,_that.classId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? raceId,  int? subraceId,  String? raceCustomText,  int? classId)?  $default,) {final _that = this;
switch (_that) {
case _CharacterCreationDraft() when $default != null:
return $default(_that.raceId,_that.subraceId,_that.raceCustomText,_that.classId);case _:
  return null;

}
}

}

/// @nodoc


class _CharacterCreationDraft implements CharacterCreationDraft {
  const _CharacterCreationDraft({this.raceId, this.subraceId, this.raceCustomText, this.classId});
  

/// Race choisie à l'étape 1, `null` si race personnalisée ou pas encore
/// choisie.
@override final  int? raceId;
/// Sous-race choisie à l'étape 1, `null` si la race n'a pas de sous-race
/// ou pas encore choisie.
@override final  int? subraceId;
/// Texte libre de race personnalisée (étape 1), `null` si une race du
/// catalogue a été choisie à la place.
@override final  String? raceCustomText;
/// Classe choisie à l'étape 2, `null` si pas encore choisie. Pas de
/// sous-classe ni de "classe personnalisée" à cette étape (décision du
/// chef de projet, voir `domain/class_catalog.dart`).
@override final  int? classId;

/// Create a copy of CharacterCreationDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterCreationDraftCopyWith<_CharacterCreationDraft> get copyWith => __$CharacterCreationDraftCopyWithImpl<_CharacterCreationDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterCreationDraft&&(identical(other.raceId, raceId) || other.raceId == raceId)&&(identical(other.subraceId, subraceId) || other.subraceId == subraceId)&&(identical(other.raceCustomText, raceCustomText) || other.raceCustomText == raceCustomText)&&(identical(other.classId, classId) || other.classId == classId));
}


@override
int get hashCode => Object.hash(runtimeType,raceId,subraceId,raceCustomText,classId);

@override
String toString() {
  return 'CharacterCreationDraft(raceId: $raceId, subraceId: $subraceId, raceCustomText: $raceCustomText, classId: $classId)';
}


}

/// @nodoc
abstract mixin class _$CharacterCreationDraftCopyWith<$Res> implements $CharacterCreationDraftCopyWith<$Res> {
  factory _$CharacterCreationDraftCopyWith(_CharacterCreationDraft value, $Res Function(_CharacterCreationDraft) _then) = __$CharacterCreationDraftCopyWithImpl;
@override @useResult
$Res call({
 int? raceId, int? subraceId, String? raceCustomText, int? classId
});




}
/// @nodoc
class __$CharacterCreationDraftCopyWithImpl<$Res>
    implements _$CharacterCreationDraftCopyWith<$Res> {
  __$CharacterCreationDraftCopyWithImpl(this._self, this._then);

  final _CharacterCreationDraft _self;
  final $Res Function(_CharacterCreationDraft) _then;

/// Create a copy of CharacterCreationDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? raceId = freezed,Object? subraceId = freezed,Object? raceCustomText = freezed,Object? classId = freezed,}) {
  return _then(_CharacterCreationDraft(
raceId: freezed == raceId ? _self.raceId : raceId // ignore: cast_nullable_to_non_nullable
as int?,subraceId: freezed == subraceId ? _self.subraceId : subraceId // ignore: cast_nullable_to_non_nullable
as int?,raceCustomText: freezed == raceCustomText ? _self.raceCustomText : raceCustomText // ignore: cast_nullable_to_non_nullable
as String?,classId: freezed == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
