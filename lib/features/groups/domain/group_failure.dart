/// Code d'erreur stable d'une [GroupFailure] (D141), traduit côté
/// présentation.
enum GroupErrorCode {
  /// Refus RLS (`42501`).
  accessDenied,

  /// Erreur avant toute réponse HTTP, ou réponse sans message exploitable.
  network,

  /// Groupe absent ou supprimé entre-temps.
  groupNotFound,

  /// Aucune session Supabase active.
  sessionExpired,

  /// Aucun code d'invitation libre trouvé après les tentatives.
  inviteCodeGenerationFailed,

  /// Tout le reste : [GroupFailure.message] (brut) fait foi.
  generic,
}

/// Échec de récupération/manipulation d'un groupe, porteur d'un message déjà
/// traduit et adapté à l'affichage utilisateur final — même principe que
/// `CharacterFailure`/`StoryInviteFailure`.
///
/// [code] (D141) est un identifiant stable résolu en texte localisé par la
/// couche `presentation/` (`presentation/group_failure_l10n.dart`) ;
/// [message] (français) ne sert que pour [GroupErrorCode.generic] (message
/// brut du serveur).
class GroupFailure implements Exception {
  const GroupFailure(this.message, {this.code = GroupErrorCode.generic});

  final String message;

  /// Voir [GroupErrorCode].
  final GroupErrorCode code;

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is GroupFailure && other.message == message && other.code == code;

  @override
  int get hashCode => Object.hash(message, code);
}
