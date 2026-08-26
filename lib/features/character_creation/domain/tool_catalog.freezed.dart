// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tool_catalog.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ToolCatalog {

 List<ToolOption> get tools;
/// Create a copy of ToolCatalog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolCatalogCopyWith<ToolCatalog> get copyWith => _$ToolCatalogCopyWithImpl<ToolCatalog>(this as ToolCatalog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolCatalog&&const DeepCollectionEquality().equals(other.tools, tools));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(tools));

@override
String toString() {
  return 'ToolCatalog(tools: $tools)';
}


}

/// @nodoc
abstract mixin class $ToolCatalogCopyWith<$Res>  {
  factory $ToolCatalogCopyWith(ToolCatalog value, $Res Function(ToolCatalog) _then) = _$ToolCatalogCopyWithImpl;
@useResult
$Res call({
 List<ToolOption> tools
});




}
/// @nodoc
class _$ToolCatalogCopyWithImpl<$Res>
    implements $ToolCatalogCopyWith<$Res> {
  _$ToolCatalogCopyWithImpl(this._self, this._then);

  final ToolCatalog _self;
  final $Res Function(ToolCatalog) _then;

/// Create a copy of ToolCatalog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tools = null,}) {
  return _then(ToolCatalog(
tools: null == tools ? _self.tools : tools // ignore: cast_nullable_to_non_nullable
as List<ToolOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [ToolCatalog].
extension ToolCatalogPatterns on ToolCatalog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToolCatalog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToolCatalog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToolCatalog value)  $default,){
final _that = this;
switch (_that) {
case _ToolCatalog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToolCatalog value)?  $default,){
final _that = this;
switch (_that) {
case _ToolCatalog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ToolOption> tools)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToolCatalog() when $default != null:
return $default(_that.tools);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ToolOption> tools)  $default,) {final _that = this;
switch (_that) {
case _ToolCatalog():
return $default(_that.tools);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ToolOption> tools)?  $default,) {final _that = this;
switch (_that) {
case _ToolCatalog() when $default != null:
return $default(_that.tools);case _:
  return null;

}
}

}

/// @nodoc


class _ToolCatalog implements ToolCatalog {
  const _ToolCatalog({required  List<ToolOption> tools}): _tools = tools;
  

 final  List<ToolOption> _tools;
@override List<ToolOption> get tools {
  if (_tools is EqualUnmodifiableListView) return _tools;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tools);
}


/// Create a copy of ToolCatalog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToolCatalogCopyWith<_ToolCatalog> get copyWith => __$ToolCatalogCopyWithImpl<_ToolCatalog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToolCatalog&&const DeepCollectionEquality().equals(other._tools, _tools));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tools));

@override
String toString() {
  return 'ToolCatalog(tools: $tools)';
}


}

/// @nodoc
abstract mixin class _$ToolCatalogCopyWith<$Res> implements $ToolCatalogCopyWith<$Res> {
  factory _$ToolCatalogCopyWith(_ToolCatalog value, $Res Function(_ToolCatalog) _then) = __$ToolCatalogCopyWithImpl;
@override @useResult
$Res call({
 List<ToolOption> tools
});




}
/// @nodoc
class __$ToolCatalogCopyWithImpl<$Res>
    implements _$ToolCatalogCopyWith<$Res> {
  __$ToolCatalogCopyWithImpl(this._self, this._then);

  final _ToolCatalog _self;
  final $Res Function(_ToolCatalog) _then;

/// Create a copy of ToolCatalog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tools = null,}) {
  return _then(_ToolCatalog(
tools: null == tools ? _self._tools : tools // ignore: cast_nullable_to_non_nullable
as List<ToolOption>,
  ));
}


}

// dart format on
