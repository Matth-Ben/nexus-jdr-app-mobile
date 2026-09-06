/// Échec de récupération/manipulation d'un groupe, porteur d'un message déjà
/// traduit et adapté à l'affichage utilisateur final — même principe que
/// `CharacterFailure`/`StoryInviteFailure`.
class GroupFailure implements Exception {
  const GroupFailure(this.message);

  final String message;

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is GroupFailure && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
