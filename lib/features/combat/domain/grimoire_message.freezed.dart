// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grimoire_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GrimoireMessage {

 String get combatId; int get seq; DateTime? get sentAt;
/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrimoireMessageCopyWith<GrimoireMessage> get copyWith => _$GrimoireMessageCopyWithImpl<GrimoireMessage>(this as GrimoireMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrimoireMessage&&(identical(other.combatId, combatId) || other.combatId == combatId)&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}


@override
int get hashCode => Object.hash(runtimeType,combatId,seq,sentAt);

@override
String toString() {
  return 'GrimoireMessage(combatId: $combatId, seq: $seq, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class $GrimoireMessageCopyWith<$Res>  {
  factory $GrimoireMessageCopyWith(GrimoireMessage value, $Res Function(GrimoireMessage) _then) = _$GrimoireMessageCopyWithImpl;
@useResult
$Res call({
 String combatId, int seq, DateTime? sentAt
});




}
/// @nodoc
class _$GrimoireMessageCopyWithImpl<$Res>
    implements $GrimoireMessageCopyWith<$Res> {
  _$GrimoireMessageCopyWithImpl(this._self, this._then);

  final GrimoireMessage _self;
  final $Res Function(GrimoireMessage) _then;

/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? combatId = null,Object? seq = null,Object? sentAt = freezed,}) {
  return _then(_self.copyWith(
combatId: null == combatId ? _self.combatId : combatId // ignore: cast_nullable_to_non_nullable
as String,seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GrimoireMessage].
extension GrimoireMessagePatterns on GrimoireMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GrimoireCombatStart value)?  combatStart,TResult Function( GrimoireInitiativeRequest value)?  initiativeRequest,TResult Function( GrimoireOrder value)?  order,TResult Function( GrimoireTurn value)?  turn,TResult Function( GrimoireParticipantRemoved value)?  participantRemoved,TResult Function( GrimoireCombatEnd value)?  combatEnd,TResult Function( GrimoireState value)?  state,TResult Function( GrimoireUnknownMessage value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GrimoireCombatStart() when combatStart != null:
return combatStart(_that);case GrimoireInitiativeRequest() when initiativeRequest != null:
return initiativeRequest(_that);case GrimoireOrder() when order != null:
return order(_that);case GrimoireTurn() when turn != null:
return turn(_that);case GrimoireParticipantRemoved() when participantRemoved != null:
return participantRemoved(_that);case GrimoireCombatEnd() when combatEnd != null:
return combatEnd(_that);case GrimoireState() when state != null:
return state(_that);case GrimoireUnknownMessage() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GrimoireCombatStart value)  combatStart,required TResult Function( GrimoireInitiativeRequest value)  initiativeRequest,required TResult Function( GrimoireOrder value)  order,required TResult Function( GrimoireTurn value)  turn,required TResult Function( GrimoireParticipantRemoved value)  participantRemoved,required TResult Function( GrimoireCombatEnd value)  combatEnd,required TResult Function( GrimoireState value)  state,required TResult Function( GrimoireUnknownMessage value)  unknown,}){
final _that = this;
switch (_that) {
case GrimoireCombatStart():
return combatStart(_that);case GrimoireInitiativeRequest():
return initiativeRequest(_that);case GrimoireOrder():
return order(_that);case GrimoireTurn():
return turn(_that);case GrimoireParticipantRemoved():
return participantRemoved(_that);case GrimoireCombatEnd():
return combatEnd(_that);case GrimoireState():
return state(_that);case GrimoireUnknownMessage():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GrimoireCombatStart value)?  combatStart,TResult? Function( GrimoireInitiativeRequest value)?  initiativeRequest,TResult? Function( GrimoireOrder value)?  order,TResult? Function( GrimoireTurn value)?  turn,TResult? Function( GrimoireParticipantRemoved value)?  participantRemoved,TResult? Function( GrimoireCombatEnd value)?  combatEnd,TResult? Function( GrimoireState value)?  state,TResult? Function( GrimoireUnknownMessage value)?  unknown,}){
final _that = this;
switch (_that) {
case GrimoireCombatStart() when combatStart != null:
return combatStart(_that);case GrimoireInitiativeRequest() when initiativeRequest != null:
return initiativeRequest(_that);case GrimoireOrder() when order != null:
return order(_that);case GrimoireTurn() when turn != null:
return turn(_that);case GrimoireParticipantRemoved() when participantRemoved != null:
return participantRemoved(_that);case GrimoireCombatEnd() when combatEnd != null:
return combatEnd(_that);case GrimoireState() when state != null:
return state(_that);case GrimoireUnknownMessage() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String combatId,  int seq,  DateTime? sentAt,  int round,  List<GrimoireParticipant> participants)?  combatStart,TResult Function( String combatId,  int seq,  DateTime? sentAt,  List<String>? characterIds)?  initiativeRequest,TResult Function( String combatId,  int seq,  DateTime? sentAt,  int round,  List<GrimoireParticipant> participants,  String? currentParticipantId)?  order,TResult Function( String combatId,  int seq,  DateTime? sentAt,  int round,  String? currentParticipantId)?  turn,TResult Function( String combatId,  int seq,  DateTime? sentAt,  String participantId)?  participantRemoved,TResult Function( String combatId,  int seq,  DateTime? sentAt,  int rounds,  int participantCount)?  combatEnd,TResult Function( String combatId,  int seq,  DateTime? sentAt,  bool active,  int round,  String? currentParticipantId,  List<String> initiativeRequestedFor,  List<GrimoireParticipant> participants)?  state,TResult Function( String combatId,  int seq,  DateTime? sentAt,  String type,  bool malformed)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GrimoireCombatStart() when combatStart != null:
return combatStart(_that.combatId,_that.seq,_that.sentAt,_that.round,_that.participants);case GrimoireInitiativeRequest() when initiativeRequest != null:
return initiativeRequest(_that.combatId,_that.seq,_that.sentAt,_that.characterIds);case GrimoireOrder() when order != null:
return order(_that.combatId,_that.seq,_that.sentAt,_that.round,_that.participants,_that.currentParticipantId);case GrimoireTurn() when turn != null:
return turn(_that.combatId,_that.seq,_that.sentAt,_that.round,_that.currentParticipantId);case GrimoireParticipantRemoved() when participantRemoved != null:
return participantRemoved(_that.combatId,_that.seq,_that.sentAt,_that.participantId);case GrimoireCombatEnd() when combatEnd != null:
return combatEnd(_that.combatId,_that.seq,_that.sentAt,_that.rounds,_that.participantCount);case GrimoireState() when state != null:
return state(_that.combatId,_that.seq,_that.sentAt,_that.active,_that.round,_that.currentParticipantId,_that.initiativeRequestedFor,_that.participants);case GrimoireUnknownMessage() when unknown != null:
return unknown(_that.combatId,_that.seq,_that.sentAt,_that.type,_that.malformed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String combatId,  int seq,  DateTime? sentAt,  int round,  List<GrimoireParticipant> participants)  combatStart,required TResult Function( String combatId,  int seq,  DateTime? sentAt,  List<String>? characterIds)  initiativeRequest,required TResult Function( String combatId,  int seq,  DateTime? sentAt,  int round,  List<GrimoireParticipant> participants,  String? currentParticipantId)  order,required TResult Function( String combatId,  int seq,  DateTime? sentAt,  int round,  String? currentParticipantId)  turn,required TResult Function( String combatId,  int seq,  DateTime? sentAt,  String participantId)  participantRemoved,required TResult Function( String combatId,  int seq,  DateTime? sentAt,  int rounds,  int participantCount)  combatEnd,required TResult Function( String combatId,  int seq,  DateTime? sentAt,  bool active,  int round,  String? currentParticipantId,  List<String> initiativeRequestedFor,  List<GrimoireParticipant> participants)  state,required TResult Function( String combatId,  int seq,  DateTime? sentAt,  String type,  bool malformed)  unknown,}) {final _that = this;
switch (_that) {
case GrimoireCombatStart():
return combatStart(_that.combatId,_that.seq,_that.sentAt,_that.round,_that.participants);case GrimoireInitiativeRequest():
return initiativeRequest(_that.combatId,_that.seq,_that.sentAt,_that.characterIds);case GrimoireOrder():
return order(_that.combatId,_that.seq,_that.sentAt,_that.round,_that.participants,_that.currentParticipantId);case GrimoireTurn():
return turn(_that.combatId,_that.seq,_that.sentAt,_that.round,_that.currentParticipantId);case GrimoireParticipantRemoved():
return participantRemoved(_that.combatId,_that.seq,_that.sentAt,_that.participantId);case GrimoireCombatEnd():
return combatEnd(_that.combatId,_that.seq,_that.sentAt,_that.rounds,_that.participantCount);case GrimoireState():
return state(_that.combatId,_that.seq,_that.sentAt,_that.active,_that.round,_that.currentParticipantId,_that.initiativeRequestedFor,_that.participants);case GrimoireUnknownMessage():
return unknown(_that.combatId,_that.seq,_that.sentAt,_that.type,_that.malformed);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String combatId,  int seq,  DateTime? sentAt,  int round,  List<GrimoireParticipant> participants)?  combatStart,TResult? Function( String combatId,  int seq,  DateTime? sentAt,  List<String>? characterIds)?  initiativeRequest,TResult? Function( String combatId,  int seq,  DateTime? sentAt,  int round,  List<GrimoireParticipant> participants,  String? currentParticipantId)?  order,TResult? Function( String combatId,  int seq,  DateTime? sentAt,  int round,  String? currentParticipantId)?  turn,TResult? Function( String combatId,  int seq,  DateTime? sentAt,  String participantId)?  participantRemoved,TResult? Function( String combatId,  int seq,  DateTime? sentAt,  int rounds,  int participantCount)?  combatEnd,TResult? Function( String combatId,  int seq,  DateTime? sentAt,  bool active,  int round,  String? currentParticipantId,  List<String> initiativeRequestedFor,  List<GrimoireParticipant> participants)?  state,TResult? Function( String combatId,  int seq,  DateTime? sentAt,  String type,  bool malformed)?  unknown,}) {final _that = this;
switch (_that) {
case GrimoireCombatStart() when combatStart != null:
return combatStart(_that.combatId,_that.seq,_that.sentAt,_that.round,_that.participants);case GrimoireInitiativeRequest() when initiativeRequest != null:
return initiativeRequest(_that.combatId,_that.seq,_that.sentAt,_that.characterIds);case GrimoireOrder() when order != null:
return order(_that.combatId,_that.seq,_that.sentAt,_that.round,_that.participants,_that.currentParticipantId);case GrimoireTurn() when turn != null:
return turn(_that.combatId,_that.seq,_that.sentAt,_that.round,_that.currentParticipantId);case GrimoireParticipantRemoved() when participantRemoved != null:
return participantRemoved(_that.combatId,_that.seq,_that.sentAt,_that.participantId);case GrimoireCombatEnd() when combatEnd != null:
return combatEnd(_that.combatId,_that.seq,_that.sentAt,_that.rounds,_that.participantCount);case GrimoireState() when state != null:
return state(_that.combatId,_that.seq,_that.sentAt,_that.active,_that.round,_that.currentParticipantId,_that.initiativeRequestedFor,_that.participants);case GrimoireUnknownMessage() when unknown != null:
return unknown(_that.combatId,_that.seq,_that.sentAt,_that.type,_that.malformed);case _:
  return null;

}
}

}

