// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tool_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ToolOption {

 int get id; String get name; String get category;
/// Create a copy of ToolOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ToolOptionCopyWith<ToolOption> get copyWith => _$ToolOptionCopyWithImpl<ToolOption>(this as ToolOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ToolOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,category);

@override
String toString() {
  return 'ToolOption(id: $id, name: $name, category: $category)';
}


}

/// @nodoc
abstract mixin class $ToolOptionCopyWith<$Res>  {
  factory $ToolOptionCopyWith(ToolOption value, $Res Function(ToolOption) _then) = _$ToolOptionCopyWithImpl;
@useResult
$Res call({
 int id, String name, String category
});




}
/// @nodoc
class _$ToolOptionCopyWithImpl<$Res>
    implements $ToolOptionCopyWith<$Res> {
  _$ToolOptionCopyWithImpl(this._self, this._then);

  final ToolOption _self;
  final $Res Function(ToolOption) _then;

/// Create a copy of ToolOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? category = null,}) {
  return _then(ToolOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ToolOption].
extension ToolOptionPatterns on ToolOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ToolOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ToolOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ToolOption value)  $default,){
final _that = this;
switch (_that) {
case _ToolOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ToolOption value)?  $default,){
final _that = this;
switch (_that) {
case _ToolOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String category)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ToolOption() when $default != null:
return $default(_that.id,_that.name,_that.category);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String category)  $default,) {final _that = this;
switch (_that) {
case _ToolOption():
return $default(_that.id,_that.name,_that.category);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String category)?  $default,) {final _that = this;
switch (_that) {
case _ToolOption() when $default != null:
return $default(_that.id,_that.name,_that.category);case _:
  return null;

}
}

}

/// @nodoc


class _ToolOption implements ToolOption {
  const _ToolOption({required this.id, required this.name, required this.category});
  

@override final  int id;
@override final  String name;
@override final  String category;

/// Create a copy of ToolOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ToolOptionCopyWith<_ToolOption> get copyWith => __$ToolOptionCopyWithImpl<_ToolOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ToolOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,category);

@override
String toString() {
  return 'ToolOption(id: $id, name: $name, category: $category)';
}


}

/// @nodoc
abstract mixin class _$ToolOptionCopyWith<$Res> implements $ToolOptionCopyWith<$Res> {
  factory _$ToolOptionCopyWith(_ToolOption value, $Res Function(_ToolOption) _then) = __$ToolOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String category
});




}
/// @nodoc
class __$ToolOptionCopyWithImpl<$Res>
    implements _$ToolOptionCopyWith<$Res> {
  __$ToolOptionCopyWithImpl(this._self, this._then);

  final _ToolOption _self;
  final $Res Function(_ToolOption) _then;

/// Create a copy of ToolOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? category = null,}) {
  return _then(_ToolOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
