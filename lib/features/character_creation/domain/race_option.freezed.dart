// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'race_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RaceOption {

 int get id; String get name; Map<String, dynamic> get abilityBonuses; List<RaceTrait> get traits;/// `races.source` — livre d'origine ("Manuel des Joueurs", "Manuel des
/// Joueurs (2024)", "Eberron / Monstres du Multivers"...). Sert
/// uniquement à [isCoreSource] (regroupement races de base/extension de
/// l'étape 1/9, voir `presentation/race_step_screen.dart`) — jamais
/// affiché tel quel à l'utilisateur. Chaîne vide retombée pour une ligne
/// sans `source` exploitable (cache offline écrit avant l'introduction
/// de cette colonne) plutôt que de crasher — voir `RaceRowMapper
/// .toRaceOption` ; classée comme extension par [isCoreSource] dans ce
/// cas (fallback conservateur).
 String get source;/// `races.is_incomplete` — `true` pour une entrée placeholder créée par
/// l'import XML aidedd.org quand l'utilisateur choisit "Garder comme
/// élément personnalisé" pour une race non cataloguée (voir
/// `features/xml_import/data/xml_import_placeholder_catalog_repository.dart`).
/// Signale qu'il manque des informations à compléter plus tard côté
/// contenu — `false` pour toute race peuplée normalement par l'équipe
/// `dev-backend-supabase`.
 bool get isIncomplete;/// Choix interactif de compétence(s) de race (`races.skill_choice`,
/// jsonb), `null` si cette race n'en a pas (la grande majorité) — étape
/// 5/9 "Compétences et outils" de l'assistant de création, carte "CHOIX
/// DE RACE" de la fiche personnage. Réutilise [ClassSkillChoices] tel
/// quel (même shape `{count, choices}`, voir sa documentation de
/// classe) : `choices` est déjà développée en la liste complète des 18
/// compétences par `data/race_row_mapper.dart::parseSkillChoice` quand
/// la colonne porte `choices: null` (choix libre, ex. Demi-elfe/
/// Forgelier/Kenku), même principe que la forme `"toutes"` du Barde.
 ClassSkillChoices? get skillChoice;/// Choix interactif d'outil(s) de race (`races.tool_choice`, jsonb),
/// `null` si cette race n'en a pas (la grande majorité) — même étape/
/// carte que [skillChoice]. Voir [RaceToolChoice] pour le détail des
/// trois formes brutes déjà résolues en une liste plate de noms
/// candidats.
 RaceToolChoice? get toolChoice;/// Compétence(s) octroyée(s) automatiquement par la race
/// (`races.skill_proficiencies`, text[]) — PAS un choix du joueur
/// (Satyre uniquement à ce jour : "Persuasion"/"Représentation"), même
/// rôle que `BackgroundOption.skillProficiencies`. Vide pour toute autre
/// race (la grande majorité).
 List<String> get skillProficiencies;/// `races.natural_weapon_item_id` — `item_id` de l'arme naturelle de
/// cette race (Aarakocra/Centaure/Homme-lézard/Minotaure/Tabaxi/Tortue à
/// ce jour, voir `item_row_mapper.dart`/`weapon_properties.properties`
/// contenant « naturelle »), `null` pour toute autre race (la grande
/// majorité). Utilisé à la création de personnage
/// (`data/character_creation_repository.dart::createCharacter`) pour
/// ajouter automatiquement cette arme, déjà équipée, à l'inventaire —
/// jamais affiché tel quel dans l'UI de cette étape.
 int? get naturalWeaponItemId;
/// Create a copy of RaceOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RaceOptionCopyWith<RaceOption> get copyWith => _$RaceOptionCopyWithImpl<RaceOption>(this as RaceOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RaceOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.abilityBonuses, abilityBonuses)&&const DeepCollectionEquality().equals(other.traits, traits)&&(identical(other.source, source) || other.source == source)&&(identical(other.isIncomplete, isIncomplete) || other.isIncomplete == isIncomplete)&&(identical(other.skillChoice, skillChoice) || other.skillChoice == skillChoice)&&(identical(other.toolChoice, toolChoice) || other.toolChoice == toolChoice)&&const DeepCollectionEquality().equals(other.skillProficiencies, skillProficiencies)&&(identical(other.naturalWeaponItemId, naturalWeaponItemId) || other.naturalWeaponItemId == naturalWeaponItemId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(abilityBonuses),const DeepCollectionEquality().hash(traits),source,isIncomplete,skillChoice,toolChoice,const DeepCollectionEquality().hash(skillProficiencies),naturalWeaponItemId);