/// @nodoc


class GrimoireCombatStart implements GrimoireMessage {
  const GrimoireCombatStart({required this.combatId, required this.seq, this.sentAt, required this.round, required  List<GrimoireParticipant> participants}): _participants = participants;
  

@override final  String combatId;
@override final  int seq;
@override final  DateTime? sentAt;
 final  int round;
 final  List<GrimoireParticipant> _participants;
 List<GrimoireParticipant> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}


/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrimoireCombatStartCopyWith<GrimoireCombatStart> get copyWith => _$GrimoireCombatStartCopyWithImpl<GrimoireCombatStart>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrimoireCombatStart&&(identical(other.combatId, combatId) || other.combatId == combatId)&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.round, round) || other.round == round)&&const DeepCollectionEquality().equals(other._participants, _participants));
}


@override
int get hashCode => Object.hash(runtimeType,combatId,seq,sentAt,round,const DeepCollectionEquality().hash(_participants));

@override
String toString() {
  return 'GrimoireMessage.combatStart(combatId: $combatId, seq: $seq, sentAt: $sentAt, round: $round, participants: $participants)';
}


}

/// @nodoc
abstract mixin class $GrimoireCombatStartCopyWith<$Res> implements $GrimoireMessageCopyWith<$Res> {
  factory $GrimoireCombatStartCopyWith(GrimoireCombatStart value, $Res Function(GrimoireCombatStart) _then) = _$GrimoireCombatStartCopyWithImpl;
@override @useResult
$Res call({
 String combatId, int seq, DateTime? sentAt, int round, List<GrimoireParticipant> participants
});




}
/// @nodoc
class _$GrimoireCombatStartCopyWithImpl<$Res>
    implements $GrimoireCombatStartCopyWith<$Res> {
  _$GrimoireCombatStartCopyWithImpl(this._self, this._then);

  final GrimoireCombatStart _self;
  final $Res Function(GrimoireCombatStart) _then;

/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? combatId = null,Object? seq = null,Object? sentAt = freezed,Object? round = null,Object? participants = null,}) {
  return _then(GrimoireCombatStart(
combatId: null == combatId ? _self.combatId : combatId // ignore: cast_nullable_to_non_nullable
as String,seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<GrimoireParticipant>,
  ));
}


}

