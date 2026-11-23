// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grimoire_combat_view.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GrimoireInitiative {

 GrimoireInitiativeStatus get status;/// Dernière valeur envoyée avec succès (ou en cours d'envoi).
 int? get sentValue;/// Horloge de Nexus au moment de l'envoi réussi.
 DateTime? get sentAt;/// Échec du dernier envoi ([GrimoireInitiativeStatus.failed]).
 GrimoireFailure? get failure;
/// Create a copy of GrimoireInitiative
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrimoireInitiativeCopyWith<GrimoireInitiative> get copyWith => _$GrimoireInitiativeCopyWithImpl<GrimoireInitiative>(this as GrimoireInitiative, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrimoireInitiative&&(identical(other.status, status) || other.status == status)&&(identical(other.sentValue, sentValue) || other.sentValue == sentValue)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,status,sentValue,sentAt,failure);

@override
String toString() {
  return 'GrimoireInitiative(status: $status, sentValue: $sentValue, sentAt: $sentAt, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $GrimoireInitiativeCopyWith<$Res>  {
  factory $GrimoireInitiativeCopyWith(GrimoireInitiative value, $Res Function(GrimoireInitiative) _then) = _$GrimoireInitiativeCopyWithImpl;
@useResult
$Res call({
 GrimoireInitiativeStatus status, int? sentValue, DateTime? sentAt, GrimoireFailure? failure
});




}
/// @nodoc
class _$GrimoireInitiativeCopyWithImpl<$Res>
    implements $GrimoireInitiativeCopyWith<$Res> {
  _$GrimoireInitiativeCopyWithImpl(this._self, this._then);

  final GrimoireInitiative _self;
  final $Res Function(GrimoireInitiative) _then;

/// Create a copy of GrimoireInitiative
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? sentValue = freezed,Object? sentAt = freezed,Object? failure = freezed,}) {
  return _then(GrimoireInitiative(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GrimoireInitiativeStatus,sentValue: freezed == sentValue ? _self.sentValue : sentValue // ignore: cast_nullable_to_non_nullable
as int?,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as GrimoireFailure?,
  ));
}

}


