import 'package:freezed_annotation/freezed_annotation.dart';

import 'combat_enums.dart';

part 'grimoire_participant.freezed.dart';

/// Participant **public** d'un combat mené depuis Grimoire, tel que diffusé
/// sur le sujet `:gm` (contrat DeepCore `docs/api-v1/contrat-temps-reel-combat.md`
/// §4.1). Seul format qui décrit un participant : ni PV, ni CA, ni état
/// « vaincu » (décision 43).
///
/// [name] est un texte **non fiable** choisi par le MJ : toujours affiché comme
/// texte brut. [status] n'accepte que [ParticipantStatus.active] et
/// [ParticipantStatus.waiting] (jamais `removed` : un retrait passe par
/// `participant_removed`).
@freezed
abstract class GrimoireParticipant with _$GrimoireParticipant {
  const GrimoireParticipant._();

  const factory GrimoireParticipant({
    /// Identifiant tiré au hasard par Grimoire pour ce combat.
    required String id,
    required ParticipantKind kind,
    required String name,

    /// Personnage Nexus d'un `pc` relié ; `null` pour un `npc` ou un `pc`
    /// non relié.
    String? characterId,

    /// Compte du joueur (« Toi ») ; `null` tant que Grimoire ne le connaît pas.
    String? userId,

    /// `null` : « Initiative à saisir ».
    int? initiative,
    @Default(ParticipantStatus.active) ParticipantStatus status,
  }) = _GrimoireParticipant;

  bool get hasInitiative => initiative != null;

  bool get isPc => kind == ParticipantKind.pc;
}