/// @nodoc


class GrimoireInitiativeRequest implements GrimoireMessage {
  const GrimoireInitiativeRequest({required this.combatId, required this.seq, this.sentAt,  List<String>? characterIds}): _characterIds = characterIds;
  

@override final  String combatId;
@override final  int seq;
@override final  DateTime? sentAt;
 final  List<String>? _characterIds;
 List<String>? get characterIds {
  final value = _characterIds;
  if (value == null) return null;
  if (_characterIds is EqualUnmodifiableListView) return _characterIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrimoireInitiativeRequestCopyWith<GrimoireInitiativeRequest> get copyWith => _$GrimoireInitiativeRequestCopyWithImpl<GrimoireInitiativeRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrimoireInitiativeRequest&&(identical(other.combatId, combatId) || other.combatId == combatId)&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&const DeepCollectionEquality().equals(other._characterIds, _characterIds));
}


@override
int get hashCode => Object.hash(runtimeType,combatId,seq,sentAt,const DeepCollectionEquality().hash(_characterIds));

@override
String toString() {
  return 'GrimoireMessage.initiativeRequest(combatId: $combatId, seq: $seq, sentAt: $sentAt, characterIds: $characterIds)';
}


}

/// @nodoc
abstract mixin class $GrimoireInitiativeRequestCopyWith<$Res> implements $GrimoireMessageCopyWith<$Res> {
  factory $GrimoireInitiativeRequestCopyWith(GrimoireInitiativeRequest value, $Res Function(GrimoireInitiativeRequest) _then) = _$GrimoireInitiativeRequestCopyWithImpl;
@override @useResult
$Res call({
 String combatId, int seq, DateTime? sentAt, List<String>? characterIds
});




}
/// @nodoc
class _$GrimoireInitiativeRequestCopyWithImpl<$Res>
    implements $GrimoireInitiativeRequestCopyWith<$Res> {
  _$GrimoireInitiativeRequestCopyWithImpl(this._self, this._then);

  final GrimoireInitiativeRequest _self;
  final $Res Function(GrimoireInitiativeRequest) _then;

/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? combatId = null,Object? seq = null,Object? sentAt = freezed,Object? characterIds = freezed,}) {
  return _then(GrimoireInitiativeRequest(
combatId: null == combatId ? _self.combatId : combatId // ignore: cast_nullable_to_non_nullable
as String,seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,characterIds: freezed == characterIds ? _self._characterIds : characterIds // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

/// @nodoc


class GrimoireOrder implements GrimoireMessage {
  const GrimoireOrder({required this.combatId, required this.seq, this.sentAt, required this.round, required  List<GrimoireParticipant> participants, this.currentParticipantId}): _participants = participants;
  

@override final  String combatId;
@override final  int seq;
@override final  DateTime? sentAt;
 final  int round;
 final  List<GrimoireParticipant> _participants;
 List<GrimoireParticipant> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}

 final  String? currentParticipantId;

/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrimoireOrderCopyWith<GrimoireOrder> get copyWith => _$GrimoireOrderCopyWithImpl<GrimoireOrder>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrimoireOrder&&(identical(other.combatId, combatId) || other.combatId == combatId)&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.round, round) || other.round == round)&&const DeepCollectionEquality().equals(other._participants, _participants)&&(identical(other.currentParticipantId, currentParticipantId) || other.currentParticipantId == currentParticipantId));
}


