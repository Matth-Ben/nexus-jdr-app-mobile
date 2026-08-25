// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'race_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RaceCatalog {

 List<RaceOption> get races; List<SubraceOption> get subraces;
/// Create a copy of RaceCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RaceCatalogCopyWith<RaceCatalog> get copyWith => _$RaceCatalogCopyWithImpl<RaceCatalog>(this as RaceCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RaceCatalog&&const DeepCollectionEquality().equals(other.races, races)&&const DeepCollectionEquality().equals(other.subraces, subraces));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(races),const DeepCollectionEquality().hash(subraces));

@override
String toString() {
  return 'RaceCatalog(races: $races, subraces: $subraces)';
}


}

/// @nodoc
abstract mixin class $RaceCatalogCopyWith<$Res>  {
  factory $RaceCatalogCopyWith(RaceCatalog value, $Res Function(RaceCatalog) _then) = _$RaceCatalogCopyWithImpl;
@useResult
$Res call({
 List<RaceOption> races, List<SubraceOption> subraces
});




}
/// @nodoc
class _$RaceCatalogCopyWithImpl<$Res>
    implements $RaceCatalogCopyWith<$Res> {
  _$RaceCatalogCopyWithImpl(this._self, this._then);

  final RaceCatalog _self;
  final $Res Function(RaceCatalog) _then;

/// Create a copy of RaceCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? races = null,Object? subraces = null,}) {
  return _then(RaceCatalog(
races: null == races ? _self.races : races // ignore: cast_nullable_to_non_nullable
as List<RaceOption>,subraces: null == subraces ? _self.subraces : subraces // ignore: cast_nullable_to_non_nullable
as List<SubraceOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [RaceCatalog].
extension RaceCatalogPatterns on RaceCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RaceCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RaceCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RaceCatalog value)  $default,){
final _that = this;
switch (_that) {
case _RaceCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RaceCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _RaceCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<RaceOption> races,  List<SubraceOption> subraces)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RaceCatalog() when $default != null:
return $default(_that.races,_that.subraces);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<RaceOption> races,  List<SubraceOption> subraces)  $default,) {final _that = this;
switch (_that) {
case _RaceCatalog():
return $default(_that.races,_that.subraces);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<RaceOption> races,  List<SubraceOption> subraces)?  $default,) {final _that = this;
switch (_that) {
case _RaceCatalog() when $default != null:
return $default(_that.races,_that.subraces);case _:
  return null;

}
}

}

/// @nodoc


class _RaceCatalog extends RaceCatalog {
  const _RaceCatalog({required  List<RaceOption> races, required  List<SubraceOption> subraces}): _races = races,_subraces = subraces,super._();
  

 final  List<RaceOption> _races;
@override List<RaceOption> get races {
  if (_races is EqualUnmodifiableListView) return _races;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_races);
}

 final  List<SubraceOption> _subraces;
@override List<SubraceOption> get subraces {
  if (_subraces is EqualUnmodifiableListView) return _subraces;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subraces);
}


/// Create a copy of RaceCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RaceCatalogCopyWith<_RaceCatalog> get copyWith => __$RaceCatalogCopyWithImpl<_RaceCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RaceCatalog&&const DeepCollectionEquality().equals(other._races, _races)&&const DeepCollectionEquality().equals(other._subraces, _subraces));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_races),const DeepCollectionEquality().hash(_subraces));

@override
String toString() {
  return 'RaceCatalog(races: $races, subraces: $subraces)';
}


}

/// @nodoc
abstract mixin class _$RaceCatalogCopyWith<$Res> implements $RaceCatalogCopyWith<$Res> {
  factory _$RaceCatalogCopyWith(_RaceCatalog value, $Res Function(_RaceCatalog) _then) = __$RaceCatalogCopyWithImpl;
@override @useResult
$Res call({
 List<RaceOption> races, List<SubraceOption> subraces
});




}
/// @nodoc
class __$RaceCatalogCopyWithImpl<$Res>
    implements _$RaceCatalogCopyWith<$Res> {
  __$RaceCatalogCopyWithImpl(this._self, this._then);

  final _RaceCatalog _self;
  final $Res Function(_RaceCatalog) _then;

/// Create a copy of RaceCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? races = null,Object? subraces = null,}) {
  return _then(_RaceCatalog(
races: null == races ? _self._races : races // ignore: cast_nullable_to_non_nullable
as List<RaceOption>,subraces: null == subraces ? _self._subraces : subraces // ignore: cast_nullable_to_non_nullable
as List<SubraceOption>,
  ));
}


}

// dart format on
