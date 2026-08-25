// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'character_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CharacterSummary {

 String get id; String get name;/// URL publique/signée du portrait (`characters.portrait_url`), `null`
/// si le joueur n'en a pas encore défini un.
 String? get portraitUrl;/// Nom de race traduit (via `translations`), `null` si race
/// personnalisée (homebrew) ou non résolue.
 String? get raceName;/// Nom de la classe principale traduit (`character_classes.is_primary`
/// = true, ou la première classe à défaut), `null` si le personnage n'a
/// aucune classe enregistrée.
 String? get className;/// Niveau total, somme de `character_classes.level` (gère le
/// multiclassage de façon simple : un personnage niveau 3/2 est affiché
/// "Niv. 5").
 int get level;/// XP cumulée actuelle (`characters.xp`).
 int get xp;
/// Create a copy of CharacterSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharacterSummaryCopyWith<CharacterSummary> get copyWith => _$CharacterSummaryCopyWithImpl<CharacterSummary>(this as CharacterSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharacterSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.portraitUrl, portraitUrl) || other.portraitUrl == portraitUrl)&&(identical(other.raceName, raceName) || other.raceName == raceName)&&(identical(other.className, className) || other.className == className)&&(identical(other.level, level) || other.level == level)&&(identical(other.xp, xp) || other.xp == xp));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,portraitUrl,raceName,className,level,xp);

@override
String toString() {
  return 'CharacterSummary(id: $id, name: $name, portraitUrl: $portraitUrl, raceName: $raceName, className: $className, level: $level, xp: $xp)';
}


}

/// @nodoc
abstract mixin class $CharacterSummaryCopyWith<$Res>  {
  factory $CharacterSummaryCopyWith(CharacterSummary value, $Res Function(CharacterSummary) _then) = _$CharacterSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? portraitUrl, String? raceName, String? className, int level, int xp
});




}
/// @nodoc
class _$CharacterSummaryCopyWithImpl<$Res>
    implements $CharacterSummaryCopyWith<$Res> {
  _$CharacterSummaryCopyWithImpl(this._self, this._then);

  final CharacterSummary _self;
  final $Res Function(CharacterSummary) _then;

/// Create a copy of CharacterSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? portraitUrl = freezed,Object? raceName = freezed,Object? className = freezed,Object? level = null,Object? xp = null,}) {
  return _then(CharacterSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,portraitUrl: freezed == portraitUrl ? _self.portraitUrl : portraitUrl // ignore: cast_nullable_to_non_nullable
as String?,raceName: freezed == raceName ? _self.raceName : raceName // ignore: cast_nullable_to_non_nullable
as String?,className: freezed == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CharacterSummary].
extension CharacterSummaryPatterns on CharacterSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharacterSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharacterSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharacterSummary value)  $default,){
final _that = this;
switch (_that) {
case _CharacterSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharacterSummary value)?  $default,){
final _that = this;
switch (_that) {
case _CharacterSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? portraitUrl,  String? raceName,  String? className,  int level,  int xp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharacterSummary() when $default != null:
return $default(_that.id,_that.name,_that.portraitUrl,_that.raceName,_that.className,_that.level,_that.xp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? portraitUrl,  String? raceName,  String? className,  int level,  int xp)  $default,) {final _that = this;
switch (_that) {
case _CharacterSummary():
return $default(_that.id,_that.name,_that.portraitUrl,_that.raceName,_that.className,_that.level,_that.xp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? portraitUrl,  String? raceName,  String? className,  int level,  int xp)?  $default,) {final _that = this;
switch (_that) {
case _CharacterSummary() when $default != null:
return $default(_that.id,_that.name,_that.portraitUrl,_that.raceName,_that.className,_that.level,_that.xp);case _:
  return null;

}
}

}

/// @nodoc


class _CharacterSummary extends CharacterSummary {
  const _CharacterSummary({required this.id, required this.name, this.portraitUrl, this.raceName, this.className, required this.level, required this.xp}): super._();
  

@override final  String id;
@override final  String name;
/// URL publique/signée du portrait (`characters.portrait_url`), `null`
/// si le joueur n'en a pas encore défini un.
@override final  String? portraitUrl;
/// Nom de race traduit (via `translations`), `null` si race
/// personnalisée (homebrew) ou non résolue.
@override final  String? raceName;
/// Nom de la classe principale traduit (`character_classes.is_primary`
/// = true, ou la première classe à défaut), `null` si le personnage n'a
/// aucune classe enregistrée.
@override final  String? className;
/// Niveau total, somme de `character_classes.level` (gère le
/// multiclassage de façon simple : un personnage niveau 3/2 est affiché
/// "Niv. 5").
@override final  int level;
/// XP cumulée actuelle (`characters.xp`).
@override final  int xp;

/// Create a copy of CharacterSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharacterSummaryCopyWith<_CharacterSummary> get copyWith => __$CharacterSummaryCopyWithImpl<_CharacterSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharacterSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.portraitUrl, portraitUrl) || other.portraitUrl == portraitUrl)&&(identical(other.raceName, raceName) || other.raceName == raceName)&&(identical(other.className, className) || other.className == className)&&(identical(other.level, level) || other.level == level)&&(identical(other.xp, xp) || other.xp == xp));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,portraitUrl,raceName,className,level,xp);

@override
String toString() {
  return 'CharacterSummary(id: $id, name: $name, portraitUrl: $portraitUrl, raceName: $raceName, className: $className, level: $level, xp: $xp)';
}


}

/// @nodoc
abstract mixin class _$CharacterSummaryCopyWith<$Res> implements $CharacterSummaryCopyWith<$Res> {
  factory _$CharacterSummaryCopyWith(_CharacterSummary value, $Res Function(_CharacterSummary) _then) = __$CharacterSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? portraitUrl, String? raceName, String? className, int level, int xp
});




}
/// @nodoc
class __$CharacterSummaryCopyWithImpl<$Res>
    implements _$CharacterSummaryCopyWith<$Res> {
  __$CharacterSummaryCopyWithImpl(this._self, this._then);

  final _CharacterSummary _self;
  final $Res Function(_CharacterSummary) _then;

/// Create a copy of CharacterSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? portraitUrl = freezed,Object? raceName = freezed,Object? className = freezed,Object? level = null,Object? xp = null,}) {
  return _then(_CharacterSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,portraitUrl: freezed == portraitUrl ? _self.portraitUrl : portraitUrl // ignore: cast_nullable_to_non_nullable
as String?,raceName: freezed == raceName ? _self.raceName : raceName // ignore: cast_nullable_to_non_nullable
as String?,className: freezed == className ? _self.className : className // ignore: cast_nullable_to_non_nullable
as String?,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,xp: null == xp ? _self.xp : xp // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
