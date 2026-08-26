// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'background_equipment_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BackgroundEquipmentEntry {

 int? get itemId;/// Nom affiché : le nom résolu si [itemId] n'est pas `null`, sinon la
/// chaîne brute de `backgrounds.equipment` telle quelle (texte libre).
 String get name; String? get category;
/// Create a copy of BackgroundEquipmentEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackgroundEquipmentEntryCopyWith<BackgroundEquipmentEntry> get copyWith => _$BackgroundEquipmentEntryCopyWithImpl<BackgroundEquipmentEntry>(this as BackgroundEquipmentEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackgroundEquipmentEntry&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category));
}


@override
int get hashCode => Object.hash(runtimeType,itemId,name,category);

@override
String toString() {
  return 'BackgroundEquipmentEntry(itemId: $itemId, name: $name, category: $category)';
}


}

/// @nodoc
abstract mixin class $BackgroundEquipmentEntryCopyWith<$Res>  {
  factory $BackgroundEquipmentEntryCopyWith(BackgroundEquipmentEntry value, $Res Function(BackgroundEquipmentEntry) _then) = _$BackgroundEquipmentEntryCopyWithImpl;
@useResult
$Res call({
 int? itemId, String name, String? category
});




}
/// @nodoc
class _$BackgroundEquipmentEntryCopyWithImpl<$Res>
    implements $BackgroundEquipmentEntryCopyWith<$Res> {
  _$BackgroundEquipmentEntryCopyWithImpl(this._self, this._then);

  final BackgroundEquipmentEntry _self;
  final $Res Function(BackgroundEquipmentEntry) _then;

/// Create a copy of BackgroundEquipmentEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemId = freezed,Object? name = null,Object? category = freezed,}) {
  return _then(BackgroundEquipmentEntry(
itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BackgroundEquipmentEntry].
extension BackgroundEquipmentEntryPatterns on BackgroundEquipmentEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BackgroundEquipmentEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BackgroundEquipmentEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BackgroundEquipmentEntry value)  $default,){
final _that = this;
switch (_that) {
case _BackgroundEquipmentEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BackgroundEquipmentEntry value)?  $default,){
final _that = this;
switch (_that) {
case _BackgroundEquipmentEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? itemId,  String name,  String? category)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BackgroundEquipmentEntry() when $default != null:
return $default(_that.itemId,_that.name,_that.category);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? itemId,  String name,  String? category)  $default,) {final _that = this;
switch (_that) {
case _BackgroundEquipmentEntry():
return $default(_that.itemId,_that.name,_that.category);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? itemId,  String name,  String? category)?  $default,) {final _that = this;
switch (_that) {
case _BackgroundEquipmentEntry() when $default != null:
return $default(_that.itemId,_that.name,_that.category);case _:
  return null;

}
}

}

/// @nodoc


class _BackgroundEquipmentEntry implements BackgroundEquipmentEntry {
  const _BackgroundEquipmentEntry({this.itemId, required this.name, this.category});
  

@override final  int? itemId;
/// Nom affiché : le nom résolu si [itemId] n'est pas `null`, sinon la
/// chaîne brute de `backgrounds.equipment` telle quelle (texte libre).
@override final  String name;
@override final  String? category;

/// Create a copy of BackgroundEquipmentEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BackgroundEquipmentEntryCopyWith<_BackgroundEquipmentEntry> get copyWith => __$BackgroundEquipmentEntryCopyWithImpl<_BackgroundEquipmentEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BackgroundEquipmentEntry&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category));
}


@override
int get hashCode => Object.hash(runtimeType,itemId,name,category);

@override
String toString() {
  return 'BackgroundEquipmentEntry(itemId: $itemId, name: $name, category: $category)';
}


}

/// @nodoc
abstract mixin class _$BackgroundEquipmentEntryCopyWith<$Res> implements $BackgroundEquipmentEntryCopyWith<$Res> {
  factory _$BackgroundEquipmentEntryCopyWith(_BackgroundEquipmentEntry value, $Res Function(_BackgroundEquipmentEntry) _then) = __$BackgroundEquipmentEntryCopyWithImpl;
@override @useResult
$Res call({
 int? itemId, String name, String? category
});




}
/// @nodoc
class __$BackgroundEquipmentEntryCopyWithImpl<$Res>
    implements _$BackgroundEquipmentEntryCopyWith<$Res> {
  __$BackgroundEquipmentEntryCopyWithImpl(this._self, this._then);

  final _BackgroundEquipmentEntry _self;
  final $Res Function(_BackgroundEquipmentEntry) _then;

/// Create a copy of BackgroundEquipmentEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemId = freezed,Object? name = null,Object? category = freezed,}) {
  return _then(_BackgroundEquipmentEntry(
itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