/// Adds pattern-matching-related methods to [GrimoireInitiative].
extension GrimoireInitiativePatterns on GrimoireInitiative {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrimoireInitiative value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrimoireInitiative() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrimoireInitiative value)  $default,){
final _that = this;
switch (_that) {
case _GrimoireInitiative():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrimoireInitiative value)?  $default,){
final _that = this;
switch (_that) {
case _GrimoireInitiative() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GrimoireInitiativeStatus status,  int? sentValue,  DateTime? sentAt,  GrimoireFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrimoireInitiative() when $default != null:
return $default(_that.status,_that.sentValue,_that.sentAt,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GrimoireInitiativeStatus status,  int? sentValue,  DateTime? sentAt,  GrimoireFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _GrimoireInitiative():
return $default(_that.status,_that.sentValue,_that.sentAt,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GrimoireInitiativeStatus status,  int? sentValue,  DateTime? sentAt,  GrimoireFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _GrimoireInitiative() when $default != null:
return $default(_that.status,_that.sentValue,_that.sentAt,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _GrimoireInitiative extends GrimoireInitiative {
  const _GrimoireInitiative({this.status = GrimoireInitiativeStatus.idle, this.sentValue, this.sentAt, this.failure}): super._();
  

@override@JsonKey() final  GrimoireInitiativeStatus status;
/// Dernière valeur envoyée avec succès (ou en cours d'envoi).
@override final  int? sentValue;
/// Horloge de Nexus au moment de l'envoi réussi.
@override final  DateTime? sentAt;
/// Échec du dernier envoi ([GrimoireInitiativeStatus.failed]).
@override final  GrimoireFailure? failure;

/// Create a copy of GrimoireInitiative
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrimoireInitiativeCopyWith<_GrimoireInitiative> get copyWith => __$GrimoireInitiativeCopyWithImpl<_GrimoireInitiative>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrimoireInitiative&&(identical(other.status, status) || other.status == status)&&(identical(other.sentValue, sentValue) || other.sentValue == sentValue)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,status,sentValue,sentAt,failure);

@override
String toString() {
  return 'GrimoireInitiative(status: $status, sentValue: $sentValue, sentAt: $sentAt, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$GrimoireInitiativeCopyWith<$Res> implements $GrimoireInitiativeCopyWith<$Res> {
  factory _$GrimoireInitiativeCopyWith(_GrimoireInitiative value, $Res Function(_GrimoireInitiative) _then) = __$GrimoireInitiativeCopyWithImpl;
@override @useResult
$Res call({
 GrimoireInitiativeStatus status, int? sentValue, DateTime? sentAt, GrimoireFailure? failure
});




}
/// @nodoc
class __$GrimoireInitiativeCopyWithImpl<$Res>
    implements _$GrimoireInitiativeCopyWith<$Res> {
  __$GrimoireInitiativeCopyWithImpl(this._self, this._then);

  final _GrimoireInitiative _self;
  final $Res Function(_GrimoireInitiative) _then;

/// Create a copy of GrimoireInitiative
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? sentValue = freezed,Object? sentAt = freezed,Object? failure = freezed,}) {
  return _then(_GrimoireInitiative(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GrimoireInitiativeStatus,sentValue: freezed == sentValue ? _self.sentValue : sentValue // ignore: cast_nullable_to_non_nullable
as int?,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as GrimoireFailure?,
  ));
}


}

/// @nodoc
mixin _$GrimoireCombatView {

 GrimoireCombatStatus get status;/// Combat affiché (`null` : aucun connu).
 String? get combatId;/// Dernier `seq` appliqué du combat affiché.
 int? get lastSeq; int get round;/// Ordre arrêté par le MJ, **jamais retrié**.
 List<GrimoireParticipant> get participants; String? get currentParticipantId;/// Personnages dont l'initiative est demandée (`initiative_requested_for`
/// du dernier `state`, complété par les `initiative_request`).
 Set<String> get requestedCharacterIds;/// `initiative_request` avec `character_ids: null` : tous les `pc` sans
/// initiative.
 bool get requestedAll;/// Réception du dernier message compté (horloge de Nexus).
 DateTime? get lastReceivedAt;/// `sent_at` du dernier message appliqué (affichage seulement).
 DateTime? get lastSentAt; GrimoireLiveness get liveness;/// « À toi de jouer » : posé seulement par un `turn` qui désigne le joueur.
 bool get yourTurn;/// `participant_removed` du participant du joueur (bandeau « Le MJ t'a
/// retiré de ce combat »), effacé s'il réapparaît dans un ordre.
 bool get removedFromCombat;/// `combat_end` : rounds atteints et participants publics vus.
 int? get endedRounds; int? get endedParticipantCount; GrimoireInitiative get initiative;
/// Create a copy of GrimoireCombatView
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrimoireCombatViewCopyWith<GrimoireCombatView> get copyWith => _$GrimoireCombatViewCopyWithImpl<GrimoireCombatView>(this as GrimoireCombatView, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrimoireCombatView&&(identical(other.status, status) || other.status == status)&&(identical(other.combatId, combatId) || other.combatId == combatId)&&(identical(other.lastSeq, lastSeq) || other.lastSeq == lastSeq)&&(identical(other.round, round) || other.round == round)&&const DeepCollectionEquality().equals(other.participants, participants)&&(identical(other.currentParticipantId, currentParticipantId) || other.currentParticipantId == currentParticipantId)&&const DeepCollectionEquality().equals(other.requestedCharacterIds, requestedCharacterIds)&&(identical(other.requestedAll, requestedAll) || other.requestedAll == requestedAll)&&(identical(other.lastReceivedAt, lastReceivedAt) || other.lastReceivedAt == lastReceivedAt)&&(identical(other.lastSentAt, lastSentAt) || other.lastSentAt == lastSentAt)&&(identical(other.liveness, liveness) || other.liveness == liveness)&&(identical(other.yourTurn, yourTurn) || other.yourTurn == yourTurn)&&(identical(other.removedFromCombat, removedFromCombat) || other.removedFromCombat == removedFromCombat)&&(identical(other.endedRounds, endedRounds) || other.endedRounds == endedRounds)&&(identical(other.endedParticipantCount, endedParticipantCount) || other.endedParticipantCount == endedParticipantCount)&&(identical(other.initiative, initiative) || other.initiative == initiative));
}


@override
int get hashCode => Object.hash(runtimeType,status,combatId,lastSeq,round,const DeepCollectionEquality().hash(participants),currentParticipantId,const DeepCollectionEquality().hash(requestedCharacterIds),requestedAll,lastReceivedAt,lastSentAt,liveness,yourTurn,removedFromCombat,endedRounds,endedParticipantCount,initiative);

@override
String toString() {
  return 'GrimoireCombatView(status: $status, combatId: $combatId, lastSeq: $lastSeq, round: $round, participants: $participants, currentParticipantId: $currentParticipantId, requestedCharacterIds: $requestedCharacterIds, requestedAll: $requestedAll, lastReceivedAt: $lastReceivedAt, lastSentAt: $lastSentAt, liveness: $liveness, yourTurn: $yourTurn, removedFromCombat: $removedFromCombat, endedRounds: $endedRounds, endedParticipantCount: $endedParticipantCount, initiative: $initiative)';
}


}

/// @nodoc
abstract mixin class $GrimoireCombatViewCopyWith<$Res>  {
  factory $GrimoireCombatViewCopyWith(GrimoireCombatView value, $Res Function(GrimoireCombatView) _then) = _$GrimoireCombatViewCopyWithImpl;
@useResult
$Res call({
 GrimoireCombatStatus status, String? combatId, int? lastSeq, int round, List<GrimoireParticipant> participants, String? currentParticipantId, Set<String> requestedCharacterIds, bool requestedAll, DateTime? lastReceivedAt, DateTime? lastSentAt, GrimoireLiveness liveness, bool yourTurn, bool removedFromCombat, int? endedRounds, int? endedParticipantCount, GrimoireInitiative initiative
});


$GrimoireInitiativeCopyWith<$Res> get initiative;

}
/// @nodoc
class _$GrimoireCombatViewCopyWithImpl<$Res>
    implements $GrimoireCombatViewCopyWith<$Res> {
  _$GrimoireCombatViewCopyWithImpl(this._self, this._then);

  final GrimoireCombatView _self;
  final $Res Function(GrimoireCombatView) _then;

/// Create a copy of GrimoireCombatView
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? combatId = freezed,Object? lastSeq = freezed,Object? round = null,Object? participants = null,Object? currentParticipantId = freezed,Object? requestedCharacterIds = null,Object? requestedAll = null,Object? lastReceivedAt = freezed,Object? lastSentAt = freezed,Object? liveness = null,Object? yourTurn = null,Object? removedFromCombat = null,Object? endedRounds = freezed,Object? endedParticipantCount = freezed,Object? initiative = null,}) {
  return _then(GrimoireCombatView(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GrimoireCombatStatus,combatId: freezed == combatId ? _self.combatId : combatId // ignore: cast_nullable_to_non_nullable
as String?,lastSeq: freezed == lastSeq ? _self.lastSeq : lastSeq // ignore: cast_nullable_to_non_nullable
as int?,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<GrimoireParticipant>,currentParticipantId: freezed == currentParticipantId ? _self.currentParticipantId : currentParticipantId // ignore: cast_nullable_to_non_nullable
as String?,requestedCharacterIds: null == requestedCharacterIds ? _self.requestedCharacterIds : requestedCharacterIds // ignore: cast_nullable_to_non_nullable
as Set<String>,requestedAll: null == requestedAll ? _self.requestedAll : requestedAll // ignore: cast_nullable_to_non_nullable
as bool,lastReceivedAt: freezed == lastReceivedAt ? _self.lastReceivedAt : lastReceivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastSentAt: freezed == lastSentAt ? _self.lastSentAt : lastSentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,liveness: null == liveness ? _self.liveness : liveness // ignore: cast_nullable_to_non_nullable
as GrimoireLiveness,yourTurn: null == yourTurn ? _self.yourTurn : yourTurn // ignore: cast_nullable_to_non_nullable
as bool,removedFromCombat: null == removedFromCombat ? _self.removedFromCombat : removedFromCombat // ignore: cast_nullable_to_non_nullable
as bool,endedRounds: freezed == endedRounds ? _self.endedRounds : endedRounds // ignore: cast_nullable_to_non_nullable
as int?,endedParticipantCount: freezed == endedParticipantCount ? _self.endedParticipantCount : endedParticipantCount // ignore: cast_nullable_to_non_nullable
as int?,initiative: null == initiative ? _self.initiative : initiative // ignore: cast_nullable_to_non_nullable
as GrimoireInitiative,
  ));
}
/// Create a copy of GrimoireCombatView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GrimoireInitiativeCopyWith<$Res> get initiative {
  
  return $GrimoireInitiativeCopyWith<$Res>(_self.initiative, (value) {
    return _then(_self.copyWith(initiative: value));
  });
}
}


