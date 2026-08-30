// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alignment_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlignmentCatalog {

 List<AlignmentOption> get alignments;
/// Create a copy of AlignmentCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlignmentCatalogCopyWith<AlignmentCatalog> get copyWith => _$AlignmentCatalogCopyWithImpl<AlignmentCatalog>(this as AlignmentCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlignmentCatalog&&const DeepCollectionEquality().equals(other.alignments, alignments));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(alignments));

@override
String toString() {
  return 'AlignmentCatalog(alignments: $alignments)';
}


}

/// @nodoc
abstract mixin class $AlignmentCatalogCopyWith<$Res>  {
  factory $AlignmentCatalogCopyWith(AlignmentCatalog value, $Res Function(AlignmentCatalog) _then) = _$AlignmentCatalogCopyWithImpl;
@useResult
$Res call({
 List<AlignmentOption> alignments
});




}
/// @nodoc
class _$AlignmentCatalogCopyWithImpl<$Res>
    implements $AlignmentCatalogCopyWith<$Res> {
  _$AlignmentCatalogCopyWithImpl(this._self, this._then);

  final AlignmentCatalog _self;
  final $Res Function(AlignmentCatalog) _then;

/// Create a copy of AlignmentCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? alignments = null,}) {
  return _then(AlignmentCatalog(
alignments: null == alignments ? _self.alignments : alignments // ignore: cast_nullable_to_non_nullable
as List<AlignmentOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [AlignmentCatalog].
extension AlignmentCatalogPatterns on AlignmentCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AlignmentCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AlignmentCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AlignmentCatalog value)  $default,){
final _that = this;
switch (_that) {
case _AlignmentCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AlignmentCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _AlignmentCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AlignmentOption> alignments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AlignmentCatalog() when $default != null:
return $default(_that.alignments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AlignmentOption> alignments)  $default,) {final _that = this;
switch (_that) {
case _AlignmentCatalog():
return $default(_that.alignments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AlignmentOption> alignments)?  $default,) {final _that = this;
switch (_that) {
case _AlignmentCatalog() when $default != null:
return $default(_that.alignments);case _:
  return null;

}
}

}

/// @nodoc


class _AlignmentCatalog implements AlignmentCatalog {
  const _AlignmentCatalog({required  List<AlignmentOption> alignments}): _alignments = alignments;
  

 final  List<AlignmentOption> _alignments;
@override List<AlignmentOption> get alignments {
  if (_alignments is EqualUnmodifiableListView) return _alignments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alignments);
}


/// Create a copy of AlignmentCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlignmentCatalogCopyWith<_AlignmentCatalog> get copyWith => __$AlignmentCatalogCopyWithImpl<_AlignmentCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AlignmentCatalog&&const DeepCollectionEquality().equals(other._alignments, _alignments));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_alignments));

@override
String toString() {
  return 'AlignmentCatalog(alignments: $alignments)';
}


}

/// @nodoc
abstract mixin class _$AlignmentCatalogCopyWith<$Res> implements $AlignmentCatalogCopyWith<$Res> {
  factory _$AlignmentCatalogCopyWith(_AlignmentCatalog value, $Res Function(_AlignmentCatalog) _then) = __$AlignmentCatalogCopyWithImpl;
@override @useResult
$Res call({
 List<AlignmentOption> alignments
});




}
/// @nodoc
class __$AlignmentCatalogCopyWithImpl<$Res>
    implements _$AlignmentCatalogCopyWith<$Res> {
  __$AlignmentCatalogCopyWithImpl(this._self, this._then);

  final _AlignmentCatalog _self;
  final $Res Function(_AlignmentCatalog) _then;

/// Create a copy of AlignmentCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? alignments = null,}) {
  return _then(_AlignmentCatalog(
alignments: null == alignments ? _self._alignments : alignments // ignore: cast_nullable_to_non_nullable
as List<AlignmentOption>,
  ));
}


}

// dart format on