@override
int get hashCode => Object.hash(runtimeType,combatId,seq,sentAt,round,const DeepCollectionEquality().hash(_participants),currentParticipantId);

@override
String toString() {
  return 'GrimoireMessage.order(combatId: $combatId, seq: $seq, sentAt: $sentAt, round: $round, participants: $participants, currentParticipantId: $currentParticipantId)';
}


}

/// @nodoc
abstract mixin class $GrimoireOrderCopyWith<$Res> implements $GrimoireMessageCopyWith<$Res> {
  factory $GrimoireOrderCopyWith(GrimoireOrder value, $Res Function(GrimoireOrder) _then) = _$GrimoireOrderCopyWithImpl;
@override @useResult
$Res call({
 String combatId, int seq, DateTime? sentAt, int round, List<GrimoireParticipant> participants, String? currentParticipantId
});




}
/// @nodoc
class _$GrimoireOrderCopyWithImpl<$Res>
    implements $GrimoireOrderCopyWith<$Res> {
  _$GrimoireOrderCopyWithImpl(this._self, this._then);

  final GrimoireOrder _self;
  final $Res Function(GrimoireOrder) _then;

/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? combatId = null,Object? seq = null,Object? sentAt = freezed,Object? round = null,Object? participants = null,Object? currentParticipantId = freezed,}) {
  return _then(GrimoireOrder(
combatId: null == combatId ? _self.combatId : combatId // ignore: cast_nullable_to_non_nullable
as String,seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<GrimoireParticipant>,currentParticipantId: freezed == currentParticipantId ? _self.currentParticipantId : currentParticipantId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class GrimoireTurn implements GrimoireMessage {
  const GrimoireTurn({required this.combatId, required this.seq, this.sentAt, required this.round, this.currentParticipantId});
  

@override final  String combatId;
@override final  int seq;
@override final  DateTime? sentAt;
 final  int round;
 final  String? currentParticipantId;

/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrimoireTurnCopyWith<GrimoireTurn> get copyWith => _$GrimoireTurnCopyWithImpl<GrimoireTurn>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrimoireTurn&&(identical(other.combatId, combatId) || other.combatId == combatId)&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.round, round) || other.round == round)&&(identical(other.currentParticipantId, currentParticipantId) || other.currentParticipantId == currentParticipantId));
}


