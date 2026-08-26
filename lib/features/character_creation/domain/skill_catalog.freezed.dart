// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skill_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SkillCatalog {

 List<SkillOption> get skills;
/// Create a copy of SkillCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillCatalogCopyWith<SkillCatalog> get copyWith => _$SkillCatalogCopyWithImpl<SkillCatalog>(this as SkillCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillCatalog&&const DeepCollectionEquality().equals(other.skills, skills));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(skills));

@override
String toString() {
  return 'SkillCatalog(skills: $skills)';
}


}

/// @nodoc
abstract mixin class $SkillCatalogCopyWith<$Res>  {
  factory $SkillCatalogCopyWith(SkillCatalog value, $Res Function(SkillCatalog) _then) = _$SkillCatalogCopyWithImpl;
@useResult
$Res call({
 List<SkillOption> skills
});




}
/// @nodoc
class _$SkillCatalogCopyWithImpl<$Res>
    implements $SkillCatalogCopyWith<$Res> {
  _$SkillCatalogCopyWithImpl(this._self, this._then);

  final SkillCatalog _self;
  final $Res Function(SkillCatalog) _then;

/// Create a copy of SkillCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? skills = null,}) {
  return _then(SkillCatalog(
skills: null == skills ? _self.skills : skills // ignore: cast_nullable_to_non_nullable
as List<SkillOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillCatalog].
extension SkillCatalogPatterns on SkillCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillCatalog value)  $default,){
final _that = this;
switch (_that) {
case _SkillCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _SkillCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SkillOption> skills)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillCatalog() when $default != null:
return $default(_that.skills);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SkillOption> skills)  $default,) {final _that = this;
switch (_that) {
case _SkillCatalog():
return $default(_that.skills);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SkillOption> skills)?  $default,) {final _that = this;
switch (_that) {
case _SkillCatalog() when $default != null:
return $default(_that.skills);case _:
  return null;

}
}

}

/// @nodoc


class _SkillCatalog implements SkillCatalog {
  const _SkillCatalog({required  List<SkillOption> skills}): _skills = skills;
  

 final  List<SkillOption> _skills;
@override List<SkillOption> get skills {
  if (_skills is EqualUnmodifiableListView) return _skills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skills);
}


/// Create a copy of SkillCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillCatalogCopyWith<_SkillCatalog> get copyWith => __$SkillCatalogCopyWithImpl<_SkillCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillCatalog&&const DeepCollectionEquality().equals(other._skills, _skills));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_skills));

@override
String toString() {
  return 'SkillCatalog(skills: $skills)';
}


}

/// @nodoc
abstract mixin class _$SkillCatalogCopyWith<$Res> implements $SkillCatalogCopyWith<$Res> {
  factory _$SkillCatalogCopyWith(_SkillCatalog value, $Res Function(_SkillCatalog) _then) = __$SkillCatalogCopyWithImpl;
@override @useResult
$Res call({
 List<SkillOption> skills
});




}
/// @nodoc
class __$SkillCatalogCopyWithImpl<$Res>
    implements _$SkillCatalogCopyWith<$Res> {
  __$SkillCatalogCopyWithImpl(this._self, this._then);

  final _SkillCatalog _self;
  final $Res Function(_SkillCatalog) _then;

/// Create a copy of SkillCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? skills = null,}) {
  return _then(_SkillCatalog(
skills: null == skills ? _self._skills : skills // ignore: cast_nullable_to_non_nullable
as List<SkillOption>,
  ));
}


}

// dart format on