@override
String toString() {
  return 'RaceOption(id: $id, name: $name, abilityBonuses: $abilityBonuses, traits: $traits, source: $source, isIncomplete: $isIncomplete, skillChoice: $skillChoice, toolChoice: $toolChoice, skillProficiencies: $skillProficiencies, naturalWeaponItemId: $naturalWeaponItemId)';
}


}

/// @nodoc
abstract mixin class $RaceOptionCopyWith<$Res>  {
  factory $RaceOptionCopyWith(RaceOption value, $Res Function(RaceOption) _then) = _$RaceOptionCopyWithImpl;
@useResult
$Res call({
 int id, String name, Map<String, dynamic> abilityBonuses, List<RaceTrait> traits, String source, bool isIncomplete, ClassSkillChoices? skillChoice, RaceToolChoice? toolChoice, List<String> skillProficiencies, int? naturalWeaponItemId
});


$ClassSkillChoicesCopyWith<$Res>? get skillChoice;$RaceToolChoiceCopyWith<$Res>? get toolChoice;

}
/// @nodoc
class _$RaceOptionCopyWithImpl<$Res>
    implements $RaceOptionCopyWith<$Res> {
  _$RaceOptionCopyWithImpl(this._self, this._then);

  final RaceOption _self;
  final $Res Function(RaceOption) _then;

/// Create a copy of RaceOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? abilityBonuses = null,Object? traits = null,Object? source = null,Object? isIncomplete = null,Object? skillChoice = freezed,Object? toolChoice = freezed,Object? skillProficiencies = null,Object? naturalWeaponItemId = freezed,}) {
  return _then(RaceOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,abilityBonuses: null == abilityBonuses ? _self.abilityBonuses : abilityBonuses // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,traits: null == traits ? _self.traits : traits // ignore: cast_nullable_to_non_nullable
as List<RaceTrait>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,isIncomplete: null == isIncomplete ? _self.isIncomplete : isIncomplete // ignore: cast_nullable_to_non_nullable
as bool,skillChoice: freezed == skillChoice ? _self.skillChoice : skillChoice // ignore: cast_nullable_to_non_nullable
as ClassSkillChoices?,toolChoice: freezed == toolChoice ? _self.toolChoice : toolChoice // ignore: cast_nullable_to_non_nullable
as RaceToolChoice?,skillProficiencies: null == skillProficiencies ? _self.skillProficiencies : skillProficiencies // ignore: cast_nullable_to_non_nullable
as List<String>,naturalWeaponItemId: freezed == naturalWeaponItemId ? _self.naturalWeaponItemId : naturalWeaponItemId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of RaceOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClassSkillChoicesCopyWith<$Res>? get skillChoice {
    if (_self.skillChoice == null) {
    return null;
  }

  return $ClassSkillChoicesCopyWith<$Res>(_self.skillChoice!, (value) {
    return _then(_self.copyWith(skillChoice: value));
  });
}/// Create a copy of RaceOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RaceToolChoiceCopyWith<$Res>? get toolChoice {
    if (_self.toolChoice == null) {
    return null;
  }

  return $RaceToolChoiceCopyWith<$Res>(_self.toolChoice!, (value) {
    return _then(_self.copyWith(toolChoice: value));
  });
}
}


/// Adds pattern-matching-related methods to [RaceOption].
extension RaceOptionPatterns on RaceOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RaceOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RaceOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RaceOption value)  $default,){
final _that = this;
switch (_that) {
case _RaceOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RaceOption value)?  $default,){
final _that = this;
switch (_that) {
case _RaceOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  Map<String, dynamic> abilityBonuses,  List<RaceTrait> traits,  String source,  bool isIncomplete,  ClassSkillChoices? skillChoice,  RaceToolChoice? toolChoice,  List<String> skillProficiencies,  int? naturalWeaponItemId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RaceOption() when $default != null:
return $default(_that.id,_that.name,_that.abilityBonuses,_that.traits,_that.source,_that.isIncomplete,_that.skillChoice,_that.toolChoice,_that.skillProficiencies,_that.naturalWeaponItemId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  Map<String, dynamic> abilityBonuses,  List<RaceTrait> traits,  String source,  bool isIncomplete,  ClassSkillChoices? skillChoice,  RaceToolChoice? toolChoice,  List<String> skillProficiencies,  int? naturalWeaponItemId)  $default,) {final _that = this;
switch (_that) {
case _RaceOption():
return $default(_that.id,_that.name,_that.abilityBonuses,_that.traits,_that.source,_that.isIncomplete,_that.skillChoice,_that.toolChoice,_that.skillProficiencies,_that.naturalWeaponItemId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  Map<String, dynamic> abilityBonuses,  List<RaceTrait> traits,  String source,  bool isIncomplete,  ClassSkillChoices? skillChoice,  RaceToolChoice? toolChoice,  List<String> skillProficiencies,  int? naturalWeaponItemId)?  $default,) {final _that = this;
switch (_that) {
case _RaceOption() when $default != null:
return $default(_that.id,_that.name,_that.abilityBonuses,_that.traits,_that.source,_that.isIncomplete,_that.skillChoice,_that.toolChoice,_that.skillProficiencies,_that.naturalWeaponItemId);case _:
  return null;

}
}

}

/// @nodoc


class _RaceOption extends RaceOption {
  const _RaceOption({required this.id, required this.name, required  Map<String, dynamic> abilityBonuses, required  List<RaceTrait> traits, required this.source, this.isIncomplete = false, this.skillChoice, this.toolChoice,  List<String> skillProficiencies = const <String>[], this.naturalWeaponItemId}): _abilityBonuses = abilityBonuses,_traits = traits,_skillProficiencies = skillProficiencies,super._();
  

@override final  int id;
@override final  String name;
 final  Map<String, dynamic> _abilityBonuses;
@override Map<String, dynamic> get abilityBonuses {
  if (_abilityBonuses is EqualUnmodifiableMapView) return _abilityBonuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_abilityBonuses);
}

 final  List<RaceTrait> _traits;
@override List<RaceTrait> get traits {
  if (_traits is EqualUnmodifiableListView) return _traits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_traits);
}