@override
int get hashCode => Object.hash(runtimeType,combatId,seq,sentAt,round,currentParticipantId);

@override
String toString() {
  return 'GrimoireMessage.turn(combatId: $combatId, seq: $seq, sentAt: $sentAt, round: $round, currentParticipantId: $currentParticipantId)';
}


}

/// @nodoc
abstract mixin class $GrimoireTurnCopyWith<$Res> implements $GrimoireMessageCopyWith<$Res> {
  factory $GrimoireTurnCopyWith(GrimoireTurn value, $Res Function(GrimoireTurn) _then) = _$GrimoireTurnCopyWithImpl;
@override @useResult
$Res call({
 String combatId, int seq, DateTime? sentAt, int round, String? currentParticipantId
});




}
/// @nodoc
class _$GrimoireTurnCopyWithImpl<$Res>
    implements $GrimoireTurnCopyWith<$Res> {
  _$GrimoireTurnCopyWithImpl(this._self, this._then);

  final GrimoireTurn _self;
  final $Res Function(GrimoireTurn) _then;

/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? combatId = null,Object? seq = null,Object? sentAt = freezed,Object? round = null,Object? currentParticipantId = freezed,}) {
  return _then(GrimoireTurn(
combatId: null == combatId ? _self.combatId : combatId // ignore: cast_nullable_to_non_nullable
as String,seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,currentParticipantId: freezed == currentParticipantId ? _self.currentParticipantId : currentParticipantId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class GrimoireParticipantRemoved implements GrimoireMessage {
  const GrimoireParticipantRemoved({required this.combatId, required this.seq, this.sentAt, required this.participantId});
  

@override final  String combatId;
@override final  int seq;
@override final  DateTime? sentAt;
 final  String participantId;

/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrimoireParticipantRemovedCopyWith<GrimoireParticipantRemoved> get copyWith => _$GrimoireParticipantRemovedCopyWithImpl<GrimoireParticipantRemoved>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrimoireParticipantRemoved&&(identical(other.combatId, combatId) || other.combatId == combatId)&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.participantId, participantId) || other.participantId == participantId));
}


