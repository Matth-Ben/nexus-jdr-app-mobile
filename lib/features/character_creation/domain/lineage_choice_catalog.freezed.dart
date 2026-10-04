// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lineage_choice_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LineageChoiceCatalog {

 Map<int, List<LineageOption>> get optionsByRaceId;
/// Create a copy of LineageChoiceCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LineageChoiceCatalogCopyWith<LineageChoiceCatalog> get copyWith => _$LineageChoiceCatalogCopyWithImpl<LineageChoiceCatalog>(this as LineageChoiceCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LineageChoiceCatalog&&const DeepCollectionEquality().equals(other.optionsByRaceId, optionsByRaceId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(optionsByRaceId));

@override
String toString() {
  return 'LineageChoiceCatalog(optionsByRaceId: $optionsByRaceId)';
}


}

/// @nodoc
abstract mixin class $LineageChoiceCatalogCopyWith<$Res>  {
  factory $LineageChoiceCatalogCopyWith(LineageChoiceCatalog value, $Res Function(LineageChoiceCatalog) _then) = _$LineageChoiceCatalogCopyWithImpl;
@useResult
$Res call({
 Map<int, List<LineageOption>> optionsByRaceId
});




}
/// @nodoc
class _$LineageChoiceCatalogCopyWithImpl<$Res>
    implements $LineageChoiceCatalogCopyWith<$Res> {
  _$LineageChoiceCatalogCopyWithImpl(this._self, this._then);

  final LineageChoiceCatalog _self;
  final $Res Function(LineageChoiceCatalog) _then;

/// Create a copy of LineageChoiceCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? optionsByRaceId = null,}) {
  return _then(LineageChoiceCatalog(
optionsByRaceId: null == optionsByRaceId ? _self.optionsByRaceId : optionsByRaceId // ignore: cast_nullable_to_non_nullable
as Map<int, List<LineageOption>>,
  ));
}

}


/// Adds pattern-matching-related methods to [LineageChoiceCatalog].
extension LineageChoiceCatalogPatterns on LineageChoiceCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LineageChoiceCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LineageChoiceCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LineageChoiceCatalog value)  $default,){
final _that = this;
switch (_that) {
case _LineageChoiceCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LineageChoiceCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _LineageChoiceCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<int, List<LineageOption>> optionsByRaceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LineageChoiceCatalog() when $default != null:
return $default(_that.optionsByRaceId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<int, List<LineageOption>> optionsByRaceId)  $default,) {final _that = this;
switch (_that) {
case _LineageChoiceCatalog():
return $default(_that.optionsByRaceId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<int, List<LineageOption>> optionsByRaceId)?  $default,) {final _that = this;
switch (_that) {
case _LineageChoiceCatalog() when $default != null:
return $default(_that.optionsByRaceId);case _:
  return null;

}
}

}

/// @nodoc


class _LineageChoiceCatalog extends LineageChoiceCatalog {
  const _LineageChoiceCatalog({required  Map<int, List<LineageOption>> optionsByRaceId}): _optionsByRaceId = optionsByRaceId,super._();
  

 final  Map<int, List<LineageOption>> _optionsByRaceId;
@override Map<int, List<LineageOption>> get optionsByRaceId {
  if (_optionsByRaceId is EqualUnmodifiableMapView) return _optionsByRaceId;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_optionsByRaceId);
}


/// Create a copy of LineageChoiceCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LineageChoiceCatalogCopyWith<_LineageChoiceCatalog> get copyWith => __$LineageChoiceCatalogCopyWithImpl<_LineageChoiceCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LineageChoiceCatalog&&const DeepCollectionEquality().equals(other._optionsByRaceId, _optionsByRaceId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_optionsByRaceId));

@override
String toString() {
  return 'LineageChoiceCatalog(optionsByRaceId: $optionsByRaceId)';
}


}

/// @nodoc
abstract mixin class _$LineageChoiceCatalogCopyWith<$Res> implements $LineageChoiceCatalogCopyWith<$Res> {
  factory _$LineageChoiceCatalogCopyWith(_LineageChoiceCatalog value, $Res Function(_LineageChoiceCatalog) _then) = __$LineageChoiceCatalogCopyWithImpl;
@override @useResult
$Res call({
 Map<int, List<LineageOption>> optionsByRaceId
});




}
/// @nodoc
class __$LineageChoiceCatalogCopyWithImpl<$Res>
    implements _$LineageChoiceCatalogCopyWith<$Res> {
  __$LineageChoiceCatalogCopyWithImpl(this._self, this._then);

  final _LineageChoiceCatalog _self;
  final $Res Function(_LineageChoiceCatalog) _then;

/// Create a copy of LineageChoiceCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? optionsByRaceId = null,}) {
  return _then(_LineageChoiceCatalog(
optionsByRaceId: null == optionsByRaceId ? _self._optionsByRaceId : optionsByRaceId // ignore: cast_nullable_to_non_nullable
as Map<int, List<LineageOption>>,
  ));
}


}

// dart format on
