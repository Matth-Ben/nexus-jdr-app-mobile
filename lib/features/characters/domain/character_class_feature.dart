/// Une aptitude de classe atteinte par le niveau actuel du personnage
/// (onglet "Compétences", carte "APTITUDES DE CLASSE" —
/// `presentation/widgets/character_class_features_card.dart`) — voir
/// `data/class_feature_row_mapper.dart` pour la résolution depuis
/// `class_features`/`character_feature_uses`.
///
/// Portée volontairement limitée à cette itération : les aptitudes de
/// sous-classe (`class_features.subclass_id`) ne sont jamais incluses ici,
/// pas seulement parce qu'elles ne sont pas encore affichées, mais parce que
/// l'assistant de création ne permet pas encore de choisir de sous-classe
/// (`character_classes.subclass_id` reste toujours `null` à la création,
/// voir `character_creation_repository.dart::createCharacter`) — rien à
/// résoudre pour l'instant. À reprendre le jour où le choix de sous-classe
/// est ajouté à l'assistant.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// `CharacterDetailClassRow` : donnée en lecture seule affichée telle
/// quelle.
class CharacterClassFeature {
  const CharacterClassFeature({
    required this.id,
    required this.name,
    required this.level,
    this.usesMax,
    this.usesRemaining,
    this.restType,
    this.description = '',
  });

  final int id;
  final String name;

  /// Niveau de classe auquel l'aptitude est obtenue.
  final int level;

  /// `class_features.uses_per_rest->>'amount'`, `null` pour une aptitude
  /// passive (sans usage limité) — affichée "Passive" plutôt qu'un compteur,
  /// voir [isPassive].
  final int? usesMax;

  /// `character_feature_uses.uses_remaining` pour ce personnage/cette
  /// aptitude, `null` si aucune ligne `character_feature_uses` n'existe
  /// encore (l'assistant de création n'en insère jamais — portée
  /// strictement en lecture seule à cette itération, aucun décompte d'usage :
  /// voir la documentation de classe de
  /// `presentation/widgets/character_skills_tab_body.dart`). C'est à
  /// l'affichage (`class_feature_usage_formatter.dart`) de retomber sur
  /// [usesMax] dans ce cas (aucune utilisation encore consommée), pas à ce
  /// modèle.
  final int? usesRemaining;

  /// `class_features.uses_per_rest->>'rest_type'` : 'repos_court' ou
  /// 'repos_long'.
  final String? restType;

  /// `class_features.description`, chaîne vide si non renseignée — panneau
  /// "Infos" (`presentation/widgets/class_feature_info_panel.dart`).
  final String description;

  /// Vrai si l'aptitude n'a pas d'usage limité (`uses_per_rest` nul côté
  /// base) — affichée "Passive" plutôt qu'un compteur.
  bool get isPassive => usesMax == null;
}