@override
int get hashCode => Object.hash(runtimeType,combatId,seq,sentAt,participantId);

@override
String toString() {
  return 'GrimoireMessage.participantRemoved(combatId: $combatId, seq: $seq, sentAt: $sentAt, participantId: $participantId)';
}


}

/// @nodoc
abstract mixin class $GrimoireParticipantRemovedCopyWith<$Res> implements $GrimoireMessageCopyWith<$Res> {
  factory $GrimoireParticipantRemovedCopyWith(GrimoireParticipantRemoved value, $Res Function(GrimoireParticipantRemoved) _then) = _$GrimoireParticipantRemovedCopyWithImpl;
@override @useResult
$Res call({
 String combatId, int seq, DateTime? sentAt, String participantId
});




}
/// @nodoc
class _$GrimoireParticipantRemovedCopyWithImpl<$Res>
    implements $GrimoireParticipantRemovedCopyWith<$Res> {
  _$GrimoireParticipantRemovedCopyWithImpl(this._self, this._then);

  final GrimoireParticipantRemoved _self;
  final $Res Function(GrimoireParticipantRemoved) _then;

/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? combatId = null,Object? seq = null,Object? sentAt = freezed,Object? participantId = null,}) {
  return _then(GrimoireParticipantRemoved(
combatId: null == combatId ? _self.combatId : combatId // ignore: cast_nullable_to_non_nullable
as String,seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,participantId: null == participantId ? _self.participantId : participantId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class GrimoireCombatEnd implements GrimoireMessage {
  const GrimoireCombatEnd({required this.combatId, required this.seq, this.sentAt, required this.rounds, required this.participantCount});
  

@override final  String combatId;
@override final  int seq;
@override final  DateTime? sentAt;
 final  int rounds;
 final  int participantCount;

/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrimoireCombatEndCopyWith<GrimoireCombatEnd> get copyWith => _$GrimoireCombatEndCopyWithImpl<GrimoireCombatEnd>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrimoireCombatEnd&&(identical(other.combatId, combatId) || other.combatId == combatId)&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.rounds, rounds) || other.rounds == rounds)&&(identical(other.participantCount, participantCount) || other.participantCount == participantCount));
}


