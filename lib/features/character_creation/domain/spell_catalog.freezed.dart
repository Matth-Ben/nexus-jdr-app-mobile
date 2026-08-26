// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spell_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SpellCatalog {

 List<SpellOption> get spells;
/// Create a copy of SpellCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpellCatalogCopyWith<SpellCatalog> get copyWith => _$SpellCatalogCopyWithImpl<SpellCatalog>(this as SpellCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpellCatalog&&const DeepCollectionEquality().equals(other.spells, spells));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(spells));

@override
String toString() {
  return 'SpellCatalog(spells: $spells)';
}


}

/// @nodoc
abstract mixin class $SpellCatalogCopyWith<$Res>  {
  factory $SpellCatalogCopyWith(SpellCatalog value, $Res Function(SpellCatalog) _then) = _$SpellCatalogCopyWithImpl;
@useResult
$Res call({
 List<SpellOption> spells
});




}
/// @nodoc
class _$SpellCatalogCopyWithImpl<$Res>
    implements $SpellCatalogCopyWith<$Res> {
  _$SpellCatalogCopyWithImpl(this._self, this._then);

  final SpellCatalog _self;
  final $Res Function(SpellCatalog) _then;

/// Create a copy of SpellCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? spells = null,}) {
  return _then(SpellCatalog(
spells: null == spells ? _self.spells : spells // ignore: cast_nullable_to_non_nullable
as List<SpellOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [SpellCatalog].
extension SpellCatalogPatterns on SpellCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpellCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpellCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpellCatalog value)  $default,){
final _that = this;
switch (_that) {
case _SpellCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpellCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _SpellCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SpellOption> spells)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpellCatalog() when $default != null:
return $default(_that.spells);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SpellOption> spells)  $default,) {final _that = this;
switch (_that) {
case _SpellCatalog():
return $default(_that.spells);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SpellOption> spells)?  $default,) {final _that = this;
switch (_that) {
case _SpellCatalog() when $default != null:
return $default(_that.spells);case _:
  return null;

}
}

}

/// @nodoc


class _SpellCatalog implements SpellCatalog {
  const _SpellCatalog({required  List<SpellOption> spells}): _spells = spells;
  

 final  List<SpellOption> _spells;
@override List<SpellOption> get spells {
  if (_spells is EqualUnmodifiableListView) return _spells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_spells);
}


/// Create a copy of SpellCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpellCatalogCopyWith<_SpellCatalog> get copyWith => __$SpellCatalogCopyWithImpl<_SpellCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpellCatalog&&const DeepCollectionEquality().equals(other._spells, _spells));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_spells));

@override
String toString() {
  return 'SpellCatalog(spells: $spells)';
}


}

/// @nodoc
abstract mixin class _$SpellCatalogCopyWith<$Res> implements $SpellCatalogCopyWith<$Res> {
  factory _$SpellCatalogCopyWith(_SpellCatalog value, $Res Function(_SpellCatalog) _then) = __$SpellCatalogCopyWithImpl;
@override @useResult
$Res call({
 List<SpellOption> spells
});




}
/// @nodoc
class __$SpellCatalogCopyWithImpl<$Res>
    implements _$SpellCatalogCopyWith<$Res> {
  __$SpellCatalogCopyWithImpl(this._self, this._then);

  final _SpellCatalog _self;
  final $Res Function(_SpellCatalog) _then;

/// Create a copy of SpellCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? spells = null,}) {
  return _then(_SpellCatalog(
spells: null == spells ? _self._spells : spells // ignore: cast_nullable_to_non_nullable
as List<SpellOption>,
  ));
}


}

// dart format on