/// Adds pattern-matching-related methods to [GrimoireCombatView].
extension GrimoireCombatViewPatterns on GrimoireCombatView {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrimoireCombatView value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrimoireCombatView() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrimoireCombatView value)  $default,){
final _that = this;
switch (_that) {
case _GrimoireCombatView():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrimoireCombatView value)?  $default,){
final _that = this;
switch (_that) {
case _GrimoireCombatView() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GrimoireCombatStatus status,  String? combatId,  int? lastSeq,  int round,  List<GrimoireParticipant> participants,  String? currentParticipantId,  Set<String> requestedCharacterIds,  bool requestedAll,  DateTime? lastReceivedAt,  DateTime? lastSentAt,  GrimoireLiveness liveness,  bool yourTurn,  bool removedFromCombat,  int? endedRounds,  int? endedParticipantCount,  GrimoireInitiative initiative)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrimoireCombatView() when $default != null:
return $default(_that.status,_that.combatId,_that.lastSeq,_that.round,_that.participants,_that.currentParticipantId,_that.requestedCharacterIds,_that.requestedAll,_that.lastReceivedAt,_that.lastSentAt,_that.liveness,_that.yourTurn,_that.removedFromCombat,_that.endedRounds,_that.endedParticipantCount,_that.initiative);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GrimoireCombatStatus status,  String? combatId,  int? lastSeq,  int round,  List<GrimoireParticipant> participants,  String? currentParticipantId,  Set<String> requestedCharacterIds,  bool requestedAll,  DateTime? lastReceivedAt,  DateTime? lastSentAt,  GrimoireLiveness liveness,  bool yourTurn,  bool removedFromCombat,  int? endedRounds,  int? endedParticipantCount,  GrimoireInitiative initiative)  $default,) {final _that = this;
switch (_that) {
case _GrimoireCombatView():
return $default(_that.status,_that.combatId,_that.lastSeq,_that.round,_that.participants,_that.currentParticipantId,_that.requestedCharacterIds,_that.requestedAll,_that.lastReceivedAt,_that.lastSentAt,_that.liveness,_that.yourTurn,_that.removedFromCombat,_that.endedRounds,_that.endedParticipantCount,_that.initiative);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GrimoireCombatStatus status,  String? combatId,  int? lastSeq,  int round,  List<GrimoireParticipant> participants,  String? currentParticipantId,  Set<String> requestedCharacterIds,  bool requestedAll,  DateTime? lastReceivedAt,  DateTime? lastSentAt,  GrimoireLiveness liveness,  bool yourTurn,  bool removedFromCombat,  int? endedRounds,  int? endedParticipantCount,  GrimoireInitiative initiative)?  $default,) {final _that = this;
switch (_that) {
case _GrimoireCombatView() when $default != null:
return $default(_that.status,_that.combatId,_that.lastSeq,_that.round,_that.participants,_that.currentParticipantId,_that.requestedCharacterIds,_that.requestedAll,_that.lastReceivedAt,_that.lastSentAt,_that.liveness,_that.yourTurn,_that.removedFromCombat,_that.endedRounds,_that.endedParticipantCount,_that.initiative);case _:
  return null;

}
}

}

