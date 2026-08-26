// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ItemOption {

 int get id; String get name; String get category; double get costAmount;
/// Create a copy of ItemOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemOptionCopyWith<ItemOption> get copyWith => _$ItemOptionCopyWithImpl<ItemOption>(this as ItemOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.costAmount, costAmount) || other.costAmount == costAmount));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,category,costAmount);

@override
String toString() {
  return 'ItemOption(id: $id, name: $name, category: $category, costAmount: $costAmount)';
}


}

/// @nodoc
abstract mixin class $ItemOptionCopyWith<$Res>  {
  factory $ItemOptionCopyWith(ItemOption value, $Res Function(ItemOption) _then) = _$ItemOptionCopyWithImpl;
@useResult
$Res call({
 int id, String name, String category, double costAmount
});




}
/// @nodoc
class _$ItemOptionCopyWithImpl<$Res>
    implements $ItemOptionCopyWith<$Res> {
  _$ItemOptionCopyWithImpl(this._self, this._then);

  final ItemOption _self;
  final $Res Function(ItemOption) _then;

/// Create a copy of ItemOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? category = null,Object? costAmount = null,}) {
  return _then(ItemOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,costAmount: null == costAmount ? _self.costAmount : costAmount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemOption].
extension ItemOptionPatterns on ItemOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemOption value)  $default,){
final _that = this;
switch (_that) {
case _ItemOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemOption value)?  $default,){
final _that = this;
switch (_that) {
case _ItemOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String category,  double costAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemOption() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.costAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String category,  double costAmount)  $default,) {final _that = this;
switch (_that) {
case _ItemOption():
return $default(_that.id,_that.name,_that.category,_that.costAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String category,  double costAmount)?  $default,) {final _that = this;
switch (_that) {
case _ItemOption() when $default != null:
return $default(_that.id,_that.name,_that.category,_that.costAmount);case _:
  return null;

}
}

}

/// @nodoc


class _ItemOption implements ItemOption {
  const _ItemOption({required this.id, required this.name, required this.category, required this.costAmount});
  

@override final  int id;
@override final  String name;
@override final  String category;
@override final  double costAmount;

/// Create a copy of ItemOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemOptionCopyWith<_ItemOption> get copyWith => __$ItemOptionCopyWithImpl<_ItemOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.costAmount, costAmount) || other.costAmount == costAmount));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,category,costAmount);

@override
String toString() {
  return 'ItemOption(id: $id, name: $name, category: $category, costAmount: $costAmount)';
}


}

/// @nodoc
abstract mixin class _$ItemOptionCopyWith<$Res> implements $ItemOptionCopyWith<$Res> {
  factory _$ItemOptionCopyWith(_ItemOption value, $Res Function(_ItemOption) _then) = __$ItemOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String category, double costAmount
});




}
/// @nodoc
class __$ItemOptionCopyWithImpl<$Res>
    implements _$ItemOptionCopyWith<$Res> {
  __$ItemOptionCopyWithImpl(this._self, this._then);

  final _ItemOption _self;
  final $Res Function(_ItemOption) _then;

/// Create a copy of ItemOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? category = null,Object? costAmount = null,}) {
  return _then(_ItemOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,costAmount: null == costAmount ? _self.costAmount : costAmount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
