/// Code d'erreur stable associé à une [GroupFailure].
///
/// **Choix architectural** (chantier "traduction de l'app" Phase B, lot
/// "Groups — rejoindre/créer") : même rationale exacte que `CharacterErrorCode`
/// (`features/characters/domain/character_failure.dart`) et `AuthErrorCode`
/// — `data/group_error_mapper.dart` vit dans la couche `data/` et n'a donc
/// jamais accès à un `BuildContext`/`AppLocalizations.of(context)`.
/// `GroupFailure` garde donc la responsabilité de choisir un [code] (cet
/// enum) à partir de l'erreur Supabase brute — un simple identifiant stable,
/// sans aucun texte — et c'est à la couche `presentation/` de résoudre le
/// texte final affiché, via `AppLocalizations` (elle, a accès à `context`).
/// [message] reste produit en parallèle (texte français déjà construit,
/// comportement inchangé) pour que tous les appelants qui n'ont pas encore
/// été migrés continuent de fonctionner sans aucune modification : seuls
/// `group_list_screen.dart` et `group_create_screen.dart` lisent [code] à ce
/// stade, tous les autres appelants de ce dépôt (`group_screen.dart`,
/// `group_settings_screen.dart`, `group_character_reassignment_screen.dart`)
/// continuent de lire [message] directement — voir D158 du registre de dette
/// technique (`docs/dette-technique.md`).
///
/// **Précédent pour les prochains lots** : chaque futur lot qui migre un
/// écran consommant une [GroupFailure] doit lire [code] (en complétant cet
/// enum si besoin) plutôt que [message], jusqu'à ce que plus aucun appelant
/// ne dépende de [message] — qui pourra alors être retiré.
enum GroupErrorCode {
  /// Code Postgres générique de refus RLS (`42501`) — voir
  /// `data/group_error_mapper.dart::mapGroupError`.
  accessDenied,

  /// Erreur survenue avant toute réponse HTTP (absence de réseau...), voir
  /// `data/group_error_mapper.dart::mapUnknownGroupError`.
  network,

  /// Tout le reste : code Postgrest/edge function non mappé explicitement,
  /// message dynamique renvoyé par le serveur, ou `GroupFailure` construite
  /// directement par un appelant qui ne précise pas [code]. [message] reste
  /// dans ce cas la seule source de texte utilisable.
  generic,
}

/// Échec de récupération/manipulation d'un groupe, porteur d'un message déjà
/// traduit et adapté à l'affichage utilisateur final ([message]), ainsi que
/// d'un [code] stable permettant une résolution localisée côté
/// `presentation/` — voir la doc de classe d'[GroupErrorCode] pour le choix
/// architectural complet. Même principe que `CharacterFailure`/
/// `StoryInviteFailure`.
class GroupFailure implements Exception {
  const GroupFailure(this.message, {this.code = GroupErrorCode.generic});

  final String message;

  /// Voir la doc de classe d'[GroupErrorCode].
  final GroupErrorCode code;

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is GroupFailure && other.message == message && other.code == code;

  @override
  int get hashCode => Object.hash(message, code);
}