/// @nodoc


class _GrimoireCombatView extends GrimoireCombatView {
  const _GrimoireCombatView({this.status = GrimoireCombatStatus.none, this.combatId, this.lastSeq, this.round = 1,  List<GrimoireParticipant> participants = const <GrimoireParticipant>[], this.currentParticipantId,  Set<String> requestedCharacterIds = const <String>{}, this.requestedAll = false, this.lastReceivedAt, this.lastSentAt, this.liveness = GrimoireLiveness.live, this.yourTurn = false, this.removedFromCombat = false, this.endedRounds, this.endedParticipantCount, this.initiative = const GrimoireInitiative()}): _participants = participants,_requestedCharacterIds = requestedCharacterIds,super._();
  

@override@JsonKey() final  GrimoireCombatStatus status;
/// Combat affiché (`null` : aucun connu).
@override final  String? combatId;
/// Dernier `seq` appliqué du combat affiché.
@override final  int? lastSeq;
@override@JsonKey() final  int round;
/// Ordre arrêté par le MJ, **jamais retrié**.
 final  List<GrimoireParticipant> _participants;
/// Ordre arrêté par le MJ, **jamais retrié**.
@override@JsonKey() List<GrimoireParticipant> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}

@override final  String? currentParticipantId;
/// Personnages dont l'initiative est demandée (`initiative_requested_for`
/// du dernier `state`, complété par les `initiative_request`).
 final  Set<String> _requestedCharacterIds;
