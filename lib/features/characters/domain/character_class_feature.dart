/// Une aptitude de classe atteinte par le niveau actuel du personnage
/// (onglet "Compétences", carte "APTITUDES DE CLASSE" —
/// `presentation/widgets/character_class_features_card.dart`) — voir
/// `data/class_feature_row_mapper.dart` pour la résolution depuis
/// `class_features`/`character_feature_uses`.
///
/// Inclut aussi bien les aptitudes de classe de base
/// (`class_features.class_id`) que les aptitudes de sous-classe
/// (`class_features.subclass_id`) de la sous-classe effectivement choisie
/// par le personnage pour chacune de ses classes
/// (`character_classes.subclass_id`, écrit par la montée de niveau,
/// `LevelUpChoiceKind.subclass`) — les deux apparaissent ensemble sur la
/// même carte, triées (voir `data/character_repository.dart
/// ::_mapCharacterDetailPayload`, tri alphabétique français, pas par
/// niveau d'acquisition). Une classe sans sous-classe encore choisie
/// n'ajoute simplement rien pour elle, sans erreur.
///
/// **Historique** : cette portée excluait initialement toute aptitude de
/// sous-classe (bug architectural trouvé par l'agent `regles-dnd` en
/// investiguant le Guerrier Maître de guerre, périmètre élargi à toutes les
/// sous-classes) — la précondition d'origine ("l'assistant de création ne
/// permet pas encore de choisir de sous-classe") n'était déjà plus vraie
/// depuis l'ajout du choix de sous-classe à la montée de niveau ; voir
/// `data/class_feature_row_mapper.dart::ClassFeatureRowMapper.filterAttained`
/// pour le détail du correctif.
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
