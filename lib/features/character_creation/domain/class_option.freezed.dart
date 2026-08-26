// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'class_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ClassOption {

 int get id; String get name; String get description; int get hitDie;
/// Create a copy of ClassOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassOptionCopyWith<ClassOption> get copyWith => _$ClassOptionCopyWithImpl<ClassOption>(this as ClassOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.hitDie, hitDie) || other.hitDie == hitDie));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,hitDie);

@override
String toString() {
  return 'ClassOption(id: $id, name: $name, description: $description, hitDie: $hitDie)';
}


}

/// @nodoc
abstract mixin class $ClassOptionCopyWith<$Res>  {
  factory $ClassOptionCopyWith(ClassOption value, $Res Function(ClassOption) _then) = _$ClassOptionCopyWithImpl;
@useResult
$Res call({
 int id, String name, String description, int hitDie
});




}
/// @nodoc
class _$ClassOptionCopyWithImpl<$Res>
    implements $ClassOptionCopyWith<$Res> {
  _$ClassOptionCopyWithImpl(this._self, this._then);

  final ClassOption _self;
  final $Res Function(ClassOption) _then;

/// Create a copy of ClassOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? hitDie = null,}) {
  return _then(ClassOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,hitDie: null == hitDie ? _self.hitDie : hitDie // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ClassOption].
extension ClassOptionPatterns on ClassOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClassOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClassOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClassOption value)  $default,){
final _that = this;
switch (_that) {
case _ClassOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClassOption value)?  $default,){
final _that = this;
switch (_that) {
case _ClassOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String description,  int hitDie)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClassOption() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.hitDie);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String description,  int hitDie)  $default,) {final _that = this;
switch (_that) {
case _ClassOption():
return $default(_that.id,_that.name,_that.description,_that.hitDie);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String description,  int hitDie)?  $default,) {final _that = this;
switch (_that) {
case _ClassOption() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.hitDie);case _:
  return null;

}
}

}

/// @nodoc


class _ClassOption extends ClassOption {
  const _ClassOption({required this.id, required this.name, required this.description, required this.hitDie}): super._();
  

@override final  int id;
@override final  String name;
@override final  String description;
@override final  int hitDie;

/// Create a copy of ClassOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassOptionCopyWith<_ClassOption> get copyWith => __$ClassOptionCopyWithImpl<_ClassOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClassOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.hitDie, hitDie) || other.hitDie == hitDie));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,hitDie);

@override
String toString() {
  return 'ClassOption(id: $id, name: $name, description: $description, hitDie: $hitDie)';
}


}

/// @nodoc
abstract mixin class _$ClassOptionCopyWith<$Res> implements $ClassOptionCopyWith<$Res> {
  factory _$ClassOptionCopyWith(_ClassOption value, $Res Function(_ClassOption) _then) = __$ClassOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String description, int hitDie
});




}
/// @nodoc
class __$ClassOptionCopyWithImpl<$Res>
    implements _$ClassOptionCopyWith<$Res> {
  __$ClassOptionCopyWithImpl(this._self, this._then);

  final _ClassOption _self;
  final $Res Function(_ClassOption) _then;

/// Create a copy of ClassOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? hitDie = null,}) {
  return _then(_ClassOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,hitDie: null == hitDie ? _self.hitDie : hitDie // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
