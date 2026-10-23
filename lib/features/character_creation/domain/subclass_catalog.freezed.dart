// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subclass_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubclassCatalog {

 List<SubclassOption> get subclasses;
/// Create a copy of SubclassCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubclassCatalogCopyWith<SubclassCatalog> get copyWith => _$SubclassCatalogCopyWithImpl<SubclassCatalog>(this as SubclassCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubclassCatalog&&const DeepCollectionEquality().equals(other.subclasses, subclasses));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(subclasses));

@override
String toString() {
  return 'SubclassCatalog(subclasses: $subclasses)';
}


}

/// @nodoc
abstract mixin class $SubclassCatalogCopyWith<$Res>  {
  factory $SubclassCatalogCopyWith(SubclassCatalog value, $Res Function(SubclassCatalog) _then) = _$SubclassCatalogCopyWithImpl;
@useResult
$Res call({
 List<SubclassOption> subclasses
});




}
/// @nodoc
class _$SubclassCatalogCopyWithImpl<$Res>
    implements $SubclassCatalogCopyWith<$Res> {
  _$SubclassCatalogCopyWithImpl(this._self, this._then);

  final SubclassCatalog _self;
  final $Res Function(SubclassCatalog) _then;

/// Create a copy of SubclassCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subclasses = null,}) {
  return _then(SubclassCatalog(
subclasses: null == subclasses ? _self.subclasses : subclasses // ignore: cast_nullable_to_non_nullable
as List<SubclassOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubclassCatalog].
extension SubclassCatalogPatterns on SubclassCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubclassCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubclassCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubclassCatalog value)  $default,){
final _that = this;
switch (_that) {
case _SubclassCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubclassCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _SubclassCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SubclassOption> subclasses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubclassCatalog() when $default != null:
return $default(_that.subclasses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SubclassOption> subclasses)  $default,) {final _that = this;
switch (_that) {
case _SubclassCatalog():
return $default(_that.subclasses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SubclassOption> subclasses)?  $default,) {final _that = this;
switch (_that) {
case _SubclassCatalog() when $default != null:
return $default(_that.subclasses);case _:
  return null;

}
}

}

/// @nodoc


class _SubclassCatalog implements SubclassCatalog {
  const _SubclassCatalog({required  List<SubclassOption> subclasses}): _subclasses = subclasses;
  

 final  List<SubclassOption> _subclasses;
@override List<SubclassOption> get subclasses {
  if (_subclasses is EqualUnmodifiableListView) return _subclasses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subclasses);
}


/// Create a copy of SubclassCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubclassCatalogCopyWith<_SubclassCatalog> get copyWith => __$SubclassCatalogCopyWithImpl<_SubclassCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubclassCatalog&&const DeepCollectionEquality().equals(other._subclasses, _subclasses));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_subclasses));

@override
String toString() {
  return 'SubclassCatalog(subclasses: $subclasses)';
}


}

/// @nodoc
abstract mixin class _$SubclassCatalogCopyWith<$Res> implements $SubclassCatalogCopyWith<$Res> {
  factory _$SubclassCatalogCopyWith(_SubclassCatalog value, $Res Function(_SubclassCatalog) _then) = __$SubclassCatalogCopyWithImpl;
@override @useResult
$Res call({
 List<SubclassOption> subclasses
});




}
/// @nodoc
class __$SubclassCatalogCopyWithImpl<$Res>
    implements _$SubclassCatalogCopyWith<$Res> {
  __$SubclassCatalogCopyWithImpl(this._self, this._then);

  final _SubclassCatalog _self;
  final $Res Function(_SubclassCatalog) _then;

/// Create a copy of SubclassCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subclasses = null,}) {
  return _then(_SubclassCatalog(
subclasses: null == subclasses ? _self._subclasses : subclasses // ignore: cast_nullable_to_non_nullable
as List<SubclassOption>,
  ));
}


}

// dart format on
