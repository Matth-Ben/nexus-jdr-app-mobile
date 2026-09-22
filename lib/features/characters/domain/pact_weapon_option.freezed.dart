// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pact_weapon_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PactWeaponOption {

/// `items.id`.
 int get id;/// Nom français (`translations`, `entity_type = 'item'`).
 String get name;/// `weapon_properties.damage_dice` (ex. « 1d8 »).
 String? get damageDice;/// `weapon_properties.damage_type` (ex. « tranchant »).
 String? get damageType;/// `weapon_properties.properties` (ex. « légère », « finesse »).
 List<String> get properties;
/// Create a copy of PactWeaponOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PactWeaponOptionCopyWith<PactWeaponOption> get copyWith => _$PactWeaponOptionCopyWithImpl<PactWeaponOption>(this as PactWeaponOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PactWeaponOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.damageDice, damageDice) || other.damageDice == damageDice)&&(identical(other.damageType, damageType) || other.damageType == damageType)&&const DeepCollectionEquality().equals(other.properties, properties));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,damageDice,damageType,const DeepCollectionEquality().hash(properties));

@override
String toString() {
  return 'PactWeaponOption(id: $id, name: $name, damageDice: $damageDice, damageType: $damageType, properties: $properties)';
}


}

/// @nodoc
abstract mixin class $PactWeaponOptionCopyWith<$Res>  {
  factory $PactWeaponOptionCopyWith(PactWeaponOption value, $Res Function(PactWeaponOption) _then) = _$PactWeaponOptionCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? damageDice, String? damageType, List<String> properties
});




}
/// @nodoc
class _$PactWeaponOptionCopyWithImpl<$Res>
    implements $PactWeaponOptionCopyWith<$Res> {
  _$PactWeaponOptionCopyWithImpl(this._self, this._then);

  final PactWeaponOption _self;
  final $Res Function(PactWeaponOption) _then;

/// Create a copy of PactWeaponOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? damageDice = freezed,Object? damageType = freezed,Object? properties = null,}) {
  return _then(PactWeaponOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,damageDice: freezed == damageDice ? _self.damageDice : damageDice // ignore: cast_nullable_to_non_nullable
as String?,damageType: freezed == damageType ? _self.damageType : damageType // ignore: cast_nullable_to_non_nullable
as String?,properties: null == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PactWeaponOption].
extension PactWeaponOptionPatterns on PactWeaponOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PactWeaponOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PactWeaponOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PactWeaponOption value)  $default,){
final _that = this;
switch (_that) {
case _PactWeaponOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PactWeaponOption value)?  $default,){
final _that = this;
switch (_that) {
case _PactWeaponOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? damageDice,  String? damageType,  List<String> properties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PactWeaponOption() when $default != null:
return $default(_that.id,_that.name,_that.damageDice,_that.damageType,_that.properties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? damageDice,  String? damageType,  List<String> properties)  $default,) {final _that = this;
switch (_that) {
case _PactWeaponOption():
return $default(_that.id,_that.name,_that.damageDice,_that.damageType,_that.properties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? damageDice,  String? damageType,  List<String> properties)?  $default,) {final _that = this;
switch (_that) {
case _PactWeaponOption() when $default != null:
return $default(_that.id,_that.name,_that.damageDice,_that.damageType,_that.properties);case _:
  return null;

}
}

}

/// @nodoc


class _PactWeaponOption extends PactWeaponOption {
  const _PactWeaponOption({required this.id, required this.name, this.damageDice, this.damageType,  List<String> properties = const <String>[]}): _properties = properties,super._();
  

/// `items.id`.
@override final  int id;
/// Nom français (`translations`, `entity_type = 'item'`).
@override final  String name;
/// `weapon_properties.damage_dice` (ex. « 1d8 »).
@override final  String? damageDice;
/// `weapon_properties.damage_type` (ex. « tranchant »).
@override final  String? damageType;
/// `weapon_properties.properties` (ex. « légère », « finesse »).
 final  List<String> _properties;
/// `weapon_properties.properties` (ex. « légère », « finesse »).
@override@JsonKey() List<String> get properties {
  if (_properties is EqualUnmodifiableListView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_properties);
}


/// Create a copy of PactWeaponOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PactWeaponOptionCopyWith<_PactWeaponOption> get copyWith => __$PactWeaponOptionCopyWithImpl<_PactWeaponOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PactWeaponOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.damageDice, damageDice) || other.damageDice == damageDice)&&(identical(other.damageType, damageType) || other.damageType == damageType)&&const DeepCollectionEquality().equals(other._properties, _properties));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,damageDice,damageType,const DeepCollectionEquality().hash(_properties));

@override
String toString() {
  return 'PactWeaponOption(id: $id, name: $name, damageDice: $damageDice, damageType: $damageType, properties: $properties)';
}


}

/// @nodoc
abstract mixin class _$PactWeaponOptionCopyWith<$Res> implements $PactWeaponOptionCopyWith<$Res> {
  factory _$PactWeaponOptionCopyWith(_PactWeaponOption value, $Res Function(_PactWeaponOption) _then) = __$PactWeaponOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? damageDice, String? damageType, List<String> properties
});




}
/// @nodoc
class __$PactWeaponOptionCopyWithImpl<$Res>
    implements _$PactWeaponOptionCopyWith<$Res> {
  __$PactWeaponOptionCopyWithImpl(this._self, this._then);

  final _PactWeaponOption _self;
  final $Res Function(_PactWeaponOption) _then;

/// Create a copy of PactWeaponOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? damageDice = freezed,Object? damageType = freezed,Object? properties = null,}) {
  return _then(_PactWeaponOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,damageDice: freezed == damageDice ? _self.damageDice : damageDice // ignore: cast_nullable_to_non_nullable
as String?,damageType: freezed == damageType ? _self.damageType : damageType // ignore: cast_nullable_to_non_nullable
as String?,properties: null == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
