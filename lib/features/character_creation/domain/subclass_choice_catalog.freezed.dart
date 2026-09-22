// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subclass_choice_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubclassChoiceCatalog {

 Map<int, List<SubclassChoiceOption>> get optionsByClassId;
/// Create a copy of SubclassChoiceCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubclassChoiceCatalogCopyWith<SubclassChoiceCatalog> get copyWith => _$SubclassChoiceCatalogCopyWithImpl<SubclassChoiceCatalog>(this as SubclassChoiceCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubclassChoiceCatalog&&const DeepCollectionEquality().equals(other.optionsByClassId, optionsByClassId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(optionsByClassId));

@override
String toString() {
  return 'SubclassChoiceCatalog(optionsByClassId: $optionsByClassId)';
}


}

/// @nodoc
abstract mixin class $SubclassChoiceCatalogCopyWith<$Res>  {
  factory $SubclassChoiceCatalogCopyWith(SubclassChoiceCatalog value, $Res Function(SubclassChoiceCatalog) _then) = _$SubclassChoiceCatalogCopyWithImpl;
@useResult
$Res call({
 Map<int, List<SubclassChoiceOption>> optionsByClassId
});




}
/// @nodoc
class _$SubclassChoiceCatalogCopyWithImpl<$Res>
    implements $SubclassChoiceCatalogCopyWith<$Res> {
  _$SubclassChoiceCatalogCopyWithImpl(this._self, this._then);

  final SubclassChoiceCatalog _self;
  final $Res Function(SubclassChoiceCatalog) _then;

/// Create a copy of SubclassChoiceCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? optionsByClassId = null,}) {
  return _then(SubclassChoiceCatalog(
optionsByClassId: null == optionsByClassId ? _self.optionsByClassId : optionsByClassId // ignore: cast_nullable_to_non_nullable
as Map<int, List<SubclassChoiceOption>>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubclassChoiceCatalog].
extension SubclassChoiceCatalogPatterns on SubclassChoiceCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubclassChoiceCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubclassChoiceCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubclassChoiceCatalog value)  $default,){
final _that = this;
switch (_that) {
case _SubclassChoiceCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubclassChoiceCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _SubclassChoiceCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<int, List<SubclassChoiceOption>> optionsByClassId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubclassChoiceCatalog() when $default != null:
return $default(_that.optionsByClassId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<int, List<SubclassChoiceOption>> optionsByClassId)  $default,) {final _that = this;
switch (_that) {
case _SubclassChoiceCatalog():
return $default(_that.optionsByClassId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<int, List<SubclassChoiceOption>> optionsByClassId)?  $default,) {final _that = this;
switch (_that) {
case _SubclassChoiceCatalog() when $default != null:
return $default(_that.optionsByClassId);case _:
  return null;

}
}

}

/// @nodoc


class _SubclassChoiceCatalog extends SubclassChoiceCatalog {
  const _SubclassChoiceCatalog({required  Map<int, List<SubclassChoiceOption>> optionsByClassId}): _optionsByClassId = optionsByClassId,super._();
  

 final  Map<int, List<SubclassChoiceOption>> _optionsByClassId;
@override Map<int, List<SubclassChoiceOption>> get optionsByClassId {
  if (_optionsByClassId is EqualUnmodifiableMapView) return _optionsByClassId;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_optionsByClassId);
}


/// Create a copy of SubclassChoiceCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubclassChoiceCatalogCopyWith<_SubclassChoiceCatalog> get copyWith => __$SubclassChoiceCatalogCopyWithImpl<_SubclassChoiceCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubclassChoiceCatalog&&const DeepCollectionEquality().equals(other._optionsByClassId, _optionsByClassId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_optionsByClassId));

@override
String toString() {
  return 'SubclassChoiceCatalog(optionsByClassId: $optionsByClassId)';
}


}

/// @nodoc
abstract mixin class _$SubclassChoiceCatalogCopyWith<$Res> implements $SubclassChoiceCatalogCopyWith<$Res> {
  factory _$SubclassChoiceCatalogCopyWith(_SubclassChoiceCatalog value, $Res Function(_SubclassChoiceCatalog) _then) = __$SubclassChoiceCatalogCopyWithImpl;
@override @useResult
$Res call({
 Map<int, List<SubclassChoiceOption>> optionsByClassId
});




}
/// @nodoc
class __$SubclassChoiceCatalogCopyWithImpl<$Res>
    implements _$SubclassChoiceCatalogCopyWith<$Res> {
  __$SubclassChoiceCatalogCopyWithImpl(this._self, this._then);

  final _SubclassChoiceCatalog _self;
  final $Res Function(_SubclassChoiceCatalog) _then;

/// Create a copy of SubclassChoiceCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? optionsByClassId = null,}) {
  return _then(_SubclassChoiceCatalog(
optionsByClassId: null == optionsByClassId ? _self._optionsByClassId : optionsByClassId // ignore: cast_nullable_to_non_nullable
as Map<int, List<SubclassChoiceOption>>,
  ));
}


}

// dart format on
