// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'spell_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SpellOption {

 int get id; String get name;/// 0 = sort mineur ("cantrip"), 1 = sort de niveau 1 (seuls niveaux
/// utilisés par cette étape, `spells.level` va jusqu'à 9 mais le contenu
/// peuplé ne couvre que le socle MVP niveau 1-3/4 — voir le commentaire
/// de classe de `data/character_creation_repository.dart`).
 int get level;/// École de magie (`spells.school`, ex. "Évocation") — première moitié de
/// la ligne de méta affichée sous le nom du sort.
 String get school;/// Temps d'incantation (`spells.casting_time`, valeur brute telle que
/// stockée en base, ex. "1 action" — pas de reformatage "action" comme
/// une première lecture de la maquette aurait pu le suggérer, la colonne
/// réelle inclut toujours la quantité) — seconde moitié de la ligne de
/// méta.
 String get castingTime;/// Portée (`spells.range`).
 String get range;/// Composantes (`spells.components`, jsonb `{verbal, somatic, material,
/// material_desc}`), formatées par `SpellComponentsFormatter`.
 Map<String, dynamic> get components;/// Durée (`spells.duration`).
 String get duration;/// `spells.concentration`.
 bool get concentration;/// Description FR (`translations`, `field_name = 'description'`).
 String get description;/// `spells.is_incomplete` — `true` pour une entrée placeholder créée par
/// l'import XML aidedd.org quand l'utilisateur choisit "Garder comme
/// élément personnalisé" pour un sort non catalogué (voir
/// `features/xml_import/data/xml_import_placeholder_catalog_repository.dart`,
/// toujours `level: 0` pour ces entrées, voir sa documentation). Signale
/// qu'il manque des informations à compléter plus tard côté contenu —
/// `false` pour tout sort peuplé normalement par l'équipe
/// `dev-backend-supabase`.
 bool get isIncomplete;
/// Create a copy of SpellOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpellOptionCopyWith<SpellOption> get copyWith => _$SpellOptionCopyWithImpl<SpellOption>(this as SpellOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SpellOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.level, level) || other.level == level)&&(identical(other.school, school) || other.school == school)&&(identical(other.castingTime, castingTime) || other.castingTime == castingTime)&&(identical(other.range, range) || other.range == range)&&const DeepCollectionEquality().equals(other.components, components)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.concentration, concentration) || other.concentration == concentration)&&(identical(other.description, description) || other.description == description)&&(identical(other.isIncomplete, isIncomplete) || other.isIncomplete == isIncomplete));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,level,school,castingTime,range,const DeepCollectionEquality().hash(components),duration,concentration,description,isIncomplete);

@override
String toString() {
  return 'SpellOption(id: $id, name: $name, level: $level, school: $school, castingTime: $castingTime, range: $range, components: $components, duration: $duration, concentration: $concentration, description: $description, isIncomplete: $isIncomplete)';
}


}

/// @nodoc
abstract mixin class $SpellOptionCopyWith<$Res>  {
  factory $SpellOptionCopyWith(SpellOption value, $Res Function(SpellOption) _then) = _$SpellOptionCopyWithImpl;
@useResult
$Res call({
 int id, String name, int level, String school, String castingTime, String range, Map<String, dynamic> components, String duration, bool concentration, String description, bool isIncomplete
});




}
/// @nodoc
class _$SpellOptionCopyWithImpl<$Res>
    implements $SpellOptionCopyWith<$Res> {
  _$SpellOptionCopyWithImpl(this._self, this._then);

  final SpellOption _self;
  final $Res Function(SpellOption) _then;

/// Create a copy of SpellOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? level = null,Object? school = null,Object? castingTime = null,Object? range = null,Object? components = null,Object? duration = null,Object? concentration = null,Object? description = null,Object? isIncomplete = null,}) {
  return _then(SpellOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,school: null == school ? _self.school : school // ignore: cast_nullable_to_non_nullable
as String,castingTime: null == castingTime ? _self.castingTime : castingTime // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as String,components: null == components ? _self.components : components // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,concentration: null == concentration ? _self.concentration : concentration // ignore: cast_nullable_to_non_nullable
as bool,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isIncomplete: null == isIncomplete ? _self.isIncomplete : isIncomplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SpellOption].
extension SpellOptionPatterns on SpellOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SpellOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SpellOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SpellOption value)  $default,){
final _that = this;
switch (_that) {
case _SpellOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SpellOption value)?  $default,){
final _that = this;
switch (_that) {
case _SpellOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  int level,  String school,  String castingTime,  String range,  Map<String, dynamic> components,  String duration,  bool concentration,  String description,  bool isIncomplete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SpellOption() when $default != null:
return $default(_that.id,_that.name,_that.level,_that.school,_that.castingTime,_that.range,_that.components,_that.duration,_that.concentration,_that.description,_that.isIncomplete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  int level,  String school,  String castingTime,  String range,  Map<String, dynamic> components,  String duration,  bool concentration,  String description,  bool isIncomplete)  $default,) {final _that = this;
switch (_that) {
case _SpellOption():
return $default(_that.id,_that.name,_that.level,_that.school,_that.castingTime,_that.range,_that.components,_that.duration,_that.concentration,_that.description,_that.isIncomplete);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  int level,  String school,  String castingTime,  String range,  Map<String, dynamic> components,  String duration,  bool concentration,  String description,  bool isIncomplete)?  $default,) {final _that = this;
switch (_that) {
case _SpellOption() when $default != null:
return $default(_that.id,_that.name,_that.level,_that.school,_that.castingTime,_that.range,_that.components,_that.duration,_that.concentration,_that.description,_that.isIncomplete);case _:
  return null;

}
}

}

