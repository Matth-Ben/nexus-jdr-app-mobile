/// Un tir arcanique disponible au choix à l'étape "Tirs arcaniques" de la
/// montée de niveau (Guerrier, Archer arcanique,
/// `presentation/level_up_screen.dart`) — nom/description déjà résolus via
/// `translations` (`entity_type = 'class_option'`), voir
/// `data/level_up_arcane_shot_row_mapper.dart`.
///
/// Ne liste que les tirs arcaniques dont `class_options.min_level` est déjà
/// atteint ET NON déjà connus du personnage (`character_class_options`, voir
/// `data/character_repository.dart::fetchAvailableArcaneShots`) — RAW : les
/// 8 tirs arcaniques du catalogue ont tous `min_level = 3` (confirmé par
/// `regles-dnd`), donc ce filtre n'exclut jamais rien par le niveau en
/// pratique, seule l'exclusion "déjà connu" est réellement discriminante.
///
/// Duplicata volontaire de [LevelUpManeuverOption]/
/// [LevelUpElementalDisciplineOption] (même structure, même rationale de
/// duplication) — voir leur documentation de classe : chaque étape dédiée de
/// la montée de niveau garde son propre modèle d'option, jamais partagé
/// entre deux mécaniques de classes différentes.
///
/// Volontairement une classe simple (pas `freezed`), même précédent.
class LevelUpArcaneShotOption {
  const LevelUpArcaneShotOption({
    required this.id,
    required this.name,
    required this.description,
  });

  /// `class_options.id` (entier côté Supabase, gardé en [Object] — même
  /// convention que `LevelUpManeuverOption.id`).
  final Object id;

  final String name;

  /// Description complète du tir arcanique, affichée en `subtitle` de la
  /// `CheckableOptionTile` de l'étape "Tirs arcaniques" — même traitement
  /// que [LevelUpManeuverOption.description].
  final String description;
}
