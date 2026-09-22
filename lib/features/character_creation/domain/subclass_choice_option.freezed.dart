// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subclass_choice_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubclassChoiceOption {

/// `subclasses.id`.
 int get id; String get name;/// `null` si aucune description n'est renseignée en base (la tuile
/// n'affiche alors pas de sous-titre).
 String? get description;
/// Create a copy of SubclassChoiceOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubclassChoiceOptionCopyWith<SubclassChoiceOption> get copyWith => _$SubclassChoiceOptionCopyWithImpl<SubclassChoiceOption>(this as SubclassChoiceOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubclassChoiceOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description);

@override
String toString() {
  return 'SubclassChoiceOption(id: $id, name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class $SubclassChoiceOptionCopyWith<$Res>  {
  factory $SubclassChoiceOptionCopyWith(SubclassChoiceOption value, $Res Function(SubclassChoiceOption) _then) = _$SubclassChoiceOptionCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? description
});




}
/// @nodoc
class _$SubclassChoiceOptionCopyWithImpl<$Res>
    implements $SubclassChoiceOptionCopyWith<$Res> {
  _$SubclassChoiceOptionCopyWithImpl(this._self, this._then);

  final SubclassChoiceOption _self;
  final $Res Function(SubclassChoiceOption) _then;

/// Create a copy of SubclassChoiceOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,}) {
  return _then(SubclassChoiceOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubclassChoiceOption].
extension SubclassChoiceOptionPatterns on SubclassChoiceOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubclassChoiceOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubclassChoiceOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubclassChoiceOption value)  $default,){
final _that = this;
switch (_that) {
case _SubclassChoiceOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubclassChoiceOption value)?  $default,){
final _that = this;
switch (_that) {
case _SubclassChoiceOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubclassChoiceOption() when $default != null:
return $default(_that.id,_that.name,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? description)  $default,) {final _that = this;
switch (_that) {
case _SubclassChoiceOption():
return $default(_that.id,_that.name,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _SubclassChoiceOption() when $default != null:
return $default(_that.id,_that.name,_that.description);case _:
  return null;

}
}

}

/// @nodoc


class _SubclassChoiceOption implements SubclassChoiceOption {
  const _SubclassChoiceOption({required this.id, required this.name, this.description});
  

/// `subclasses.id`.
@override final  int id;
@override final  String name;
/// `null` si aucune description n'est renseignée en base (la tuile
/// n'affiche alors pas de sous-titre).
@override final  String? description;

/// Create a copy of SubclassChoiceOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubclassChoiceOptionCopyWith<_SubclassChoiceOption> get copyWith => __$SubclassChoiceOptionCopyWithImpl<_SubclassChoiceOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubclassChoiceOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description);

@override
String toString() {
  return 'SubclassChoiceOption(id: $id, name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class _$SubclassChoiceOptionCopyWith<$Res> implements $SubclassChoiceOptionCopyWith<$Res> {
  factory _$SubclassChoiceOptionCopyWith(_SubclassChoiceOption value, $Res Function(_SubclassChoiceOption) _then) = __$SubclassChoiceOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? description
});




}
/// @nodoc
class __$SubclassChoiceOptionCopyWithImpl<$Res>
    implements _$SubclassChoiceOptionCopyWith<$Res> {
  __$SubclassChoiceOptionCopyWithImpl(this._self, this._then);

  final _SubclassChoiceOption _self;
  final $Res Function(_SubclassChoiceOption) _then;

/// Create a copy of SubclassChoiceOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,}) {
  return _then(_SubclassChoiceOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