/// @nodoc


class _SpellOption extends SpellOption {
  const _SpellOption({required this.id, required this.name, required this.level, required this.school, required this.castingTime, this.range = '',  Map<String, dynamic> components = const <String, dynamic>{}, this.duration = '', this.concentration = false, this.description = '', this.isIncomplete = false}): _components = components,super._();
  

@override final  int id;
@override final  String name;
/// 0 = sort mineur ("cantrip"), 1 = sort de niveau 1 (seuls niveaux
/// utilisés par cette étape, `spells.level` va jusqu'à 9 mais le contenu
/// peuplé ne couvre que le socle MVP niveau 1-3/4 — voir le commentaire
/// de classe de `data/character_creation_repository.dart`).
@override final  int level;
/// École de magie (`spells.school`, ex. "Évocation") — première moitié de
/// la ligne de méta affichée sous le nom du sort.
@override final  String school;
/// Temps d'incantation (`spells.casting_time`, valeur brute telle que
/// stockée en base, ex. "1 action" — pas de reformatage "action" comme
/// une première lecture de la maquette aurait pu le suggérer, la colonne
/// réelle inclut toujours la quantité) — seconde moitié de la ligne de
/// méta.
@override final  String castingTime;
/// Portée (`spells.range`).
@override@JsonKey() final  String range;
/// Composantes (`spells.components`, jsonb `{verbal, somatic, material,
/// material_desc}`), formatées par `SpellComponentsFormatter`.
 final  Map<String, dynamic> _components;
/// Composantes (`spells.components`, jsonb `{verbal, somatic, material,
/// material_desc}`), formatées par `SpellComponentsFormatter`.
@override@JsonKey() Map<String, dynamic> get components {
  if (_components is EqualUnmodifiableMapView) return _components;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_components);
}

/// Durée (`spells.duration`).
@override@JsonKey() final  String duration;
/// `spells.concentration`.
@override@JsonKey() final  bool concentration;
/// Description FR (`translations`, `field_name = 'description'`).
@override@JsonKey() final  String description;
/// `spells.is_incomplete` — `true` pour une entrée placeholder créée par
/// l'import XML aidedd.org quand l'utilisateur choisit "Garder comme
/// élément personnalisé" pour un sort non catalogué (voir
/// `features/xml_import/data/xml_import_placeholder_catalog_repository.dart`,
/// toujours `level: 0` pour ces entrées, voir sa documentation). Signale
/// qu'il manque des informations à compléter plus tard côté contenu —
/// `false` pour tout sort peuplé normalement par l'équipe
/// `dev-backend-supabase`.
@override@JsonKey() final  bool isIncomplete;

/// Create a copy of SpellOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpellOptionCopyWith<_SpellOption> get copyWith => __$SpellOptionCopyWithImpl<_SpellOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SpellOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.level, level) || other.level == level)&&(identical(other.school, school) || other.school == school)&&(identical(other.castingTime, castingTime) || other.castingTime == castingTime)&&(identical(other.range, range) || other.range == range)&&const DeepCollectionEquality().equals(other._components, _components)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.concentration, concentration) || other.concentration == concentration)&&(identical(other.description, description) || other.description == description)&&(identical(other.isIncomplete, isIncomplete) || other.isIncomplete == isIncomplete));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,level,school,castingTime,range,const DeepCollectionEquality().hash(_components),duration,concentration,description,isIncomplete);

@override
String toString() {
  return 'SpellOption(id: $id, name: $name, level: $level, school: $school, castingTime: $castingTime, range: $range, components: $components, duration: $duration, concentration: $concentration, description: $description, isIncomplete: $isIncomplete)';
}


}

/// @nodoc
abstract mixin class _$SpellOptionCopyWith<$Res> implements $SpellOptionCopyWith<$Res> {
  factory _$SpellOptionCopyWith(_SpellOption value, $Res Function(_SpellOption) _then) = __$SpellOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, int level, String school, String castingTime, String range, Map<String, dynamic> components, String duration, bool concentration, String description, bool isIncomplete
});




}
/// @nodoc
class __$SpellOptionCopyWithImpl<$Res>
    implements _$SpellOptionCopyWith<$Res> {
  __$SpellOptionCopyWithImpl(this._self, this._then);

  final _SpellOption _self;
  final $Res Function(_SpellOption) _then;

/// Create a copy of SpellOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? level = null,Object? school = null,Object? castingTime = null,Object? range = null,Object? components = null,Object? duration = null,Object? concentration = null,Object? description = null,Object? isIncomplete = null,}) {
  return _then(_SpellOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,school: null == school ? _self.school : school // ignore: cast_nullable_to_non_nullable
as String,castingTime: null == castingTime ? _self.castingTime : castingTime // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as String,components: null == components ? _self._components : components // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,concentration: null == concentration ? _self.concentration : concentration // ignore: cast_nullable_to_non_nullable
as bool,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isIncomplete: null == isIncomplete ? _self.isIncomplete : isIncomplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
