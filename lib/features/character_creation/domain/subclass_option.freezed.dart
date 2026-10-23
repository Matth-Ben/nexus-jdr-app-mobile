// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subclass_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubclassOption {

 int get id; String get name; int get classId;
/// Create a copy of SubclassOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubclassOptionCopyWith<SubclassOption> get copyWith => _$SubclassOptionCopyWithImpl<SubclassOption>(this as SubclassOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubclassOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.classId, classId) || other.classId == classId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,classId);

@override
String toString() {
  return 'SubclassOption(id: $id, name: $name, classId: $classId)';
}


}

/// @nodoc
abstract mixin class $SubclassOptionCopyWith<$Res>  {
  factory $SubclassOptionCopyWith(SubclassOption value, $Res Function(SubclassOption) _then) = _$SubclassOptionCopyWithImpl;
@useResult
$Res call({
 int id, String name, int classId
});




}
/// @nodoc
class _$SubclassOptionCopyWithImpl<$Res>
    implements $SubclassOptionCopyWith<$Res> {
  _$SubclassOptionCopyWithImpl(this._self, this._then);

  final SubclassOption _self;
  final $Res Function(SubclassOption) _then;

/// Create a copy of SubclassOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? classId = null,}) {
  return _then(SubclassOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SubclassOption].
extension SubclassOptionPatterns on SubclassOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubclassOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubclassOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubclassOption value)  $default,){
final _that = this;
switch (_that) {
case _SubclassOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubclassOption value)?  $default,){
final _that = this;
switch (_that) {
case _SubclassOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  int classId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubclassOption() when $default != null:
return $default(_that.id,_that.name,_that.classId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  int classId)  $default,) {final _that = this;
switch (_that) {
case _SubclassOption():
return $default(_that.id,_that.name,_that.classId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  int classId)?  $default,) {final _that = this;
switch (_that) {
case _SubclassOption() when $default != null:
return $default(_that.id,_that.name,_that.classId);case _:
  return null;

}
}

}

/// @nodoc


class _SubclassOption implements SubclassOption {
  const _SubclassOption({required this.id, required this.name, required this.classId});
  

@override final  int id;
@override final  String name;
@override final  int classId;

/// Create a copy of SubclassOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubclassOptionCopyWith<_SubclassOption> get copyWith => __$SubclassOptionCopyWithImpl<_SubclassOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubclassOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.classId, classId) || other.classId == classId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,classId);

@override
String toString() {
  return 'SubclassOption(id: $id, name: $name, classId: $classId)';
}


}

/// @nodoc
abstract mixin class _$SubclassOptionCopyWith<$Res> implements $SubclassOptionCopyWith<$Res> {
  factory _$SubclassOptionCopyWith(_SubclassOption value, $Res Function(_SubclassOption) _then) = __$SubclassOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, int classId
});




}
/// @nodoc
class __$SubclassOptionCopyWithImpl<$Res>
    implements _$SubclassOptionCopyWith<$Res> {
  __$SubclassOptionCopyWithImpl(this._self, this._then);

  final _SubclassOption _self;
  final $Res Function(_SubclassOption) _then;

/// Create a copy of SubclassOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? classId = null,}) {
  return _then(_SubclassOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,classId: null == classId ? _self.classId : classId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