/// `races.source` — livre d'origine ("Manuel des Joueurs", "Manuel des
/// Joueurs (2024)", "Eberron / Monstres du Multivers"...). Sert
/// uniquement à [isCoreSource] (regroupement races de base/extension de
/// l'étape 1/9, voir `presentation/race_step_screen.dart`) — jamais
/// affiché tel quel à l'utilisateur. Chaîne vide retombée pour une ligne
/// sans `source` exploitable (cache offline écrit avant l'introduction
/// de cette colonne) plutôt que de crasher — voir `RaceRowMapper
/// .toRaceOption` ; classée comme extension par [isCoreSource] dans ce
/// cas (fallback conservateur).
@override final  String source;
/// `races.is_incomplete` — `true` pour une entrée placeholder créée par
/// l'import XML aidedd.org quand l'utilisateur choisit "Garder comme
/// élément personnalisé" pour une race non cataloguée (voir
/// `features/xml_import/data/xml_import_placeholder_catalog_repository.dart`).
/// Signale qu'il manque des informations à compléter plus tard côté
/// contenu — `false` pour toute race peuplée normalement par l'équipe
/// `dev-backend-supabase`.
@override@JsonKey() final  bool isIncomplete;
/// Choix interactif de compétence(s) de race (`races.skill_choice`,
/// jsonb), `null` si cette race n'en a pas (la grande majorité) — étape
/// 5/9 "Compétences et outils" de l'assistant de création, carte "CHOIX
/// DE RACE" de la fiche personnage. Réutilise [ClassSkillChoices] tel
/// quel (même shape `{count, choices}`, voir sa documentation de
/// classe) : `choices` est déjà développée en la liste complète des 18
/// compétences par `data/race_row_mapper.dart::parseSkillChoice` quand
/// la colonne porte `choices: null` (choix libre, ex. Demi-elfe/
/// Forgelier/Kenku), même principe que la forme `"toutes"` du Barde.
@override final  ClassSkillChoices? skillChoice;
/// Choix interactif d'outil(s) de race (`races.tool_choice`, jsonb),
/// `null` si cette race n'en a pas (la grande majorité) — même étape/
/// carte que [skillChoice]. Voir [RaceToolChoice] pour le détail des
/// trois formes brutes déjà résolues en une liste plate de noms
/// candidats.
@override final  RaceToolChoice? toolChoice;
/// Compétence(s) octroyée(s) automatiquement par la race
/// (`races.skill_proficiencies`, text[]) — PAS un choix du joueur
/// (Satyre uniquement à ce jour : "Persuasion"/"Représentation"), même
/// rôle que `BackgroundOption.skillProficiencies`. Vide pour toute autre
/// race (la grande majorité).
 final  List<String> _skillProficiencies;
/// Compétence(s) octroyée(s) automatiquement par la race
/// (`races.skill_proficiencies`, text[]) — PAS un choix du joueur
/// (Satyre uniquement à ce jour : "Persuasion"/"Représentation"), même
/// rôle que `BackgroundOption.skillProficiencies`. Vide pour toute autre
/// race (la grande majorité).
@override@JsonKey() List<String> get skillProficiencies {
  if (_skillProficiencies is EqualUnmodifiableListView) return _skillProficiencies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skillProficiencies);
}