/// Personnages dont l'initiative est demandée (`initiative_requested_for`
/// du dernier `state`, complété par les `initiative_request`).
@override@JsonKey() Set<String> get requestedCharacterIds {
  if (_requestedCharacterIds is EqualUnmodifiableSetView) return _requestedCharacterIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_requestedCharacterIds);
}

/// `initiative_request` avec `character_ids: null` : tous les `pc` sans
/// initiative.
@override@JsonKey() final  bool requestedAll;
/// Réception du dernier message compté (horloge de Nexus).
@override final  DateTime? lastReceivedAt;
/// `sent_at` du dernier message appliqué (affichage seulement).
@override final  DateTime? lastSentAt;
@override@JsonKey() final  GrimoireLiveness liveness;
/// « À toi de jouer » : posé seulement par un `turn` qui désigne le joueur.
@override@JsonKey() final  bool yourTurn;
/// `participant_removed` du participant du joueur (bandeau « Le MJ t'a
/// retiré de ce combat »), effacé s'il réapparaît dans un ordre.
@override@JsonKey() final  bool removedFromCombat;
/// `combat_end` : rounds atteints et participants publics vus.
@override final  int? endedRounds;
@override final  int? endedParticipantCount;
@override@JsonKey() final  GrimoireInitiative initiative;

/// Create a copy of GrimoireCombatView
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrimoireCombatViewCopyWith<_GrimoireCombatView> get copyWith => __$GrimoireCombatViewCopyWithImpl<_GrimoireCombatView>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrimoireCombatView&&(identical(other.status, status) || other.status == status)&&(identical(other.combatId, combatId) || other.combatId == combatId)&&(identical(other.lastSeq, lastSeq) || other.lastSeq == lastSeq)&&(identical(other.round, round) || other.round == round)&&const DeepCollectionEquality().equals(other._participants, _participants)&&(identical(other.currentParticipantId, currentParticipantId) || other.currentParticipantId == currentParticipantId)&&const DeepCollectionEquality().equals(other._requestedCharacterIds, _requestedCharacterIds)&&(identical(other.requestedAll, requestedAll) || other.requestedAll == requestedAll)&&(identical(other.lastReceivedAt, lastReceivedAt) || other.lastReceivedAt == lastReceivedAt)&&(identical(other.lastSentAt, lastSentAt) || other.lastSentAt == lastSentAt)&&(identical(other.liveness, liveness) || other.liveness == liveness)&&(identical(other.yourTurn, yourTurn) || other.yourTurn == yourTurn)&&(identical(other.removedFromCombat, removedFromCombat) || other.removedFromCombat == removedFromCombat)&&(identical(other.endedRounds, endedRounds) || other.endedRounds == endedRounds)&&(identical(other.endedParticipantCount, endedParticipantCount) || other.endedParticipantCount == endedParticipantCount)&&(identical(other.initiative, initiative) || other.initiative == initiative));
}


@override
int get hashCode => Object.hash(runtimeType,status,combatId,lastSeq,round,const DeepCollectionEquality().hash(_participants),currentParticipantId,const DeepCollectionEquality().hash(_requestedCharacterIds),requestedAll,lastReceivedAt,lastSentAt,liveness,yourTurn,removedFromCombat,endedRounds,endedParticipantCount,initiative);

