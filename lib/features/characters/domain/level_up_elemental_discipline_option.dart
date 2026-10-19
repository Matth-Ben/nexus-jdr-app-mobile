/// Une discipline élémentaire disponible au choix à l'étape "Disciplines
/// élémentaires" de la montée de niveau (Moine, Voie des quatre éléments,
/// `presentation/level_up_screen.dart`) — nom/description déjà résolus via
/// `translations` (`entity_type = 'class_option'`), voir
/// `data/level_up_elemental_discipline_row_mapper.dart`.
///
/// Ne liste que les disciplines dont `class_options.min_level` est déjà
/// atteint ET NON déjà connues du personnage (`character_class_options`,
/// voir `data/character_repository.dart::fetchAvailableElementalDisciplines`)
/// — contrairement à [LevelUpInvocationOption] (voisine, même chantier
/// correctif), aucun prérequis structuré supplémentaire à ce jour (RAW : la
/// seule condition d'obtention d'une discipline élémentaire est le niveau de
/// Moine).
///
/// Volontairement une classe simple (pas `freezed`) : même précédent que
/// [LevelUpInvocationOption]/[LevelUpFeatOption], donnée en lecture seule
/// construite une fois par le repository.
class LevelUpElementalDisciplineOption {
  const LevelUpElementalDisciplineOption({
    required this.id,
    required this.name,
    required this.description,
  });

  /// `class_options.id` (entier côté Supabase, gardé en [Object] — même
  /// convention que `LevelUpInvocationOption.id`).
  final Object id;

  final String name;

  /// Description complète de la discipline, affichée en `subtitle` de la
  /// `CheckableOptionTile` de l'étape "Disciplines élémentaires" — même
  /// traitement que [LevelUpInvocationOption.description] (pas de panneau
  /// "Infos" séparé pour cette étape).
  final String description;
}