@override
int get hashCode => Object.hash(runtimeType,combatId,seq,sentAt,rounds,participantCount);

@override
String toString() {
  return 'GrimoireMessage.combatEnd(combatId: $combatId, seq: $seq, sentAt: $sentAt, rounds: $rounds, participantCount: $participantCount)';
}


}

/// @nodoc
abstract mixin class $GrimoireCombatEndCopyWith<$Res> implements $GrimoireMessageCopyWith<$Res> {
  factory $GrimoireCombatEndCopyWith(GrimoireCombatEnd value, $Res Function(GrimoireCombatEnd) _then) = _$GrimoireCombatEndCopyWithImpl;
@override @useResult
$Res call({
 String combatId, int seq, DateTime? sentAt, int rounds, int participantCount
});




}
/// @nodoc
class _$GrimoireCombatEndCopyWithImpl<$Res>
    implements $GrimoireCombatEndCopyWith<$Res> {
  _$GrimoireCombatEndCopyWithImpl(this._self, this._then);

  final GrimoireCombatEnd _self;
  final $Res Function(GrimoireCombatEnd) _then;

/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? combatId = null,Object? seq = null,Object? sentAt = freezed,Object? rounds = null,Object? participantCount = null,}) {
  return _then(GrimoireCombatEnd(
combatId: null == combatId ? _self.combatId : combatId // ignore: cast_nullable_to_non_nullable
as String,seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rounds: null == rounds ? _self.rounds : rounds // ignore: cast_nullable_to_non_nullable
as int,participantCount: null == participantCount ? _self.participantCount : participantCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class GrimoireState implements GrimoireMessage {
  const GrimoireState({required this.combatId, required this.seq, this.sentAt, required this.active, required this.round, this.currentParticipantId, required  List<String> initiativeRequestedFor, required  List<GrimoireParticipant> participants}): _initiativeRequestedFor = initiativeRequestedFor,_participants = participants;
  

@override final  String combatId;
@override final  int seq;
@override final  DateTime? sentAt;
 final  bool active;
 final  int round;
 final  String? currentParticipantId;
 final  List<String> _initiativeRequestedFor;
 List<String> get initiativeRequestedFor {
  if (_initiativeRequestedFor is EqualUnmodifiableListView) return _initiativeRequestedFor;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_initiativeRequestedFor);
}

 final  List<GrimoireParticipant> _participants;
 List<GrimoireParticipant> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}


/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrimoireStateCopyWith<GrimoireState> get copyWith => _$GrimoireStateCopyWithImpl<GrimoireState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrimoireState&&(identical(other.combatId, combatId) || other.combatId == combatId)&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.active, active) || other.active == active)&&(identical(other.round, round) || other.round == round)&&(identical(other.currentParticipantId, currentParticipantId) || other.currentParticipantId == currentParticipantId)&&const DeepCollectionEquality().equals(other._initiativeRequestedFor, _initiativeRequestedFor)&&const DeepCollectionEquality().equals(other._participants, _participants));
}


@override
int get hashCode => Object.hash(runtimeType,combatId,seq,sentAt,active,round,currentParticipantId,const DeepCollectionEquality().hash(_initiativeRequestedFor),const DeepCollectionEquality().hash(_participants));

@override
String toString() {
  return 'GrimoireMessage.state(combatId: $combatId, seq: $seq, sentAt: $sentAt, active: $active, round: $round, currentParticipantId: $currentParticipantId, initiativeRequestedFor: $initiativeRequestedFor, participants: $participants)';
}


}

