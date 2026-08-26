// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'class_tool_choice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ClassToolChoice {

 int get count; List<String> get categories;
/// Create a copy of ClassToolChoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClassToolChoiceCopyWith<ClassToolChoice> get copyWith => _$ClassToolChoiceCopyWithImpl<ClassToolChoice>(this as ClassToolChoice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClassToolChoice&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other.categories, categories));
}


@override
int get hashCode => Object.hash(runtimeType,count,const DeepCollectionEquality().hash(categories));

@override
String toString() {
  return 'ClassToolChoice(count: $count, categories: $categories)';
}


}

/// @nodoc
abstract mixin class $ClassToolChoiceCopyWith<$Res>  {
  factory $ClassToolChoiceCopyWith(ClassToolChoice value, $Res Function(ClassToolChoice) _then) = _$ClassToolChoiceCopyWithImpl;
@useResult
$Res call({
 int count, List<String> categories
});




}
/// @nodoc
class _$ClassToolChoiceCopyWithImpl<$Res>
    implements $ClassToolChoiceCopyWith<$Res> {
  _$ClassToolChoiceCopyWithImpl(this._self, this._then);

  final ClassToolChoice _self;
  final $Res Function(ClassToolChoice) _then;

/// Create a copy of ClassToolChoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,Object? categories = null,}) {
  return _then(ClassToolChoice(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ClassToolChoice].
extension ClassToolChoicePatterns on ClassToolChoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClassToolChoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClassToolChoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClassToolChoice value)  $default,){
final _that = this;
switch (_that) {
case _ClassToolChoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClassToolChoice value)?  $default,){
final _that = this;
switch (_that) {
case _ClassToolChoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int count,  List<String> categories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClassToolChoice() when $default != null:
return $default(_that.count,_that.categories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int count,  List<String> categories)  $default,) {final _that = this;
switch (_that) {
case _ClassToolChoice():
return $default(_that.count,_that.categories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int count,  List<String> categories)?  $default,) {final _that = this;
switch (_that) {
case _ClassToolChoice() when $default != null:
return $default(_that.count,_that.categories);case _:
  return null;

}
}

}

/// @nodoc


class _ClassToolChoice implements ClassToolChoice {
  const _ClassToolChoice({required this.count, required  List<String> categories}): _categories = categories;
  

@override final  int count;
 final  List<String> _categories;
@override List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}


/// Create a copy of ClassToolChoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClassToolChoiceCopyWith<_ClassToolChoice> get copyWith => __$ClassToolChoiceCopyWithImpl<_ClassToolChoice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClassToolChoice&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other._categories, _categories));
}


@override
int get hashCode => Object.hash(runtimeType,count,const DeepCollectionEquality().hash(_categories));

@override
String toString() {
  return 'ClassToolChoice(count: $count, categories: $categories)';
}


}

/// @nodoc
abstract mixin class _$ClassToolChoiceCopyWith<$Res> implements $ClassToolChoiceCopyWith<$Res> {
  factory _$ClassToolChoiceCopyWith(_ClassToolChoice value, $Res Function(_ClassToolChoice) _then) = __$ClassToolChoiceCopyWithImpl;
@override @useResult
$Res call({
 int count, List<String> categories
});




}
/// @nodoc
class __$ClassToolChoiceCopyWithImpl<$Res>
    implements _$ClassToolChoiceCopyWith<$Res> {
  __$ClassToolChoiceCopyWithImpl(this._self, this._then);

  final _ClassToolChoice _self;
  final $Res Function(_ClassToolChoice) _then;

/// Create a copy of ClassToolChoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? categories = null,}) {
  return _then(_ClassToolChoice(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