@override
String toString() {
  return 'GrimoireCombatView(status: $status, combatId: $combatId, lastSeq: $lastSeq, round: $round, participants: $participants, currentParticipantId: $currentParticipantId, requestedCharacterIds: $requestedCharacterIds, requestedAll: $requestedAll, lastReceivedAt: $lastReceivedAt, lastSentAt: $lastSentAt, liveness: $liveness, yourTurn: $yourTurn, removedFromCombat: $removedFromCombat, endedRounds: $endedRounds, endedParticipantCount: $endedParticipantCount, initiative: $initiative)';
}


}

/// @nodoc
abstract mixin class _$GrimoireCombatViewCopyWith<$Res> implements $GrimoireCombatViewCopyWith<$Res> {
  factory _$GrimoireCombatViewCopyWith(_GrimoireCombatView value, $Res Function(_GrimoireCombatView) _then) = __$GrimoireCombatViewCopyWithImpl;
@override @useResult
$Res call({
 GrimoireCombatStatus status, String? combatId, int? lastSeq, int round, List<GrimoireParticipant> participants, String? currentParticipantId, Set<String> requestedCharacterIds, bool requestedAll, DateTime? lastReceivedAt, DateTime? lastSentAt, GrimoireLiveness liveness, bool yourTurn, bool removedFromCombat, int? endedRounds, int? endedParticipantCount, GrimoireInitiative initiative
});


@override $GrimoireInitiativeCopyWith<$Res> get initiative;

}
/// @nodoc
class __$GrimoireCombatViewCopyWithImpl<$Res>
    implements _$GrimoireCombatViewCopyWith<$Res> {
  __$GrimoireCombatViewCopyWithImpl(this._self, this._then);

  final _GrimoireCombatView _self;
  final $Res Function(_GrimoireCombatView) _then;

/// Create a copy of GrimoireCombatView
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? combatId = freezed,Object? lastSeq = freezed,Object? round = null,Object? participants = null,Object? currentParticipantId = freezed,Object? requestedCharacterIds = null,Object? requestedAll = null,Object? lastReceivedAt = freezed,Object? lastSentAt = freezed,Object? liveness = null,Object? yourTurn = null,Object? removedFromCombat = null,Object? endedRounds = freezed,Object? endedParticipantCount = freezed,Object? initiative = null,}) {
  return _then(_GrimoireCombatView(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GrimoireCombatStatus,combatId: freezed == combatId ? _self.combatId : combatId // ignore: cast_nullable_to_non_nullable
as String?,lastSeq: freezed == lastSeq ? _self.lastSeq : lastSeq // ignore: cast_nullable_to_non_nullable
as int?,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<GrimoireParticipant>,currentParticipantId: freezed == currentParticipantId ? _self.currentParticipantId : currentParticipantId // ignore: cast_nullable_to_non_nullable
as String?,requestedCharacterIds: null == requestedCharacterIds ? _self._requestedCharacterIds : requestedCharacterIds // ignore: cast_nullable_to_non_nullable
as Set<String>,requestedAll: null == requestedAll ? _self.requestedAll : requestedAll // ignore: cast_nullable_to_non_nullable
as bool,lastReceivedAt: freezed == lastReceivedAt ? _self.lastReceivedAt : lastReceivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastSentAt: freezed == lastSentAt ? _self.lastSentAt : lastSentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,liveness: null == liveness ? _self.liveness : liveness // ignore: cast_nullable_to_non_nullable
as GrimoireLiveness,yourTurn: null == yourTurn ? _self.yourTurn : yourTurn // ignore: cast_nullable_to_non_nullable
as bool,removedFromCombat: null == removedFromCombat ? _self.removedFromCombat : removedFromCombat // ignore: cast_nullable_to_non_nullable
as bool,endedRounds: freezed == endedRounds ? _self.endedRounds : endedRounds // ignore: cast_nullable_to_non_nullable
as int?,endedParticipantCount: freezed == endedParticipantCount ? _self.endedParticipantCount : endedParticipantCount // ignore: cast_nullable_to_non_nullable
as int?,initiative: null == initiative ? _self.initiative : initiative // ignore: cast_nullable_to_non_nullable
as GrimoireInitiative,
  ));
}

/// Create a copy of GrimoireCombatView
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GrimoireInitiativeCopyWith<$Res> get initiative {
  
  return $GrimoireInitiativeCopyWith<$Res>(_self.initiative, (value) {
    return _then(_self.copyWith(initiative: value));
  });
}
}

// dart format on