/// @nodoc
abstract mixin class $GrimoireStateCopyWith<$Res> implements $GrimoireMessageCopyWith<$Res> {
  factory $GrimoireStateCopyWith(GrimoireState value, $Res Function(GrimoireState) _then) = _$GrimoireStateCopyWithImpl;
@override @useResult
$Res call({
 String combatId, int seq, DateTime? sentAt, bool active, int round, String? currentParticipantId, List<String> initiativeRequestedFor, List<GrimoireParticipant> participants
});




}
/// @nodoc
class _$GrimoireStateCopyWithImpl<$Res>
    implements $GrimoireStateCopyWith<$Res> {
  _$GrimoireStateCopyWithImpl(this._self, this._then);

  final GrimoireState _self;
  final $Res Function(GrimoireState) _then;

/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? combatId = null,Object? seq = null,Object? sentAt = freezed,Object? active = null,Object? round = null,Object? currentParticipantId = freezed,Object? initiativeRequestedFor = null,Object? participants = null,}) {
  return _then(GrimoireState(
combatId: null == combatId ? _self.combatId : combatId // ignore: cast_nullable_to_non_nullable
as String,seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,round: null == round ? _self.round : round // ignore: cast_nullable_to_non_nullable
as int,currentParticipantId: freezed == currentParticipantId ? _self.currentParticipantId : currentParticipantId // ignore: cast_nullable_to_non_nullable
as String?,initiativeRequestedFor: null == initiativeRequestedFor ? _self._initiativeRequestedFor : initiativeRequestedFor // ignore: cast_nullable_to_non_nullable
as List<String>,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<GrimoireParticipant>,
  ));
}


}

/// @nodoc


class GrimoireUnknownMessage implements GrimoireMessage {
  const GrimoireUnknownMessage({required this.combatId, required this.seq, this.sentAt, required this.type, this.malformed = false});
  

@override final  String combatId;
@override final  int seq;
@override final  DateTime? sentAt;
 final  String type;
@JsonKey() final  bool malformed;

/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrimoireUnknownMessageCopyWith<GrimoireUnknownMessage> get copyWith => _$GrimoireUnknownMessageCopyWithImpl<GrimoireUnknownMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrimoireUnknownMessage&&(identical(other.combatId, combatId) || other.combatId == combatId)&&(identical(other.seq, seq) || other.seq == seq)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.type, type) || other.type == type)&&(identical(other.malformed, malformed) || other.malformed == malformed));
}


@override
int get hashCode => Object.hash(runtimeType,combatId,seq,sentAt,type,malformed);

@override
String toString() {
  return 'GrimoireMessage.unknown(combatId: $combatId, seq: $seq, sentAt: $sentAt, type: $type, malformed: $malformed)';
}


}

/// @nodoc
abstract mixin class $GrimoireUnknownMessageCopyWith<$Res> implements $GrimoireMessageCopyWith<$Res> {
  factory $GrimoireUnknownMessageCopyWith(GrimoireUnknownMessage value, $Res Function(GrimoireUnknownMessage) _then) = _$GrimoireUnknownMessageCopyWithImpl;
@override @useResult
$Res call({
 String combatId, int seq, DateTime? sentAt, String type, bool malformed
});




}
/// @nodoc
class _$GrimoireUnknownMessageCopyWithImpl<$Res>
    implements $GrimoireUnknownMessageCopyWith<$Res> {
  _$GrimoireUnknownMessageCopyWithImpl(this._self, this._then);

  final GrimoireUnknownMessage _self;
  final $Res Function(GrimoireUnknownMessage) _then;

/// Create a copy of GrimoireMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? combatId = null,Object? seq = null,Object? sentAt = freezed,Object? type = null,Object? malformed = null,}) {
  return _then(GrimoireUnknownMessage(
combatId: null == combatId ? _self.combatId : combatId // ignore: cast_nullable_to_non_nullable
as String,seq: null == seq ? _self.seq : seq // ignore: cast_nullable_to_non_nullable
as int,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,malformed: null == malformed ? _self.malformed : malformed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
