// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'class_skill_choices.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ClassSkillChoices {

 int get count; List<String> get choices;
/// Create a copy of ClassSkillChoices
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassSkillChoicesCopyWith<ClassSkillChoices> get copyWith => _$ClassSkillChoicesCopyWithImpl<ClassSkillChoices>(this as ClassSkillChoices, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassSkillChoices&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other.choices, choices));
}


@override
int get hashCode => Object.hash(runtimeType,count,const DeepCollectionEquality().hash(choices));

@override
String toString() {
  return 'ClassSkillChoices(count: $count, choices: $choices)';
}


}

/// @nodoc
abstract mixin class $ClassSkillChoicesCopyWith<$Res>  {
  factory $ClassSkillChoicesCopyWith(ClassSkillChoices value, $Res Function(ClassSkillChoices) _then) = _$ClassSkillChoicesCopyWithImpl;
@useResult
$Res call({
 int count, List<String> choices
});




}
/// @nodoc
class _$ClassSkillChoicesCopyWithImpl<$Res>
    implements $ClassSkillChoicesCopyWith<$Res> {
  _$ClassSkillChoicesCopyWithImpl(this._self, this._then);

  final ClassSkillChoices _self;
  final $Res Function(ClassSkillChoices) _then;

/// Create a copy of ClassSkillChoices
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,Object? choices = null,}) {
  return _then(ClassSkillChoices(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,choices: null == choices ? _self.choices : choices // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ClassSkillChoices].
extension ClassSkillChoicesPatterns on ClassSkillChoices {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClassSkillChoices value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClassSkillChoices() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClassSkillChoices value)  $default,){
final _that = this;
switch (_that) {
case _ClassSkillChoices():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClassSkillChoices value)?  $default,){
final _that = this;
switch (_that) {
case _ClassSkillChoices() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int count,  List<String> choices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClassSkillChoices() when $default != null:
return $default(_that.count,_that.choices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int count,  List<String> choices)  $default,) {final _that = this;
switch (_that) {
case _ClassSkillChoices():
return $default(_that.count,_that.choices);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int count,  List<String> choices)?  $default,) {final _that = this;
switch (_that) {
case _ClassSkillChoices() when $default != null:
return $default(_that.count,_that.choices);case _:
  return null;

}
}

}

/// @nodoc


class _ClassSkillChoices implements ClassSkillChoices {
  const _ClassSkillChoices({required this.count, required  List<String> choices}): _choices = choices;
  

@override final  int count;
 final  List<String> _choices;
@override List<String> get choices {
  if (_choices is EqualUnmodifiableListView) return _choices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_choices);
}


/// Create a copy of ClassSkillChoices
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassSkillChoicesCopyWith<_ClassSkillChoices> get copyWith => __$ClassSkillChoicesCopyWithImpl<_ClassSkillChoices>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClassSkillChoices&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other._choices, _choices));
}


@override
int get hashCode => Object.hash(runtimeType,count,const DeepCollectionEquality().hash(_choices));

@override
String toString() {
  return 'ClassSkillChoices(count: $count, choices: $choices)';
}


}

/// @nodoc
abstract mixin class _$ClassSkillChoicesCopyWith<$Res> implements $ClassSkillChoicesCopyWith<$Res> {
  factory _$ClassSkillChoicesCopyWith(_ClassSkillChoices value, $Res Function(_ClassSkillChoices) _then) = __$ClassSkillChoicesCopyWithImpl;
@override @useResult
$Res call({
 int count, List<String> choices
});




}
/// @nodoc
class __$ClassSkillChoicesCopyWithImpl<$Res>
    implements _$ClassSkillChoicesCopyWith<$Res> {
  __$ClassSkillChoicesCopyWithImpl(this._self, this._then);

  final _ClassSkillChoices _self;
  final $Res Function(_ClassSkillChoices) _then;

/// Create a copy of ClassSkillChoices
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? choices = null,}) {
  return _then(_ClassSkillChoices(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,choices: null == choices ? _self._choices : choices // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