/// `races.natural_weapon_item_id` — `item_id` de l'arme naturelle de
/// cette race (Aarakocra/Centaure/Homme-lézard/Minotaure/Tabaxi/Tortue à
/// ce jour, voir `item_row_mapper.dart`/`weapon_properties.properties`
/// contenant « naturelle »), `null` pour toute autre race (la grande
/// majorité). Utilisé à la création de personnage
/// (`data/character_creation_repository.dart::createCharacter`) pour
/// ajouter automatiquement cette arme, déjà équipée, à l'inventaire —
/// jamais affiché tel quel dans l'UI de cette étape.
@override final  int? naturalWeaponItemId;

/// Create a copy of RaceOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RaceOptionCopyWith<_RaceOption> get copyWith => __$RaceOptionCopyWithImpl<_RaceOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RaceOption&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._abilityBonuses, _abilityBonuses)&&const DeepCollectionEquality().equals(other._traits, _traits)&&(identical(other.source, source) || other.source == source)&&(identical(other.isIncomplete, isIncomplete) || other.isIncomplete == isIncomplete)&&(identical(other.skillChoice, skillChoice) || other.skillChoice == skillChoice)&&(identical(other.toolChoice, toolChoice) || other.toolChoice == toolChoice)&&const DeepCollectionEquality().equals(other._skillProficiencies, _skillProficiencies)&&(identical(other.naturalWeaponItemId, naturalWeaponItemId) || other.naturalWeaponItemId == naturalWeaponItemId));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_abilityBonuses),const DeepCollectionEquality().hash(_traits),source,isIncomplete,skillChoice,toolChoice,const DeepCollectionEquality().hash(_skillProficiencies),naturalWeaponItemId);

@override
String toString() {
  return 'RaceOption(id: $id, name: $name, abilityBonuses: $abilityBonuses, traits: $traits, source: $source, isIncomplete: $isIncomplete, skillChoice: $skillChoice, toolChoice: $toolChoice, skillProficiencies: $skillProficiencies, naturalWeaponItemId: $naturalWeaponItemId)';
}


}

/// @nodoc
abstract mixin class _$RaceOptionCopyWith<$Res> implements $RaceOptionCopyWith<$Res> {
  factory _$RaceOptionCopyWith(_RaceOption value, $Res Function(_RaceOption) _then) = __$RaceOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, Map<String, dynamic> abilityBonuses, List<RaceTrait> traits, String source, bool isIncomplete, ClassSkillChoices? skillChoice, RaceToolChoice? toolChoice, List<String> skillProficiencies, int? naturalWeaponItemId
});


@override $ClassSkillChoicesCopyWith<$Res>? get skillChoice;@override $RaceToolChoiceCopyWith<$Res>? get toolChoice;

}
/// @nodoc
class __$RaceOptionCopyWithImpl<$Res>
    implements _$RaceOptionCopyWith<$Res> {
  __$RaceOptionCopyWithImpl(this._self, this._then);

  final _RaceOption _self;
  final $Res Function(_RaceOption) _then;

/// Create a copy of RaceOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? abilityBonuses = null,Object? traits = null,Object? source = null,Object? isIncomplete = null,Object? skillChoice = freezed,Object? toolChoice = freezed,Object? skillProficiencies = null,Object? naturalWeaponItemId = freezed,}) {
  return _then(_RaceOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,abilityBonuses: null == abilityBonuses ? _self._abilityBonuses : abilityBonuses // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,traits: null == traits ? _self._traits : traits // ignore: cast_nullable_to_non_nullable
as List<RaceTrait>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,isIncomplete: null == isIncomplete ? _self.isIncomplete : isIncomplete // ignore: cast_nullable_to_non_nullable
as bool,skillChoice: freezed == skillChoice ? _self.skillChoice : skillChoice // ignore: cast_nullable_to_non_nullable
as ClassSkillChoices?,toolChoice: freezed == toolChoice ? _self.toolChoice : toolChoice // ignore: cast_nullable_to_non_nullable
as RaceToolChoice?,skillProficiencies: null == skillProficiencies ? _self._skillProficiencies : skillProficiencies // ignore: cast_nullable_to_non_nullable
as List<String>,naturalWeaponItemId: freezed == naturalWeaponItemId ? _self.naturalWeaponItemId : naturalWeaponItemId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of RaceOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClassSkillChoicesCopyWith<$Res>? get skillChoice {
    if (_self.skillChoice == null) {
    return null;
  }

  return $ClassSkillChoicesCopyWith<$Res>(_self.skillChoice!, (value) {
    return _then(_self.copyWith(skillChoice: value));
  });
}/// Create a copy of RaceOption
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RaceToolChoiceCopyWith<$Res>? get toolChoice {
    if (_self.toolChoice == null) {
    return null;
  }

  return $RaceToolChoiceCopyWith<$Res>(_self.toolChoice!, (value) {
    return _then(_self.copyWith(toolChoice: value));
  });
}
}

// dart format on
